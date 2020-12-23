NetEvents:Subscribe(GameMessage.S2C_GAME_SYNC, function(info)
	WebUI:ExecuteJS('setRoundInfo(' .. info.numSeeker .. ', ' .. info.numHider .. ', ' .. info.numSpectator .. ', "' .. info.roundStatusMessage .. '", ' .. math.floor(info.roundTimer) .. ');')

	if info.roundState == GameState.idle then				-- idle after mapchange
		WebUI:ExecuteJS('setUserMessage("Waiting for players");')
	elseif info.roundState == GameState.preRound then		-- pre round before game starts
		WebUI:ExecuteJS('setUserMessage("");')
	elseif info.roundState == GameState.postRound then	-- end of game
		WebUI:ExecuteJS('setUserMessage("' .. info.winner .. ' won!");')
		WebUI:ExecuteJS('setUserTeam(0);')
	end
end)
