#############################
# Generate standard errors and
# generate table 5
#############################
##Clear workspace and unload any existing packages
rm(list=ls())
try(sapply(paste("package:",names(sessionInfo()$other), sep=""), 
           detach, character.only=T, unload=T), silent=T)

#### Fresh installs to keep things consistent ####
if(sessionInfo()$running=="Ubuntu 14.04"){
  libDir <- '~/R/x86_64-pc-linux-gnu-library/3.4'
}else{
  libDir <- .libPaths()[1]
}
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('Matrix', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('pracma', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('data.table', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('magic', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)

# packages  
library(stringr)
library(Matrix)
library(magic)
library(pracma)
library(data.table)


# Functions
source('Additional Functions/genDyadGiven.r', chdir = TRUE)
source('Additional Functions/choiceProb.r', chdir = TRUE)
source('Additional Functions/JMPECct.R', encoding='UTF-8')
source('Additional Functions/gradLL.R', encoding='UTF-8')
source('Additional Functions/kappaDyad.r', encoding='UTF-8')
source('Additional Functions/DPhiTheta.R')
source('Additional Functions/v_PhiDer.R')
source('Additional Functions/UsaDyadParams.R', encoding='UTF-8')

### useful function ####
prepDyadID <- function(x){
  x <- as.character(x)
  x <- str_split(x, "")
  x <- lapply(x, function(z){
    #z <- z[-1]
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
####################

cindex <- unique(read.csv("AnalysisExtraDatasets/countryIndexV2.csv",stringsAsFactors=F)[,2:5])
COWref <- read.csv("AnalysisExtraDatasets/COW State list.csv", stringsAsFactors=F)

load("ReplicationOutput.rdata")




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


Jconst <- function(x){as.matrix(JMPECct(x,given))}
gLL <- function(x){gradLL(x,given)}





# SE stuff
Btheta <- jacobian(gLL,results) # this is hessian of likelihood.
Htheta <- t(Jconst(results))
W <- Btheta + Htheta %*% t(Htheta)
top <- cbind(W, -Htheta)
bottom <- cbind(-t(Htheta), matrix(0, dim(Htheta)[2], dim(Htheta)[2]))
BorderHessian <- rbind(top,bottom)
BorderHessian <- Matrix(BorderHessian, sparse=T)
invBorderHessian <- solve(BorderHessian)
se <- sqrt(diag(invBorderHessian))

z <- results[1:given$nReal]/se[1:given$nReal]
p <- 2*pnorm(abs(z),lower.tail = F)

#print("Table 5:") #Table 5 no longer in manuscript
#print(round(cbind(results[1:given$nReal], se[1:given$nReal], z, p)[1:17,], 2))

save(list=c("se", "results"), file="mainModelResults.rdata")
