local nameTagHeight = 1.5

local function doRender()
	-- iterate through all players
	local players = PlayerManager:GetPlayers()
	local localPlayer = PlayerManager:GetLocalPlayer()
	local teamText = ''
	for _, player in pairs(players) do
		-- only spawned players
		if player.soldier == nil then
			goto continue
		end
		-- check whether player is in same team or if player is spectator
		if localPlayer.teamId ~= 0 and localPlayer.teamId ~= player.teamId then
			goto continue
		end
		-- check whether we are that player (we do not need our nametag)
		if localPlayer == player then
			goto continue
		end
		-- get player position
		local playerTrans = player.soldier.transform.trans:Clone()
		-- set height of nametag
		playerTrans.y = playerTrans.y + nameTagHeight
		-- get player world screen position
		local screenPos = ClientUtils:WorldToScreen(playerTrans)
		-- check if screenPos is nil
		if screenPos == nil then
			goto continue
		end
		-- set team teamText
		if player.teamId == 1 then
			teamText = '[SEEKER] '
		elseif player.teamId == 2 then
			teamText = '[HIDER] '
		end
		-- draw name of player
		DebugRenderer:DrawText2D(screenPos.x, screenPos.y, teamText .. player.name, Vec4(0, 1, 0, 1), 1.0)
		:: continue ::
	end
end


Events:Subscribe('UI:DrawHud', self, doRender)