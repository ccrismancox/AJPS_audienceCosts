gradLL <- function(x, given){
  #####################################################################################
  # INFO :: Compute gradient of the log-likelihood
  # INPUTS :: 
  # # # x: sturctural parameters and value (theta, v)
  # # # given : given from genDyadGiven
  # OUTPUTS :: dLLdV, the derivative of the log-likelihood, a vector of length given$nAll
  #####################################################################################
  
  # Values, v1ij := action i, state j
  V <- matrix(x[(given$nReal+1):given$nAll],  ncol=given$mun) 
  v1 <- V[1:(nrow(V)/2),]
  v2 <- V[(nrow(V)/2 +1):nrow(V),]
  v1m <- array(v1,  c(3,3,given$mun)) 
  v2m <- array(v2,  c(3,3,given$mun))
  
  ##normalization
  v1m <- exp(sweep(v1m, c(2,3), apply(v1m, c(2,3), max)))
  v2m <- exp(sweep(v2m, c(2,3), apply(v2m, c(2,3), max)))
  
  p1 <- sweep(v1m, c(2,3), colSums(v1m), FUN="/")
  p2 <- sweep(v2m, c(2,3), colSums(v2m), FUN="/")
  
  
  dLLdV <- c(rep(0, given$nReal), 
             rbind(given$stateActionsInData[1:(nrow(V)/2),] -  ((given$statesInData %x% rep(1,3)) *  matrix(p1, ncol=given$mun)),
                   given$stateActionsInData[(nrow(V)/2+1):nrow(V),] -  ((given$statesInData %x% rep(1,3))*  matrix(p2, ncol=given$mun))))
  return(-dLLdV)
}
    
