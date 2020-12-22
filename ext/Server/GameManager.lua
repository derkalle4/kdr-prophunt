-- global variables
currentState = {
	roundTimer = 0.0,
	roundState = GameState.idle,
	roundStatusMessage = ''
}

-- send round info to a player as soon as they join.
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, function(player)
	-- send event
	NetEvents:SendTo(GameMessage.S2C_GAME_SYNC, player, currentState)
end)

-- broadcast specific information to clients
-- e.g. GameManager stuff like roundTimer, roundState
-- e.g. Client UI stuff like roundStatusMessage
local function broadCastClients(info)
	NetEvents:Broadcast(GameMessage.S2C_GAME_SYNC, info)
end

Events:Subscribe('Engine:Update', function(dt)
	-- check round state
	checkRoundState(currentState.roundState)
	-- check whether we can count time down
	if currentState.roundTimer >= 0.0 then
		-- set timer when necessary
		currentState.roundTimer = currentState.roundTimer - dt
		-- set timer to 0.0 when it is smaller than 0.0
		if currentState.roundTimer < 0.0 then
			currentState.roundTimer = 0.0
		end
	end
end)

-- check round state
local function checkRoundState(state)
	if state == GameState.idle then				-- idle after mapchange
		inIdleState()
	elseif state == GameState.preRound then		-- pre round before game starts
		inPreRoundState()
	elseif state == GameState.hiding then		-- hide phase for hiders
		inHidingState()
	elseif state == GameState.seeking then		-- seek phase for seekers
		inSeekingState()
	elseif state == GameState.postRound then	-- end of game
		inPostRoundState()
	end
end

-- things to do when we go in idle state
local function prepareIdleState()
	currentState.roundTimer = 0.0
	currentState.roundState = GameState.idle
end

-- when we are in idle state
local function inIdleState()
	-- check whether we have enough players on the server
	if #readyPlayers < Config.MinPlayers then
		-- set current roundStatusMessage and send to clients when necessary
		local tmpRoundStatusMessage = 'Waiting for players to join. Please stand by.'
		if not currentState.roundStatusMessage == tmpRoundStatusMessage then
			currentState.roundStatusMessage = tmpRoundStatusMessage
		end
		-- end function
		return
	end
	-- prepare PreRound state
	preparePreRoundState()
end

-- things to do when we go in preRound state
local function preparePreRoundState()
	-- set timer to preRound countdown
	currentState.roundTimer = Config.RoundStartCountdown
	-- set round state to preRound
	currentState.roundState = GameState.preRound
	-- broadcast changes to clients
	broadCastClients(currentState)
end

-- when we are in preRoundState()
local function inPreRoundState()

end

-- things to do when we go in hiding state
local function prepareHidingState()

end

-- when we are in hiding state
local function inHidingState()

end

-- things to do when we go in seeking state
local function prepareSeekingState()

end

-- when we are in seeking state
local function inSeekingState()

end

-- things to do when we go in postRound state
local function preparePostRoundState()

end

-- when we are in postRound state
local function inPostRoundState()
	-- restart map
	RCON:SendCommand('mapList.restartRound')
end