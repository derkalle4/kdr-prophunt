-- PlayerManager
-- manages player states and their teams

-- all players that are ready
readyPlayers = {}


-- send player information to specific player
function sendPlayerUpdateToPlayer(player)
    debugMessage('[S2C_PLAYER_SYNC] to ' .. player.name)
    NetEvents:SendTo(GameMessage.S2C_PLAYER_SYNC, player, player.id, player.teamId)
end

-- set ammo for seekers
function setAmmoForSeekers()
    for i, player in pairs(readyPlayers) do
        -- Ignore bots
        if not player.onlineId ~= 0 and player.soldier ~= nil and isSeeker(player) then
            local soldierWeapons = player.soldier.weaponsComponent.weapons
            for _, weapon in ipairs(soldierWeapons) do
                SoldierWeapon(weapon).secondaryAmmo = 500
            end
        end
    end
end

-- set ammo for props
function setAmmoForProps()
    for i, player in pairs(readyPlayers) do
        -- Ignore bots
        if not player.onlineId ~= 0 and player.soldier ~= nil and isProp(player) then
            local soldierWeapons = player.soldier.weaponsComponent.weapons
            for _, weapon in ipairs(soldierWeapons) do
                SoldierWeapon(weapon).secondaryAmmo = 500
            end
        end
    end
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

-- check whether given entity is client entity
function checkEntityForPlayerEntity(entity)
    local players = PlayerManager:GetPlayers()
    for i, player in pairs(players) do
        if player == entity then
            return true
        end
    end
    return false
end

-- get count of seekers
function getSeekerCount()
    local count = 0
    for i, player in pairs(readyPlayers) do
        -- Ignore bots
        if not player.onlineId ~= 0 and player.soldier ~= nil and isSeeker(player) then
            count = count + 1
        end
    end
    return count
end

-- get count of props
function getPropCount()
    local count = 0
    for i, player in pairs(readyPlayers) do
        -- Ignore bots and dead players.
        if player.onlineId ~= 0 and player.soldier ~= nil and isProp(player) then
            count = count + 1
        end
    end
    return count
end

-- get count of specator
function getSpecCount()
    local count = 0
    for i, player in pairs(readyPlayers) do
        -- Ignore bots and only dead players
        if player.onlineId ~= 0 and player.soldier == nil and isSpectator(player) then
            count = count + 1
        end
    end
    return count
end

-- get count of player
function getPlayerCount()
    local count = 0
    for i, player in pairs(readyPlayers) do
        -- ignore bots
        if player.onlineId ~= 0 then
            count = count + 1
        end
    end
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

-- disable input from seekers
function disableSeekerInput()
    debugMessage('disableSeekerInput')
    -- Make prop players into props and seekers into seekers.
    for _, player in pairs(readyPlayers) do
        if isSeeker(player) then
            -- For seekers we want to fade their screen to black
            -- BUG: does not fade to black completely when it runs directly after spawn
            player:Fade(1.0, true)
            -- And also prevent them from moving.
            player:EnableInput(EntryInputActionEnum.EIAThrottle, false)
            player:EnableInput(EntryInputActionEnum.EIAStrafe, false)
            player:EnableInput(EntryInputActionEnum.EIAFire, false)
        end
    end
end

-- enable input from seekers
function enableSeekerInput()
    debugMessage('enableSeekerInput')
    -- Make prop players into props and seekers into seekers.
    for _, player in pairs(readyPlayers) do
        if isSeeker(player) then
            -- For seekers we want to fade their screen to black.
            player:Fade(1.0, false)
            -- And also prevent them from moving.
            player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
            player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
            player:EnableInput(EntryInputActionEnum.EIAFire, true)
        end
    end
end

-- when a player joined and is ready
local function onClientReady(player)
    debugMessage('[C2S_CLIENT_READY] from ' .. player.name)
    -- add player to player list
    table.insert(readyPlayers, player)
    -- set player to spectator
    setPlayerSpectating(player)
    -- send update to player
    sendPlayerUpdateToPlayer(player)
end

-- when a player wants to quit the game
local function onQuitGame(player)
    debugMessage('[C2S_QUIT_GAME] from ' .. player.name)
    -- remove player from readyPlayers
    for i, readyPlayer in pairs(readyPlayers) do
        if readyPlayer == player then
            table.remove(readyPlayers, i)
            break
        end
    end
    -- kick player
    player:Kick('see you next time!')
end

-- Remove player from list of ready players when they disconnect.
local function onPlayerDestroyed(player)
    debugMessage('[Player:Destroyed] from ' .. player.name)
    for i, readyPlayer in pairs(readyPlayers) do
        if readyPlayer == player then
            table.remove(readyPlayers, i)
            break
        end
    end
end

-- Clear all ready players when the level is getting destroyed
local function onLevelDestroy()
    readyPlayers = {}
end

-- events and hooks
NetEvents:Subscribe(GameMessage.C2S_CLIENT_READY, onClientReady)
NetEvents:Subscribe(GameMessage.C2S_QUIT_GAME, onQuitGame)
Events:Subscribe('Player:Destroyed', onPlayerDestroyed)
Events:Subscribe('Level:Destroy', onLevelDestroy)