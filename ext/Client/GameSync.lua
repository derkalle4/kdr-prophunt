local oldState = -1

NetEvents:Subscribe(GameMessage.S2C_GAME_SYNC, function(info)
	WebUI:ExecuteJS('setRoundInfo(' .. info.numSeeker .. ', ' .. info.numHider .. ', ' .. info.numSpectator .. ', "' .. info.roundStatusMessage .. '", ' .. math.floor(info.roundTimer) .. ');')

	if oldState ~= info.roundState then
		if info.roundState == GameState.idle then				-- idle after mapchange
			WebUI:ExecuteJS('setUserMessage("Waiting for players");')
			WebUI:ExecuteJS('setCenterMessage("");')
			oldState = GameState.idle
		elseif info.roundState == GameState.preRound then		-- pre round before game starts
			WebUI:ExecuteJS('setUserMessage("");')
			oldState = GameState.preRound
		elseif info.roundState == GameState.hiding then		-- pre round before game starts
			local localPlayer = PlayerManager:GetLocalPlayer()
			-- play round start sound
			WebUI:ExecuteJS('playSound("roundstart1");')
			if localPlayer.teamId == 1 then
				WebUI:ExecuteJS('setCenterMessage("Wait until Hiders are hidden", 5);')
			elseif localPlayer.teamId == 2 then
				WebUI:ExecuteJS('setCenterMessage("Hide yourself now!", 5);')
			else
				WebUI:ExecuteJS('setCenterMessage("a new round is starting", 5);')
			end
			oldState = GameState.hiding
		elseif info.roundState == GameState.postRound then	-- end of game
			if oldState ~= info.roundState then
				local localPlayer = PlayerManager:GetLocalPlayer()
				if info.winner == 1 then
					WebUI:ExecuteJS('setCenterMessage("Seekers win!");')
				else
					WebUI:ExecuteJS('setCenterMessage("Hiders win!");')
				end
				WebUI:ExecuteJS('setUserMessage("");')
				WebUI:ExecuteJS('postRoundOverlay(' .. info.winner .. ', ' .. localPlayer.teamId .. ');')
				WebUI:ExecuteJS('setUserTeam(0);')
				oldState = GameState.postRound
			end
		end
	end
end)

local function UIsendPlayerData()
	local data = {}
	local localPlayer = PlayerManager:GetLocalPlayer()
	if localPlayer == nil then
		return
	end
	local players = PlayerManager:GetPlayers()
	for _, player in pairs(players) do
		table.insert(data, {
			alive = player.soldier ~= nil,
			username = player.name,
			team = player.teamId,
		})
	end
	WebUI:ExecuteJS('updateScoreboard(' .. json.encode(data) .. ', ' .. localPlayer.teamId .. ');')
end

local lastUpdate = 0.0
Events:Subscribe('Engine:Update', function(deltaTime)
	-- run event only every 1.0 seconds to save CPU time
	if lastUpdate >= 0.9 then
		-- update UI player data
		UIsendPlayerData()
		lastUpdate = 0.0
	end
	-- increase lastUpdate value
	lastUpdate = lastUpdate + deltaTime
end)