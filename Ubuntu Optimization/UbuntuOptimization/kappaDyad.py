def kappaDyad(K2, K3, Xk):
  '''
  INFO :: Compute actor-action specific costs in dynamic escalation game
  INPUTS ::
  - K2, K3 : vector of coefficients for intermediate and extreme actions
  - X : a data frame, with n rows, one for actor
  OUTPUTS :: ActCost a n x 3 matrix, with row: 0, k_i(2), k_i(3)
  '''
  import numpy as np
  ActCost = np.hstack( (np.zeros((Xk.shape[0], 1)),
Xk.dot(K2).reshape(((Xk.shape[0], 1))),
Xk.dot(K3).reshape((Xk.shape[0], 1)) )) 
  
  return ActCost
