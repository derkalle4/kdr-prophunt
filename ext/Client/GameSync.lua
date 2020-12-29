-- GameSync
-- client side game logic implementation for all players

-- when we are in idle state
local function inIdleState(info, localPlayer)
    -- disable any center message
    WebUI:ExecuteJS('setCenterMessage("");')
    -- hide spectator keys
    WebUI:ExecuteJS('showSpectatorKeys(false);')
    -- hide hider keys
    WebUI:ExecuteJS('showHiderKeys(false);')
end

-- when we are in preRound state
local function inPreRoundState(info, localPlayer)
    -- disable spectator message
    WebUI:ExecuteJS('setSpectatorMessage("");')
    -- hide welcome message
    WebUI:ExecuteJS('showWelcomeMessage(false);')
    -- hide spectator keys
    WebUI:ExecuteJS('showSpectatorKeys(false);')
    -- hide hider keys
    WebUI:ExecuteJS('showHiderKeys(false);')
    -- show killfeed
    WebUI:ExecuteJS('showKillfeed(true);')
end

-- when we are in hiding state
local function inHidingState(info, localPlayer)
    -- play round start sound (TODO: same sound for all clients)
    WebUI:ExecuteJS('playSound("roundstart1");')
    -- check for player team
    if localPlayer.teamId == 1 then -- when player is seeker
        -- give center message for hiding state
        WebUI:ExecuteJS('setCenterMessage("wait until hiders are hidden", 7);')
        -- disable spectator message
        WebUI:ExecuteJS('setSpectatorMessage("");')
    elseif localPlayer.teamId == 2 then -- when player is hider
        -- set center message for hiding state
        WebUI:ExecuteJS('setCenterMessage("prepare to hide!", 7);')
        -- show key tooltip for hider
        WebUI:ExecuteJS('showHiderKeys(true);')
        -- disable spectator message
        WebUI:ExecuteJS('setSpectatorMessage("");')
    else -- when player is spectator
        -- set center message for hiding state
        WebUI:ExecuteJS('setCenterMessage("hiders going to hide themself", 7);')
        -- show spectator keys
        WebUI:ExecuteJS('showSpectatorKeys(true);')
    end
    -- show killfeed
    WebUI:ExecuteJS('showKillfeed(true);')
end

-- when we are in seeking state
local function inSeekingState(info, localPlayer)
    -- check for player team
    if localPlayer.teamId == 1 then -- when player is seeker
        -- set center message for seeking state
        WebUI:ExecuteJS('setCenterMessage("kill all props!", 7);')
    elseif localPlayer.teamId == 2 then -- when player is hider
        -- set center message for seeking state
        WebUI:ExecuteJS('setCenterMessage("hide now!", 7);')
    else -- when player is spectator
        -- set center message for seeking state
        WebUI:ExecuteJS('setCenterMessage("seekers starting their search", 7);')
        -- show spectator keys
        WebUI:ExecuteJS('showSpectatorKeys(true);')
    end
    -- show killfeed
    WebUI:ExecuteJS('showKillfeed(true);')
end

-- when we are in postRound state
local function inPostRoundState(info, localPlayer)
    -- check for winning team
    if info.winner == 1 then -- when seekers win
        WebUI:ExecuteJS('setCenterMessage("seekers win!", 15);')
    else -- when hiders win
        WebUI:ExecuteJS('setCenterMessage("hiders win!", 15);')
    end
    -- show postRound overlay
    WebUI:ExecuteJS('postRoundOverlay(' .. info.winner .. ', ' .. localPlayer.teamId .. ');')
    -- set team of user for UI to 0 again
    WebUI:ExecuteJS('setUserTeam(0);')
    -- hide hiding keys
    WebUI:ExecuteJS('showHiderKeys(false);')
    -- hide spectator keys
    WebUI:ExecuteJS('showSpectatorKeys(false);')
    -- hide health bar
    WebUI:ExecuteJS('showHealthBar(false);')
    -- hide killfeed
    WebUI:ExecuteJS('showKillfeed(false);')
end

-- synchronisation of each server game object
local oldState = -1
local function onGameSync(info)
    -- sync currentState with state we got from server
    currentState = info
    -- set UI round information
    WebUI:ExecuteJS('setRoundInfo(' .. info.numPlayer .. ',' .. info.numSeeker .. ', ' .. info.numHider .. ', ' .. info.numSpectator .. ', "' .. info.roundStatusMessage .. '", ' .. math.floor(info.roundTimer) .. ');')
    -- check whether we got into a new state
    if oldState ~= info.roundState then
        -- get local player
        local localPlayer = PlayerManager:GetLocalPlayer()
        -- do not proceed when localPlayer does not exist
        if localPlayer == nil then
            return
        end
        -- check for specific round phases
        if info.roundState == GameState.idle then               -- idle after mapchange
            -- set current state to idle
            oldState = GameState.idle
            -- run inIdleState
            inIdleState(info, localPlayer)
        elseif info.roundState == GameState.preRound then       -- pre round before game starts
            -- set current state to preRound
            oldState = GameState.preRound
            -- run inPreRoundState
            inPreRoundState(info, localPlayer)
        elseif info.roundState == GameState.hiding then     -- game starts with hiding
            -- set current state to hiding
            oldState = GameState.hiding
            -- run inHidingState
            inHidingState(info, localPlayer)
        elseif info.roundState == GameState.seeking then -- game starts with seeking
            -- set current state to seeking
            oldState = GameState.seeking
            -- run inSeekingState
            inSeekingState(info, localPlayer)
        elseif info.roundState == GameState.postRound then  -- end of game
            -- set current state to postRound
            oldState = GameState.postRound
            -- run inPostRoundState
            inPostRoundState(info, localPlayer)
        end
    end
end

-- send scoreboard data to UI
local function SendScoreBoardData()
    -- data array with players
    local data = {}
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do not progress when localPlayer does not exist
    if localPlayer == nil then
        return
    end
    -- get all players
    local players = PlayerManager:GetPlayers()
    for _, player in pairs(players) do
        table.insert(data, {
            id = player.id,
            alive = player.soldier ~= nil,
            username = player.name,
            team = player.teamId,
            score = (player.score >= 0 and player.score or 0),
            kills = (player.kills >= 0 and player.kills or 0),
            deaths = (player.deaths >= 0 and player.deaths or 0),
            ping = (player.ping >= 0 and player.ping or 0),
        })
    end
    -- send players to scoreboard UI
    WebUI:ExecuteJS('updateScoreboard(' .. json.encode(data) .. ', ' .. localPlayer.teamId .. ');')
end

-- send health data to UI
local function SendHealthBarData()
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do not progress when localPlayer does not exist
    if localPlayer == nil then
        return
    end
    -- do not progress when localPlayer soldier does not exist
    if localPlayer.soldier == nil then
        return
    end
    -- get primary ammo
    local curPrimaryAmmo = localPlayer.soldier.weaponsComponent.currentWeapon.primaryAmmo
    -- set primary ammo to 0 when it does not exist
    if curPrimaryAmmo == nil then
        curPrimaryAmmo = 0
    end
    -- send health data to UI
    WebUI:ExecuteJS('setHealthBar(' .. math.floor(localPlayer.soldier.health) .. ', ' .. curPrimaryAmmo .. ');')
end

-- on engine update
local lastUpdate = 0.0
local function onEngineUpdate(deltaTime)
    -- run event only every 1.0 seconds to save CPU time
    if lastUpdate >= 0.1 then
        -- update UI player data
        SendScoreBoardData()
        -- update UI health bar
        SendHealthBarData()
        -- reset last engine update
        lastUpdate = 0.0
    end
    -- increase lastUpdate value
    lastUpdate = lastUpdate + deltaTime
end

NetEvents:Subscribe(GameMessage.S2C_GAME_SYNC, onGameSync)
Events:Subscribe('Engine:Update', onEngineUpdate)
