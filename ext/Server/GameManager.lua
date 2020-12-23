-- global variables
currentState = {
	roundTimer = 0.0,
	roundState = GameState.idle,
	roundStatusMessage = 'Waiting',
	numSeeker = 0,
	numHider = 0,
	numSpectator = 0,
	winner = ''
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
	NetEvents:Broadcast(GameMessage.S2C_GAME_SYNC, info)
end

-- things to do when we go in idle state
local function prepareIdleState()
	debugMessage('preparing idle state')
	-- set timer to 0.0
	currentState.roundTimer = 0.0
	-- set round state to idle
	currentState.roundState = GameState.idle
	-- set info message
	currentState.roundStatusMessage = 'Waiting'
	-- set number of seeker and Props
	currentState.numSeeker = 0
	currentState.numHider = 0
	-- broadcast changes to clients
	broadCastClients(currentState)
end

-- things to do when we go in preRound state
local function preparePreRoundState()
	debugMessage('preparing preRound state')
	-- set timer to preRound countdown
	currentState.roundTimer = Config.PreRoundTime
	-- set round state to preRound
	currentState.roundState = GameState.preRound
	-- set info message
	currentState.roundStatusMessage = 'PreRound'
	-- set number of seeker and Props
	currentState.numSeeker = getSeekerCount()
	currentState.numHider = getPropCount()
	-- assign team to player
	assignTeams()
	-- spawn players
	spawnAllPlayers()
	-- broadcast changes to clients
	broadCastClients(currentState)
end

-- things to do when we go in hiding state
local function prepareHidingState()
	debugMessage('preparing hiding state')
	-- set timer to hiding countdown
	currentState.roundTimer = Config.HidingTime
	-- set round state to hiding
	currentState.roundState = GameState.hiding
	-- set info message
	currentState.roundStatusMessage = 'Hiding'
	-- set role for players
	setAllPlayersRole()
	-- set number of seeker and Props
	currentState.numSeeker = getSeekerCount()
	currentState.numHider = getPropCount()
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- disable input of seekers
	disableSeekerInput()
end

-- things to do when we go in seeking state
local function prepareSeekingState()
	debugMessage('preparing seeking state')
	-- set timer to seeking countdown
	currentState.roundTimer = Config.TimeLimit
	-- set round state to seeking
	currentState.roundState = GameState.seeking
	-- set info message
	currentState.roundStatusMessage = 'Seeking'
	-- set number of seeker and Props
	currentState.numSeeker = getSeekerCount()
	currentState.numHider = getPropCount()
	-- broadcast changes to clients
	broadCastClients(currentState)
	-- enable input of seekers
	enableSeekerInput()
end

-- things to do when we go in postRound state
local function preparePostRoundState()
	debugMessage('preparing postround state')
	-- set timer to postRound countdown
	currentState.roundTimer = Config.PostRoundTime
	-- set round state to postRound
	currentState.roundState = GameState.postRound
	-- set info message
	currentState.roundStatusMessage = 'PostRound'
	-- set winner
	if getSeekerCount() == 0 then
		currentState.winner = 'Hider'
	elseif getPropCount() == 0 then
		currentState.winner = 'Seeker'
	else
		currentState.winner = 'Hider'
	end
	-- broadcast changes to clients
	broadCastClients(currentState)
end

-- when we are in idle state
local function inIdleState()
	-- check whether we have enough players on the server
	if #readyPlayers < Config.MinPlayers then
		-- end function
		return
	end
	-- prepare PreRound state
	preparePreRoundState()
end

-- when we are in preRoundState()
local function inPreRoundState()
	-- SendMessage to players (no gui yet)
	broadCastClients(currentState)
	-- go into hiding state when pre round is finished
	if currentState.roundTimer == 0.0 then
		prepareHidingState()
	end
end

-- when we are in hiding state
local function inHidingState()
	-- SendMessage to players (no gui yet)
	broadCastClients(currentState)
	-- go into seeking state when pre round is finished
	if currentState.roundTimer == 0.0 then
		prepareSeekingState()
	end
end

-- when we are in seeking state
local function inSeekingState()
	-- broadcast status to clients
	broadCastClients(currentState)
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
	-- broadcast status to clients
	broadCastClients(currentState)
	-- go into hiding state when pre round is finished
	if currentState.roundTimer == 0.0 then
		-- restart map
		RCON:SendCommand('mapList.restartRound')
	end
end

-- check round state
local function checkRoundState(state)
	-- set number of seeker and Props
	currentState.numSeeker = getSeekerCount()
	currentState.numHider = getPropCount()
	currentState.numSpectator = getSpecCount()
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
	if lastUpdate >= 0.9 then
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