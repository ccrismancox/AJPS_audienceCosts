#############################
# Replicate figures 3 and 4
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
install.packages('doParallel', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('Matrix', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('pracma', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('magic', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('lattice', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('viridis', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('extrafont', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('zoo', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)


#packages
library(stringr)
library(doParallel)
library(Matrix)
library(pracma)
library(magic)
library(lattice)
library(viridis)
library(extrafont)
options(repos = 'http://lib.stat.cmu.edu/R/CRAN/')
font_install("fontcm", prompt=FALSE)
loadfonts(quiet=TRUE) 

color <- viridis(100)


#### other useful functions #### 
prepDyadID <- function(x){
  x <- as.character(x)
  x <- str_split(x, "")
  x <- lapply(x, function(z){
    # z <- z[-1]
    if(length(z)==1){
      y <- c("0", "0", z)
    }else{
      if(length(z)==2){
        y <- c("0", z)
      }else{
        y <- z
      }}
    return(str_c(y, collapse=""))
  })
  x <- do.call(rbind,x)
  return(x)
}

source('../../Additional Functions/genDyadGiven.r', chdir = TRUE)
source('../../Additional Functions/compStat2.R', chdir = TRUE)
source('../../Additional Functions/choiceProb.r', chdir = TRUE)
source('../../Additional Functions/UsaDyad.R', chdir = TRUE)
source('../../Additional Functions/kappaDyad.r', chdir = TRUE)
source('../../Additional Functions/v_PhiDer.R', chdir = TRUE)
source('../../Additional Functions/dyadPhiQRE.r', chdir = TRUE)
source('../../Additional Functions/DPhiTheta.R', chdir = TRUE)
source('../../Additional Functions/invarDist.R', chdir = TRUE)


cindex <- unique(read.csv("../../AnalysisExtraDatasets/countryIndexV2.csv",stringsAsFactors=F)[,2:5])
load("../../ReplicationOutput.rdata") #data and estimates
ts_df$date <- zoo::as.Date(as.numeric(ts_df$date)) #make time series usable

#### FUNCTIONS FOR QUANTITIES OF INTEREST ####
# computes probability of back down
prBackDown <- function(vk, given){
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  pbd1 <- sum(rep(pik[2:3],each=2) * Psa[given$G[,3]>=given$G[,1] & given$G[,2] < given$G[,1],])
  pbd2 <- sum(rep(pik[2:3],each=2) * Psa[given$G[,2]>=given$G[,1] & given$G[,3] < given$G[,1],])	
  
  # probability of backing down for player 1 and 2, respectively
  return(c(pbd1,pbd2))
}

# computes probability of back down
prInitiate <- function(vk, given){
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  pi1 <- sum(rep(pik[1],6) * Psa[given$G[,1]==1 & given$G[,2] > 1,])
  pi2 <- sum(rep(pik[1],6) * Psa[given$G[,1]==1 & given$G[,3] > 1,])	
  
  # probability of backing down for player 1 and 2, respectively
  return(c(pi1, pi2))
}

# computes probability of seeing an end to war
prTerminate <- function(vk, given){
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  prt <- pik[2]*Psa[given$G[,1]==2 & given$G[,2]==1 & given$G[,3]==1,] + pik[3]*Psa[given$G[,1]==3 & given$G[,2]==1 & given$G[,3]==1,]
  
  # probability of backing down for player 1 and 2, respectively
  return(prt)
}

# computes probability of descalating
prDescalate <- function(vk, given){
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)
  pik <- invarDist(vk, given$prob)
  
  pbd1 <- sum(c(rep(pik[2],each=3),rep(pik[3],each=6)) * Psa[given$G[,2] < given$G[,1],])
  pbd2 <- sum(c(rep(pik[2],each=3),rep(pik[3],each=6)) * Psa[given$G[,3] < given$G[,1],])	
  
  # probability of backing down for player 1 and 2, respectively
  return(c(pbd1,pbd2))
}


# computes the average duration of disputes, i.e., not peace
aveDurDisp <- function(vk,given){
  P <- choiceProb(vk, 0)
  Psa <- matrix(matrix(P[,2], ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1) * matrix(matrix(P[,1], ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)	
  pik <- invarDist(vk, given$prob)
  
  # weight transition matrix
  wTrans <- apply(given$prob, 2, function(x){x*Psa})
  
  #sum up over states
  Trans <- rbind(colSums(wTrans[1:9,]),
                 colSums(wTrans[10:18,]),
                 colSums(wTrans[19:27,])
  )
  
  
  Q <- Trans[-1,-1] #transitions among crisis and war only
  N <- solve(diag(2)-Q) # expected number of times visiting each state
  tn <- N %*% c(1,1) # number of times until reaching peace, starting in crisis or war
  return(sum(tn*pik[2:3]/(sum(pik[2:3])))) # average over crisis and war using invariant distribution
}



#############################
# CREATE GIVEN
#############################

games <- as.data.frame(Mun)
games$country1 <- cindex$StateNme[Mun[,1]]
games$country2 <- cindex$StateNme[Mun[,2]]
games$CowCode1 <- cindex$CowCode[Mun[,1]]
games$CowCode2 <- cindex$CowCode[Mun[,2]]


ts <- array(0, c(180, 3,nrow(Mun)))
for(i in 1:nrow(Mun)){
  ID <- paste(prepDyadID(games$CowCode1[i]),prepDyadID(games$CowCode2[i]),sep="")
  ts[,,i] <- as.matrix(ts_df[ts_df$dyadID==ID, c("state", "action1", "action2")])
}


# create time series array
given <- genDyadGiven(M, Mun, ts, Xij, list(c(1:4),c(1:4)), Z, .9)

Vhat <- matrix(results[(given$nReal+1):length(results)], nrow=18)




AC <- cbind(1:given$n,
            results[(given$nBeta+given$nKappa+4):(given$nBeta+given$nKappa+3+given$n)]
)
AC <- as.data.frame(AC)
names(AC) <- c("ccode","audCost")
out <- merge(cindex, AC, by="ccode")



################################################
# COMPARATIVE STATICS 
################################################



####3D plot for alpha (Korea)####

k = 166 #Korea 
vindex <- (given$nReal+18*k-17):(given$nReal+18*k)
thetac <- results[1:(given$nBeta+given$nKappa+3)] #w/o AC
theta <- c(thetac, AC[,2][unlist(games[k,1:2])]) #with AC
V <- results[(given$nReal+18*k-17):(given$nReal+18*k)]



##South East to South West (baseline)
theta.lo <- theta.hi <- theta
theta.lo[18] <- theta[18]-3 # first adjust just NK all the way (x)
theta.hi[18] <- theta[18]+0.15 # first adjust just NK all the way (x)
NKseq <- c(seq(theta.lo[18], theta[18], length=25)[-25],
           seq(theta[18], theta.hi[18], length=2))

#for later
ACNK <- theta[18]
ACSK <- theta[19]

H.lo <- compStat2(k, theta, V,  theta.lo, 25, given, 1000)
H.hi <- compStat2(k, theta, V,  theta.hi, 2, given,1000)
plot(apply(H.lo,2,invarDist,prob=given$prob)[1,])
plot(apply(H.hi,2,invarDist,prob=given$prob)[1,])	

BaseEQ  <- cbind(H.lo[,25:2],H.hi) #EQ at each point ()
plot(apply(BaseEQ,2,invarDist,prob=given$prob)[1,])  



library(doParallel)

# map all the effects for Korea
workers <- makeCluster(detectCores())
registerDoParallel(workers)


KoreaEffects <- foreach(i = 1:ncol(BaseEQ), .combine="rbind",
                        .packages=c("Matrix", "pracma", "magic")) %dopar%{
                          V <- BaseEQ[,i]
                          theta.lo <- theta.hi <- theta.start <- theta
                          theta.lo[18] <- theta.hi[18] <- theta.start[18] <- NKseq[i]
                          theta.lo[19] <- theta[19]-3
                          theta.hi[19] <- theta[19]+0.15
                          H.lo <- compStat2(k, theta.start, V,  theta.lo, 25, given, 1000)
                          H.hi <- compStat2(k, theta.start, V,  theta.hi, 2, given,1000)
                          
                          
                          tempEQ  <- cbind(H.lo[,25:2],H.hi) #EQ at each point ()
                          backDown <- t(apply(tempEQ, 2, prBackDown, given))
                          desc <- t(apply(tempEQ, 2, prDescalate, given))
                          init <- t(apply(tempEQ, 2, prInitiate, given))
                          PR <- apply(tempEQ,2,invarDist,prob=given$prob)
                          term <- apply(tempEQ, 2, prTerminate, given)
                          
                          data.frame(alphaNK = NKseq[i],
                                     alphaSK = c(seq(theta.lo[19], theta[19], length=25)[-25],
                                                 seq(theta[19], theta.hi[19], length=2)),
                                     PrNKbd = backDown[,1],
                                     PrSKbd = backDown[,2],
                                     PrNKin = init[,1],
                                     PrSKin = init[,2],
                                     PrNKde = desc[,1],
                                     PrSKde = desc[,2],
                                     PR = PR[1,],
                                     term=term
                          )
                          
                        }

stopCluster(workers)






####3D plot for alpha (Israel)####

k = 146 #Israel-Leb
vindex <- (given$nReal+18*k-17):(given$nReal+18*k)
thetac <- results[1:(given$nBeta+given$nKappa+3)] #w/o AC
theta <- c(thetac, AC[,2][unlist(games[k,1:2])]) #with AC
V <- results[(given$nReal+18*k-17):(given$nReal+18*k)]



##South East to South West (baseline)
theta.lo <- theta.hi <- theta
theta.lo[18] <- theta[18]-1.7 # first adjust just Lebanon all the way (x)
theta.hi[18] <- theta[18]+0.35 # first adjust just Leb all the way (x)
Lebseq <- c(seq(theta.lo[18], theta[18], length=25)[-25],
            seq(theta[18], theta.hi[18], length=5))
ACLE <- theta[18]
ACIS <- theta[19]
H.lo <- compStat2(k, theta, V,  theta.lo, 25, given, 2500)
H.hi <- compStat2(k, theta, V,  theta.hi, 5, given,1000)
plot(apply(H.lo,2,invarDist,prob=given$prob)[1,])
plot(apply(H.hi,2,invarDist,prob=given$prob)[1,])

BaseEQ  <- cbind(H.lo[,25:2],H.hi) #EQ at each point ()
plot(apply(BaseEQ,2,invarDist,prob=given$prob)[1,])





# map all the effects for Isr-Leb
workers <- makeCluster(detectCores())
registerDoParallel(workers)


IsraelEffects <- foreach(i = 1:ncol(BaseEQ), .combine="rbind",
                         .packages=c("Matrix", "pracma", "magic")) %dopar%{
                           V <- BaseEQ[,i]
                           theta.lo <- theta.hi <- theta.start <- theta
                           theta.lo[18] <- theta.hi[18] <- theta.start[18] <- Lebseq[i]
                           theta.lo[19] <- theta[19]-1.7
                           theta.hi[19] <- theta[19]+0.35
                           H.lo <- compStat2(k, theta.start, V,  theta.lo, 25, given, 1000)
                           H.hi <- compStat2(k, theta.start, V,  theta.hi, 2, given,1000)
                           
                           
                           
                           tempEQ  <- cbind(H.lo[,25:2],H.hi) #EQ at each point ()
                           backDown <- t(apply(tempEQ, 2, prBackDown, given))
                           init <- t(apply(tempEQ, 2, prInitiate, given))
                           desc <- t(apply(tempEQ, 2, prDescalate, given))
                           term <- apply(tempEQ, 2, prTerminate, given)
                           dur <- apply(tempEQ, 2, aveDurDisp, given)
                           
                           PR <- apply(tempEQ,2,invarDist,prob=given$prob)
                           
                           data.frame(alphaLeb = Lebseq[i],
                                      alphaIsr = c(seq(theta.lo[19], theta[19], length=25)[-25],
                                                   seq(theta[19], theta.hi[19], length=2)),
                                      PrLebBd = backDown[,1],
                                      PrIsrBd = backDown[,2],
                                      PrLebIn = init[,1],
                                      PrIsrIn = init[,2],
                                      PrLebde = desc[,1],
                                      PrIsrde = desc[,2],
                                      PR=PR[1,],
                                      dur=dur,
                                      term=term
                           )
                           
                         }

stopCluster(workers)


### Make the figures ###
pdf("Figure3.pdf", family="CM Roman", height=9, width=12)
wireframe(PR~ I(-alphaNK) + I(-alphaSK), data=KoreaEffects, 
          #screen=list(x=-100, z=-10, y=-130), 
          col='black',
          col.regions=color, drape=T, colorkey=F, 
          scales=list(arrows=F, col=1,
                      fontfamily="CM Roman",
                      cex=1.2,
                      x=list(at=c(12, 11, 10), labels=-c(12,11,10)),
                      y=list(at=c(12, 11, 10), labels=-c(12,11,10)),
                      zlab=list(rot=90)),
          par.settings =  list(axis.line = list(col = "transparent")), 
          xlab=list(label="North Korea AC",
                    cex=2, rot=30),
          ylab=list(label="South Korea AC",
                    cex=2, rot=-40),
          zlab=list(rot=90, label="Pr(Peace)",
                    cex=2))
dev.off()
embed_fonts("Figure3.pdf")

pdf("Figure4.pdf", family="CM Roman", height=9, width=12)
wireframe(PR~ I(-alphaLeb) + I(-alphaIsr), data=IsraelEffects[-c(1:26, nrow(IsraelEffects)),], 
          screen=list(x=-75, y=50, z=12),
          col='black',
          col.regions=color, drape=T, colorkey=F, 
          scales=list(arrows=F, col=1,
                      fontfamily="CM Roman",
                      cex=1.2,
                      y=list(at=c(12.5,12, 11.5, 11), labels=-c(12.5,12, 11.5, 11)),
                      x=list(at=c(2.5, 3, 3.5, 4), labels=-c(2.5, 3, 3.5, 4)),
                      zlab=list(rot=90)),
          par.settings =  list(axis.line = list(col = "transparent")), 
          xlab=list(label="Lebanon AC",
                    cex=2, rot=26),
          ylab=list(label="Israel AC",
                    cex=2, rot=-18),
          zlab=list(rot=92, label="Pr(Peace)",
                    cex=2))
dev.off()
embed_fonts("Figure4.pdf")


