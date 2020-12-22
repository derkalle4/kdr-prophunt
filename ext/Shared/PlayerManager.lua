-- check whether a player is seeker
function isSeeker(player)
	if player == nil then
		return false
	end
	return player.teamId == TeamId.Team1
end

-- check whether a player is prop
function isProp(player)
	if player == nil then
		return false
	end
	return player.teamId == TeamId.Team2
end

-- check whether a player is spectator
function isSpectator(player)
	if player == nil then
		return false
	end
	return player.teamId == TeamId.TeamNeutral
end