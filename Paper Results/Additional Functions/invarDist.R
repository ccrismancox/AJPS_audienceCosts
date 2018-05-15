invarDist <- function(v, prob){
  #####################################################################################
  #
  # Updated: 06/13/14
  #####################################################################################
  # INFO :: Compute invariant distriubtion associated with Eq. Values v
  # # # the function solves P %*% pi = pi for pi 
  # INPUTS :: 
  # # # v : a vector of state-action values, v = v(v1,v2), length=18
  # # # prob : a 27 x 3 transition matrix
  # OUTPUTS :: ps, a vector of length 3, probability of reach state s=1,2,3
  #####################################################################################
  
  # compute choice probabilities
  cP <- choiceProb(v, 0)

  # compute probability of each action-profile in each state
  PA <- matrix(matrix(cP[,1], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1)*
        matrix(matrix(cP[,2], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  
  # weight transition matrix
  wTrans <- apply(prob, 2, function(x){x*PA})
  
  #sum up over states
  Trans <- rbind(colSums(wTrans[1:9,]),
                 colSums(wTrans[10:18,]),
                 colSums(wTrans[19:27,])
    )
  
  # solve for invariant distriubtion
  A = t(Trans) - diag(3)
  A[3,] <- c(1,1,1)
  b = c(0,0,1)
  ps <- solve(A,b)
  
  return(ps)
  
}
