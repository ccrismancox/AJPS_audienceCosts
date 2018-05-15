#############################
# Replicate table 2
#############################
##Clear workspace and unload any existing packages
rm(list=ls())
try(sapply(paste("package:",names(sessionInfo()$other), sep=""), 
           detach, character.only=T, unload=T), silent=T)

#### Fresh installs to keep things consistent ####
if(sessionInfo()$running=="Ubuntu 14.04"){ # are we in the live world?
  libDir <- '~/R/x86_64-pc-linux-gnu-library/3.4' #if so, use the dir created by ubuntuSetup.sh
}else{ 
  libDir <- .libPaths()[1] #else stick with the default
}
install.packages('data.table', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('Matrix', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('pracma', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('magic', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)


# load packages
library("stringr")
library("pracma")
library("Matrix")
library("magic")
library("data.table")


# necessary functions
source('../../Additional Functions/prepDyadID.r', chdir = TRUE)
source('../../Additional Functions/genDyadGiven.r', chdir = TRUE)
source('../../Additional Functions/choiceProb.r', chdir = TRUE)
source('../../Additional Functions/v_PhiDer.R', chdir = TRUE)
source('../../Additional Functions/UsaDyad.R', chdir = TRUE)
source('../../Additional Functions/DPhiTheta.R', chdir = TRUE)
source('../../Additional Functions/dyadPhiQRE.r', chdir = TRUE)
source('../../Additional Functions/invarDist.R', chdir = TRUE)
source('../../Additional Functions/kappaDyad.r', chdir = TRUE)
source('../../Additional Functions/UsaDyadParams.R', chdir = TRUE)



#############################
# Substantive effects
############################## 
# see Appendix B for formal definitions

prBackDown <- function(vk, given){
  # probability of backing down
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  pbd1 <- sum(rep(pik[2:3],each=2) * Psa[given$G[,3]>=given$G[,1] & given$G[,2] < given$G[,1],])
  pbd2 <- sum(rep(pik[2:3],each=2) * Psa[given$G[,2]>=given$G[,1] & given$G[,3] < given$G[,1],])	
  
  # probability of backing down for player 1 and 2, respectively
  return(c(pbd1,pbd2))
}

prInitiate <- function(vk, given){
  # probability of intitation
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  pi1 <- sum(rep(pik[1],6) * Psa[given$G[,1]==1 & given$G[,2] > 1,])
  pi2 <- sum(rep(pik[1],6) * Psa[given$G[,1]==1 & given$G[,3] > 1,])	
  
  # probability of intitiating for player 1 and 2, respectively
  return(c(pi1, pi2))
}



#############################
# Prelims
############################## 

# Data
load('../../ReplicationOutput.rdata')
cindex <- read.csv("../../AnalysisExtraDatasets/countryIndexV2.csv", header=T,stringsAsFactors=F)


# Create given model strcuture
games <- as.data.frame(Mun)
games$country1 <- cindex$StateNme[Mun[,1]]
games$country2 <- cindex$StateNme[Mun[,2]]
games$CowCode1 <- cindex$CowCode[Mun[,1]]
games$CowCode2 <- cindex$CowCode[Mun[,2]]
games$dyadID <- rep(NA, dim(Mun)[1])

ts <- array(0, c(180, 3,nrow(Mun)))
for(i in 1:nrow(Mun)){
  games$dyadID[i] <- paste(prepDyadID(games$CowCode1[i]),prepDyadID(games$CowCode2[i]),sep="")
  ts[,,i] <- as.matrix(ts_df[ts_df$dyadID==games$dyadID[i], c("state", "action1", "action2")])
}
given <- genDyadGiven(M, Mun, ts, Xij,  list(c(1:4),c(1:4)), Z, 0.9)

#peal off estimated equilibria from results
V <- matrix(results[(given$nReal+1):length(results)], nrow=18)


# create AC matrix
AC <- cbind(1:max(given$Mun),
            results[(given$nBeta+given$nKappa+4):(given$nBeta+given$nKappa+3+given$n)] 
)


# pre-allocate output
acExp <- data.frame(
  countryName = c(t(matrix(c(games$country1,games$country2),ncol=2))),
  countryNumber = c(t(matrix(c(games$V1,games$V2),ncol=2))),
  countryCowCode = c(t(matrix(c(games$CowCode1,games$CowCode2),ncol=2))),
  dyadGame = rep(1:given$mun, each=2),  
  dyadID = rep(games$dyadID, each=2),
  dyadName = rep(paste(games$country1,games$country2, sep="-"), each=2),
  mep = rep(0, given$m), # marginal effect on peace
  mebdi = rep(0, given$m), # marginal effect of i's back down prob.
  mebdj = rep(0, given$m), # marginal effect of j's back down prob.
  meii = rep(0, given$m), # marginal effect of i's initiate prob.
  meij =  rep(0, given$m) # marginal effect of j's initiate prob.
)



#############################
# Experiment
#############################

beta2 <- results[1:length(given$statVar[[1]])]
beta3 <- results[(length(beta2)+1):given$nBeta]
kappa2 <- results[(given$nBeta+1):(given$nBeta+given$nKappa/2)]
kappa3 <- results[(given$nBeta+given$nKappa/2+1):(given$nBeta+given$nKappa)]
gamma <- results[(given$nBeta+given$nKappa+1):(given$nBeta+given$nKappa+3)]

Uold <- UsaDyadParams(beta2, beta3, gamma, kappaDyad(kappa2, kappa3, given$Xk), AC[,2], given)

for (k in 1:179){
  # prelims
  oldJac <- v_PhiDer(V[,k], Uold[,,k], given)
  DPT <- as.matrix(t(DPhiTheta(k, V[,k], given)))[c(1:(given$nBeta+given$nKappa+3), as.numeric(sort(games[k,1:2]+ given$nBeta+given$nKappa+3))),]
  vPrime <- -DPT %*% solve(t(oldJac)) #IFT
  
  # marginal effect on pr peace
  Jpi_wrt_theta <- jacobian(invarDist, V[,k], prob=given$prob) %*% t(vPrime) # chain rule
  acExp$mep[(2*(k-1) + 1):(2*(k-1) + 2)] <- -Jpi_wrt_theta[1,18:19] # neg b.c. we make ACs more extreme (move to -oo)
  
  # marginal effect on pr backing down
  Jpbd_wrt_theta <- jacobian(prBackDown, V[,k], given=given) %*% t(vPrime)
  acExp$mebdi[(2*(k-1) + 1):(2*(k-1) + 2)] <- -diag(Jpbd_wrt_theta[1:2,18:19]) # diag
  acExp$mebdj[(2*(k-1) + 1):(2*(k-1) + 2)] <- -diag(t(Jpbd_wrt_theta[1:2,19:18])) # off diag
  
  # marginal effect on pr initiating 
  Jpri_wrt_theta <- jacobian(prInitiate, V[,k], given=given) %*% t(vPrime)
  acExp$meii[(2*(k-1) + 1):(2*(k-1) + 2)] <- -diag(Jpri_wrt_theta[1:2,18:19])
  acExp$meij[(2*(k-1) + 1):(2*(k-1) + 2)] <- -diag(t(Jpri_wrt_theta[1:2,19:18]))
}



#############################
# Analysis, produce table 3
#############################
cat("reproducing Table 2 (Marginal Effects), Section 5.1:\n")
# row 1
round(with(acExp, mean(mebdi>0)), digits=2)*100

# row 2
round(with(acExp, mean(mebdj>0)), digits=2)*100

# row 3
round(with(acExp, mean(meii>0)), digits=2)*100

# row 4
round(with(acExp, mean(meij>0)), digits=2)*100

# row 5
round(with(acExp, mean(mep>0)), digits=2)*100


#############################
# Result mentioned in text
#############################
cat("Replicating a result mentioned in text:\n")
# sum marginal effects of peace by dyad
round(mean(aggregate(mep~dyadGame, acExp, sum)[,2] >0),digits=2)*100






