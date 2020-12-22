local Camera = require('Camera')

-- local variables
local playerPropBps = {}	-- player props blueprints
local playerProps = {}		-- player props blueprint names

local soldierEntityInstanceId = nil
local propInstanceIds = {}

local bloodFx = nil

local playersHit = {}

function createPlayerProp(player, bpName)
	debugMessage('createPlayerProp for ' .. player.name .. ' with blueprint ' .. bpName)
	local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- skip when we are this prop already
    if playerPropBps[player.id] == bpName then
        return
    end
    -- delete  old prop
	if playerProps[player.id] ~= nil then
		playerProps[player.id].entities[1]:Destroy()
		playerProps[player.id] = nil
    end
    -- get real blueprint
    local realBp = blueprint(bpName)
    debugMessage('Creating player prop with BP: ' .. realBp.name)

    -- create the new player prop
    local bus = EntityManager:CreateEntitiesFromblueprint(bpName, player.soldier.transform)
    -- check whether creation did work or not
    if bus == nil or #bus.entities == 0 then
        debugMessage('Failed to create prop entity for client.')
        return
    end

    -- cast and initialize the entity
	playerPropBps[player.id] = bpName

	if isLocalPlayer then
		propInstanceIds = {}
	end

    playerProps[player.id] = bus

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
	debugMessage('isPlayerProp')
	for _, bus in pairs(playerProps) do
		for _, entity in pairs(bus.entities) do
			if entity.instanceId == otherEntity.instanceId then
				return true
			end
		end
	end
	return false
end

Events:Subscribe('Engine:Update', function(delta, simDelta)
    for id, bus in pairs(playerProps) do
        local player = PlayerManager:GetPlayerById(id)

        if player == nil or player.soldier == nil then
            goto continue
        end

		local entity = SpatialEntity(bus.entities[1])

		entity.transform = player.soldier.transform
		entity:FireEvent('Disable')
		entity:FireEvent('Enable')

        ::continue::
    end
end)

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
local function changePlayerProp(playerID)
	debugMessage('changePlayerProp ' .. playerID)
	-- get player
    local player = PlayerManager:GetPlayerById(playerID)
    -- check whether player is available
	if player == nil or player.soldier == nil then
        return
    end
    -- load blueprint
    local blueprint = ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
    -- check whether blueprint exists
    if blueprint == nil then
        return
    end
    -- create player prop
    createPlayerProp(player, blueprint)
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
NetEvents:Subscribe(GameMessage.S2C_PROP_SYNC, function(playerID, bpName)
	debugMessage('[S2C_PROP_SYNC] for ' .. playerID .. ' with blueprint ' .. bpName)
	-- when prop is nil (no prop anymore, then delete user)
	if prop == nil then
		removePlayerProp(playerID)
	else
		changePlayerProp(playerID)
	end
end)

-- make player to prop
NetEvents:Subscribe(GameMessage.S2C_PLAYER_SYNC, function(playerID)
	debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID)
	local player = PlayerManager:GetPlayerById(playerID)
	local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
	-- check for local player and whether he is in the prop team
	-- TODO: shared checks for "isSeeker" and "isProp"
	if isLocalPlayer and player.teamId == TeamId.Team2 then
		debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID .. ' is prop')
		isProp = true
		Camera:enable()
	end
end)

Events:Subscribe('Player:Respawn', function(player)
	if PlayerManager:GetLocalPlayer() == player then
		soldierEntityInstanceId = player.soldier.physicsEntityBase.instanceId
	end
end)

Events:Subscribe('Player:Killed', function(soldier)
	if PlayerManager:GetLocalPlayer() == player then
		soldierEntityInstanceId = nil
	end
end)

-- TODO: Do we need to optimize this further?
Hooks:Install('Entity:ShouldCollideWith', 100, function(hook, entityA, entityB)
	if not isProp then
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
end)

Events:Subscribe('Level:Destroy', cleanupRound)
Events:Subscribe('Extension:Unloading', cleanupRound)

Events:Subscribe('Extension:Loaded', function()
	local player = PlayerManager:GetLocalPlayer()

	if player ~= nil and player.soldier ~= nil then
		soldierEntityInstanceId = player.soldier.physicsEntityBase.instanceId
	end
end)

Events:Subscribe('Engine:Update', function()
	playersHit = {}
end)

-- hooking bullet collision
Hooks:Install('BulletEntity:Collision', 100, function(hook, entity, hit, shooter)
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
end)
