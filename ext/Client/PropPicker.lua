-- PropPicker
-- client side UI logic for picking props

local maxDistance = 2.0

local function getMesh(entity)
    local data = entity.data
    -- reuturn when data is nil
    if data == nil then
        return nil
    end
    -- return mesh for StaticModelEntityData
    if data:Is('StaticModelEntityData') then
        data = StaticModelEntityData(data)
        return data.mesh
    end
    -- return mesh for RigidMeshEntityData
    if data:Is('RigidMeshEntityData') then
        data = RigidMeshEntityData(data)
        return data.mesh
    end
    -- return mesh for CompositeMeshEntityData
    if data:Is('CompositeMeshEntityData') then
        data = CompositeMeshEntityData(data)
        return data.mesh
    end
    -- return mesh for BreakableModelEntityData
    if data:Is('BreakableModelEntityData') then
        data = BreakableModelEntityData(data)
        return data.mesh
    end
    -- otherwise return nil
    return nil
end

local function intersect(from, to, aabb, transform, maxDist)
    local tmin = 0.0
    local tmax = maxDist

    local heading = to - from
    local direction = heading:Normalize()

    local delta = transform.trans - from

    local function checkAxis(axis, min, max)
        local e = axis:Dot(delta)
        local f = direction:Dot(axis)

        if math.abs(f) > math.epsilon then
            local t1 = (e + min) / f
            local t2 = (e + max) / f

            if t1 > t2 then
                local temp = t1
                t1 = t2
                t2 = temp
            end

            if t2 < tmax then
                tmax = t2
            end

            if t1 > tmin then
                tmin = t1
            end

            if tmax < tmin then
                return false
            end
        else
            if min - e > 0.0 or max - e < 0.0 then
                return false
            end
        end

        return true
    end

    if not checkAxis(transform.left, aabb.min.x, aabb.max.x) then
        return false
    end

    if not checkAxis(transform.up, aabb.min.y, aabb.max.y) then
        return false
    end

    if not checkAxis(transform.forward, aabb.min.z, aabb.max.z) then
        return false
    end

    return { tmin, tmax }
end

local function pickProp(drawOnly)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- only proceed when player and soldier exist and player is alive
    if localPlayer == nil or localPlayer.soldier == nil or not localPlayer.alive then
        return
    end
    -- get camera data
    local cameraTransform = getCameraTransform()
    -- check whether camera transform is available
    if cameraTransform == nil then
        return
    end
    -- prepare raycast data
    local cameraLookAtPos = getCameraLookAtPos()
    -- check whether camera look at pos is available
    if cameraLookAtPos == nil then
        return
    end
    local raycastTarget = cameraLookAtPos - cameraTransform.forward * maxDistance
    -- get entities
    local raycastEntities = RaycastManager:SpatialRaycast(cameraLookAtPos, raycastTarget, SpatialQueryFlags.AllGrids)
    -- set hit distance to maxDistance
    local raycastHitDistance = maxDistance
    -- get everything we hit
    local raycastHit = RaycastManager:Raycast(cameraLookAtPos, raycastTarget, RayCastFlags.CheckDetailMesh | RayCastFlags.DontCheckWater | RayCastFlags.DontCheckCharacter | RayCastFlags.DontCheckRagdoll)
    -- check whether we hit something
    if hit ~= nil then
        raycastHitDistance = cameraLookAtPos:Distance(hit.position)
        raycastHitDistance = raycastHitDistance + 0.020
    end
    local possibleEntities = {}
    -- iterate through all entities
    for i, entity in pairs(raycastEntities) do
        -- continue when it is no spatial entity
        if not entity:Is('SpatialEntity') then
            goto continue
        end
        -- continue when player prop
        if isPlayerProp(entity) then
            goto continue
        end
        -- get spatial entity from entity
        entity = SpatialEntity(entity)
        -- continue when entity is nil
        if entity == nil then
            goto continue
        end
        -- get mesh
        local mesh = getMesh(entity)
        -- continue when mesh is nil
        if mesh == nil then
            goto continue
        end
        -- continue when mesh is whitelisted
        local whitelistedMeshData = isMeshWhitelisted(mesh.name)
        if whitelistedMeshData == false then
            goto continue
        end
        -- get player mesh
        local playerMesh = getMesh(localPlayer.soldier)
         -- check whether this mesh is the current player mesh and ignore it
        if playerMesh ~= nil and mesh ~= nil and playerMesh == mesh then
            goto continue
        end
        -- do secondary raytracing
        local intersection = intersect(cameraLookAtPos, raycastTarget, entity.aabb, entity.aabbTransform, maxDistance)
        -- check whether we got an intersection
        if intersection then
            table.insert(possibleEntities, { mesh, entity, intersection })
        else
            table.insert(possibleEntities, { mesh, entity, {0.0, raycastHitDistance * 2.0} })
        end
        ::continue::
    end
    -- variable for our new prop
    local foundProp = nil
    -- find the prop closest to the player
    for _, entity in pairs(possibleEntities) do
        if entity[3][1] <= raycastHitDistance then
            if foundProp == nil then
                foundProp = entity
            elseif entity[3][1] < foundProp[3][1] then
                foundProp = entity
            end
        end
    end
    -- try to find a blueprint
    if foundProp ~= nil then
        if drawOnly then
            DebugRenderer:DrawOBB(foundProp[2].aabb, foundProp[2].aabbTransform, Vec4(0, 0, 1, 1))
            return
        else
            local bpName = string.lower(foundProp[1].name)
            -- get blueprint name
            bpName = string.gsub(bpName, '_mesh$', '')
            -- debug message
            -- return blueprint
            return ResourceManager:LookupDataContainer(ResourceCompartment.ResourceCompartment_Game, bpName)
        end
    end
    -- return nil otherwise
    return nil
end

local lastUpdate = 0.0
local function onClientUpdateInput(deltaTime)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- check whether player exist and is alive
    if localPlayer == nil or localPlayer.soldier == nil or not localPlayer.alive then
        return
    end
    -- check whether we are a prop
    if not isProp(localPlayer) then
        return
    end
    -- check whether we are in hiding or seeking state to be able to change props
    if currentState.roundState ~= GameState.hiding and
        currentState.roundState ~= GameState.seeking and
        currentState.roundState ~= GameState.revenge then
        return
    end
    -- when player press E to select a prop
    if InputManager:IsKeyDown(InputDeviceKeys.IDK_E) and lastUpdate >= 0.25 then
        -- reset last update
        lastUpdate = 0.0
        -- pick a prop
        local blueprint = pickProp(false)
        -- return when we did not found one
        if blueprint == nil then
            return
        end
        -- get blueprint name
        local bpName = Blueprint(blueprint).name
        -- debug message
        debugMessage('[Client:UpdateInput] for ' .. localPlayer.name .. ': has selected blueprint ' .. bpName)
        -- create prop
        createPlayerProp(localPlayer, bpName)
        -- send to server
        NetEvents:Send(GameMessage.C2S_PROP_CHANGE, bpName)
    end
    -- If the player is requesting a random prop
    if InputManager:IsKeyDown(InputDeviceKeys.IDK_T) and lastUpdate >= 1.0 then
        -- reset last update
        lastUpdate = 0.0
        -- get level name
        local level = SharedUtils:GetLevelName()
        -- get random prop
        math.randomseed(SharedUtils:GetTimeMS())
        local bpName = RandomPropsBlueprints[level][MathUtils:GetRandomInt(1, #RandomPropsBlueprints[level])]
        -- If we managed to find one, turn the player into it.
        if bpName ~= nil then
            -- First create it (so there's no visual delay) and then inform the server.
            debugMessage('[Client:UpdateInput] for ' .. localPlayer.name .. ': got random blueprint ' .. bpName)
            changePlayerProp(localPlayer.id, bpName)
            NetEvents:Send(GameMessage.C2S_PROP_CHANGE, bpName)
        end
    end
    -- add time to our last update
    lastUpdate = lastUpdate + deltaTime
end

-- on render UI
local function onUiDrawHud()
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- only when player is prop
    if isProp(localPlayer) then
        -- draw box around prop
        pickProp(true)
    end
end

-- events and hooks
Events:Subscribe('Client:UpdateInput', onClientUpdateInput)
Events:Subscribe('UI:DrawHud', onUiDrawHud)
