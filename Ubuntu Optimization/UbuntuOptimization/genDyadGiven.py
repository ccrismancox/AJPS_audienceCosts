import itertools as it
import numpy as np

def genDyadGiven(M, Mun, ts, X,  Xk, delta=0.9,statVar=None):
    '''
    INFO :: Generate ``Given'' or a list of things used to estimate escalation game
    INPUTS ::
    -M   : a matrix of directed dyads
    -Mun	: a matrix of undired dyads
    -ts : A l x 3 x mun array, corresponding to time series of each relevant dyad
    -X : data corresponding to directed dyads
    -statVar : a list of vectors, one for each state,
    -delta : the assumed discount factor
    OUTPUTS :: given, used in structural estimation
    '''
    given = {}
    given['M'] = M
    given['m'] = M.shape[0]
    given['Mun'] = Mun
    given['mun'] = given['Mun'].shape[0]
    given['n'] = len(np.unique(np.ravel(M)))
    given['G'] = np.hstack( ((np.arange(1,4).repeat(9)).reshape(-1,1), 
  (np.tile(np.arange(1,4).repeat(3),3)).reshape(-1,1), 
  (np.tile(np.arange(1,4), 9)).reshape(-1,1)))
    given['X'] =  X
    given['Xk'] = Xk
    given['delta'] = delta
    
    if statVar is None:
        given['statVar'] = {0: np.arange(0, X.shape[1]), 1: np.arange(0, X.shape[1])}
    else:
        given['statVar'] = statVar
    
    
    given['P'] = np.zeros((given['G'].shape[0], 3))
    actmax = np.amax(given['G'][:,1:3], axis=1)
    given['P'][actmax==1] = [1,0,0]
    given['P'][actmax==2] = [0,1,0]
    given['P'][actmax==3] = [0,0,1]
    
    
    given['nBeta'] = sum(map(lambda x:len(given['statVar'][x]), xrange(len(given['statVar']))))
    given['nKappa'] = Xk.shape[1]*2
    given['nReal'] = given['nBeta'] + given['nKappa'] + 3 +given['n']
    given['nAux'] = given['mun'] * 18
    given['nAll'] = given['nReal'] + given['nAux']
    
    ts = np.int_(ts)
    given['statesInData'] =np.apply_along_axis(lambda x: np.bincount(x, minlength=4), 1, ts[:,:,0])[:,1:4].T
    
    stateActions = np.array(list(it.product(np.arange(1,4), np.arange(1,4))))
    
    stateActionsInData = np.zeros((stateActions.shape[0]*2, given['mun']))
    for i in xrange(stateActions.shape[0]):
        stateActionsInData[i,:] = np.sum(np.logical_and(ts[:,:,0] == stateActions[i,0], ts[:,:,1]==stateActions[i,1]), axis=1)
        stateActionsInData[i+9,:] = np.sum(np.logical_and(ts[:,:,0] == stateActions[i,0], ts[:,:,2]==stateActions[i,1]), axis=1)
        
    given['stateActionsInData'] = stateActionsInData
    given['stateActions'] = stateActions
    
    return given
    
    
    
    
  
