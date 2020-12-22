-- global variables
readyPlayers = {}

-- send players their information
function sendPlayerUpdateToPlayer(player)
	debugMessage('[S2C_PLAYER_SYNC] to ' .. player.name)
	NetEvents:SendTo(GameMessage.S2C_PLAYER_SYNC, player, player.id)
end

-- set player to spectator
local function setPlayerSpectating(player)
	debugMessage('setPlayerSpectating ' .. player.name)
	player.teamId = TeamId.TeamNeutral
end

-- set player to props
local function setPlayerProps(player)
	debugMessage('setPlayerProps ' .. player.name)
	player.teamId = TeamId.Team2
end

-- set player to seeker
local function setPlayerSeeker(player)
	debugMessage('setPlayerSeeker ' .. player.name)
	player.teamId = TeamId.Team1
end

-- check whether a player is seeker
function isSeeker(player)
	debugMessage('isSeeker ' .. player.name)
	debugMessage(player.teamId == TeamId.Team1)
	return player.teamId == TeamId.Team1
end

-- check whether a player is prop
function isProp(player)
	debugMessage('isProp ' .. player.name)
	debugMessage(player.teamId == TeamId.Team2)
	return player.teamId == TeamId.Team2
end

-- check whether a player is spectator
function isSpectator(player)
	debugMessage('isSpectator ' .. player.name)
	debugMessage(player.teamId == TeamId.TeamNeutral)
	return player.teamId == TeamId.TeamNeutral
end

-- get count of seekers
function getSeekerCount()
	local count = 0
	for i, player in pairs(readyPlayers) do
		-- Ignore bots
		if not player.onlineId ~= 0 and player.soldier ~= nil then
			count = count + 1
		end
	end
	debugMessage('getSeekerCount ' .. count)
	return count
end

-- get count of props
function getPropCount()
	local count = 0
	for i, player in pairs(readyPlayers) do
		-- Ignore bots and dead players.
		if player.onlineId ~= 0 and player.soldier ~= nil then
			count = count + 1
		end
	end
	debugMessage('getPropCount ' .. count)
	return count
end

-- reset players to default (specating)
function resetPlayers()
	debugMessage('resetPlayers')
	for i, player in pairs(readyPlayers) do
		setPlayerSpectating(player)
		sendPlayerUpdateToPlayer(player)
	end
end

-- assign player to teams
function assignTeams()
	debugMessage('assignTeams')
	-- get count of seeker for this round
	local numSeeker = math.floor((#readyPlayers / 100) * Config.PercenTageSeeker)
	-- set change to be selected as a seeker
	local seekerChance = 1.0 / #readyPlayers
	-- set to at least one seeker
	if numSeeker < 1 then
		numSeeker = 1
	end
	-- First we reset all players
	resetPlayers()
	-- fill in random seed
	math.randomseed(SharedUtils:GetTimeMS())
	-- Then we start going through everyone, randomly selecting seekers
	-- until we have filled our quota.
	local count = 0
	-- as long as we have not enough seeker
	while count < numSeeker do
		-- iterate through all ready players
		for i, player in pairs(readyPlayers) do
			-- ignore when we got enough
			if count >= numSeeker then
				goto assign_continue
			end
			-- ignore when already seeker
			if isSeeker(player) then
				goto assign_continue
			end
			-- set player to seeker otherwise
			if math.random() <= seekerChance then
				setPlayerSeeker(player)
				sendPlayerUpdateToPlayer(player)
				count = count + 1
			end

			::assign_continue::
		end
	end
	-- set other ready player to props
	for i, player in pairs(readyPlayers) do
		if not isSeeker(player) then
			setPlayerProps(player)
			sendPlayerUpdateToPlayer(player)
		end
	end
end

-- set props to props and seekers to seekers
function prepareSpawnedPlayers()
	-- Make prop players into props and seekers into seekers.
	for _, player in pairs(readyPlayers) do
		if isSeeker(player) then
			--makePlayerSeeker(player)
			-- For seekers we also want to fade their screen to black.
			player:Fade(1.0, true)
			-- And also prevent them from moving.
			player:EnableInput(EntryInputActionEnum.EIAThrottle, false)
			player:EnableInput(EntryInputActionEnum.EIAStrafe, false)
			player:EnableInput(EntryInputActionEnum.EIAFire, false)
		--else
		--	makePlayerProp(player)
		end
	end
end

-- when a player joined and is ready
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, function(player)
	debugMessage('[C2S_CLIENT_READY] from ' .. player.name)
	-- add player to player list
	table.insert(readyPlayers, player)
	-- set player to spectator
	setPlayerSpectating(player)
	-- send update to player
	sendPlayerUpdateToPlayer(player)
end)

-- Remove player from list of ready players when they disconnect.
Events:Subscribe('Player:Destroyed', function(player)
	debugMessage('[Player:Destroyed] from ' .. player.name)
	for i, readyPlayer in pairs(readyPlayers) do
		if readyPlayer == player then
			table.remove(readyPlayers, i)
			break
		end
	end
end)

-- Clear all ready players when a new level is loading.
Events:Subscribe('Level:Destroy', function()
	readyPlayers = {}
end)