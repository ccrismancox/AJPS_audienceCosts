DPhiTheta <- function(game, v, given){
  #####################################################################################
  #
  # Updated: 06/11/14
  #####################################################################################
  # INFO :: Compute Jacobian of Phi with respect to theta
  # INPUTS :: 
  # # # game : what game?
  # # # v    : values for game, a vector of length 18 
  # # # given : given from genDyadGiven
  # OUTPUTS :: JthetaPhi, a sparse, 18 x given$nReal matrix
  #####################################################################################
  
  # PLAYER 1
  one <- given$Mun[game,1]
  two <- given$Mun[game,2]
  ref1 <- which(given$M[,1]==one & given$M[,2]==two)
  ref2 <- which(given$M[,1]==two & given$M[,2]==one)
  
  # betas
  Zv1 <- matrix(rep(given$X[ref1,given$statVar[[1]]], each =3), ncol=length(given$statVar[[1]]))
  Zv1 <- rbind(matrix(0, nrow=3,ncol=length(given$statVar[[1]])), Zv1)
  Zv1 <- adiag(Zv1, 
               matrix(rep(given$X[ref1,given$statVar[[2]]], each =3), ncol=length(given$statVar[[2]]))
               )
  #kappas
  Zv1 <- cbind(Zv1,
               matrix(t(apply(matrix(rep(1:3,3)==2, ncol=1), 1, function(x){x*given$Xk[one,]})), ncol=dim(given$Xk)[2])
        )
  Zv1 <- cbind(Zv1,
               matrix(t(apply(matrix(rep(1:3,3)==3, ncol=1), 1, function(x){x*given$Xk[one,]})), ncol=dim(given$Xk)[2])
  )
  
  # gammas
  P <- choiceProb(v,0)
  Zv1 <- cbind(Zv1,
               c((1:3>1) * sum(P[2:3,2]), rep(0, 6)),
               c(rep(0,3), (1:3>1) * sum(P[5:6,2]), rep(0,3)),
               c(rep(0,6), (1:3>1) * sum(P[8:9,2]))
          )
  
  # alpha
  Da1 <- matrix(0,nrow=9,ncol=given$n)
  Da1[,one] <- rep(1:3, each=3) >  rep(1:3,3) 
  Da1[,one] <- Da1[,one]*c(rep(sum(P[1:3,2]),3), rep(sum(P[5:6,2]),3), rep(sum(P[9,2]),3))
  Zv1 <- cbind(Zv1,Da1)
  
 
  # betas
  Zv2 <- matrix(rep(given$X[ref2,given$statVar[[1]]], each =3), ncol=length(given$statVar[[1]]))
  Zv2 <- rbind(matrix(0, nrow=3,ncol=length(given$statVar[[1]])), Zv2)
  Zv2 <- adiag(Zv2, 
               matrix(rep(given$X[ref2,given$statVar[[2]]], each =3), ncol=length(given$statVar[[2]]))
  )
  #kappas
  Zv2 <- cbind(Zv2,
               matrix(t(apply(matrix(rep(1:3,3)==2, ncol=1), 1, function(x){x*given$Xk[two,]})), ncol=dim(given$Xk)[2])
  )
  Zv2 <- cbind(Zv2,
               matrix(t(apply(matrix(rep(1:3,3)==3, ncol=1), 1, function(x){x*given$Xk[two,]})), ncol=dim(given$Xk)[2])
  )
  
  # gammas
  Zv2 <- cbind(Zv2,
               c((1:3>1) * sum(P[2:3,1]), rep(0, 6)),
               c(rep(0,3), (1:3>1) * sum(P[5:6,1]), rep(0,3)),
               c(rep(0,6), (1:3>1) * sum(P[8:9,1]))
  )
  
  # alpha
  Da2 <- matrix(0,nrow=9,ncol=given$n)
  Da2[,two] <- rep(1:3, each=3) >  rep(1:3,3) 
  Da2[,two] <- Da2[,two]*c(rep(sum(P[1:3,1]),3), rep(sum(P[5:6,1]),3), rep(sum(P[9,1]),3))
  Zv2 <- cbind(Zv2,Da2)
  
  JthetaPhi <- rbind(Zv1,Zv2)
  return(Matrix(JthetaPhi,sparse=T))
}
