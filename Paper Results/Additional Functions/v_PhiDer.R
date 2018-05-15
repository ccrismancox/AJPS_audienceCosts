v_PhiDer <- function(V, U, given){
  
  # Jacbian of F(v) = Phi(v;theta)-v, with respect to v
  

  nAct1 <- nAct2 <- 3    
  nActs <- nAct1*nAct2
  nS <- 3
  
  v1 <- V[1:(length(V)/2)]
  v2 <- V[(length(V)/2 +1):length(V)]
  v1m <- matrix(v1, 3,3)
  v2m <- matrix(v2, 3,3)
 
  ##normalization
  v1max <- apply(v1m, 2, max)
  v2max <- apply(v2m, 2, max)
  v1m <- exp(sweep(v1m, 2, v1max))
  v2m <- exp(sweep(v2m, 2, v2max))
  G1 <- v1max + log(colSums(v1m))
  G2 <- v2max + log(colSums(v2m))

  #probs
  p1 <- sweep(v1m, 2, colSums(v1m), FUN="/")
  p2 <- sweep(v2m, 2, colSums(v2m), FUN="/")
  
  
  Q <- Matrix(given$prob, sparse=T)
  
  

  
  # utilities
  U1sa <- U[,1] + given$delta * given$prob %*% G1
  U2sa <- U[,2] + given$delta * given$prob %*% G2
  idx <- as.numeric(rep(1,3) %x% matrix(rep(1:9) ,3))
  
  #Set up Jacobian of Phi
  JPhi <- Matrix(0, nrow=nS*(nAct1+nAct2), ncol=nS*(nAct1+nAct2))
    
  p2.1 <- t(p2) %x% rep(1, nAct1)
  p2.2 <- matrix(t(t(p2) %x% rep(1, 3)), ncol=1)
  P <- t(bdiag(split(p2.1,1:nrow(p2.1)))) 
    
    
    
  #dV1/dV1
  JPhi[1:(nS*nAct1),1:(nS*nAct1)] <- (given$delta*P%*% Q %x% t(rep(1,nAct1))) %*% Diagonal(nS*nAct1,as.numeric(p1))-Diagonal(nS*nAct1)
  


  #dV1/dV2
  jsp <- (1:(nS*nAct2))%x%rep(1,nAct1)
  isp <- as.numeric(matrix(1:(nS*nAct1), nrow=nAct1,ncol=nS) %x% t(rep(1,nAct2)))
  hsp <- p2.2* (U1sa - P %*% U1sa %x% rep(1,3))
  JPhi[1:(nS*nAct1),(nS*nAct1+1):(nS*nAct1+nS*nAct2)] <- sparseMatrix(jsp,isp,x=hsp,dims=c(nS*nAct1,nS*nAct2))
  
  #dV2/dV2 
  jsp <- rep(1:(nS*nActs), nAct2)
  isp <- matrix( matrix(1:(nS*nAct2),nS,nAct2, byrow=TRUE), ncol=1) %x% rep(1, nActs)
  hsp <- Diagonal(nAct2) %x% p1
  dim(hsp) <- c(nS*nAct2*nActs,1)
  P <- sparseMatrix(isp,jsp,x=hsp,dims=c(nS*nAct2,nS*nActs))
  JPhi[(nS*nAct1+1):(nS*nAct1+nS*nAct2),(nS*nAct1+1):(nS*nAct1+nS*nAct2)] <- ((given$delta*P %*% Q %x% t(rep(1,nAct2))) %*% Diagonal(nS*nAct2, matrix(p2,nS*nAct2,1))) -
                                                                                    Diagonal(nS*nAct2)
                                                      
  
  #dV2/dV1
  jsp <- as.numeric( (matrix(1:(nS*nAct1),nAct1,nS) %x% t(rep(1,nAct2))))
  isp <-  rep(1:(nS*nAct2), each=nAct1)
  x2 <- U2sa[order(idx)] - P %*% U2sa[order(idx)]%x% rep(1,3)

  p1.2 <- matrix(t(t(p1) %x% rep(1, 3)), ncol=1)
  hsp <- p1.2*x2
  JPhi[(nS*nAct1+1):(nS*nAct1+nS*nAct2),1:(nS*nAct1)] <- sparseMatrix(isp,jsp, x=hsp, dims= c(nS*nAct2,nS*nAct1))

  
  return(JPhi)
}