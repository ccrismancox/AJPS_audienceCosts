#############################
# Reproduce table 1
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
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)

#packages
library("stringr")

#load data and functions
load('../ReplicationOutput.rdata')

source('../Additional Functions/genDyadGiven.r', chdir = TRUE)
source('../Additional Functions/prepDyadID.r', chdir = TRUE)

cindex <- read.csv("../AnalysisExtraDatasets/countryIndexV2.csv", header=T, stringsAsFactors=F)

# use the time series data frame to create "given" model
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
given <- genDyadGiven(M, Mun, ts, Xij,  list(c(1:4),c(1:4)), Z, 0.9)


ActualTransition <- matrix(numeric(9*179),nrow=9,ncol=179)
for(i in 1:179){
  ActualTransition[,i] <- c(t(
    table(factor(ts[,1,i],levels=c(1,2,3)),factor(pmax(ts[,2,i],ts[,3,i]),levels=c(1,2,3)))
    ))
}

actualDistTrans <- rowSums(ActualTransition)/(180*179)
actualDistTransCond <- c(actualDistTrans[1:3]/sum(actualDistTrans[1:3]), actualDistTrans[4:6]/sum(actualDistTrans[4:6]), actualDistTrans[7:9]/sum(actualDistTrans[7:9]))

# TABE 1
round(cbind(actualDistTrans, actualDistTransCond),digits=3)


# EXTRA RESULTS DESCRIBED IN TEXT (Section 4)
# percentage of states in data
table(ts[,1,])/180/179

# percentage of actions in data
table(rbind(ts[,2,],ts[,3,]))/180/179/2


