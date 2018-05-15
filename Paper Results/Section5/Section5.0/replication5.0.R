#############################################
####### Create Figure 1 and Table 2 #########
#############################################

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
install.packages('foreign', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('ggplot2', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('gridExtra', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('extrafont', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('zoo', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)


#### Load packages ####
library(data.table)
library(foreign)
library(ggplot2)
library(gridExtra)
library(stringr)
library(extrafont)
options(repos = 'http://lib.stat.cmu.edu/R/CRAN/') 
font_install("fontcm", prompt=FALSE)
loadfonts(quiet=TRUE) 

##### useful functions####
funNA <- function(x, FUN,...){
  c <- class(x)
  if(!all(is.na(x))){
    x <- FUN(x, ...)
  }
  class(x) <- c
  return(x)
}

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
############ Let's begin #############


#### Load data ####
load('../../../Data/DyadicMIDS_Rdata.rdata')
cindex <- unique(read.csv("../../AnalysisExtraDatasets/countryIndexV2.csv",stringsAsFactors=F)[,2:5])
load("../../ReplicationOutput.rdata") #data and estimates
NMC <- fread("../../../Data/Sources/NMC_v4_0.csv")
load("../../mainModelResults.rdata") #estimates and standard errors


#### prep time series ###
games <- as.data.frame(Mun)
games$country1 <- cindex$StateNme[Mun[,1]]
games$country2 <- cindex$StateNme[Mun[,2]]
games$CowCode1 <- cindex$CowCode[Mun[,1]]
games$CowCode2 <- cindex$CowCode[Mun[,2]]



ts_df$date <- zoo::as.Date(as.numeric(ts_df$date))
ts <- array(0, c(180, 3,nrow(Mun)))
for(i in 1:nrow(Mun)){
  ID <- paste(prepDyadID(games$CowCode1[i]),prepDyadID(games$CowCode2[i]),sep="")
  ts[,,i] <- as.matrix(ts_df[ts_df$dyadID==ID, c("state", "action1", "action2")])
}

given <- genDyadGiven(M, Mun, ts, Xij[,3:dim(Xij)[2]], list(c(1:4),c(1:4)), Z[,2:dim(Z)[2]], .9)


####### Read and process Week's Data ######

##### Organize the audience cost estimates #######
nBeta <- 8
nKappa <- 6
nGamma <- 3
nAlpha <- 125
nNA <- nBeta + nKappa + nGamma
ACse <- se[(nNA+1):(nNA+125)] #audience costs standard errors
AC <- results[(given$nBeta + given$nKappa + 6):(given$nReal+2)] #audience costs
seAClow  <- AC - 1.96*ACse
seAChigh  <- AC + 1.96*ACse


AC <- data.table(cindex, AC=AC, ACse=ACse,
                 seLOW=seAClow, seHI =seAChigh)
setnames(AC, c("CowCode", "ccode"), c("ccode", "mcode"))

AC <- merge(NMC, AC,  by="ccode", all.y=TRUE)
AC <- AC[, list(ccode, stateabb,  AC, ACse,
                seLOW, seHI,
                 tpop)]
AC[, tpop := funNA(tpop, mean, na.rm=TRUE), by=ccode]
AC <- unique(AC, by=colnames(AC))




## generate weights
M <- data.table(M)
setnames(cindex, c("CowCode", "ccode"), c('ccode', 'mcode1'))
setnames(M, c("V1", "V2"), c('mcode1', 'mcode2'))
games <- merge(M, cindex, by='mcode1')
setnames(games,  c('mcode1', 'mcode2'), c('mcode2', 'mcode1'))
games <- merge(games, cindex, by='mcode1', suffixes =c("2", "1"))
weight <- table(games[,ccode1])





# Sort AC in high/low
AC[,AC:=-AC]
setkey(AC, AC)
AC[,stateabb:=factor(stateabb, levels=stateabb)]
AC[,AC:=-AC]

#Generate Figure 1
pdf("Figure1.pdf", height=16, width=8)
grid.arrange(
  ggplot(AC[63:125])+
    geom_pointrange(aes(x=stateabb, y=AC, ymin=seLOW, ymax=seHI))+
    coord_flip()+
    xlab("Country")+
    ylab('Audience Cost')+
    geom_hline(aes(yintercept=0), alpha=.25, size=1)+
    theme_bw(20)+
    theme(text=element_text(family="CM Roman")),
  ggplot(AC[1:62])+
    geom_pointrange(aes(x=stateabb, y=AC, ymin=seLOW, ymax=seHI))+
    coord_flip()+
    xlab("")+
    ylab('Audience Cost')+
    geom_hline(aes(yintercept=0), alpha=.25, size=1)+
    theme_bw(20)+
    theme(text=element_text(family="CM Roman")),
  ncol=2)
dev.off()
embed_fonts("Figure1.pdf")
