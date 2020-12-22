-- global variables
currentState = {
	roundTimer = 0.0,
	roundState = GameState.idle,
	roundStatusMessage = ''
}

-- local variables
local lastUpdate = 0.0

-- send players their information
local function sendUpdateToPlayer(player, info)
	debugMessage('[S2C_GAME_SYNC] to ' .. player.name)
	NetEvents:SendTo(GameMessage.S2C_GAME_SYNC, player, info)
end

-- broadcast specific information to clients
-- e.g. GameManager stuff like roundTimer, roundState
-- e.g. Client UI stuff like roundStatusMessage
local function broadCastClients(info)
	debugMessage('[S2C_GAME_SYNC] broadcast')
	NetEvents:Broadcast(GameMessage.S2C_GAME_SYNC, info)
end

-- things to do when we go in preRound state
local function prepareIdleState()
	debugMessage('preparing idle state')
	-- set timer to 0.0
	currentState.roundTimer = 0.0
	-- set round state to preRound
	currentState.roundState = GameState.idle
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Waiting for players')
end

-- things to do when we go in preRound state
local function preparePreRoundState()
	debugMessage('preparing preRound state')
	-- set timer to preRound countdown
	currentState.roundTimer = Config.RoundStartCountdown
	-- set round state to preRound
	currentState.roundState = GameState.preRound
	-- assign team to player
	assignTeams()
	-- spawn players
	spawnAllPlayers()
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Waiting for Game to start')
end

-- things to do when we go in hiding state
local function prepareHidingState()
	debugMessage('preparing hiding state')
	-- set timer to preRound countdown
	currentState.roundTimer = Config.HidingTime
	-- set round state to preRound
	currentState.roundState = GameState.hiding
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- prepare spawned players for a new round
	prepareSpawnedPlayers()
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Prepare to hide!')
end

-- things to do when we go in seeking state
local function prepareSeekingState()
	debugMessage('preparing seeking state')
	-- set timer to preRound countdown
	currentState.roundTimer = Config.TimeLimit
	-- set round state to preRound
	currentState.roundState = GameState.seeking
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- Fade in all the seekers and allow them to move again.
	for _, player in pairs(readyPlayers) do
		if isSeeker(player) then
			player:Fade(1.0, false)
			player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
			player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
			player:EnableInput(EntryInputActionEnum.EIAFire, true)
		end
	end
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Prepare to seek!')
end

-- things to do when we go in postRound state
local function preparePostRoundState()
	debugMessage('preparing postround state')
	-- set timer to preRound countdown
	currentState.roundTimer = Config.PostRoundTime
	-- set round state to preRound
	currentState.roundState = GameState.postRound
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Round end! Do not know who won yet. LOL!')
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

-- when we are in preRoundState()
local function inPreRoundState()
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Game starting in ' .. math.floor(currentState.roundTimer))
	-- go into hiding state when pre round is finished
	if currentState.roundTimer == 0.0 then
		prepareHidingState()
	end
end

-- when we are in hiding state
local function inHidingState()
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Time left to hide ' .. math.floor(currentState.roundTimer))
	-- go into seeking state when pre round is finished
	if currentState.roundTimer == 0.0 then
		prepareSeekingState()
	end
end

-- when we are in seeking state
local function inSeekingState()
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Time left to seek ' .. math.floor(currentState.roundTimer))
	-- go into postround state when pre round is finished
	if currentState.roundTimer == 0.0 then
		preparePostRoundState()
	end
	-- or go into postround state when one group is "dead"
	--if currentState.roundState == GameState.seeking and (getSeekerCount() == 0 or getPropCount() == 0) then
	--	preparePostRoundState()
	--end
end

-- when we are in postRound state
local function inPostRoundState()
	-- TODO: Actual messages.
	if getSeekerCount() == 0 then
		ChatManager:SendMessage('Props win! (Because Seeker died!)')
	elseif getPropCount() == 0 then
		ChatManager:SendMessage('Seekers win!')
	else
		ChatManager:SendMessage('Props win! (Because Time is over!)')
	end
	-- SendMessage to players (no gui yet)
	ChatManager:SendMessage('Round restart in ' .. math.floor(currentState.roundTimer))
	-- go into hiding state when pre round is finished
	if currentState.roundTimer == 0.0 then
		-- restart map
		RCON:SendCommand('mapList.restartRound')
	end
end

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

-- send round info to a player as soon as they join.
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, function(player)
	debugMessage('[C2S_CLIENT_READY] from ' .. player.name)
	-- send event
	sendUpdateToPlayer(player, currentState)
end)

Events:Subscribe('Engine:Update', function(deltaTime)
	-- run event only every 1.0 seconds to save CPU time
	if lastUpdate >= 1.0 then
		-- check round state
		checkRoundState(currentState.roundState)
		lastUpdate = 0.0
	end
	-- increase lastUpdate value
	lastUpdate = lastUpdate + deltaTime
	-- check whether we can count time down
	if currentState.roundTimer >= 0.0 then
		-- set timer when necessary
		currentState.roundTimer = currentState.roundTimer - deltaTime
		-- set timer to 0.0 when it is smaller than 0.0
		if currentState.roundTimer < 0.0 then
			currentState.roundTimer = 0.0
		end
	end
end)

-- reset round info when a level is loading
Events:Subscribe('Level:LoadResources', function()
	-- reset to idle
	prepareIdleState()
end)