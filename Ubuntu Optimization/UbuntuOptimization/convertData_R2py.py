'''
Read in Dyadic MIDs data.  Convert to pandas DataFrame for now.  
Will change to numpy arrays when needed
'''
import rpy2.robjects as robj #for loading the .rdata file
import pandas.rpy.common as rpd #for converting into something python recognizes 
#FUTURE 
# from rpy2.robjects import pandas2ri
# find and replace rpd.convert_robj with pandas2ri.ri2py
import pickle as pk
import numpy as np
import pandas as pd

print "CONVERTING DATA FROM R TO PYTHON"

#open a connection to R and load data
robj.r("load('../../Data/DyadicMIDS_Rdata.rdata')")
robj.r("install.packages('data.table', lib='~/R/x86_64-pc-linux-gnu-library/3.4', repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)")
robj.r("library(data.table)")
Xi = rpd.convert_robj(robj.r('Xi'))
Xij = rpd.convert_robj(robj.r('Xij'))
monthDat = rpd.convert_robj(robj.r('dataSets$M'))
robj.r('mf <- unique(c(Xij$ccode1,Xij$ccode2)); Xij$ccode1 <- as.numeric(factor(Xij$ccode1 ,levels=mf));Xij$ccode2 <- as.numeric(factor(Xij$ccode2 ,levels=mf))')

M = rpd.convert_robj(robj.r('subset(Xij, select=c(ccode1, ccode2))'))
Mun = rpd.convert_robj(robj.r(' Xij[, list(dyadID=base::min(dyadID)), by=list(ccode1=pmin(ccode1,ccode2), ccode2=pmax(ccode1,ccode2))]'))

#Remove non-conflict dyads
keepDyad = tuple()
keepCcode = tuple()
for i in Xij.dyadID:
    case = monthDat[monthDat.dyadID==i]
    if(np.any(case.state > 1)): 
        keepDyad = keepDyad + (i,) 
        keepCcode = keepCcode + (np.unique(case.ccode1) , np.unique(case.ccode2))


keepCcode = np.unique(np.array(keepCcode))
Xi = Xi[pd.match(Xi.ccode, keepCcode) >=0]
Xij = Xij[pd.match(Xij.dyadID, keepDyad) >=0]
monthDat = monthDat[pd.match(monthDat.dyadID, keepDyad) >=0]


Q1 = pd.Categorical(Xij.ccode1)
Q1.levels = np.arange(1, len(Q1.levels)+1 )
Xij.loc[:, ('ccode1')] = Q1


Q2 = pd.Categorical(Xij.ccode2)
Q2.levels = np.arange(1, len(Q2.levels)+1 )
Xij.loc[:, ('ccode2')]  = Q2
M = Xij[['ccode1', 'ccode2']]


Q = pd.DataFrame(np.min(Xij[['ccode1', 'ccode2']], axis=1), columns=['ccode1']).join(pd.DataFrame(np.max(Xij[['ccode1', 'ccode2']], axis=1), columns=['ccode2'])).drop_duplicates()
D = Q.merge(Xij).dyadID
Q = Q.reset_index()[['ccode1', 'ccode2']]
Mun = Q.join(D)
saves = dict(Xi=Xi, Xij=Xij, dataSets=monthDat, M=M, Mun=Mun)

pk.dump(saves, open("MainDataSet.p", "wb"))
