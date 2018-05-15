import numpy as np
from kappaDyad import *
from UsaDyadParam import *


    
def LLdyad_Month(x, given):
    '''
    INFO :: Evaluate the log likelihood
    INPUTS :: 
    -x     : structural parameters (theta, v)
    -given : given from genDyadGiven
    OUTPUTS ::  a scaler, LL, that is the negative of the log-likelihood
    '''
    V = x[given['nReal']:(given['nAll']+1)].reshape((18,-1), order='F')
    v1 = V[0:9,:].reshape((1,-1), order='F')
    v2 = V[9:19,:].reshape((1,-1), order='F')
    
    v1m =  np.array(np.split(v1, given['mun'], axis=1)).reshape((given['mun'],3,3), order='F')
    v2m =  np.array(np.split(v2, given['mun'], axis=1)).reshape((given['mun'],3,3), order='F')
    
    cSAD1 = given['stateActionsInData'][0:9,:].reshape((-1,1), order='F')    
    cSAD2 = given['stateActionsInData'][9:19,:].reshape((-1,1), order='F')    
    
    LL = v1.dot(cSAD1)/180 -  np.sum(np.log(np.sum(np.exp(v1m), axis=1).T) * given['statesInData'])/180
    LL = LL + v2.dot(cSAD2)/180  - np.sum(np.log(np.sum(np.exp(v2m), axis=1).T) * given['statesInData'])/180
    
    return -LL    
    
def MPECct(x, given):
    '''
    INFO :: Evaluate the constraint
    INPUTS :: 
    -x     : structural parameters (theta, v)
    -given : given from genDyadGiven
    OUTPUTS :: v-Phi(v), a vector of 18*given['mun'] 
    '''
    beta2 = x[0:(len(given['statVar'][given['statVar'].keys()[0]]))]
    beta3 = x[len(beta2):(given['nBeta'])]
    ActCost = kappaDyad(x[(given['nBeta']):(given['nBeta']+given['nKappa']/2)].reshape((-1,1)),
                        x[(given['nBeta']+given['nKappa']/2):(given['nBeta']+given['nKappa'])].reshape(-1,1),
                          given['Xk'])
    gamma = x[(given['nBeta']+given['nKappa']):(given['nBeta'] + given['nKappa']+3)]                      
    alpha = x[(given['nBeta']+given['nKappa']+3):(given['nReal'])]                      
    
    U = UsaDyadParam(beta2, beta3, gamma, ActCost, alpha, given)
    V0 = x[given['nReal']:(given['nAll']+1)].reshape((18,-1), order='F')
    #dV = np.zeros((given['nAux']))
    dV = np.empty(given['nAux'], dtype='O')
    
    for k in xrange(given['mun']):
        Vk = dyadPhiQRE(V0[:,k], U[k,:,:], given['P'], given['delta'])
        #Vk = np.arange(18)
        dV[np.arange(18) + 18*k] = Vk- V0[:,k]
    
    return dV
    

    
    
    
def dyadPhiQRE(v, U, P, delta):
  #####################################################################################
  # INFO :: Value function for dynamic escalation game
  # INPUTS ::
  # # # v : a vector of actor-state-action values
  # # # # # # v = c(v1,v2), vi state-action values for i
  # # # U : a matrix of state-action-profile utilities, ncol=2
  # # # P : a transition matrix, see model$prob
  # # # delta : a discount factor
  # OUTPUTS :: v, return values
  #####################################################################################


    # Values, v1ij := action i, state j
    v1 = np.reshape(v[0:9], (-1,3), order='F')
    v2 = np.reshape(v[9:18], (-1,3), order='F')

    # Normalization

    #mv1 = np.amax(v1, axis=0)
    #mv2 = np.amax(v2, axis=0)
    
 
    ev1n = np.exp(v1 )
    ev2n = np.exp(v2 )

    #Conditional Choice Probabilites
    P1 = (ev1n/np.sum(ev1n, axis=0)).reshape((-1,1), order='F')
    P2 = (ev2n/np.sum(ev2n, axis=0)).reshape((-1,1), order='F')


    #U_i(a|s)
    U1sa = (U[:,0] + delta * (P.dot(np.log(np.sum(ev1n, axis=0)) ))).reshape((-1,1))
    U2sa = (U[:,1] + delta * (P.dot(np.log(np.sum(ev2n, axis=0)) ))).reshape((-1,1))
     
    V1=np.kron(P2.reshape((-1,3), order='F'), np.ones((1,3))).reshape((-1,1), order='F') * U1sa
    V2=np.kron(P1.reshape((-1,3), order='F'), np.ones((3,1))).reshape((-1,1),order='F') * U2sa
     
    V1 = np.sum(V1.reshape((-1,3)), axis=1)
    V2 = np.sum(np.array(np.split(V2, 3)).reshape(3, 3,3), axis=1)
#    V1 = np.ravel(v1)
#    V2 = np.ravel(v2)
    return np.concatenate((V1, np.ravel(V2, order='C')))
