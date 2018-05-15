JMPECct <- function(x,given){
  #####################################################################################
  # INFO :: Compute Jacobian of Phi with respect to (theta, v) for all games
  # INPUTS :: 
  # # # x: sturctural parameters and value (theta, v)
  # # # given : given from genDyadGiven
  # OUTPUTS :: J a jacobian matrix
  #####################################################################################
  
  # PRELIMS
  V <- matrix(x[(given$nReal+1):given$nAll], nrow=18) # value functions of game
  
  #utility parameters
  beta2 <- x[1:length(given$statVar[[1]])]
  beta3 <- x[(length(beta2)+1):given$nBeta]
  ActCost <- kappaDyad(x[(given$nBeta+1):(given$nBeta+given$nKappa/2)],
                       x[(given$nBeta+given$nKappa/2+1):(given$nBeta+given$nKappa)],
                       given$Xk
  )
  gamma <- x[(given$nBeta+given$nKappa+1):(given$nBeta+given$nKappa+3)]
  alpha <- x[(given$nBeta+given$nKappa+4):given$nReal]
  
  # utilities
  U <- UsaDyadParams(beta2, beta3, gamma, ActCost, alpha, given)
  
  # JACOBIAN
  J <- cBind(
        DPhiTheta(1,V[,1],given), v_PhiDer(V[,1], U[,,1], given)
    )
  
  if (given$mun>1){
    for (i in 2:given$mun){ #loop over games
      J <- bdiag(J, v_PhiDer(V[,i], U[,,i], given))
      J[(18*(i-1)+1):(18*i),1:given$nReal] <- DPhiTheta(i,V[,i],given)
    }
  }

  return(J)
}
