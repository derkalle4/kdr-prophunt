NetEvents:Subscribe(GameMessage.S2C_PLAYER_SYNC, function(playerID, teamID)
	debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID)
	local player = PlayerManager:GetPlayerById(playerID)
	local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
	-- check for local player and whether he is in the prop team
	if isLocalPlayer and isSeekerByTeamID(teamID) then
		debugMessage('[S2C_PLAYER_SYNC] local player ' .. playerID .. ' is a seeker')
		WebUI:ExecuteJS('setUserTeam(1);')
		Camera:disable()
	end
end)
