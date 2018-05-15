import numpy as np
from numpy.lib.recfunctions import join_by

def UsaDyadParam(beta2, beta3, gamma, ActCost, alpha, given):
    '''
    INFO :: Compute utilites of dynamic escalation model with parameters above
    INPUTS :: 
    -Model Parameters (above)
    -given : given from genDyadGiven
    -OUTPUTS :: Usa, state-action-profile utilites, see given$G for order
    '''
    idx = np.zeros((given['M'].shape[0], 1), dtype=[('stateA', '<i8'), ('stateB', '<i8'), ('idx', '<i8')])
    idx['stateA'] = given['M'][:,0, None]
    idx['stateB'] = given['M'][:,1, None]
    idx['idx'] = np.arange(given['M'].shape[0]).reshape((-1,1))
    
    #idx = np.hstack((given['M'], np.arange(given['M'].shape[0]).reshape((-1,1))))
    #idx = pd.DataFrame(idx)
    #idx.dtype={'names':['stateA','stateB', 'idx'], 'formats':['int64']*3}
    sortedMdir = np.kron(given['Mun'], [[1],[1]])
    sortedMdir[np.arange(1, sortedMdir.shape[0]+1, 2), :] = sortedMdir[np.arange(1, sortedMdir.shape[0]+1, 2), :][:,[1,0]]
    sortedMdir = np.hstack((sortedMdir, np.arange(sortedMdir.shape[0]).reshape((-1,1))))

    #sortedMdir = pd.DataFrame(sortedMdir)
    sortedMdir.dtype= {'names':['stateA','stateB', 'idx2'], 'formats':['int64']*3}
    idx = join_by(('stateA', 'stateB'), idx, sortedMdir, usemask=False)
    #idx = np.array(pd.merge(sortedMdir, idx)[2])
    idx = np.sort(idx, order= 'idx2')['idx']


    X2 = given['X'][:,given['statVar'][given['statVar'].keys()[0]]].reshape((-1, len(given['statVar'][given['statVar'].keys()[0]])), order='F')
    X3 = given['X'][:,given['statVar'][given['statVar'].keys()[1]]].reshape((-1, len(given['statVar'][given['statVar'].keys()[1]])), order='F')
   
    beta2 = beta2.reshape((-1,1), order='F')
    beta3 = beta3.reshape((-1,1), order='F')
    XB = np.hstack( (np.zeros((X2.shape[0], 1)), X2.dot(beta2), X3.dot(beta3)))

    XBreshape = np.kron(XB.T, np.ones((9,1)))
    XBreshape = XBreshape[:,idx]
    
    kappaReshape = np.hstack(ActCost[:,given['G'][:,1:3]-1])
    colNames = 'a%i b%i ' * np.amax(given['Mun'])
    colNames = (colNames %tuple(np.repeat(np.arange(1, np.amax(given['Mun'])+1) ,2))).split()
    colNames= np.array(colNames)
    #kappaReshape = pd.DataFrame(kappaReshape, columns=colNames) 
    #kappaReshape.dtype= {'names':colNames, 'formats':[kappaReshape.dtype.char]*kappaReshape.shape[1]}

    idxnames = np.vstack(((('a%i '*given['Mun'].shape[0]) %tuple(given['Mun'][:,0])).split(),
    (('b%i '*given['Mun'].shape[0]) %tuple(given['Mun'][:,1])).split())).reshape((1,-1), order='F')[0]
    
    idxnames = np.ravel(map(lambda x: np.where(colNames == idxnames[x]), xrange(len(idxnames))))
    #kappaReshape = kappaReshape[idxnames[0].tolist()]
    #kappaReshape = np.hstack(map(lambda x: kappaReshape[idxnames[0].tolist()[x]], xrange(idxnames.shape[1])))
    kappaReshape = kappaReshape[:,idxnames]
    gamma =np.tile(gamma[given['G'][:,0]-1]* ( given['G'][:,1]>1), (XBreshape.shape[1],1)).T* np.kron(given['G'][:,2]>1, np.ones((XBreshape.shape[1],1))).T
    
    alpha = (alpha[given['Mun'].T-1]).reshape(1,-1, order='F')
    Gmat = np.kron(np.concatenate( ((given['G'][:,0]>0)* (given['G'][:,2]>=given['G'][:,0]) * (given['G'][:,1]<given['G'][:,0]), 
                                    (given['G'][:,0]>0)* (given['G'][:,1]>=given['G'][:,0]) * (given['G'][:,2]<given['G'][:,0]))), np.ones((alpha.shape[1]/2,1))).T
    
    Gmat = Gmat.reshape((-1, alpha.shape[1]), order='F')          
    
    alpha = np.tile(alpha, (Gmat.shape[0],1)) * Gmat
    
    
    Usa1 = (XBreshape + kappaReshape+ gamma + alpha)
    
    Usa2 = np.array(np.hsplit(Usa1, given['m']/2))
    return Usa2
