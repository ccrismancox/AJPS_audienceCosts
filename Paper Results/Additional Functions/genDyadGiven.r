genDyadGiven <-function(M, Mun, ts, X, statVar, Xk, delta){
  #####################################################################################
  #
  # Updated: 06/25/14
  #####################################################################################  
  # INFO :: Generate ``Given'' or a list of things used to estimate escalation game
  # INPUTS ::
  # # # M   : a matrix of directed dyads
  # # # Mun	: a matrix of undired dyads # # THIS IS NEW, mbg
  # # # ts : A l x 3 x mun array, corresponding to time series of each relevant dyad
  # # # X : data corresponding to directed dyads
  # # # statVar : a list of vectors, one for each state,
  # # # delta : the assumed discount factor
  # OUTPUTS :: given, used in structural estimation
  #####################################################################################
		
	# prelim stuff
  given <- list()
  given$M <- M
  given$m <- dim(M)[1] # number of ordered dyads
  given$Mun <- Mun 
  given$mun <- dim(given$Mun)[1] #number of dyads, aka unique games
  given$n <- length(unique(given$M[,1])) # number of countries
  given$G <- cbind(rep(1:3,each=9), rep(sort(rep(1:3,3)),3), rep(1:3,3*3))
  given$X <- X
  given$Xk <- Xk
  # given$ts <- ts     # # # THIS IS NEW.  DOES NOT NEED TO BE HERE, mbg
	
  # optional parameters
  if (missing(statVar)){
    given$statVar <- list(1:dim(X)[2],1:dim(X)[2])
  } else {
    given$statVar <- statVar
  }
  
  if (missing(delta)){
    given$delta <- .9
  } else {
    given$delta <- delta
  }
  
  # how many REAL parameters
  given$nBeta <- sum(sapply(given$statVar, FUN=length)) # n Betas
  given$nKappa <- dim(Xk)[2]*2
  given$nReal <-  given$nBeta+given$nKappa+3+given$n
  # how man AUXILIAY parameters
  given$nAux <- given$mun*18
  given$nAll <- given$nAux + given$nReal
  
  
  # transition matrix
  given$prob <- matrix(0,nrow=dim(given$G)[1],ncol=3)
  
  for(i in 1:dim(given$G)[1]){
    if (max(given$G[i,2:3])==1){
      given$prob[i,] <- c(1,0,0)
    } else if(max(given$G[i,2:3])==2){
      given$prob[i,] <- c(0,1,0)
    } else {
      given$prob[i,] <- c(0,0,1)
    }
  }
	
	
	statesInData <- apply(ts[,1,], 2, function(x){x=factor(x,levels=c(1,2,3)); table(x)})
	stateActions <- expand.grid(1:3,1:3)
	stateActions <- stateActions[order(stateActions[,1]),]
	stateActionsInData <- matrix(NA, nrow=dim(stateActions)[1]*2, ncol=given$mun)
  ### ^ *2 for number of players
	
	for (i in 1:dim(stateActions)[1]){
		stateActionsInData[i,] <- colSums(ts[,1,]==stateActions[i,1] & ts[,2,]==stateActions[i,2])
		stateActionsInData[i+9,] <- colSums(ts[,1,]==stateActions[i,1] & ts[,3,]==stateActions[i,2])
	}

  given$statesInData <- statesInData
  given$stateActions <- stateActions
  given$stateActionsInData <- stateActionsInData
	 
	return(given)
}