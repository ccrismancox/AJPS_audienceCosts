UsaDyad <- function(beta1, beta2, ActCost, gamma, alpha1, alpha2, x12, x21, given){
  #####################################################################################
  #
  # Updated: 06/08/14
  #####################################################################################
  # INFO :: Compute utilites of dynamic escalation model
  # INPUTS ::
  # OUTPUTS :: 
  #####################################################################################

	# prelims
 	Usa <- matrix(0,ncol=2, nrow=27)

  	
  	# add state variables
  	Usa[,1] <- rep(c(0, x12 %*% beta1, x12 %*% beta2), each=9)
    Usa[,2] <- rep(c(0, x21 %*% beta1, x21 %*% beta2), each=9)

    # add action costs
    Usa[,1] <- Usa[,1] + ActCost[1,][given$G[,2]]
    Usa[,2] <- Usa[,2] + ActCost[2,][given$G[,3]]

    # add cross partials
    Usa[,1] <- Usa[,1] + gamma[given$G[,1]]* as.numeric(given$G[,2]>1) * as.numeric(given$G[,3] > 1)
    Usa[,2] <- Usa[,2] + gamma[given$G[,1]]* as.numeric(given$G[,2]>1) * as.numeric(given$G[,3] > 1)

    # add audience costs
    Usa[,1] <- Usa[,1] + alpha1*as.numeric(given$G[,1]>1) *
    						as.numeric(given$G[,3]>= given $G[,1]) *
    						as.numeric(given$G[,2]<given $G[,1])
    Usa[,2] <- Usa[,2] + alpha2*as.numeric(given$G[,1]>1) *
    						as.numeric(given $G[,2]>= given $G[,1]) *
    						as.numeric(given $G[,3]<given $G[,1])
 

  return(Usa)
}
