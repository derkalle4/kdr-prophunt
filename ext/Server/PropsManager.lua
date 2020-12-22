local playerPropNames = {}

-- subscribe to level destroy
Events:Subscribe('Level:Destroy', cleanupRound)

-- subscribe to extension unloading
Events:Subscribe('Extension:Unloading', cleanupRound)

-- subscribe to client onready event
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, function(player)
	-- Sync existing props to connecting clients.
	for id, bpName in pairs(playerPropNames) do
		sendUpdateToPlayer(player, id, bpName)
	end
end)

-- subscribe to client prop change event
NetEvents:Subscribe(GameMessage.C2S_PROP_CHANGE, function(player, bpName)
	-- set new client prop
	setPlayerProp(player, bpName)
end)

-- subscribe to player killed event
Events:Subscribe('Player:Killed', function(player)
	removePlayerProp(player)
end)

-- subscribe to player destroyed event
Events:Subscribe('Player:Destroyed', function(player)
	removePlayerProp(player)
end)

-- send data to specific client
local function sendUpdateToPlayer(player, playerID, prop)
	NetEvents:SendTo(GameMessage.S2C_PROP_SYNC, player, playerID, prop)
end

-- broadcast changed prop
local function broadCastClients(playerID, prop)
	NetEvents:Broadcast(GameMessage.S2C_PROP_SYNC, playerID, prop)
end

-- set new prop for player
function setPlayerProp(player, bpName)
	print('Setting prop for player')
	-- player has to be alive
	if player.soldier == nil then
		return
	end
	-- player must be on the prop team
	if not isProp(player) then
		return
	end
    -- Set the prop for this player.
    local oldProp = playerPropNames[player.id]
    -- If it has not changed then do nothing.
	if oldProp == bpName then
		return
	end
	-- check for blueprint
    local bp = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
    -- fail when blueprint does not exist
    if bp == nil then
        return
    end
	-- save new prop name for player
	playerPropNames[player.id] = bpName
	-- broadcast changes to clients
	broadCastClients(player, player.id, bpName)
end

-- remove prop from player
local function removePlayerProp(player)
	if player.soldier ~= nil then
		player.soldier.forceInvisible = false
	end
	playerPropNames[player.id] = nil
	-- broadcast to clients
	broadCastClients(player.id, nil)
end

-- make player to prop
function makePlayerProp(player)
	local bpName = 'XP2/Objects/SkybarBarStool_01/SkybarBarStool_01'
	-- make player invisible
	player.soldier.forceInvisible = true
	-- Set default prop for player.
	setPlayerProp(player, bpName)
	-- remove most functions
	player:EnableInput(EntryInputActionEnum.EIAFire, false)
	player:EnableInput(EntryInputActionEnum.EIAZoom, false)
	player:EnableInput(EntryInputActionEnum.EIAProne, false)
	player:EnableInput(EntryInputActionEnum.EIAReload, false)
	player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, false)
	player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, false)
	-- keep parachute enabled for reasons
	player:EnableInput(EntryInputActionEnum.EIAToggleParachute, true)
	-- update local player
	sendPlayerUpdateToPlayer(player)
end

-- make player a seeker
function makePlayerSeeker(player)
	-- make player visible
	player.soldier.forceInvisible = false
	-- enable most functions
	player:EnableInput(EntryInputActionEnum.EIAFire, true)
	player:EnableInput(EntryInputActionEnum.EIAZoom, true)
	player:EnableInput(EntryInputActionEnum.EIAProne, true)
	player:EnableInput(EntryInputActionEnum.EIAReload, true)
	player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, false)
	player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, false)
	-- keep parachute enabled for reasons
	player:EnableInput(EntryInputActionEnum.EIAToggleParachute, true)
	-- broadcast change to player
	broadCastClients(player.id, nil)
	-- update local player
	sendPlayerUpdateToPlayer(player)
end

-- clean up round
local function cleanupRound()
	playerPropNames = {}
	-- set all players visible again
	for i, player in pairs(readyPlayers) do
		if player.soldier ~= nil then
			player.soldier.forceInvisible = false
		end
	end
end
