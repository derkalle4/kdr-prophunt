-- IngameCamera
-- spectator and third person view at a glance


-- local variables
local CameraTypes = {
    firstPerson = 0,
    thirdPerson = 1,
    autoRoute = 2,
    freeCam = 3
}
local cameraType = CameraTypes.autoRoute
local cameraFov = 100
local isActive = false
local spectatedPlayerID = nil
local currentAutomaticRoute = {}
local cameraHeight = 1.5
local cameraDistance = 2.0
local minCameraDistance = 1.0
local maxCameraDistance = 8.0
local cameraYaw = 0.0
local cameraPitch = 0.0
local cameraForward = 0.0
local cameraSidewards = 0.0
local cameraUpward = 0.0
local cameraLookAtPos = nil
local isLocked = false
local canAltPressAgain = true
local cameraEntity = nil
local maxPitch = 85.0 * (math.pi / 180.0)
local minPitch = -70.0 * (math.pi / 180.0)
local twoPi = math.pi * 2
local rotateMultiplierBase = 1.916686
local rotateMultipliers = {
    [CameraTypes.freeCam] = rotateMultiplierBase * 0.25,
    [CameraTypes.thirdPerson] = rotateMultiplierBase,
    [CameraTypes.firstPerson] = rotateMultiplierBase
}
local freelookMultiplier = 0.6
local keyConfig = {
    nextPlayer = InputDeviceKeys.IDK_1,
    prevPlayer = InputDeviceKeys.IDK_2,
    freecam = InputDeviceKeys.IDK_3,
    autocam = InputDeviceKeys.IDK_4,
    freelook = InputDeviceKeys.IDK_LeftAlt,
    freecamUpward = InputDeviceKeys.IDK_Space,
    freecamDownward = InputDeviceKeys.IDK_LeftCtrl
}

local function resetIngameCamera()
    debugMessage('IngameCamera:resetIngameCamera')
    cameraFov = 100
    spectatedPlayerID = nil
    currentAutomaticRoute = {}
    cameraHeight = 1.5
    cameraDistance = 2.0
    minCameraDistance = 1.0
    maxCameraDistance = 8.0
    cameraYaw = 0.0
    cameraPitch = 0.0
    cameraForward = 0.0
    cameraSidewards = 0.0
    cameraUpward = 0.0
    cameraLookAtPos = nil
    isLocked = false
    canAltPressAgain = true
end

local function createCamera()
    debugMessage('IngameCamera:createCamera')
    if cameraEntity ~= nil then
        return
    end
    if cameraEntityData == nil then
        cameraEntityData = CameraEntityData()
        cameraEntityData.fov = cameraFov
        cameraEntityData.enabled = true
        cameraEntityData.priority = 99999
        cameraEntityData.nameId = 'PlayerCam'
        cameraEntityData.transform = LinearTransform()
    end
    cameraEntity = EntityManager:CreateEntity(cameraEntityData, cameraEntityData.transform)
    cameraEntity:Init(Realm.Realm_Client, true)
end

local function destroyCamera()
    debugMessage('IngameCamera:destroyCamera')
    if cameraEntity ~= nil then
        cameraEntity:Destroy()
        cameraEntity = nil
    end
    cameraEntityData = nil
    isActive = false
    cameraType = CameraTypes.autoRoute
end

local function enable()
    debugMessage('IngameCamera:enable')
    isActive = true
    if cameraEntity == nil or cameraEntityData == nil then
        createCamera()
    end
    cameraEntity:FireEvent('TakeControl')
end

local function disable()
    debugMessage('IngameCamera:disable')
    -- release control from camera to push back to user camera
    if cameraEntity ~= nil then
        cameraEntity:FireEvent('ReleaseControl')
    end
    isActive = false
    -- reset camera settings to default
    resetIngameCamera()
end

local function _findFirstPlayerToSpectate()
    debugMessage('IngameCamera:_findFirstPlayerToSpectate')
    local playerToSpectate = nil
    local players = PlayerManager:GetPlayers()
    local localPlayer = PlayerManager:GetLocalPlayer()

    for _, player in pairs(players) do
        -- We don't want to spectate the local player.
        if player == localPlayer then
            goto continue_enable
        end
        -- We don't want to spectate players who are dead.
        if player.soldier == nil or not player.alive then
            goto continue_enable
        end
        -- Otherwise we're good to spectate this player.
        playerToSpectate = player
        break

        ::continue_enable::
    end

    return playerToSpectate
end

-- disable ingame camera
function disableIngameCamera()
    debugMessage('IngameCamera:disableIngameCamera')
    disable()
end

-- enable ingame camera
function enableIngameCamera()
    debugMessage('IngameCamera:enableIngameCamera')
    enable()
    switchToAutoCam()
end

-- set distance to prop
function setCameraDistance(distance)
    debugMessage('IngameCamera:setCameraDistance')
    cameraDistance = distance
end

-- set the height of the camera
function setCameraHeight(height)
    debugMessage('IngameCamera:setCameraHeight')
    cameraHeight = height
end

-- disable or enable freelooking
function setCameraFreelooking(bool)
    debugMessage('IngameCamera:setCameraFreelooking')
    isLocked = bool
    -- show UI alt state as red when freelooking got disabled
    if not isLocked then
        -- highlight alt keys on UI
        WebUI:ExecuteJS('highlightKey("alt","green",false);')
        WebUI:ExecuteJS('highlightKey("alt","red",true);')
        WebUI:ExecuteJS('highlightKey("alt2","green",false);')
        WebUI:ExecuteJS('highlightKey("alt2","red",true);')
    end
end

-- ggets the position of what the camera is currently looking at
function getCameraLookAtPos()
    return cameraLookAtPos
end

function getCameraTransform()
    if not isActive or cameraEntityData == nil then
        return nil
    end
    -- return the cloned camera transform
    return cameraEntityData.transform:Clone()
end

-- switch to Auto Cam
function switchToAutoCam()
    debugMessage('IngameCamera:switchToAutoCam')
    -- do not continue when disabled
    if not isActive then
        return
    end
    -- reset all predefined values
    resetIngameCamera()
    -- get current local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do not switch when player does not exist or is alive
    if localPlayer == nil or localPlayer.alive then
        return
    end
    -- change camera type to auto cam
    cameraType = CameraTypes.autoRoute
end

-- switch to Auto Cam
function switchToFreeCam()
    debugMessage('IngameCamera:switchToFreeCam')
    -- do not continue when disabled
    if not isActive then
        return
    end
    -- reset all predefined values
    resetIngameCamera()
    -- get current local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do not switch when player does not exist or is alive
    if localPlayer == nil or localPlayer.alive then
        return
    end
    -- change camera type to auto cam
    cameraType = CameraTypes.freeCam
    -- disable mouse
    WebUI:DisableMouse()
    -- remove spectator message
    WebUI:ExecuteJS('setSpectatorMessage("");')
end

function spectatePlayer(player)
    debugMessage('IngameCamera:spectatePlayer')
    -- do not continue when disabled
    if not isActive then
        return
    end
    -- when player is nil switch to auto cam
    if player == nil then
        switchToAutoCam()
        return
    end
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- When local player is still alive the player can only spectate himself
    if localPlayer.alive and localPlayer ~= player then
        return
    end
    -- only show ui message when we are not "spectating" our self
    if localPlayer ~= player then
        WebUI:ExecuteJS('setSpectatorMessage("' .. player.name .. '",' .. player.teamId .. ');')
    end
    -- change camera type to spectator cam
    cameraType = CameraTypes.thirdPerson
    -- set player id for spectated player
    spectatedPlayerID = player.id
    -- disable mouse input when spectating someone
    WebUI:DisableMouse()
end

-- find next player to spectate
local function spectateNextPlayer()
    debugMessage('IngameCamera:spectateNextPlayer')
    -- do not continue when disabled
    if not isActive then
        return
    end
    -- If we are not spectating anyone just find the first player to spectate.
    if spectatedPlayerID == nil then
        local playerToSpectate = _findFirstPlayerToSpectate()
        -- switch to player when we got one or switch to auto cam otherwise
        if playerToSpectate ~= nil then
            spectatePlayer(playerToSpectate)
        else
            switchToAutoCam()
        end
        return
    end
    -- declare current index
    local currentIndex = 0
    -- get current players
    local players = PlayerManager:GetPlayers()
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- when localplayer is nil switch to automatic cam
    if localPlayer == nil then
        switchToAutoCam()
        return
    end
    -- find index of current player
    for i, player in pairs(players) do
        if player.id == spectatedPlayerID then
            currentIndex = i
            break
        end
    end
    -- increment of index to get next player
    currentIndex = currentIndex + 1
    -- when currentIndex is higher then amount of players
    if currentIndex > #players then
        -- set index to 1
        currentIndex = 1
    end
    -- get the next player that we can spectate
    local nextPlayer = nil
    -- iterate over all players
    for i = 1, #players do
        -- set new player index
        local playerIndex = (i - 1) + currentIndex
        -- when index is bigger then amount of players
        if playerIndex > #players then
            -- set index to a lower value
            playerIndex = playerIndex - #players
        end
        -- get the player
        local player = players[playerIndex]
        -- when player is not nil, got a soldier, is not local player and alive
        -- and player team id is localplayer team id (or player is spectator)
        if player ~= nil and player.soldier ~= nil and player ~= localPlayer and player.alive and (player.teamId == localPlayer.teamId or isSpectator(localPlayer)) then
            nextPlayer = player
            break
        end
    end
    -- check whether we found a player to spectate
    if nextPlayer == nil then
        -- switch to autocam otherwise
        switchToAutoCam()
    else
        spectatePlayer(nextPlayer)
    end
end

-- find previous player to spectate
local function spectatePreviousPlayer()
    debugMessage('IngameCamera:spectatePreviousPlayer')
    -- do not continue when disabled
    if not isActive then
        return
    end
    -- If we are not spectating anyone just find the first player to spectate.
    if spectatedPlayerID == nil then
        local playerToSpectate = _findFirstPlayerToSpectate()
        -- switch to player when we got one or switch to auto cam otherwise
        if playerToSpectate ~= nil then
            spectatePlayer(playerToSpectate)
        else
            switchToAutoCam()
        end
        return
    end
    -- declare current index
    local currentIndex = 0
    -- get current players
    local players = PlayerManager:GetPlayers()
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- when localplayer is nil switch to automatic cam
    if localPlayer == nil then
        switchToAutoCam()
        return
    end
    -- find index of current player
    for i, player in pairs(players) do
        if player.id == spectatedPlayerID then
            currentIndex = i
            break
        end
    end
    -- increment of index to get next player
    currentIndex = currentIndex - 1
    -- when currentIndex is higher then amount of players
    if currentIndex <= 0 then
        -- set index to to amount of players
        currentIndex = #players
    end
    -- get the next player that we can spectate
    local nextPlayer = nil
    -- iterate over all players
    for i = #players, 1, -1 do
        -- set new player index
        local playerIndex = (i - (#players - currentIndex))
        -- when index is smaller then zero
        if playerIndex <= 0 then
            -- set playerIndex to next possible player index
            playerIndex = playerIndex + #players
        end
        -- get the player
        local player = players[playerIndex]
        -- when player is not nil, got a soldier, is not local player and alive
        -- and player team id is localplayer team id (or player is spectator)
        if player ~= nil and player.soldier ~= nil and player ~= localPlayer and player.alive and (player.teamId == localPlayer.teamId or isSpectator(localPlayer)) then
            nextPlayer = player
            break
        end
    end
    -- check whether we found a player to spectate
    if nextPlayer == nil then
        -- switch to autocam otherwise
        switchToAutoCam()
    else
        spectatePlayer(nextPlayer)
    end
end

-- check input of player before we proceed
local function onInputPreUpdate(hook, cache, deltaTime)
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end

    -- get the local player
    local player = PlayerManager:GetLocalPlayer()

    -- do nothing when our player does not exist
    if player == nil then
        return
    end

    -- if we are locking the player remove the mouse input
    if isLocked and cameraType == CameraTypes.thirdPerson then
        player:EnableInput(EntryInputActionEnum.EIAYaw, false)
        player:EnableInput(EntryInputActionEnum.EIAPitch, false)
    else -- reenable the mouse input
        player:EnableInput(EntryInputActionEnum.EIAYaw, true)
        player:EnableInput(EntryInputActionEnum.EIAPitch, true)
    end

    -- update camera distance
    if cameraType == CameraTypes.freeCam or cameraType == CameraTypes.thirdPerson then
        -- local temp = {["jump"] = InputConceptIdentifiers.ConceptJump, ["coh"] = InputConceptIdentifiers.ConceptCrouchOnHold}
        -- for k, v in pairs(temp) do
        --     if cache[v] ~= 0.0 then
        --         print(k .. cache[v])
        --     end
        -- end

        local newCameraDistance = cameraDistance - cache[InputConceptIdentifiers.ConceptZoom]
        if newCameraDistance <= maxCameraDistance and newCameraDistance >= minCameraDistance then
            cameraDistance = newCameraDistance
        end
    end

    -- update the pitch manually when camera position is locked
    if isLocked or cameraType == CameraTypes.freeCam then
        -- 1.916686 is a magic number we use to somewhat match the rotation speed
        -- with the actual soldier rotation speed.

        -- Get the yaw and pitch movement values and multiply by it to figure out
        -- how much to rotate the camera.
        local rotateYaw = cache[InputConceptIdentifiers.ConceptYaw] * rotateMultipliers[cameraType]
        local rotatePitch = cache[InputConceptIdentifiers.ConceptPitch] * rotateMultipliers[cameraType]

        -- And then just rotate!
        cameraYaw = cameraYaw + rotateYaw
        cameraPitch = cameraPitch + rotatePitch
        -- Limit the pitch to the actual min / max viewing angles.
        if cameraPitch > maxPitch then
            cameraPitch = maxPitch
        end
        if cameraPitch < minPitch then
            cameraPitch = minPitch
        end
        -- Limit the yaw to [0, pi * 2].
        while cameraYaw < 0 do
            cameraYaw = twoPi + cameraYaw
        end
        while cameraYaw > twoPi do
            cameraYaw = cameraYaw - twoPi
        end
        -- get the forward / sideward movement
        local moveForward = cache[InputConceptIdentifiers.ConceptMoveForward]
        local moveBackward = cache[InputConceptIdentifiers.ConceptMoveBackward]
        local moveLeft = cache[InputConceptIdentifiers.ConceptMoveLeft]
        local moveRight = cache[InputConceptIdentifiers.ConceptMoveRight]
        if moveForward > 0 then
            cameraForward = moveForward * (freelookMultiplier / 4)
        else
            cameraForward = -1 * moveBackward * (freelookMultiplier / 4)
        end
        if moveRight > 0 then
            cameraSidewards = -1 * moveRight * (freelookMultiplier / 4)
        else
            cameraSidewards = moveLeft * (freelookMultiplier / 4)
        end
    end
end

-- move camera entity on each engine tick
local function onEngineUpdate(deltaTime)
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end
    -- get the local player
    local player = PlayerManager:GetLocalPlayer()
    -- do not proceed when player is nil
    if player == nil then
        return
    end
    -- set spectator to nil
    local specPlayer = nil
    -- set player to external player when we have a player id which is not our player
    if spectatedPlayerID ~= nil  and spectatedPlayerID ~= player.id then
        -- get the player we want to spectate
        specPlayer = PlayerManager:GetPlayerById(spectatedPlayerID)
        -- do nothing when user id does not exist
        if specPlayer == nil or specPlayer.soldier == nil then
            -- reset spectator player id
            spectatedPlayerID = nil
            return
        end
    end
    -- if the user has chosen the third person camera
    if cameraType == CameraTypes.thirdPerson then
        -- check for nil on our entities and do not proceed
        if (player.soldier == nil and specPlayer == nil) or player.input == nil then
            return
        end
        -- when the camera is not locked (aka we are following our player)
        if not isLocked then
            -- when we are following our spectator player
            if specPlayer ~= nil then
                -- set the camera yaw to the spectator camera yaw
                cameraYaw = -math.atan(specPlayer.soldier.worldTransform.forward.x, specPlayer.soldier.worldTransform.forward.z)
                cameraPitch = 0.0
            else
                -- set to our players yaw when we are following our player
                cameraYaw = player.input.authoritativeAimingYaw
                cameraPitch = player.input.authoritativeAimingPitch
            end
        end
        -- set the spectator to our player for the next operations
        if specPlayer ~= nil then
            player = specPlayer
        end
        local yaw = cameraYaw
        local pitch = cameraPitch
        -- Fix angles so we're looking at the right thing.
        yaw = yaw - math.pi / 2
        pitch = pitch + math.pi / 2
        -- Set the look at position above the soldier's feet.
        cameraLookAtPos = player.soldier.transform.trans:Clone()
        cameraLookAtPos.y = cameraLookAtPos.y + cameraHeight
        -- Calculate where our camera has to be base on the angles.
        local cosfi = math.cos(yaw)
        local sinfi = math.sin(yaw)
        local costheta = math.cos(pitch)
        local sintheta = math.sin(pitch)
        -- calculate position of our camera
        local cx = cameraLookAtPos.x + (cameraDistance * sintheta * cosfi)
        local cy = cameraLookAtPos.y + (cameraDistance * costheta)
        local cz = cameraLookAtPos.z + (cameraDistance * sintheta * sinfi)
        -- set camera location
        local cameraLocation = Vec3(cx, cy, cz)
        -- raycast anything between the player and our camera
        local hit = RaycastManager:Raycast(cameraLookAtPos, cameraLocation, RayCastFlags.DontCheckWater | RayCastFlags.DontCheckCharacter | RayCastFlags.DontCheckRagdoll)
        -- when the first hit is the players physics entity check for a second hit from the players physics entity to the camera, then for a third, fourth etc.
        -- (trying to find the first hit of the ray which is not a hit on the players physics entity)
        if hit ~= nil and isHittingPlayerPhysicsEntity(player, hit) then
            for i=1,5 do
                hit = RaycastManager:Raycast(hit.position:MoveTowards(cameraLocation, player.input.deltaTime * 1), cameraLocation, RayCastFlags.DontCheckWater | RayCastFlags.DontCheckCharacter | RayCastFlags.DontCheckRagdoll)
                -- if no hit is found on the ray or an object was found which is not the player, we don't need to search further and have our camera position
                if hit == nil or not isHittingPlayerPhysicsEntity(player, hit) then
                    break
                end
            end
        end
        -- if something does hit change the camera perspective to avoid geometry
        if hit ~= nil then
            cameraLocation = hit.position
            -- Move it just a bit forward so we're not actually inside geometry.
            local heading = cameraLookAtPos - cameraLocation
            local direction = heading:Normalize()
            -- set our new camera location and move it a little bit so that we are not stucking inside that prop
            cameraLocation = cameraLocation + (direction * 0.1)
        end
        -- finally calculate our new look at position
        cameraEntityData.transform:LookAtTransform(cameraLocation, cameraLookAtPos)
        -- Flip the camera angles so we're looking at the player.
        cameraEntityData.transform.left = cameraEntityData.transform.left * -1
        cameraEntityData.transform.forward = cameraEntityData.transform.forward * -1
    elseif cameraType == CameraTypes.autoRoute then
        -- automatic route selection for autoroute
        local level = SharedUtils:GetLevelName()
        local tmpSpectatorRoutes = IngameSpectatorRoutes[level]
        if level ~= nil and tmpSpectatorRoutes ~= nil then
            -- select new automatic route when round is complete or not started yet
            if #currentAutomaticRoute == 0 or Vec3(currentAutomaticRoute[2][1], currentAutomaticRoute[2][2], currentAutomaticRoute[2][3]):Distance(cameraEntityData.transform.trans) <= 3.0  then
                debugMessage('IngameCamera:select new automatic route')
                -- get new automatic route
                math.randomseed(SharedUtils:GetTimeMS())
                local randomNumber = MathUtils:GetRandomInt(1, #tmpSpectatorRoutes)
                -- set current automatic route
                currentAutomaticRoute = tmpSpectatorRoutes[randomNumber]
                -- set starting point
                local startpoint = currentAutomaticRoute[1]
                -- set view point
                local viewpoint = currentAutomaticRoute[3]
                -- set name
                local name = currentAutomaticRoute[5]
                -- show message for spectator
                WebUI:ExecuteJS('setSpectatorMessage("' .. name .. '");')
                -- set start point of new automatic route
                cameraEntityData.transform.trans = Vec3(
                    startpoint[1],
                    startpoint[2],
                    startpoint[3]
                )
                -- set view direction of new automatic route
                cameraEntityData.transform:LookAtTransform(
                    Vec3(
                        startpoint[1],
                        startpoint[2],
                        startpoint[3]
                    ),
                    Vec3(
                        viewpoint[1],
                        viewpoint[2],
                        viewpoint[3]
                    )
                )
            elseif #currentAutomaticRoute > 2 then -- when we have a automatic route selected already
                -- move Vec3 position forward to goal
                local endpoint = currentAutomaticRoute[2]
                local tempo = currentAutomaticRoute[4]
                -- move camera entity
                cameraEntityData.transform.trans = Vec3(cameraEntityData.transform.trans):MoveTowards(
                    Vec3(
                        endpoint[1],
                        endpoint[2],
                        endpoint[3]
                    )
                , tempo)
            end
        end
    elseif cameraType == CameraTypes.freeCam then
        -- set initial camera position when nil
        if cameraLookAtPos == nil then
            -- when camera entity data is nil spawn at a default position
            if cameraEntityData.transform.trans == nil then
                cameraLookAtPos = Vec3(30,30,30)
            else
                -- set current camera position to current camera entity data
                cameraLookAtPos = cameraEntityData.transform.trans:Clone()
            end
        end

        local yaw = cameraYaw
        local pitch = cameraPitch
        yaw = yaw - math.pi / 2
        pitch = pitch + math.pi / 2

        local cosfi = math.cos(yaw)
        local sinfi = math.sin(yaw)
        local costheta = math.cos(pitch)
        local sintheta = math.sin(pitch)
        local forwardDirection = Vec3(sintheta * cosfi, costheta, sintheta * sinfi) * -1
        forwardDirection = forwardDirection:Normalize()

        if cameraForward ~= 0.0 then
            cameraLookAtPos = cameraLookAtPos + forwardDirection * cameraForward
        end

        if cameraSidewards ~= 0.0 then
            local rightDirection = forwardDirection:Cross(Vec3.up)
            cameraLookAtPos = cameraLookAtPos - rightDirection * cameraSidewards
        end

        if cameraUpward ~= 0.0 then
            local rightDirection = forwardDirection:Cross(Vec3.up)
            local upDirection = forwardDirection:Cross(rightDirection)
            cameraLookAtPos = cameraLookAtPos - upDirection * cameraUpward
        end

        local cameraLocation = cameraLookAtPos - forwardDirection

        -- cameraEntityData calculate our new look at position
        cameraEntityData.transform:LookAtTransform(cameraLocation, cameraLookAtPos)
        cameraEntityData.transform.left = cameraEntityData.transform.left * -1
        cameraEntityData.transform.forward = cameraEntityData.transform.forward * -1
    end
end

local function onPlayerUpdateInput(player, deltaTime)
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end
    -- get the local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- only proceed when we got the player and it is the local player
    if player == nil or localPlayer ~= player then
        return
    end
    -- when freelook key went down
    if cameraType == CameraTypes.thirdPerson and InputManager:WentKeyDown(keyConfig.freelook) then
        -- if it is currently not locked and we are in hiding or seeking state
        if not isLocked and player.input ~= nil and
            (currentState.roundState == GameState.hiding or currentState.roundState == GameState.seeking) then
            -- lock it
            isLocked = true
            -- set view
            cameraYaw = player.input.authoritativeAimingYaw
            cameraPitch = player.input.authoritativeAimingPitch
            -- highlight ALT key on UI
            WebUI:ExecuteJS('highlightKey("alt","green",true);')
            WebUI:ExecuteJS('highlightKey("alt2","green",true);')
         else
            -- If we were previously locked then unlock.
            isLocked = false
            -- unhighlight key on UI
            WebUI:ExecuteJS('highlightKey("alt","green",false);')
            WebUI:ExecuteJS('highlightKey("alt2","green",false);')
        end
    end
    -- freecam upward/downward movement
    if cameraType == CameraTypes.freeCam then
        if InputManager:IsKeyDown(keyConfig.freecamUpward) then
            cameraUpward = freelookMultiplier / 4
        elseif InputManager:IsKeyDown(keyConfig.freecamDownward) then
            cameraUpward = -1 * (freelookMultiplier / 4)
        else
            cameraUpward = 0.0
        end
    end
    -- keys for spectators
    if not player.alive then
        -- spectate next player
        if InputManager:WentKeyDown(keyConfig.nextPlayer) then
            spectateNextPlayer()
        -- spectate previous player
        elseif InputManager:WentKeyDown(keyConfig.prevPlayer) then
            spectatePreviousPlayer()
        -- swap freecam
        elseif InputManager:WentKeyDown(keyConfig.freecam) then
            -- swap to free view camera
            switchToFreeCam()
        -- swap autocam
        elseif InputManager:WentKeyDown(keyConfig.autocam) then
            -- swap to automatic camera
            switchToAutoCam()
        end
    end
end

-- when a player does respawn
local function onPlayerRespawn(player)
    debugMessage('IngameCamera:onPlayerRespawn')
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end
    -- get the local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- only proceed when we got the player object
    if localPlayer == nil then
        return
    end
    -- disable camera when our player respawns
    if localPlayer == player then
        disable()
        return
    end
end

-- when a player gets Killed
local function onPlayerKilled(player)
    debugMessage('IngameCamera:onPlayerKilled')
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end
    -- spectate next living player
    if player.id == spectatedPlayerID then
        spectateNextPlayer()
    end
end

-- when a player gets deleted
local function onPlayerDeleted(player)
    debugMessage('IngameCamera:onPlayerDeleted')
    -- do not proceed when the camera is not active
    if not isActive then
        return
    end
    -- spectate next living player
    if player.id == spectatedPlayerID then
        spectateNextPlayer()
    end
end

-- when extension is unloading
local function onExtensionUnloading()
    disable()
    resetIngameCamera()
    destroyCamera()
end

-- hooks and events
Hooks:Install('Input:PreUpdate', 100, onInputPreUpdate)
Events:Subscribe('Engine:Update', onEngineUpdate)
Events:Subscribe('Player:UpdateInput', onPlayerUpdateInput)
Events:Subscribe('Extension:Unloading', onExtensionUnloading)
Events:Subscribe('Level:Destroy', onExtensionUnloading)
Events:Subscribe('Player:Respawn', onPlayerRespawn)
Events:Subscribe('Player:Killed', onPlayerKilled)
Events:Subscribe('Player:Deleted', onPlayerDeleted)