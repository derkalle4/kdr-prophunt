-- PlayerProp
-- client side UI logic for making players to props


-- local variables
local playerPropBps = {} -- player props blueprints
local playerProps = {} -- player props blueprint names
local soldierEntityInstanceId = nil  -- soldier entity instance
local propInstanceIds = {} -- prop instances
local bloodFx = nil -- blood FX
local playersHit = {} -- whether a player got hit


-- check whether we are hitting the player physics entity
function isHittingPlayerPhysicsEntity(player, hit)
        local bus = playerProps[player.id]
        if bus == nil then
            return false
        end
        for _, prop in pairs(bus.entities) do
            if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                return true
            end
        end
    return false
end

-- create a player prop
function createPlayerProp(player, bp)
    debugMessage('createPlayerProp for ' .. player.name)
    local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- skip when we are this prop already
    if playerPropBps[player.id] == bp then
        return
    end
    -- delete  old prop
    if playerProps[player.id] ~= nil then
        playerProps[player.id].entities[1]:Destroy()
        playerProps[player.id] = nil
    end

    -- create the new player prop
    local bus = EntityManager:CreateEntitiesFromBlueprint(bp, player.soldier.transform)
    -- check whether creation did work or not
    if bus == nil or #bus.entities == 0 then
        debugMessage('Failed to create prop entity for client.')
        return
    end

    -- cast and initialize the entity
    playerPropBps[player.id] = bp

    if isLocalPlayer then
        propInstanceIds = {}
    end

    playerProps[player.id] = bus
    -- iterate through all entities
    for _, entity in pairs(bus.entities) do
        entity:Init(Realm.Realm_Client, true)

        if entity:Is('ClientPhysicsEntity') then
            if isLocalPlayer then
                table.insert(propInstanceIds, PhysicsEntity(entity).physicsEntityBase.instanceId)
            end

            PhysicsEntity(entity):RegisterDamageCallback(player.id, function() return false end)
        end
    end
end

-- check if entity is player prop
function isPlayerProp(otherEntity)
    for _, bus in pairs(playerProps) do
        for _, entity in pairs(bus.entities) do
            if entity.instanceId == otherEntity.instanceId then
                return true
            end
        end
    end
    return false
end

-- remove prop
local function removePlayerProp(playerID)
    debugMessage('removePlayerProp ' .. playerID)
    -- get local entry for player
    local bus = playerProps[playerID]
    -- when there is no entry for that player
    if bus == nil then
        return
    end

    for _, entity in pairs(bus.entities) do
        entity:Destroy()
    end

    playerProps[playerID] = nil
    playerPropBps[playerID] = nil
end

-- player change prop
local function changePlayerProp(playerID, bpName)
    debugMessage('changePlayerProp ' .. playerID)
    -- get player
    local player = PlayerManager:GetPlayerById(playerID)
    -- check whether player is available
    if player == nil or player.soldier == nil then
        debugMessage('changePlayerProp player or soldier nil')
        return
    end
    -- load blueprint
    local blueprint = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
    -- check whether blueprint exists
    if blueprint == nil then
        debugMessage('changePlayerProp blueprint ' .. bpName .. ' is nil')
        return
    end
    -- create player prop
    createPlayerProp(player, blueprint)
end

-- on engine update -> make props follow player
local function onEngineUpdate(delta, simDelta)
    -- reset player hit
    playersHit = {}
    -- iterate through all player props
    for id, bus in pairs(playerProps) do
        -- get player entity
        local player = PlayerManager:GetPlayerById(id)
        -- check for nil values
        if player == nil or player.soldier == nil then
            goto continue
        end
        -- get spatial entity
        local entity = SpatialEntity(bus.entities[1])
        -- when entity is nil disable prop for user
        if entity == nil then
            removePlayerProp(id)
            goto continue
        end
        -- entity must follow player soldier entity
        entity.transform = player.soldier.transform
        entity:FireEvent('Disable')
        entity:FireEvent('Enable')

        ::continue::
    end
end

-- do damage to prop
local function doPropDamage(playerID, position)
    debugMessage('doPropDamage ' .. playerID)
    -- Only apply damage once per tick.
    if playersHit[playerID] then
        return
    end

    playersHit[playerID] = true

    -- Spawn blood effect
    if bloodFx == nil then
        bloodFx = ResourceManager:SearchForDataContainer('FX/Impacts/Soldier/FX_Impact_Soldier_Body_S')
    end

    if bloodFx ~= nil then
        local transform = LinearTransform()
        transform.trans = position
        EffectManager:PlayEffect(bloodFx, transform, EffectParams(), false)
    end
    NetEvents:Send(GameMessage.C2S_PROP_DAMAGE, playerID)
end

-- clean up round
local function cleanupRound()
    debugMessage('cleanupRound')
    WebUI:ExecuteJS('setUserTeam(0);')
    for _, prop in pairs(playerProps) do
        for _, entity in pairs(prop.entities) do
            entity:Destroy()
        end
    end

    Camera:disable()

    playerProps = {}
    playerPropBps = {}
    soldierEntityInstanceId = nil
    propInstanceIds = {}
    bloodFx = nil
end

-- prop sync request from server
local function onPropSync(playerID, bpName, magnitude)
    debugMessage('[S2C_PROP_SYNC] for ' .. playerID .. ' with blueprint ' .. (bpName and bpName or "nil"))
    -- when prop is nil (no prop anymore, then delete user)
    if bpName == nil then
        removePlayerProp(playerID)
        -- reset camera distance
        Camera:setDistance(2.0)
        -- reset camera height
        Camera:setHeight(1.5)
    else
        changePlayerProp(playerID, bpName)
        -- set player camera distance to prop depending on prop size
        local distance = MathUtils:Lerp(1.0, 3.0, magnitude)
        if distance > 3.0 then
            distance = 3.0
        elseif distance < 1.0 then
            distance = 1.0
        end
        Camera:setDistance(distance)
    end
end

-- make player to prop
local function onPlayerSync(playerID, teamID)
    debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID)
    local player = PlayerManager:GetPlayerById(playerID)
    local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- check for local player and whether he is in the prop team
    if isLocalPlayer and isPropByTeamID(teamID) then
        debugMessage('[S2C_PLAYER_SYNC] local player ' .. playerID .. ' is a prop')
        WebUI:ExecuteJS('setUserTeam(2);')
        Camera:enable()
    end
end

-- on player respawn
local function onPlayerRespawn(player)
    if PlayerManager:GetLocalPlayer() == player then
        soldierEntityInstanceId = player.soldier.physicsEntityBase.instanceId
    end
end

-- on player killed
local function onPlayerKilled(soldier)
    if PlayerManager:GetLocalPlayer() == player then
        soldierEntityInstanceId = nil
    end
end

-- check whether an entity should collide with another entity
-- TODO maybe check with checkEntityForPlayerEntity
local function onEntityShouldCollideWith(hook, entityA, entityB)
    if not isProp(PlayerManager:GetLocalPlayer()) then
        return
    end

    if entityA.instanceId == soldierEntityInstanceId then
        for _, entityId in pairs(propInstanceIds) do
            if entityId == entityB.instanceId then
                hook:Return(false)
                return
            end
        end
    elseif entityB.instanceId == soldierEntityInstanceId then
        for _, entityId in pairs(propInstanceIds) do
            if entityId == entityA.instanceId then
                hook:Return(false)
                return
            end
        end
    end
end


local function onExtensionLoaded()
    local player = PlayerManager:GetLocalPlayer()

    if player ~= nil and player.soldier ~= nil then
        soldierEntityInstanceId = player.soldier.physicsEntityBase.instanceId
    end
end

-- hooking bullet collision
local function onBulletEntityCollision(hook, entity, hit, shooter)
    local localPlayer = PlayerManager:GetLocalPlayer()

    if shooter ~= localPlayer or hit.rigidBody == nil then
        return
    end

    for playerId, bus in pairs(playerProps) do
        if playerId ~= localPlayer.id then
            for _, prop in pairs(bus.entities) do
                if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                    doPropDamage(playerId, hit.position)
                    return
                end
            end
        end
    end
end

-- hooks and events
Hooks:Install('Entity:ShouldCollideWith', 100, onEntityShouldCollideWith)
Hooks:Install('BulletEntity:Collision', 100, onBulletEntityCollision)
Events:Subscribe('Engine:Update', onEngineUpdate)
Events:Subscribe('Level:Destroy', cleanupRound)
Events:Subscribe('Extension:Unloading', cleanupRound)
Events:Subscribe('Extension:Loaded', onExtensionLoaded)
Events:Subscribe('Player:Respawn', onPlayerRespawn)
Events:Subscribe('Player:Killed', onPlayerKilled)
NetEvents:Subscribe(GameMessage.S2C_PROP_SYNC, onPropSync)
NetEvents:Subscribe(GameMessage.S2C_PLAYER_SYNC, onPlayerSync)
