local Camera = require('Camera')

NetEvents:Subscribe(GameMessage.S2C_PLAYER_SYNC, function(playerID)
	debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID)
	local player = PlayerManager:GetPlayerById(playerID)
	local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
	-- check for local player and whether he is in the prop team
	-- TODO: shared checks for "isSeeker" and "isProp"
	if isLocalPlayer and player.teamId == TeamId.Team1 then
		debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID .. ' is seeker')
		isProp = false
		Camera:disable()
	end
end)
