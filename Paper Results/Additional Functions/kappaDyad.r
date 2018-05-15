kappaDyad <- function(K2, K3, X){
  #####################################################################################
  #
  # Updated: 06/11/14
  #####################################################################################
  # INFO :: Compute actor-action specific costs in dynamic escalation game
  # INPUTS ::
  # # # # K2, K3 : vector of coefficients for intermediate and extreme actions
  # # # # X : a data frame, with n rows, one for actor
  # OUTPUTS :: ActCost a n x 3 matrix, with row: 0, k_i(2), k_i(3)
  #####################################################################################
  
  ActCost <- cbind(0, X %*% K2, X %*% K3)
  
  return(ActCost)
  
}