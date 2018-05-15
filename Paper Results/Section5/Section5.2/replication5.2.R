#############################
# Replicate figure 2 and table 4
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
install.packages('foreign', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('rpart', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('rpart.plot', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('ggplot2', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('extrafont', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('zoo', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)


##packages
library(stringr)
library(data.table)
library(foreign)
library(rpart)
library(rpart.plot)
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

#################



## load data
load('../../../Data/DyadicMIDS_Rdata.rdata')
cindex <- unique(read.csv("../../AnalysisExtraDatasets/countryIndexV2.csv",stringsAsFactors=F)[,2:5])
load("../../ReplicationOutput.rdata")
polity <- fread("../../../Data/Sources/p4v2013.csv")
IEP <- data.table(read.dta("../../AnalysisExtraDatasets/institutions-data-11-16-11.dta"))
BDM <- data.table(read.dta("../../AnalysisExtraDatasets/bdm2s2_nation_year_data_may2002.dta"))
usg <- data.table(read.dta("../../AnalysisExtraDatasets/UGSreplication.dta"))
load("../../mainModelResults.rdata")



### prep time series ###
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


nBeta <- 8
nKappa <- 6
nGamma <- 3
nAlpha <- 125
nNA <- nBeta + nKappa + nGamma 
AC <- results[(given$nBeta + given$nKappa + 6):(given$nReal+2)]


# form AC data
AC <- data.table(cindex, AC=AC)
setnames(AC, c("CowCode", "ccode"), c("ccode", "mcode"))

#####Polity IV#####
##Known mistakes
polity[scode=="KOS", ccode:=347]
polity[scode=="MNT", ccode :=341]
polity[scode=="YGS", ccode :=345]
polity[scode=="SER", ccode :=345]
polity[scode=="USR", ccode :=365]
polity[scode=="PKS", ccode :=770]
polity[scode=="VIE", ccode :=816]
polity <- polity[year>=1993 & year <= 2006]
AC <- merge(polity, AC, by="ccode")

AC <- AC[, list(ccode, country, scode, AC,
                polity2, exconst)]
funNA <- function(x, FUN,...){
  c <- class(x)
  if(!all(is.na(x))){
    x <- FUN(x, ...)
  }
  class(x) <- c
  return(x)
}
AC[exconst<0, exconst:=NA]
AC[ccode==660 & is.na(polity2), polity2:=0]
AC[ccode==700 & is.na(polity2), polity2:=-7]
AC[ccode==645 & is.na(polity2), polity2:=-9]
AC[ccode==346 & is.na(polity2), polity2:=0]
AC[, polity2 := funNA(polity2, median, na.rm=TRUE), by=ccode]
AC[, exconst := funNA(exconst, median,na.rm=TRUE), by=ccode]
AC <- AC[!(ccode==345 & country!='Yugoslavia')]
AC <- unique(AC, by=colnames(AC))

IEP <- IEP[year>=1993 & year <= 2006]
AC <- merge(IEP, AC, by="ccode", all.y=TRUE)
AC <- AC[, list(ccode, country, scode, AC,  
                polity2, exconst, removeexec, elecexec,milnone, lelecsystem)]

AC[is.na(lelecsystem), lelecsystem:=0]
AC[, elecexec := funNA(elecexec, median, na.rm=TRUE), by=ccode]
AC[, milnone := funNA(milnone, median, na.rm=TRUE), by=ccode]
AC[, lelecsystem := funNA(lelecsystem, median, na.rm=TRUE), by=ccode]
AC[, removeexec := funNA(removeexec, median, na.rm=TRUE), by=ccode]

AC <- unique(AC, by=colnames(AC))


BDM <- BDM[year>=1993 & year <= 2006, list(W, WoverS, ccode)]
AC <- merge(BDM, AC, by="ccode", all.y=TRUE)
AC <- AC[, list(ccode, country, scode, AC,
                polity2, exconst, removeexec, elecexec,milnone, lelecsystem, W, WoverS)]

AC[, W := funNA(W, mean, na.rm=TRUE), by=ccode]
AC[, WoverS := funNA(WoverS, mean, na.rm=TRUE), by=ccode]

AC <- unique(AC, by=colnames(AC))


AC <- merge(AC, Xi, by="ccode")


##### rivals####
rivals <- fread("../../AnalysisExtraDatasets/thompsonRivals.csv")
rivals <- unique(rivals, by=NULL)
rivals[,numRival := sum(anyRival), by=ccode1]
rivals[,ccode2:=NULL]
rivals <- unique(rivals, by=NULL)
setnames(rivals, "ccode1", "ccode")
AC <- merge(AC, rivals, by="ccode", all.x=T)
AC[is.na(anyRival), `:=`(anyRival=0, numRival=0)]



#USG 
usg <- subset(usg, year >=1993, select=c(acc1nomvx, ccode1))
usg[,acc := mean(acc1nomvx), by=ccode1]
usg[,acc1nomvx:=NULL]
usg <- unique(usg)
setnames(usg, "ccode1", "ccode")
AC <- merge(AC, usg, by="ccode", all.x=T)
corMat <- with(AC, cor(cbind(AC, polity2, W, pressMED.1,
                             elecexec, removeexec, exconst, numRival, acc), 
                       use="pairwise" ,
                       method="spearman"))
corMat <- corMat[-1, 1]
N <- apply(with(AC, cbind(polity2, W, pressMED.1, 
                          elecexec, removeexec, exconst, numRival, acc)), 
           2, function(x){sum(!is.na(x))})
t <- corMat*sqrt((N-2)/(1-corMat^2))
p.t <- pt(abs(t), lower.tail = F, df=N-2)

corMat <- cbind(corMat,  t, p.t)
colnames(corMat) <- c("Spearman's $\\rho$", "$t$", "$p$-value (one-sided)")
rownames(corMat) <- c("Polity2", "W", "Free Press", "Elected Executive", "Executive Removal",
                      "Executive Constraints", "Rivalry", "USG's ACC")
print(corMat)



#weights
M <- data.table(M)
setnames(cindex, c("CowCode", "ccode"), c('ccode', 'mcode1'))
setnames(M, c("V1", "V2"), c('mcode1', 'mcode2'))
games <- merge(M, cindex, by='mcode1')
setnames(games,  c('mcode1', 'mcode2'), c('mcode2', 'mcode1'))
games <- merge(games, cindex, by='mcode1', suffixes =c("2", "1"))
weight <- table(games[,ccode1])




#### Regression tree analysis####
treeDat <- AC[, list(AC, polity2, W, pressMED.1, elecexec, removeexec, lelecsystem, numRival)]
treeDat[,elecexec:=factor(elecexec, labels=c("no", ""))]
treeDat[,removeexec:=factor(removeexec, labels=c("no", ""))]
treeDat[,pressMED.1 := factor(pressMED.1, labels=c("no", ""))]
setnames(treeDat, c("AC", "polity2", "W", "Press", "Elected Executive", "Executive Removal", "System", "Rivals"))
ft <- AC~polity2 +W+Press+ `Elected Executive` + `Executive Removal`+factor(System) + Rivals
ACtree <- rpart(ft,data=treeDat, weights=weight, method="anova") #grow
plot(ACtree); text(ACtree) #access
print(ACtree)
printcp(ACtree)
plotcp(ACtree)
ACtree1 <- prune(ACtree, cp= 0.02) #trim
print(ACtree1)
prp(ACtree1)

pdf("Figure2.pdf", family="CM Roman", height=5, width=8)
prp(ACtree1, extra=100, shadow.col=0, varlen=0, eq="?",
    round=1)
dev.off()
embed_fonts("Figure2.pdf")

## Note that Figure 2 in the paper is different
## Using the output from the regression tree 
## we draw Figure 2 using TikZ within the LaTex
## document.

