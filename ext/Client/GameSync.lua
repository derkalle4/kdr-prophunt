local oldState = -1

NetEvents:Subscribe(GameMessage.S2C_GAME_SYNC, function(info)
	WebUI:ExecuteJS('setRoundInfo(' .. info.numPlayer .. ',' .. info.numSeeker .. ', ' .. info.numHider .. ', ' .. info.numSpectator .. ', "' .. info.roundStatusMessage .. '", ' .. math.floor(info.roundTimer) .. ');')

	if oldState ~= info.roundState then
		local localPlayer = PlayerManager:GetLocalPlayer()
		if info.roundState == GameState.idle then				-- idle after mapchange
			WebUI:ExecuteJS('setCenterMessage("");')
			WebUI:ExecuteJS('showHiderKeys(false);')
			WebUI:ExecuteJS('showIdleStateMessage(true);')
			oldState = GameState.idle
		elseif info.roundState == GameState.preRound then		-- pre round before game starts
			oldState = GameState.preRound
			WebUI:ExecuteJS('showIdleStateMessage(false);')
			if localPlayer.teamId == 2 then
				WebUI:ExecuteJS('showHiderKeys(true);')
			end
		elseif info.roundState == GameState.hiding then		-- pre round before game starts
			-- play round start sound
			WebUI:ExecuteJS('playSound("roundstart1");')
			if localPlayer.teamId == 1 then
				WebUI:ExecuteJS('setCenterMessage("wait until hiders are hidden", 7);')
			elseif localPlayer.teamId == 2 then
				WebUI:ExecuteJS('setCenterMessage("prepare to hide!", 7);')
			else
				WebUI:ExecuteJS('setCenterMessage("hiders going to hide themself", 7);')
			end
			oldState = GameState.hiding
		elseif info.roundState == GameState.seeking then
			if localPlayer.teamId == 1 then
				WebUI:ExecuteJS('setCenterMessage("kill all props!", 7);')
			elseif localPlayer.teamId == 2 then
				WebUI:ExecuteJS('setCenterMessage("hide now!", 7);')
			else
				WebUI:ExecuteJS('setCenterMessage("seekers starting their search", 7);')
			end
			oldState = GameState.seeking
		elseif info.roundState == GameState.postRound then	-- end of game
			if oldState ~= info.roundState then
				if info.winner == 1 then
					WebUI:ExecuteJS('setCenterMessage("seekers win!", 15);')
				else
					WebUI:ExecuteJS('setCenterMessage("hiders win!", 15);')
				end
				WebUI:ExecuteJS('postRoundOverlay(' .. info.winner .. ', ' .. localPlayer.teamId .. ');')
				WebUI:ExecuteJS('setUserTeam(0);')
				WebUI:ExecuteJS('showHiderKeys(false);')
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
			id = player.id,
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