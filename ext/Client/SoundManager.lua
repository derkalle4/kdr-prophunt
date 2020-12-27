-- SoundManager
-- does manage sounds that players can make to reveal their position <3


preparedSoundList = {} -- list of prepared sounds for further use
local playerSounds = {} -- current player sound props
local cooldownTime = 3.0 -- cooldown before next use
local cooldown = 0.0 -- actual cooldown time left


-- spawn sound on entity
local function spawnSound(player, sound)
    debugMessage('spawn sound ' .. sound .. ' for player ' .. player.name)
    -- do not continue when player soldier does not exist
    if player.soldier == nil then
        debugMessage('player not spawned')
        return
    end
    -- do not continue when sound does not exist
    if preparedSoundList[sound] == nil then
        debugMessage('sound does not exist')
        return
    end
    -- delete  old prop
    if playerSounds[player.id] ~= nil then
        playerSounds[player.id]:Destroy()
        playerSounds[player.id] = nil
    end
    -- create entity position
    local entityPos = LinearTransform()
    -- set entity position to player position
    entityPos.trans = player.soldier.transform.trans:Clone()
    -- set entity sound a little bit higher
    entityPos.trans.y = entityPos.trans.y + 1.5
    -- create sound entity data
    local data = SoundEntityData()
    -- set entity data position to player position
    data.transform = entityPos
    data.sound = SoundAsset(preparedSoundList[sound])
    data.obstructionHandle = 0
    data.playOnCreation = true
    -- create entity
    local soundEntity = SoundEntity(EntityManager:CreateEntity(data, entityPos))
    -- spawn entity
    if soundEntity ~= nil then
        soundEntity:Init(Realm.Realm_Client, true)
        playerSounds[player.id] = soundEntity
    end
end

-- when a client does make an input
local function onPlayerInput(player, deltaTime)
    -- do not proceed when player is not spawned
    if player.soldier == nil then
        return
    end
    -- do not proceed when player is not prop
    if not isProp(player) then
        return
    end
    -- sound on button Q
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_Q) then
        local sound = nil
        -- check for cooldown
        if cooldown > 0.0 then
            return
        end
        -- set cooldown time
        cooldown = cooldownTime
        -- check whether sound exist and choose another when not
        local loop = #soundList
        while loop > 0 do
            local randomNumber = MathUtils:GetRandomInt(1, #soundList)
            sound = soundList[randomNumber]
            -- when sound does exist
            if preparedSoundList[sound] ~= nil then
                -- end loop
                loop = 0
            else
                -- sound does not exist, remove it from the list
                table.remove(soundList, randomNumber)
                loop = loop - 1
            end
        end
        -- do not continue when no sound was found
        if sound == nil then
            debugMessage('did not find sound to send to all players')
            return
        end
        debugMessage('request to send sound ' .. sound .. ' to all players')
        -- send sound request to server (do not play sound locally. Let server decide...)
        NetEvents:SendLocal(GameMessage.C2S_PROP_SOUND, sound)
    end
end

-- when we get a sound play request
local function onSoundSync(playerID, sound)
    debugMessage('[S2C_SOUND_SYNC] for ' .. playerID .. ' with sound ' .. sound)
    local player = PlayerManager:GetPlayerById(playerID)
    -- do not proceed when player is not spawned
    if player.soldier == nil then
        return
    end
    -- do not proceed when sound does not exist
    if preparedSoundList[sound] == nil then
        return
    end
    spawnSound(player, sound)
end

-- on engine update
local lastUpdate = 0.0
local function onEngineUpdate(deltaTime)
    -- run event only every 1.0 seconds to save CPU time
    if lastUpdate >= 0.1 then
        -- descrease cooldown
        if cooldown > 0.0 then
            cooldown = cooldown - lastUpdate
        end
        -- reset last engine update
        lastUpdate = 0.0
    end
    -- increase lastUpdate value
    lastUpdate = lastUpdate + deltaTime
end

-- on level load
local function onLevelLoaded()
    -- load sound assets when possible
    for _, sound in pairs(soundList) do
        debugMessage('try loading sound asset ' .. sound)
        local soundResource = ResourceManager:SearchForDataContainer(sound)
        -- when sound exists
        if soundResource ~= nil then
            debugMessage('successful')
            preparedSoundList[sound] = SoundAsset(soundResource)
        else
            debugMessage('failed')
        end
    end
end

-- on level destroy
local function onLevelDestroy()
    for _, entity in pairs(playerSounds) do
        entity:Destroy()
    end
    playerSounds = {}
end

-- events and hooks
Events:Subscribe('Player:UpdateInput', onPlayerInput)
Events:Subscribe('Level:Loaded', onLevelLoaded)
NetEvents:Subscribe(GameMessage.S2C_SOUND_SYNC, onSoundSync)
Events:Subscribe('Engine:Update', onEngineUpdate)
Events:Subscribe('Level:Destroy', onLevelDestroy)
