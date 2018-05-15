compStat2 <- function(k, theta, V, thetaF, length.out=100, given, maxiter=500, tol=1e-6){
#####################################################################################
#
# Updated: 08/04/14
#####################################################################################
# INFO :: Compute new equilibria as data moves from (X,Xk) to (XijF,XiF)
#			Implements a homotophy method using an IFT linear approximation for hot start
#			Intial data must come from given and theta must be equilibrium 
# INPUTS :: 
# # # theta : set of parameters estimated from procedure
# # # # # theta = (beta^2, beta^3, kappa^2, kappa^3, gamma, alpha_1, alpha_2)
# # # V, equilibrium under theta of game k
# # # XijF : FINAL set of dyad-specific variables, ordered by 12, 21
# # # ZiF  : FINAL set of country specific variables, ordered 1,2
# # # length.out : how slow do we move from intial to final
# OUTPUTS :: 
# # # H : a matrix with length.out columns, representing new equilibra 
#####################################################################################


# house keeping
one <- given$Mun[k,1]
two <- given$Mun[k,2]
ref1 <- which(given$M[,1]==one & given$M[,2]==two)
ref2 <- which(given$M[,1]==two & given$M[,2]==one)

beta2old <- theta[1:length(given$statVar[[1]])]
beta3old <- theta[(length(beta2old)+1):given$nBeta]
kappa2old <- theta[(given$nBeta+1):(given$nBeta+given$nKappa/2)]
kappa3old <- theta[(given$nBeta+given$nKappa/2+1):(given$nBeta+given$nKappa)]
gammaold <- theta[(given$nBeta+given$nKappa+1):(given$nBeta+given$nKappa+3)]
alpha1old <- theta[length(theta)-1]
alpha2old <- theta[length(theta)]


# set up tracing procedure
Lambda <- seq(from=1, to=0, length.out=length.out)
H <- matrix(NA, nrow=18, ncol=length.out)
H[,1] <- V
Xk <- as.matrix(given$Xk[c(one,two),])
X12 <- given$X[ref1,]
X21<- given$X[ref2,]
Uold <-  UsaDyad(beta2old, beta3old, kappaDyad(kappa2old, kappa3old, Xk), gammaold, alpha1old, alpha2old, 
				X12, X21, given)

# execute tracing procedure with a IFT hot start
for (l in 2:length.out){
	
	beta2new <- theta[1:length(given$statVar[[1]])]*Lambda[l] + thetaF[1:length(given$statVar[[1]])]*(1-Lambda[l])
	beta3new <- theta[(length(beta2new)+1):given$nBeta]*Lambda[l] + thetaF[(length(beta2new)+1):given$nBeta]*(1-Lambda[l])
	kappa2new <- theta[(given$nBeta+1):(given$nBeta+given$nKappa/2)]*Lambda[l] + thetaF[(given$nBeta+1):(given$nBeta+given$nKappa/2)]*(1-Lambda[l])
	kappa3new <- theta[(given$nBeta+given$nKappa/2+1):(given$nBeta+given$nKappa)]*Lambda[l] + 
					thetaF[(given$nBeta+given$nKappa/2+1):(given$nBeta+given$nKappa)]*(1-Lambda[l])
	gammanew <- theta[(given$nBeta+given$nKappa+1):(given$nBeta+given$nKappa+3)]*Lambda[l] + 
					thetaF[(given$nBeta+given$nKappa+1):(given$nBeta+given$nKappa+3)]*(1-Lambda[l])
	alpha1new <- theta[length(theta)-1]*Lambda[l] + thetaF[length(theta)-1]*(1-Lambda[l])
	alpha2new <- theta[length(theta)]*Lambda[l] + thetaF[length(theta)]*(1-Lambda[l])
		
	
	oldJac <- v_PhiDer(H[,l-1], Uold, given)
	DPT <- t(DPhiTheta(k, H[,l-1], given))[c(1:(given$nBeta+given$nKappa+3), sort(c(one,two)+ given$nBeta+given$nKappa+3)),]
	
	slope <- -DPT %*% solve(t(oldJac)) #IFT
	start <- H[,l-1] + 
			as.vector(c(beta2new-beta2old,beta3new-beta3old, kappa2new-kappa2old, kappa3new-kappa3old, 
						gammanew-gammaold, alpha1new-alpha1old, alpha2new-alpha2old)) %*% slope
	
	ActCostNew <- kappaDyad(kappa2new, kappa3new, Xk)
	Unew <- UsaDyad(beta2new, beta3new, ActCostNew, gammanew, alpha1new, alpha2new, 
				X12, X21, given)
	

	F1 <- function(v){dyadPhiQRE(v, Unew, given$prob, given$delta)-v}		
	H[,l]<- broyden(F1, as.vector(start), tol=1e-6, maxiter=maxiter, J0=as.matrix(v_PhiDer(as.vector(start), Unew, given)))$zero
	
	beta2old <- beta2new
	beta3old <- beta3new
	kappa2old <- kappa2new
	kappa3old <- kappa3new
	gammaold <- gammanew
	alpha1old <- alpha1old
	alpha2old <- alpha2old
	Uold <- Unew
}
return(H)
}


# library("data.table")
# library("pracma")
# library("doParallel")
# library("abind")
# library("magic")
# library("Matrix")



# rm(list=ls())
# source("modelDyadEq.r")
# source("kappaDyad.r")
# source("genDyadData.r")
# source("JFNKdyad.r")
# source("UsaDyad2.r")
# source("dyadPhiQRE.r")
# source("genDyadGiven.r")
# source("UsaDyad.r")
# source("v_PhiDer.r")
# source("choiceProb.r")
# source("PhiDer.r")
# source("DPhiXZ.r")

# library("data.table")
# library("pracma")
# library("doParallel")

# # parameters 
# n <- 3
# beta <- list(c(-1,1),c(-2,2))
# kappa <- list(-.5, -1)
# M <- t(combn(n,2))
# M <- rbind(M, t(apply(M, 1, rev)))
# X <- cbind(1, matrix(rnorm(dim(M)[1]*(1)), ncol=(1)))
# statVar <- list(1:2,1:2)
# Xk <- matrix(2*runif(n), nrow=n)
# gamma <- c(-.5,0,.5)
# alpha <- seq(-1,1, length.out=n)
# delta <- .9
# model <- modelDyadEQ(M, X, statVar, Xk, beta, kappa, gamma, alpha, delta)
# stuff <- genDyadData(20, model, burnIn=1)
# Mun <-  t(utils::combn(unique(model$M[,1]),2))
# given <- genDyadGiven(M, Mun, stuff$D, X, statVar, Xk, delta)


# k <- 1 # pick dyad
# theta <- c(beta[[1]], beta[[2]], kappa[[1]], kappa[[2]], gamma, alpha[given$Mun[k,]])
# V <- stuff$Values[,k]
# XijF <- rbind(c(1, -5), c(1,5))
# ZiF <- Xk
# length.out=100

# PRwar1 <- exp(H[3,])/colSums(exp(H[1:3,]))
# PRwar2 <- exp(H[6,])/colSums(exp(H[4:6,]))
# PRwar3 <- exp(H[9,])/colSums(exp(H[7:9,]))
# plot(Lambda, PRwar3)
