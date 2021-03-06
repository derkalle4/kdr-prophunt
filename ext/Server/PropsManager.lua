-- PropsManager
-- manages everything related to props


-- all player prop names
local playerPropNames = {}



-- send data to specific client
local function sendUpdateToPlayer(player, playerID, prop)
    debugMessage('[S2C_PROP_SYNC] to ' .. player.name)
    NetEvents:SendTo(GameMessage.S2C_PROP_SYNC, player, playerID, prop)
end

-- broadcast changed prop
local function broadCastClients(playerID, prop, magnitude)
    if prop == nil then
        debugMessage('[S2C_PROP_SYNC] broadcast: nil')
    else
        debugMessage('[S2C_PROP_SYNC] broadcast: ' .. prop)
    end
    NetEvents:Broadcast(GameMessage.S2C_PROP_SYNC, playerID, prop, magnitude)
end

-- set new prop for player
function setPlayerProp(player, bpName)
    debugMessage('Setting prop ' .. bpName .. ' for player ' .. player.name)
    -- player has to be alive
    if player.soldier == nil then
        return
    end
    -- player must be on the prop team
    if not isProp(player) then
        return
    end
    -- If it has not changed then do nothing.
    if playerPropNames[player.id] == bpName then
        return
    end
    -- check for blueprint
    local bp = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
    -- fail when blueprint does not exist
    if bp == nil then
        return
    end
    -- make player invisible
    player.soldier.forceInvisible = true
    -- set temporary entity position
    local entityPos = LinearTransform()
    entityPos.trans = Vec3(0.0, 0.0, 0.0)
    -- create temporary entity from blueprint
    local tmpEntity = EntityManager:CreateEntitiesFromBlueprint(bp, entityPos)
    -- create spatial entity from entity
    tmpEntity = SpatialEntity(tmpEntity.entities[1])
    -- calculate health from entity magnitude
    tmpHealth = math.floor(MathUtils:Lerp(5.0, 75.0, tmpEntity.aabb.max.magnitude))
    -- set current health to 1 when 0 to avoid divide by zero
    if player.soldier.health == 0 then
        player.soldier.health = 1
    end
    -- set tmpHealth to max health when it exceeds our maximum
    if tmpHealth > Config.MaxHiderHealth then
        tmpHealth = Config.MaxHiderHealth
    end
    -- calculate current health from user (take percentage from current health for new health)
    local curHealthPercentage = player.soldier.health / player.soldier.maxHealth
    -- set new maxHealth to player
    player.soldier.maxHealth = tmpHealth
    -- set new current health to player
    player.soldier.health = player.soldier.maxHealth * curHealthPercentage
    -- save new prop name for player
    playerPropNames[player.id] = bpName
    -- broadcast changes to clients
    broadCastClients(player.id, bpName, tmpEntity.aabb.max.magnitude)
end

-- remove prop from player
local function removePlayerProp(player)
    debugMessage('removePlayerProp ' .. player.name)
    if player.soldier ~= nil then
        player.soldier.forceInvisible = false
    end
    playerPropNames[player.id] = nil
    -- broadcast to clients
    broadCastClients(player.id, nil, nil)
end

-- make player to prop
function makePlayerProp(player)
    debugMessage('makePlayerProp ' .. player.name)
    -- get level name
    local level = SharedUtils:GetLevelName()
    -- get random prop for spawn
    math.randomseed(SharedUtils:GetTimeMS())
    local bpName = RandomPropsBlueprints[level][MathUtils:GetRandomInt(1, #RandomPropsBlueprints[level])]
    -- Set default prop for player when he did not choose one already
    if playerPropNames[player.id] == nil then
        setPlayerProp(player, bpName)
    end
    -- remove most functions
    player:EnableInput(EntryInputActionEnum.EIAFire, false)
    player:EnableInput(EntryInputActionEnum.EIAZoom, false)
    player:EnableInput(EntryInputActionEnum.EIAProne, false)
    player:EnableInput(EntryInputActionEnum.EIAReload, false)
    player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, false)
    player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, false)
    -- keep parachute enabled for reasons
    player:EnableInput(EntryInputActionEnum.EIAToggleParachute, true)
    player:EnableInput(EntryInputActionEnum.EIASprint, true)
    -- update local player
    sendPlayerUpdateToPlayer(player)
end

-- make player a seeker
function makePlayerSeeker(player)
    debugMessage('makePlayerSeeker ' .. player.name)
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
    player:EnableInput(EntryInputActionEnum.EIASprint, true)
    -- broadcast change to player
    broadCastClients(player.id, nil, nil)
    -- update local player
    sendPlayerUpdateToPlayer(player)
end

-- clean up round
local function cleanupRound()
    debugMessage('cleanupRound')
    playerPropNames = {}
    -- set all players visible again
    for i, player in pairs(readyPlayers) do
        if player.soldier ~= nil then
            player.soldier.forceInvisible = false
        end
    end
end

-- subscribe to client onready event
local function onClientReady(player)
    debugMessage('[C2S_CLIENT_READY] from ' .. player.name)
    -- Sync existing props to connecting clients.
    for id, bpName in pairs(playerPropNames) do
        sendUpdateToPlayer(player, id, bpName)
    end
end

-- subscribe to client prop change event
local function onPropChange(player, bpName)
    debugMessage('[C2S_PROP_CHANGE] from ' .. player.name)
    -- set new client prop
    setPlayerProp(player, bpName)
end

-- subscribe to player killed event
local function onPlayerKilled(player)
    debugMessage('[Player:Killed] ' .. player.name)
    removePlayerProp(player)
end

-- subscribe to player destroyed event
local function onPlayerDestroyed(player)
    debugMessage('[Player:Destroyed] ' .. player.name)
    removePlayerProp(player)
end

-- events and hooks
Events:Subscribe('Level:Destroy', cleanupRound)
Events:Subscribe('Extension:Unloading', cleanupRound)
Events:Subscribe('Player:Killed', onPlayerKilled)
Events:Subscribe('Player:Destroyed', onPlayerDestroyed)
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, onClientReady)
NetEvents:Subscribe(GameMessage.C2S_PROP_CHANGE, onPropChange)