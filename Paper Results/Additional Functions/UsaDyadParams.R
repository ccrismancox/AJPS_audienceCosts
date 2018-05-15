UsaDyadParams <- function(beta2, beta3, gamma, ActCost, alpha, given){
  #####################################################################################
  #
  # Updated: 06/09/14
  #####################################################################################
  # INFO :: Compute utilites of dynamic escalation model with parameters above
  # INPUTS ::
	# #	# given : given from 
  # OUTPUTS :: Usa, state-action-profile utilites, see given$G for order
  #####################################################################################

    ## State variables
    idx <- data.table(cbind(given$M, 1:nrow(given$M)))
    setnames(idx,names(idx),c("V1","V2","V3"))
    setkey(idx, V1, V2)
    sortedMdir <- given$Mun %x% c(1,1)
    sortedMdir[seq(2, nrow(sortedMdir), by=2), ] <- matrix(sortedMdir[seq(2, nrow(sortedMdir), by=2), ],ncol=2)[,2:1] 
    	#sortedMdir[seq(2, nrow(sortedMdir), by=2), ] <- sortedMdir[seq(2, nrow(sortedMdir), by=2), ][,2:1]
    	#sortedMdir[seq(2, nrow(sortedMdir), by=2), ] <- sortedMdir[seq(2, nrow(sortedMdir), by=2), ][2:1]
    sortedMdir <- data.table(sortedMdir)
    idx <- idx[sortedMdir][,V3]
    
    X2 <- matrix(given$X[,given$statVar[[1]]], ncol=length(given$statVar[[1]]))
    X3 <- matrix(given$X[,given$statVar[[2]]], ncol=length(given$statVar[[2]]))
    
    XB <- cbind(X2 %*% beta2, X3 %*% beta3)
    XB.reshape <- t(cbind(0, XB)) %x% (rep(1,9))
    XB.reshape <- XB.reshape[,idx]


    # Kappa
  
    kappa.reshape <- matrix(apply(ActCost, 1, function(x){x[given$G[,2:3]]}), nrow=nrow(given$G))
    colnames(kappa.reshape) <- paste(rep(sort(unique(c(given$Mun[,1],
                                                     given$Mun[,2]))), each=2),
                                   c("a", "b"), sep="")
    idxName <- t(cbind(paste(given$Mun[,1], "a", sep=""),
                     paste(given$Mun[,2], "b", sep="")))
    kappa.reshape <- kappa.reshape[, as.vector(idxName)]


    ## Gamma
    gamma.reshape <-  as.numeric(gamma[given$G[,1]]*
                       as.numeric(given$G[,2]>1) *
                       as.numeric(given$G[,3] > 1)) %x% t(rep(1, ncol(XB.reshape)))

    ## Alpha
    ## This, so far as I can tell, is the only place where we
    ## require that the countries be numbered 1:N.
    ## That's not a problem, just something to remember.


    alpha.reshape <- alpha[t(given$Mun)]

    Gmat <- c(as.numeric(given$G[,1]>0) *
                    as.numeric(given$G[,3]>=given$G[,1]) *
                    as.numeric(given$G[,2]<given$G[,1]),
                  as.numeric(given$G[,1]>0) *
                    as.numeric(given$G[,2]>=given$G[,1]) *
                    as.numeric(given$G[,3]<given$G[,1])) %x% t(rep(1, length(alpha.reshape)/2))

    Gmat <- matrix(Gmat, ncol=length(alpha.reshape))
    alpha.reshape<- t(sweep(t(Gmat),1,alpha.reshape,'*'))
    #alpha.reshape <-  t(alpha.reshape * t(Gmat))


  #Usa1 <- kappa.reshape + gamma.reshape + alpha.reshape
  Usa1 <- XB.reshape + kappa.reshape + gamma.reshape + alpha.reshape
  


    Usa2 <- array(Usa1, dim=c(dim(given$G)[1],2,given$m/2))
  
    return(Usa2)
}

## Kappa
# kappa.reshape <- matrix(apply(kappa, 1, function(x){x[given$G[,2:3]]}), nrow=nrow(given$G))
# colnames(kappa.reshape) <- paste(rep(sort(unique(c(given$Mun[,1],
#                                                    given$Mun[,2]))), each=2),
#                                  c("a", "b"), sep="")
# idxName <- t(cbind(paste(given$Mun[,1], "a", sep=""),
#                    paste(given$Mun[,2], "b", sep="")))
# kappa.reshape <- kappa.reshape[, as.vector(idxName)]

## ## time testing
## source("modelDyadEQ.R")
## source("UsaDyad.R")
## N <- 57
## M <- t(utils::combn(1:N, 2))
## M <- rbind(M, M[,2:1])
## X <- replicate(2, rnorm(nrow(M)))
## statVars <- NULL
## beta <- list(c(-2,2), c(1,-3))
## kappa <- cbind(0, replicate(2, rnorm(N)))
## gamma <- c(-1, 1, 3)
## alpha <-  rnorm(N)
## model <- modelDyadEQ(M,X, beta=beta, kappa=kappa, gamma=gamma, alpha=alpha)

## system.time(replicate(500, {Usa2 <- UsaDyad2(model)}))
## system.time(replicate(500, {Usa  <- UsaDyad(model)}))
## identical(Usa, Usa2)
## ## 7 seconds v. 4 minutes
