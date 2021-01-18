-- PlayerProp
-- client side UI logic for making players to props


-- local variables
local playerProps = {} -- player props blueprint names
local soldierEntityInstanceId = nil  -- soldier entity instance
local propInstanceIds = {} -- prop instances
local bloodFx = nil -- blood FX
local playersHit = {} -- whether a player got hit


-- check whether we are hitting the player physics entity
function isHittingPlayerPhysicsEntity(player, hit)
        local props = playerProps[player.id]
        if props == nil or props['playerbus'] == nil then
            return false
        end
        -- check player bus entities
        for _, prop in pairs(props['playerbus'].entities) do
            if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                return true
            end
        end
        -- check for additional meshes
        if props['additionalMeshes'] ~= nil then
            -- remove all additional meshes entities
            for _, meshdata in pairs(props['additionalMeshes']) do
                for _, prop in pairs(meshdata['bus'].entities) do
                    if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                        return true
                    end
                end
            end
        end
    return false
end

-- check if entity is player prop
function isPlayerProp(otherEntity)
    for _, props in pairs(playerProps) do
        for _, entity in pairs(props['playerbus'].entities) do
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
    local props = playerProps[playerID]
    -- when there is no entry for that player
    if props == nil or props['playerbus'] == nil then
        return
    end
    -- remove all playerbus entities
    for _, entity in pairs(props['playerbus'].entities) do
        entity:Destroy()
    end
    -- remove all additional meshes entities
    for _, meshdata in pairs(props['additionalMeshes']) do
        for _, entity in pairs(meshdata['bus'].entities) do
            entity:Destroy()
        end
    end
    playerProps[playerID] = nil
end

-- create entity from blueprint
function createEntityFromBlueprint(transform, bpName)
    -- load blueprint
    local blueprint = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
    -- check whether blueprint exists
    if blueprint == nil then
        debugMessage('createEntityFromBlueprint blueprint ' .. bpName .. ' is nil')
        return nil
    end
    -- create the new player prop
    local bus = EntityManager:CreateEntitiesFromBlueprint(blueprint, transform)
    -- check whether creation did work or not
    if bus == nil or #bus.entities == 0 then
        debugMessage('createEntityFromBlueprint: failed to create prop entity')
        return nil
    end
    return bus
end

-- create a player prop
function createPlayerProp(player, bpName)
    debugMessage('createPlayerProp for ' .. player.name)
    local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- check whether player already has a prop
    if playerProps[player.id] ~= nil then
        -- skip when we are this prop already
        if playerProps[player.id]['bpname'] == bpName then
            return
        end
        -- remove old prop
        removePlayerProp(player.id)
    end
    -- continue only when mesh is whitelisted
    local whitelistedMeshData = isMeshWhitelisted(bpName)
    if whitelistedMeshData == false then
        return
    end
    -- create player bus entity
    local trans = player.soldier.transform
    if whitelistedMeshData['position'] ~= nil then
        trans.trans = trans.trans + whitelistedMeshData['position']
    end
    local playerbus = createEntityFromBlueprint(trans, bpName)
    -- check whether we got a playerbus
    if playerbus == nil then
        return
    end
    -- create additional props for the player when necessary
    local additionalMeshes = {}
    if whitelistedMeshData['additionalMeshes'] ~= nil then
        for mesh, options in pairs(whitelistedMeshData['additionalMeshes']) do
            debugMessage('found additional mesh ' .. mesh)
            local trans = player.soldier.transform
            if options['position'] ~= nil then
                trans.trans = trans.trans + options['position']
            end
            local tmpBus = createEntityFromBlueprint(trans, mesh)
            if tmpBus ~= nil then
                debugMessage('add to list of meshes')
                additionalMeshes[mesh] = {
                    ['bus'] = tmpBus,
                    ['options'] = options
                }
            end
        end
    end
    -- reset prop instance IDs when local player
    if isLocalPlayer then
        propInstanceIds = {}
    end
    -- create playerprop array
    playerProps[player.id] = {
        ['options'] = whitelistedMeshData,
        ['bpname'] = bpName,
        ['playerbus'] = playerbus,
        ['additionalMeshes'] = additionalMeshes
    }
    -- create temporary table with all bus entities (playerbus and additional meshes)
    local tmpBus = {playerbus}
    for _, mesh in pairs(additionalMeshes) do
        table.insert(tmpBus, mesh['bus'])
    end
    -- iterate through all available entities
    for _, bus in pairs(tmpBus) do
        for _, entity in pairs(bus.entities) do
            -- init entity
            entity:Init(Realm.Realm_Client, true)
            -- check whether entity is a physics entity
            if entity:Is('ClientPhysicsEntity') then
                -- when it is the local player add the instance ID to our instance IDs (for player damage)
                if isLocalPlayer then
                    local tmpPhysicsEntity = PhysicsEntity(entity)
                    if tmpPhysicsEntity ~= nil and tmpPhysicsEntity.physicsEntityBase ~= nil then
                        table.insert(propInstanceIds, tmpPhysicsEntity.physicsEntityBase.instanceId)
                    end
                end
                -- disable damage callback for entity (aka no [visible] damage at all)
                PhysicsEntity(entity):RegisterDamageCallback(player.id, function() return false end)
            end
        end
    end
end

-- player change prop
function changePlayerProp(playerID, bpName)
    debugMessage('changePlayerProp ' .. playerID)
    -- get player
    local player = PlayerManager:GetPlayerById(playerID)
    -- check whether player is available
    if player == nil or player.soldier == nil then
        debugMessage('changePlayerProp player or soldier nil')
        return
    end
    -- create player prop
    createPlayerProp(player, bpName)
end

-- on engine update -> make props follow player
local function onEngineUpdate(delta, simDelta)
    -- reset player hit
    playersHit = {}
    -- iterate through all player props
    for id, props in pairs(playerProps) do
        -- get player entity
        local player = PlayerManager:GetPlayerById(id)
        -- check for nil values
        if player == nil or player.soldier == nil then
            goto continue
        end
        -- get spatial entity
        local entity = SpatialEntity(props['playerbus'].entities[1])
        -- when entity is nil disable prop for user
        if entity == nil then
            removePlayerProp(id)
            goto continue
        end
        -- entity must follow player soldier entity
        local trans = player.soldier.transform
        if props['options'] ~= nil and props['options']['position'] ~= nil then
            trans.trans = trans.trans + props['options']['position']
        end
        entity.transform = trans
        entity:FireEvent('Disable')
        entity:FireEvent('Enable')

        -- additional meshes must follow player soldier entity
        for _, meshdata in pairs(props['additionalMeshes']) do
            -- get spatial entity
            local entity = SpatialEntity(meshdata['bus'].entities[1])
            local trans = player.soldier.transform
            if meshdata['options'] ~= nil and meshdata['options']['position'] ~= nil then
                trans.trans = trans.trans + meshdata['options']['position']
            end
            entity.transform = trans
            entity:FireEvent('Disable')
            entity:FireEvent('Enable')
        end

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
    if playerProps ~= nil then
        for _, props in pairs(playerProps) do
            if props ~= nil then
                -- when we got a player prop delete all entities
                if props['playerbus'] ~= nil then
                    for _, entity in pairs(props['playerbus'].entities) do
                        entity:Destroy()
                    end
                end
                -- when we got additional meshes delete all entities
                if props['additionalMeshes'] ~= nil then
                    -- remove all additional meshes entities
                    for _, meshdata in pairs(props['additionalMeshes']) do
                        for _, entity in pairs(meshdata['bus'].entities) do
                            entity:Destroy()
                        end
                    end
                end
            end
        end
    end
    -- disable ingame camera
    disableIngameCamera()
    playerProps = {}
    soldierEntityInstanceId = nil
    propInstanceIds = {}
    bloodFx = nil
end

-- prop sync request from server
local function onPropSync(playerID, bpName, magnitude)
    debugMessage('[S2C_PROP_SYNC] for ' .. playerID .. ' with blueprint ' .. (bpName and bpName or "nil"))
    local player = PlayerManager:GetPlayerById(playerID)
    local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- when prop is nil (no prop anymore, then delete user)
    if bpName == nil then
        removePlayerProp(playerID)
        if isLocalPlayer then
            -- reset camera distance
            setCameraDistance(2.0)
            -- reset camera height
            setCameraHeight(1.5)
        end
    else
        changePlayerProp(playerID, bpName)
        -- set player camera distance to prop depending on prop size
        if isLocalPlayer then
            local distance = MathUtils:Lerp(1.0, 3.0, magnitude)
            if distance > 3.0 then
                distance = 3.0
            elseif distance < 1.0 then
                distance = 1.0
            end
            setCameraDistance(distance)
        end
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
        -- enable ingame camera
        enableIngameCamera()
        -- spectate yourself in third person
        spectatePlayer(player)
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
    if localPlayer == nil or shooter ~= localPlayer or hit.rigidBody == nil then
        return
    end

    for playerId, props in pairs(playerProps) do
        if playerId ~= localPlayer.id then
            if props ~= nil then
                if props['playerbus'] ~= nil then
                    for _, prop in pairs(props['playerbus'].entities) do
                        if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                            doPropDamage(playerId, hit.position)
                            return
                        end
                    end
                    -- when we got additional meshes delete all entities
                    if props['additionalMeshes'] ~= nil then
                        -- remove all additional meshes entities
                        for _, meshdata in pairs(props['additionalMeshes']) do
                            for _, prop in pairs(meshdata['bus'].entities) do
                                if prop:Is('ClientPhysicsEntity') and PhysicsEntity(prop).physicsEntityBase.instanceId == hit.rigidBody.instanceId then
                                    doPropDamage(playerId, hit.position)
                                    return
                                end
                            end
                        end
                    end
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
