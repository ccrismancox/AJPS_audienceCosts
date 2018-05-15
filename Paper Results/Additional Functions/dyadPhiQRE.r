dyadPhiQRE <- function(v, U, P, delta){
  #####################################################################################
  #
  # Updated: 06/09/14
  #####################################################################################
  # INFO :: Value function for dynamic escalation game
  # INPUTS ::
  # # # v : a vector of actor-state-action values
  # # # # # # v = c(v1,v2), vi state-action values for i
  # # # U : a matrix of state-action-profile utilities, ncol=2
  # # # P : a transition matrix, see model$prob
  # # # delta : a discount factor
  # OUTPUTS :: v, return values
  #####################################################################################
	
	# Values, v1ij := action i, state j
	v1 <- matrix(v[1:9],  ncol=3) 
	v2 <- matrix(v[10:18],  ncol=3)

	# normalize
	mv1 <- apply(v1, 2, max)
	mv2 <- apply(v2, 2, max)
	ev1n <- exp(sweep(v1, 2, mv1, "-"))
	ev2n <- exp(sweep(v2, 2, mv2, "-"))
	
	# Condition choice probabilties
	P1 <- matrix(sweep(ev1n, 2, colSums(ev1n), "/"), ncol=1)
	P2 <- matrix(sweep(ev2n, 2, colSums(ev2n), "/"), ncol=1)
	
	# U_i(a|s)
	U1sa <- U[,1] + delta * (P %*% (log(colSums(ev1n)) + mv1)) 
	U2sa <- U[,2] + delta * (P %*% (log(colSums(ev2n)) + mv2))
	
	# Multiply by p_{-i}(a_{-1}|s) 
	V1 <- matrix(matrix(P2, ncol=3) %x% matrix(c(1,1,1), nrow=1), ncol=1)*U1sa
	V2 <- matrix(matrix(P1, ncol=3) %x% matrix(c(1,1,1), ncol=1), ncol=1)*U2sa
	
	# Sum over a_{-i}
	V1 <- rowSums(matrix(V1, ncol=3,byrow=T))
	V2 <- matrix(apply(array(V2, c(3,3,3)), 3, rowSums), ncol=1)
	return(c(V1,V2))
}
