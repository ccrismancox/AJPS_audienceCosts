import numpy as np
import pickle as pk
import pandas as pd
import os
import shutil
import scipy.sparse as sps
import pyipopt
from time import time
import adolc
from genDyadGiven import *
from estFunctions import *


## Load the data and create matrices from them

Data = pk.load(open('MainDataSet.p', 'rb'))
Xij = Data['Xij']
Z = Data['Xi']
ts = Data['dataSets']
M = np.array(Data['M'], dtype='int64')
Mun = Data['Mun']


'''
Generate the time series array 
(179 dyads by 180 time periods by 3 state-action pairs)
'''
tsArray = np.zeros((len(Mun.dyadID), 180, 3) )
k = 0
for i in Mun.dyadID:
    tempdf =  np.array(ts[ts.dyadID==i][['state', 'action1',  'action2']])
    tsArray[k,:tempdf.shape[0],:] = tempdf
    k += 1
        
    
#Peel off and create X matrix
Xij = np.array(Xij[['minPolityMEAN', 'cap.ratioMEAN', 'dependMEAN']])
Xij = np.hstack((np.ones((Xij.shape[0], 1)), Xij))
Xij[:,2] = np.log(Xij[:,2])
Xij[:,3] = np.sqrt(Xij[:,3])

#Peel off and transform Z variables as mentioned in the paper    
Z = np.array(Z[['gdppcMEAN.1', 'milperpcMEAN.1']])
Z[:, 0] = np.log(Z[:,0]+1)
Z[:, 1] = np.log(Z[:,1]+1)
Z = np.hstack((np.ones((Z.shape[0], 1)), Z))

Mun = np.array(Mun, dtype='int64')[:,:2] #convert Mun into array
given = genDyadGiven(M,Mun, tsArray, Xij, Z,.9)


startValues = pk.load(open('replicationInput.p', 'rb'))

'''
#The original starting values can be found here; if using these
#computation will take roughly 3-4 months and will require this code to be
#modified.  We side step this here in order to save everyone time, but we 
#varify that the solution is a local optimum, as mentioned in the manuscript

#original start values 
restart = {'results': (np.random.uniform(size=given['nAll']),0, 0,np.random.uniform(size=given['nAux'])) } 
'''

x0 = startValues['results'][0]
xL = startValues['results'][3]

#define the functions
def LL(x):
    return  LLdyad_Month(x, given)
     
def const(x):
    """ constraint function """
    return MPECct(x, given)

  
def lagrangian(x, lagrange, obj_factor):
    return  obj_factor*LL(x) + np.dot(lagrange, const(x))



#create a directory for ADOLC files to go
ccd = os.getcwd()
if not os.path.exists('/home/%s/Documents/Python/ADOLC'%(os.environ["USER"])):
    os.makedirs('/home/%s/Documents/Python/ADOLC'%(os.environ["USER"]))

os.chdir('/home/%s/Documents/Python/ADOLC'%(os.environ["USER"]))


adolc.trace_on(1)
ax = adolc.adouble(x0)
adolc.independent(ax)
ay = LL(ax)
adolc.dependent(ay)
adolc.trace_off()

# trace constraint function
adolc.trace_on(2)
ax = adolc.adouble(x0)
adolc.independent(ax)
ay = const(ax)
adolc.dependent(ay)
adolc.trace_off()

  
#Define the AD versions of the functions
    
def LLadolc(x):
    return adolc.function(1,x)

def grLLadolc(x):
    return adolc.gradient(1,x)

def  const_adolc(x):
    return adolc.function(2,x)


'''
Jacobian
'''

#### initalize it
class jac_c_adolc:
    
    def __init__(self, x):
        options = np.array([1,1,0,0],dtype=int)
        result = adolc.colpack.sparse_jac_no_repeat(2,x,options)
        
        self.nnz  = result[0]     
        self.rind = np.asarray(result[1],dtype=int)
        self.cind = np.asarray(result[2],dtype=int)
        self.values = np.asarray(result[3],dtype=float)
        
    def __call__(self, x, flag, user_data=None):
        if flag:
            return (self.rind, self.cind)
        else:
            result = adolc.colpack.sparse_jac_repeat(2, x, self.nnz, self.rind,
                self.cind, self.values)
            return result[3]

##### create the function
Jac_c_adolc = jac_c_adolc(x0)





'''
Hessian
'''    
# trace lagrangian function
adolc.trace_on(3)
ax = adolc.adouble(x0)
adolc.independent(ax)
ay = lagrangian(ax, xL, 1.0)
adolc.dependent(ay)
adolc.trace_off()
    
    
    
# Create a spare hessian function
# setup
    
class hessLag_adolc_sp:
  def __init__(self, x, given):
      options = np.array([0,1],dtype=int)
      result = adolc.colpack.sparse_hess_no_repeat(3,x,options)
          
      self.cind = np.asarray(result[2],dtype=int)        
      #self.mask = np.where(self.cind < given['nAll'])    
      self.rind = np.asarray(result[1],dtype=int)
      self.cind = self.cind
      self.values = np.asarray(result[3],dtype=float)
      self.mask = np.where(self.cind < given['nAll'])    
  def __call__(self, x, lagrange,obj_factor,flag, user_data=None):
      if flag:
          return (self.rind[self.mask], self.cind[self.mask])
      else:
       #   x = np.hstack([x,lagrange,obj_factor])
          result = adolc.colpack.sparse_hess_repeat(3, x, self.rind,
                                                      self.cind, self.values)
      return result[3][self.mask]
      
      
# initalize the function          
hessLag_adolc = hessLag_adolc_sp(x0, given)



H2 = hessLag_adolc(x0, xL, 1.0, False)
nnzh = len(H2)
    
'''
Optimization
'''

#PRELIMS: other things to pass to IPOPT
nvar = len(x0) #number of variables in the problem
x_L = np.array([-np.inf]*nvar, dtype=float) #box contraints on variables (none)
x_U = np.array([np.inf]*nvar, dtype=float)
 
#PRELIMS:define the (in)equality constraints
ncon = const(x0).shape[0] #number of constraints
g_L = np.array([0]*ncon, dtype=float) #constraints are to equal 0
g_U = np.array([0]*ncon, dtype=float) #constraints are to equal 0


#PRELIMS: define the number of nonzeros in the jacobian 
val = Jac_c_adolc(x0, False) 
nnzj = len(val)            

  
# create the nonlinear programming model
nlp2 = pyipopt.create(
nvar, 
x_L,
x_U,
ncon,
g_L,
g_U,
nnzj,
nnzh,
LLadolc,
grLLadolc,
const_adolc,
Jac_c_adolc,
hessLag_adolc
)
    


# set options for IPOPT
nlp2.num_option('expect_infeasible_problem_ctol', 1e-15)
nlp2.int_option('max_iter', 22500*2)
nlp2.num_option('dual_inf_tol', 1)
nlp2.num_option('constr_viol_tol', 1e-5)
nlp2.num_option('tol', 1e-6)

# Solve the problem
results = nlp2.solve(x0)


# free the model
nlp2.close()
print results[0][:given['nReal']]
out = {'results': results}

#clean up ADOLC and return to original directory for saving results
os.chdir(ccd)
shutil.rmtree('/home/%s/Documents/Python/ADOLC'%(os.environ["USER"])) 
results = out['results'][0]





'''
Convert results for use in R
'''

print "CONVERTING OUTPUT TO R DATA"
from rpy2.robjects import r
from rpy2.robjects.numpy2ri import numpy2ri
import pandas.rpy.common as com

ts_df = com.convert_to_r_dataframe(ts)
r.assign("ts_df", ts_df)

export = ['results', 'Xij', 'Z', 'M', 'Mun']
for s in export:
    exec("%s = numpy2ri(%s)"%(s,s))
    r.assign("%s"%s, eval("%s"%s))
        
        
r("save.image('../../Paper Results/ReplicationOutput.rdata')")

   