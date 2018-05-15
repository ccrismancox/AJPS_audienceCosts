choiceProb <- function(v,t=1){
  #####################################################################################
  #
  # Updated: 06/11/14
  #####################################################################################
  # INFO :: Compute Choice Probabilites given state-action values for each player
  # INPUTS :: 
  # # # v : a vector of state-action values, v = v(v1,v2)
  # # # t    : should choice probabilities be a vector?  If t=1, then yes.
  # OUTPUTS :: P = c(P1,P2) or P = cbind(P1,P2)
  #################s####################################################################

  # Values, v1ij := action i, state j
  v1 <- matrix(v[1:9],  ncol=3) 
  v2 <- matrix(v[10:18],  ncol=3)
  
  # normalize
  mv1 <- apply(v1, 2, max)
  mv2 <- apply(v2, 2, max)
  ev1n <- exp(sweep(v1, 2, mv1, "-"))
  ev2n <- exp(sweep(v2, 2, mv2, "-"))
  
  # Condition choice probabilties
  P1 <- matrix(sweep(ev1n, 2, colSums(ev1n), "/"), ncol=1)
  P2 <- matrix(sweep(ev2n, 2, colSums(ev2n), "/"), ncol=1)
  
  if(t==T){
    return(c(P1,P2))
  } else {
    return(cbind(P1,P2))
  }
}