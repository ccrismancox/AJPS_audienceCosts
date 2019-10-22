#############################################
####### Create Figure 1 and Table 2 #########
#############################################

##Clear workspace and unload any existing packages
rm(list=ls())
try(sapply(paste("package:",names(sessionInfo()$other), sep=""), 
           detach, character.only=T, unload=T), silent=T)

#### Fresh installs to keep things consistent ####
libDir <- .libPaths()[1] #else stick with the default


install.packages('stringr', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('data.table', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('chron', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('zoo', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('reshape2', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN/', verbose=F, quiet=T)
install.packages('foreign', lib=libDir, repos='http://lib.stat.cmu.edu/R/CRAN', verbose=F, quiet=T)

#packages
library(stringr)
library(data.table)
library(chron)
library(zoo)
library(reshape2)
library(foreign)

# additional functions
source("Additional Functions/stringr_to_cow.R", encoding="unknown")
source("Additional Functions/ISO_to_COW.R")



prepDyadID <- function(x){
  x <- as.character(x)
  x <- str_split(x, "")
  x <- lapply(x, function(z){
    # z <- z[-1] #fix a problem introduced by updating stringr
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
#################################

####data sources ####
setwd("Sources")
dyadData <- fread("directedDyads.csv")
polity <- fread("p4v2013.csv")
midIP <- fread("MIDIP_4.01.csv")
system <- fread("states2011.csv")
NMC <- fread("NMC_v4_0.csv")
dist <- fread("distance.csv")
trade <- fread("dyadic_trade_3.0.csv")
growth <- read.csv("world-gdp-growth.csv", check.names=FALSE)
pressA<-read.csv("Press_FH.csv", check.name=FALSE, encoding='latin1')
pressB<-read.dta("jcr_event1_democracy.dta")
gdp <- read.csv("pwt8_gdp.csv")
gdpSupplement <- read.csv('world-gdp.csv', check.names=FALSE)
growthSupplement <- read.csv('world-growth.csv', check.names=FALSE)
ally <- fread("alliance1993_2007.csv")
trickyTrade <- read.csv('trickTrade.csv')
israelTrade <- fread('israelTradeSupplement.csv') #From Gleditch
setwd("..")

##Clean up and merge press sources
press.1<-melt(pressA,
              id.vars=c("country"),
              value.name="Press",
              variable.name="year")
pressB <- subset(pressB, select=c("cow",
                                  "year",
                                  "pressfree1"))

press.1$year<-as.numeric(as.character(press.1$year))
press.1$Press[press.1$Press=="NF" | press.1$Press=="PF"]<-0
press.1$Press[press.1$Press=="F"]<-1
press.1$Press[press.1$Press=="N/A" |press.1$Press== ""]<-NA
press.1<-stringr.to.cow(press.1$country, press.1$year, press.1)
press.1$Press<-as.numeric(press.1$Press)
press.1$Press[press.1$country==
                "Israeli-Occupied Territories and Palestinian Authority"]<-NA
press.1[press.1$ccode==0,] <- NA
press.1 <- merge(press.1, pressB, by.x=c("ccode", "year"), by.y=c("cow", "year"), all=T)
press.1$Press <- ifelse(is.na(press.1$Press) & press.1$ccode!=345,
                        press.1$pressfree1,
                        press.1$Press)
press.1$pressfree1 <- NULL
press.1$country<-NULL
press.1<-na.omit(press.1)
press.1 <- data.table(press.1)
press.1 <- press.1[year>=1993 & year <=2007,]

press.1 <- unique(press.1)

##Clean up and merge GDP sources
gdpSupplement<-melt(gdpSupplement,
                    id.vars=c("Country Name"),
                    value.name="gdp",
                    variable.name="year")
gdpSupplement$year <- as.numeric(as.character(gdpSupplement$year))
gdpSupplement$gdp <- as.numeric(as.character(gdpSupplement$gdp))
gdpSupplement <- stringr.to.cow(gdpSupplement$`Country Name`, gdpSupplement$year, gdpSupplement)
gdpSupplement <- subset(gdpSupplement, ccode>0 & year<=2007)
gdpSupplement$gdp <- gdpSupplement$gdp/1000000 #Convert to millions of dollars
gdpSupplement <- gdpSupplement[gdpSupplement$`Country Name`!="American Samoa",]
gdpSupplement <- gdpSupplement[gdpSupplement$`Country Name`!="Hong Kong SAR, China",]
gdpSupplement <- gdpSupplement[gdpSupplement$`Country Name`!="Macao SAR, China",]
gdpSupplement <- gdpSupplement[gdpSupplement$`Country Name`!="South Sudan",]
gdpSupplement$`Country Name` <- NULL

gdp <- iso.to.cow(gdp$countrycode, gdp$year, gdp)
gdp <- data.table(gdp[, c("ccode", "year", "rgdpna")])
gdp <- merge(gdp, gdpSupplement, by=c('ccode', 'year'), all.x=TRUE, all.y=TRUE)
gdp[ccode==520, gdp:=1370] #1990 value converted into 2005 dollars (World Bank + BLS to convert to 2005 USD)
gdp[ccode==775, gdp:=11931] #2005 value. Earliest I could find (UN)   
gdp[ccode==731, gdp:=13031] #2005 value. Earliest I could find (UN)   
gdp[,rgdpna := rowSums(cbind(rgdpna, gdp), na.rm=TRUE)]
gdp[,rgdpna:= ifelse(rgdpna==0, NA, rgdpna)]
gdp[,gdp:=NULL]

#UN sources: http://data.un.org/CountryProfile.aspx (accessed June 2013)

##Clean up and merge growth sources
growth.1 <- melt(growth[, -2],
                 id.vars=c("Country Name"),
                 value.name="growth",
                 variable.name="year")
growth.1$year <- as.numeric(as.character(growth.1$year))
growth.1 <- stringr.to.cow(growth.1$`Country Name`, growth.1$year, growth.1)
growth.1 <- growth.1[growth.1$`Country Name`!="American Samoa",]
growth.1 <- growth.1[growth.1$`Country Name`!="Hong Kong SAR, China",]
growth.1 <- growth.1[growth.1$`Country Name`!="Macao SAR, China",]
growth.1 <- growth.1[growth.1$`Country Name`!="South Sudan",]
growth.1 <- subset(growth.1, ccode>0 & year<=2007)
growth.1$country <- NULL
growth.1 <- data.table(growth.1)
growth.1[ccode==731, growth:=3.8] #2005 value from UN website



#####################################################################################




# create the basic dyadic dataset 
dyadData$dyadID <- apply(cbind(prepDyadID(dyadData$ccode1),
                               prepDyadID(dyadData$ccode2)),
                         1, str_c, collapse="")
dyadSet <- dyadData[, list(Syear=min(year)), by=dyadID]



setnames(dyadData, "year", "Syear")
dyadSet <- merge(dyadSet, dyadData, by=c("dyadID", "Syear"), all.x=T, all.y=F)


system <- system[endyear > 1993,list(ccode, endyear)]
setnames(system, "ccode", "ccode1")
dyadSet <- merge(dyadSet, system, by="ccode1", all.x=TRUE, all.y=FALSE)
setnames(system, "ccode1", "ccode2")
dyadSet <- merge(dyadSet, system, by="ccode2", all.x=TRUE, all.y=FALSE, suffixes=c("1", "2"))
dyadSet[, `:=`(endyear = min(endyear1, endyear2), endyear2 = NULL, endyear1=NULL)]
dyadSet$endyear[dyadSet$endyear>2007] <- 2007
dyadSet <- dyadSet[Syear <=2007,]
setkey(dyadSet, ccode1, ccode2)

#####Clean up NMC and merge GDP with NMC####
NMC <- NMC[year >= 1993, list(ccode, year, cinc, milper, tpop)]
NMC$cinc[NMC$cinc==-9] <- NA
NMC$tpop[NMC$tpop==-9] <- NA
NMC$milper[NMC$milper==-9] <- NA

NMC <- merge(NMC, gdp, by=c("ccode", "year"), all.x=TRUE)
NMC[,gdppc := rgdpna/tpop]
NMC[,milperpc := milper/tpop]




setnames(NMC, "ccode", "ccode1")
setnames(NMC, "year", "Syear")
dyadSet <- merge(dyadSet, NMC, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(NMC, "Syear", "endyear")
dyadSet <- merge(dyadSet, NMC, by=c("ccode1", "endyear"), all.x=TRUE, all.y=FALSE, suffixes=c(".1start", ".1end"))
setnames(NMC, "ccode1", "ccode2")
dyadSet <- merge(dyadSet, NMC, by=c("ccode2", "endyear"), all.x=TRUE, all.y=FALSE)
setnames(NMC, "endyear", "Syear")
dyadSet <- merge(dyadSet, NMC, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c(".2end", ".2start"))


NMC[,`:=`(milperpcMEAN = mean(milperpc, na.rm=TRUE), 
          gdppcMEAN = mean(gdppc, na.rm=TRUE),
          tpopMEAN = mean(tpop, na.rm=TRUE),
          cincMEAN = mean(cinc, na.rm=TRUE)), by=ccode2]
NMC[,`:=`(cinc=NULL, milper=NULL, tpop=NULL, gdppc=NULL, milperpc=NULL, rgdpna=NULL)]
dyadSet <- merge(dyadSet, NMC, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(NMC, "ccode2", "ccode1")
dyadSet <- merge(dyadSet, NMC, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c('.2', '.1'))
dyadSet[ccode1==41, rgdpna.1start:=gdp[ccode==41 & year==1998, rgdpna]]
dyadSet[ccode2==41, rgdpna.2start:=gdp[ccode==41 & year==1998, rgdpna]]
dyadSet[ccode1==41, gdppc.1start := rgdpna.1start/tpop.1start]
dyadSet[ccode2==41, gdppc.2start := rgdpna.2start/tpop.2start]

dyadSet[ccode1==700, rgdpna.1start:=gdp[ccode==700 & year==2002, rgdpna]]
dyadSet[ccode2==700, rgdpna.2start:=gdp[ccode==700 & year==2002, rgdpna]]
dyadSet[ccode1==700, gdppc.1start := rgdpna.1start/tpop.1start]
dyadSet[ccode2==700, gdppc.2start := rgdpna.2start/tpop.2start]

dyadSet[ccode1==620, rgdpna.1start:=gdp[ccode==620 & year==1999, rgdpna]]
dyadSet[ccode2==620, rgdpna.2start:=gdp[ccode==620 & year==1999, rgdpna]]
dyadSet[ccode1==620, gdppc.1start := rgdpna.1start/tpop.1start]
dyadSet[ccode2==620, gdppc.2start := rgdpna.2start/tpop.2start]




#####distance#####
setnames(dist, "year", "Syear")
dyadSet <-  merge(dyadSet, dist, by=c("ccode1","ccode2", "Syear"), all.x=TRUE, all.y=FALSE)

#####Polity IV#####
##Known mistakes
polity$ccode[polity$scode=="KOS"]<-347
polity$ccode[polity$scode=="MNT"]<-341
polity$ccode[polity$scode=="YGS"]<-345
polity$ccode[polity$scode=="SER"]<-345
polity$ccode[polity$scode=="USR"]<-365
polity$ccode[polity$scode=="PKS"]<-770
polity$ccode[polity$scode=="VIE"]<-816

polity <- polity[year>=1993,
                 list(ccode,
                      year,
                      polity2)]
#Lebanon =0
polity$polity2[polity$ccode==660] <- 0

setnames(polity, c("ccode", "year"), c( "ccode1", "Syear"))
dyadSet <- merge(dyadSet, polity, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(polity, "Syear", "endyear")
dyadSet <- merge(dyadSet, polity, by=c("ccode1", "endyear"), all.x=TRUE, all.y=FALSE, suffixes=c(".1start", ".1end"))
setnames(polity, "ccode1", "ccode2")
dyadSet <- merge(dyadSet, polity, by=c("ccode2", "endyear"), all.x=TRUE, all.y=FALSE)
setnames(polity, "endyear", "Syear")
dyadSet <- merge(dyadSet, polity, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c(".2end", ".2start"))
setkey(dyadSet, ccode1, ccode2)

polity[,`:=`(polity2MEAN = mean(polity2, na.rm=TRUE),
             polity2MED = median(polity2, na.rm=TRUE)), by=ccode2]
polity[,polity2:=NULL]

dyadSet <- merge(dyadSet, polity, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(polity, "ccode2", "ccode1")
dyadSet <- merge(dyadSet, polity, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c('.2', '.1'))

######Trade#####
trade <- trade[year >=1993, list(ccode1, ccode2, year, flow1, flow2)]
trade1 <- copy(trade)
setnames(trade1, c("ccode1", "ccode2", "flow1", "flow2"), c("ccode2", "ccode1", "flow2", "flow1"))
trade <- rbind(trade, trade1,use.names=TRUE)
rm(list="trade1")
#Gleditsch: Dyads with no observed data, assumed to be 0
trade$flow1[trade$flow1==-9] <- NA
trade$flow2[trade$flow2==-9] <- NA

for(i in 1:nrow(trickyTrade)){
  tmp <- trade[ccode1==trickyTrade$ccode1[i] & ccode2==trickyTrade$ccode2[i],]
  NAs <- apply(tmp, 1, anyNA)
  tmp$flow1[1] <- tmp[!NAs,]$flow1[1]
  tmp$flow2[1] <- tmp[!NAs,]$flow2[1]
  trade[ccode1==trickyTrade$ccode1[i] & ccode2==trickyTrade$ccode2[i],] <- tmp
}
trade[ccode1==666 & ccode2==652 & year==1993,] <- israelTrade[ccode1==666 & ccode2==652 & year==1993,]
trade[ccode1==666 & ccode2==660 & year==1993,] <- israelTrade[ccode1==666 & ccode2==660 & year==1993,]
trade[ccode2==666 & ccode1==652 & year==1993,] <- israelTrade[ccode2==666 & ccode1==652 & year==1993,]
trade[ccode2==666 & ccode1==660 & year==1993,] <- israelTrade[ccode2==666 & ccode1==660 & year==1993,]

setnames(gdp, "ccode", "ccode1")
trade <- merge(trade, gdp, by=c("ccode1", "year"), all.x=TRUE, all.y=FALSE)



trade[,meanGDP:= mean(rgdpna, na.rm=TRUE), by=c("ccode1")]
trade[,rgdpna:= ifelse(is.na(rgdpna), meanGDP, rgdpna)]
trade[,meanGDP:=NULL]
trade[,depend := rowSums(cbind(flow1,flow2),na.rm=TRUE)/rgdpna]

setnames(trade, "year", "Syear")
dyadSet <- merge(dyadSet, trade, by=c("ccode1", "ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(trade, "Syear", "endyear")
dyadSet <- merge(dyadSet, trade, by=c("ccode1", "ccode2", "endyear"), all.x=TRUE, all.y=FALSE, suffixes=c(".start", ".end"))


trade[,`:=`(flow1MEAN = mean(flow1, na.rm=TRUE),
            flow2MEAN = mean(flow2, na.rm=TRUE),
            dependMEAN = mean(depend, na.rm=TRUE)), by=c("ccode1", "ccode2")]
trade[,`:=`(flow1=NULL,
            flow2=NULL,
            rgdpna=NULL)]
trade[ccode1==345 & ccode2==255 & endyear == 2006, endyear:=2007 ]
trade[ccode1==345 & ccode2==365 & endyear == 2006, endyear:=2007]
trade[ccode2==345 & ccode1==255 & endyear == 2006, endyear:=2007 ]
trade[ccode2==345 & ccode1==365 & endyear == 2006, endyear:=2007]

trade[ccode2==345 & ccode1==343 & endyear == 2006, endyear:=2007 ]
trade[ccode1==345 & ccode2==343 & endyear == 2006, endyear:=2007]
trade[ccode2==345 & ccode1==344 & endyear == 2006, endyear:=2007 ]
trade[ccode1==345 & ccode2==344 & endyear == 2006, endyear:=2007]
trade[ccode2==345 & ccode1==346 & endyear == 2006, endyear:=2007 ]
trade[ccode1==345 & ccode2==346 & endyear == 2006, endyear:=2007]

dyadSet <- merge(dyadSet, trade, by=c("ccode1", "ccode2", "endyear"), all.x=TRUE, all.y=FALSE)


####Growth#####
growth.1[,`:=`(`Country Name`=NULL)]
setnames(growth.1, "ccode", "ccode1")
setnames(growth.1, "year", "Syear")
dyadSet <- merge(dyadSet, growth.1, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(growth.1, "Syear", "endyear")
dyadSet <- merge(dyadSet, growth.1, by=c("ccode1", "endyear"), all.x=TRUE, all.y=FALSE, suffixes=c(".1start", ".1end"))
setnames(growth.1, "ccode1", "ccode2")
dyadSet <- merge(dyadSet, growth.1, by=c("ccode2", "endyear"), all.x=TRUE, all.y=FALSE)
setnames(growth.1, "endyear", "Syear")
dyadSet <- merge(dyadSet, growth.1, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c(".2end", ".2start"))


growth.1[,`:=`(growthMEAN = mean(growth, na.rm=TRUE)), by=ccode2]
growth.1[,growth:=NULL]

dyadSet <- merge(dyadSet, growth.1, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(growth.1, "ccode2", "ccode1")
dyadSet <- merge(dyadSet, growth.1, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c('.2', '.1'))



#####Free Press#####
setnames(press.1, "ccode", "ccode1")
setnames(press.1, "year", "Syear")
dyadSet <- merge(dyadSet, press.1, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(press.1, "Syear", "endyear")
dyadSet <- merge(dyadSet, press.1, by=c("ccode1", "endyear"), all.x=TRUE, all.y=FALSE, suffixes=c(".1start", ".1end"))
setnames(press.1, "ccode1", "ccode2")
dyadSet <- merge(dyadSet, press.1, by=c("ccode2", "endyear"), all.x=TRUE, all.y=FALSE)
setnames(press.1, "endyear", "Syear")
dyadSet <- merge(dyadSet, press.1, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c(".2end", ".2start"))


press.1[,`:=`(pressMED = median(Press, na.rm=TRUE)), by=ccode2]
press.1[,Press:=NULL]

dyadSet <- merge(dyadSet, press.1, by=c("ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(press.1, "ccode2", "ccode1")
dyadSet <- merge(dyadSet, press.1, by=c("ccode1", "Syear"), all.x=TRUE, all.y=FALSE, suffixes=c('.2', '.1'))



###alliance###
ally$alliance <- 1
ally <- ally[,list(ccode1, ccode2, year, alliance)]
setkey(ally, ccode1, ccode2, year)
ally <- unique(ally)
setnames(ally, "year", "Syear")
dyadSet <- merge(dyadSet, ally, by=c("ccode1", "ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(ally, c("ccode1", "ccode2"), c("ccode2", "ccode1"))
dyadSet <- merge(dyadSet, ally, by=c("ccode1", "ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
dyadSet[, alliance := rowSums(cbind(alliance.x, alliance.y),  na.rm=TRUE)]
dyadSet[,alliance.x:= NULL]
dyadSet[,alliance.y := NULL]
ally[,allyMED := median(alliance, na.rm=TRUE), by=c('ccode1', 'ccode2')]
ally[,`:=` (alliance =NULL)]
dyadSet <- merge(dyadSet, ally, by=c("ccode1", "ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
setnames(ally, c("ccode1", "ccode2"), c("ccode2", "ccode1"))
dyadSet <- merge(dyadSet, ally, by=c("ccode1", "ccode2", "Syear"), all.x=TRUE, all.y=FALSE)
dyadSet[, allyMED := rowSums(cbind(allyMED.x,allyMED.y),  na.rm=TRUE)]
dyadSet[,allyMED.x:= NULL]
dyadSet[,allyMED.y := NULL]


#### Clean up data ####

setkey(dyadSet, ccode1, ccode2)
dyadSet[, `:=`(minPolity = apply(cbind(polity2.1start, polity2.2start), 1, min),
               minPolityMEAN = apply(cbind(polity2MEAN.1 , polity2MEAN.2), 1, min),
               minPolityMED = apply(cbind(polity2MED.1 , polity2MED.2), 1, min),
               cap.ratio = cinc.1start/cinc.2start,
               cap.ratioMEAN= cincMEAN.1/cincMEAN.2),]

Xij <- copy(dyadSet)
Xij <- Xij[, list(ccode1,
                  ccode2,
                  dyadID,
                  Syear,
                  endyear,
                  minPolityMEAN,
                  minPolityMED,
                  distance,
                  dependMEAN,
                  cap.ratioMEAN,
                  allyMED)]




Xi <- copy(dyadSet)
Xi <- Xi[, list(ccode1,
                Syear,
                endyear,
                gdppcMEAN.1,
                growthMEAN.1,
                polity2MEAN.1,
                tpopMEAN.1,
                milperpcMEAN.1,
                pressMED.1)]
XiSort <-  Xi[, list(Syear=min(Syear), endyear=max(endyear)), by=ccode1]
Xi <- unique(merge(XiSort, Xi, by=c("ccode1", "Syear", "endyear"), all.y=FALSE))

setnames(Xi, "ccode1", "ccode")


naStates <- apply(Xi, 1, anyNA)
Xi <-Xi[!naStates,]


statesInData <- Xi$ccode
Xij <-  Xij[ccode1 %in% statesInData & ccode2 %in% statesInData,]

naDyads <- apply(Xij, 1, anyNA)

Xij <- Xij[!naDyads,]
print(all(unique(c(Xij$ccode1, Xij$ccode2)) %in% Xi$ccode))
print(all(Xi$ccode %in% unique(c(Xij$ccode1, Xij$ccode2))))



######MIDS######
mids <- midIP[,list(IncidNum3,
                    ccode,
                    StMon,
                    StYear,
                    EndDay,
                    EndMon,
                    EndYear,
                    SideA,
                    `InSide A`,
                    Action)]
setnames(mids, "InSide A", "InA")

reshapedMids <- data.table()
for(i in unique(mids$IncidNum3)){
  tmp <- mids[mids$IncidNum3==i,]
  tmp2 <- data.table(ccode1  = tmp$ccode[tmp$InA==1],
                     ccode2  = tmp$ccode[tmp$InA==0],
                     action1 = tmp$Action[tmp$InA==1],
                     action2 = tmp$Action[tmp$InA==0],
                     StMon1  = tmp$StMon[tmp$InA==1],
                     StYear1 = tmp$StYear[tmp$InA==1],
                     StMon2  = tmp$StMon[tmp$InA==0],
                     StYear2  = tmp$StYear[tmp$InA==0],
                     IncidNum3 = i
  )
  reshapedMids <- rbind(reshapedMids, tmp2)
}

reshapedMids <- rbind(reshapedMids,
                      data.table(ccode1  = reshapedMids$ccode2,
                                 ccode2  = reshapedMids$ccode1,
                                 action1 = reshapedMids$action2,
                                 action2 = reshapedMids$action1,
                                 StMon1  = reshapedMids$StMon2,
                                 StYear1 = reshapedMids$StYear2,
                                 StMon2  = reshapedMids$StMon1,
                                 StYear2 = reshapedMids$StYear1,
                                 IncidNum3 = reshapedMids$IncidNum3))


setkey(reshapedMids, ccode1, ccode2, StYear1, StMon1)

reshapedMids$startDate <- with(reshapedMids, as.Date(paste(StYear1,  "-", StMon1,  "-", 01,  sep="")))

monthData <- data.table()
quartData <- data.table()
yearData <- data.table()
###actions
for(i in dyadSet$dyadID){
  tmp <- dyadSet[dyadSet$dyadID==i, list(ccode1, ccode2, Syear, endyear)]
  incidents <- reshapedMids[ccode1==tmp$ccode1 & ccode2==tmp$ccode2,]
  if(nrow(incidents)==0){
    incidents <- data.table(ccode1 = tmp$ccode1,
                            ccode2 = tmp$ccode2,
                            action1 = 0,
                            action2 = 0,
                            startDate= as.Date("1992/01/01"))
  }
  
  
  ##MONTHLY
  OutDataMonth <- data.table(date=seq(from=as.Date(paste(tmp$Syear, "/1/1", sep="")), to=as.Date(paste(tmp$endyear, "/12/31", sep="")), by="month"),
                             dyadID = i,
                             ccode1 = tmp$ccode1,
                             ccode2 = tmp$ccode2)
  idx1 <- sapply(incidents$startDate, function(x){ifelse(OutDataMonth$date>=x, 1, 0)})
  idx2 <- sapply(incidents$startDate, function(x){ifelse(OutDataMonth$date<=x, 1, 0)})
  actions <-  matrix(c(t(incidents[, list(action1, action2)] )),nrow=1) %x% rep(1, nrow(idx1))
  idx  <- (idx1*idx2) %x% t(rep(1, 2))
  actions <- actions*idx
  actions2 <- matrix(nrow=nrow(idx), ncol=2)
  actions2[,1] <- apply(actions[,seq(1, ncol(actions), by=2), drop=FALSE], 1, max)
  actions2[,2] <- apply(actions[,seq(2, ncol(actions), by=2), drop=FALSE], 1, max)
  state <- lag(as.zoo(actions2), k=-1, na.pad=TRUE)
  state <- apply(state, 2, function(x){ifelse(is.na(x), 0 ,x)})
  state <- apply(state, 1, max)
  OutDataMonth[ , `:=` (action1 = actions2[,1], action2 = actions2[,2], state=state)]
  monthData <- rbind(monthData, OutDataMonth)
  
  ##Quarterly
  OutDataQuart <- data.table(date=seq(from=as.Date(paste(tmp$Syear, "/1/1", sep="")), to=as.Date(paste(tmp$endyear, "/12/31", sep="")), by="quarter"),
                             dyadID = i,
                             ccode1 = tmp$ccode1,
                             ccode2 = tmp$ccode2)
  
  minus1 <- as.POSIXlt(incidents$startDate)
  minus1$mon <- minus1$mon - 3
  minus1 <- as.Date(minus1)
  idx1 <- sapply(minus1, function(x){ifelse(OutDataQuart$date>x, 1, 0)})
  idx2 <- sapply(incidents$startDate, function(x){ifelse(OutDataQuart$date<=x, 1, 0)})
  actions <-  matrix(c(t(incidents[, list(action1, action2)] )),nrow=1) %x% rep(1, nrow(idx1))
  idx  <- (idx1*idx2) %x% t(rep(1, 2))
  actions <- actions*idx
  actions2 <- matrix(nrow=nrow(idx), ncol=2)
  actions2[,1] <- apply(actions[,seq(1, ncol(actions), by=2), drop=FALSE], 1, max)
  actions2[,2] <- apply(actions[,seq(2, ncol(actions), by=2), drop=FALSE], 1, max)
  state <- lag(as.zoo(actions2), k=-1, na.pad=TRUE)
  state <- apply(state, 2, function(x){ifelse(is.na(x), 0 ,x)})
  state <- apply(state, 1, max)
  OutDataQuart[ , `:=` (action1 = actions2[,1], action2 = actions2[,2], state=state)]
  quartData <- rbind(quartData, OutDataQuart)
  
  ##Yearly
  OutDataYear  <- data.table(date=seq(from=as.Date(paste(tmp$Syear, "/1/1", sep="")), to=as.Date(paste(tmp$endyear, "/12/31", sep="")), by="year"),
                             dyadID = i,
                             ccode1 = tmp$ccode1,
                             ccode2 = tmp$ccode2)
  
  minus1 <- as.POSIXlt(incidents$startDate)
  minus1$year <- minus1$year - 1
  minus1 <- as.Date(minus1)
  idx1 <- sapply(minus1, function(x){ifelse(OutDataYear$date>x, 1, 0)})
  idx2 <- sapply(incidents$startDate, function(x){ifelse(OutDataYear$date<=x, 1, 0)})
  actions <-  matrix(c(t(incidents[, list(action1, action2)] )),nrow=1) %x% rep(1, nrow(idx1))
  idx  <- (idx1*idx2) %x% t(rep(1, 2))
  actions <- actions*idx
  actions2 <- matrix(nrow=nrow(idx), ncol=2)
  actions2[,1] <- apply(actions[,seq(1, ncol(actions), by=2), drop=FALSE], 1, max)
  actions2[,2] <- apply(actions[,seq(2, ncol(actions), by=2), drop=FALSE], 1, max)
  state <- lag(as.zoo(actions2), k=-1, na.pad=TRUE)
  state <- apply(state, 2, function(x){ifelse(is.na(x), 0 ,x)})
  state <- apply(state, 1, max)
  OutDataYear[ , `:=` (action1 = actions2[,1], action2 = actions2[,2], state=state)]
  yearData <- rbind(yearData, OutDataYear)
  
}



dataSets <- list(M=monthData,
                 Q=quartData,
                 Y=yearData)
codeStateActions <- function(x)
{
  y <- x[, list(action1, action2, state)]
  
  y <- ifelse(y>=16,
              3,
              ifelse(y>0,
                     2,
                     1))
  x$action1  <- y[,"action1"]
  x$action2  <- y[,"action2"]
  x$state  <- y[,"state"]
  
  return(x)
}

dataSets <- lapply(dataSets, codeStateActions)


monTab <- dataSets$M[,list(A11=sum(action1==1), A12=sum(action1==2), A13=sum(action1==3),
                           A21=sum(action2==1), A22=sum(action2==2), A23=sum(action2==3)), by=dyadID]
monTab[, `:=` (A1= A11+A21, A2 =A12+A22, A3= A13+A23)]
monTab[, `:=` (tab12 = (A1*A2)>0, tab13 = (A1*A3)>0, tab123 = (A1*A2*A3)>0, tab0 = (A2+A3)==0)]
table(monTab$tab12)
table(monTab$tab13)
table(monTab$tab123)
table(monTab$tab0)



quartTab <- dataSets$Q[,list(A11=sum(action1==1), A12=sum(action1==2), A13=sum(action1==3),
                             A21=sum(action2==1), A22=sum(action2==2), A23=sum(action2==3)), by=dyadID]
quartTab[, `:=` (A1= A11+A21, A2 =A12+A22, A3= A13+A23)]
quartTab[, `:=` (tab12 = (A1*A2)>0, tab13 = (A1*A3)>0, tab123 = (A1*A2*A3)>0, tab0 = (A2+A3)==0)]
table(quartTab$tab12)
table(quartTab$tab13)
table(quartTab$tab123)
table(quartTab$tab0)

yearTab <- dataSets$Q[,list(A11=sum(action1==1), A12=sum(action1==2), A13=sum(action1==3),
                            A21=sum(action2==1), A22=sum(action2==2), A23=sum(action2==3)), by=dyadID]
yearTab[, `:=` (A1= A11+A21, A2 =A12+A22, A3= A13+A23)]
yearTab[, `:=` (tab12 = (A1*A2)>0, tab13 = (A1*A3)>0, tab123 = (A1*A2*A3)>0, tab0 = (A2+A3)==0)]
table(yearTab$tab12)
table(yearTab$tab13)
table(yearTab$tab123)
table(yearTab$tab0)


mP1 <- with(monTab, sum(A1)/sum(A1, A2, A3))
mP2 <- with(monTab, sum(A2)/sum(A1, A2, A3))
mP3 <- with(monTab, sum(A3)/sum(A1, A2, A3))
qP1 <- with(quartTab, sum(A1)/sum(A1, A2, A3))
qP2 <- with(quartTab, sum(A2)/sum(A1, A2, A3))
qP3 <- with(quartTab, sum(A3)/sum(A1, A2, A3))
yP1 <- with(yearTab, sum(A1)/sum(A1, A2, A3))
yP2 <- with(yearTab, sum(A2)/sum(A1, A2, A3))
yP3 <- with(yearTab, sum(A3)/sum(A1, A2, A3))

cbind(c(mP1, mP2, mP3),
      c(qP1, qP2, qP3),
      c(yP1, yP2, yP3))




save(list=c("Xij",
            "Xi",
            "dataSets"),
     file="DyadicMIDS_Rdata.rdata")
