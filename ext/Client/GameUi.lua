-- GameUi
-- client side UI logic for everything


-- draw UI HUD
local function onUiDrawHud()
    -- If we're a prop and alive then render a crosshair.
    local localPlayer = PlayerManager:GetLocalPlayer()
    if isProp(localPlayer) and localPlayer.alive then
        local windowSize = ClientUtils:GetWindowSize()
        local cx = math.floor(windowSize.x / 2.0 + 0.5)
        local cy = math.floor(windowSize.y / 2.0 + 0.5)

        DebugRenderer:DrawLine2D(Vec2(cx - 7, cy - 1), Vec2(cx + 6, cy - 1), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx - 7, cy), Vec2(cx + 6, cy), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx - 7, cy + 1), Vec2(cx + 6, cy + 1), Vec4(1, 1, 1, 0.5))

        DebugRenderer:DrawLine2D(Vec2(cx - 1, cy - 7), Vec2(cx - 1, cy - 2), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx, cy - 7), Vec2(cx, cy - 2), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx + 1, cy - 7), Vec2(cx + 1, cy - 2), Vec4(1, 1, 1, 0.5))

        DebugRenderer:DrawLine2D(Vec2(cx - 1, cy + 1), Vec2(cx - 1, cy + 6), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx, cy + 1), Vec2(cx, cy + 6), Vec4(1, 1, 1, 0.5))
        DebugRenderer:DrawLine2D(Vec2(cx + 1, cy + 1), Vec2(cx + 1, cy + 6), Vec4(1, 1, 1, 0.5))
    end
end

-- patch ingame MP graph
local function patchInGameMenuMPGraph(instance)
    if instance == nil then
        return
    end

    local graph = UIGraphAsset(instance)
    graph:MakeWritable()

    for i = #graph.connections, 1, -1 do
        local connection = UINodeConnection(graph.connections[i])

        -- We get rid of these connections so when a user presses the "Squad & Team"
        -- or the "Suicide" buttons nothing happens.
        if connection.sourcePort.name == 'ID_M_IGMMP_SQUAD' or connection.sourcePort.name == 'ID_M_IGMMP_SUICIDE' then
            graph.connections:erase(i)
        end
    end
end

-- on partition loaded
local ingameMenuMPGraphGuid = Guid('E4386C4A-D5BB-DE8D-67DA-35456C8C51FD', 'D')
local function onPartitionLoaded(partition)
    for _, instance in pairs(partition.instances) do
        if instance.instanceGuid == ingameMenuMPGraphGuid then
            patchInGameMenuMPGraph(instance)
        end
    end
end

-- on push screen
local function onPushScreen(hook, screen, priority, parentGraph, stateNodeGuid)
    local asset = UIScreenAsset(screen)
    if asset.name == 'UI/Flow/Screen/SpawnScreenPC' or
        asset.name == 'UI/Flow/Screen/SpawnButtonScreen' or
        asset.name == 'UI/Flow/Screen/SpawnScreenTicketCounterTDMScreen' or
        string.match(string.lower(asset.name), 'scoreboard') then
            hook:Return()
        return
    end

    -- Remove the TDM hud (minimap, compass, etc.)
    if asset.name == 'UI/Flow/Screen/HudTDMScreen' then
        asset:MakeWritable()
        asset.connections:clear()

        -- Here we remove everything BUT the minimap because we remove it
        -- through the UI:RenderMinimap hook. If we don't remove it here
        -- it'll just render suspended in space.
        for i = #asset.nodes, 1, -1 do
            if not asset.nodes[i]:Is('WidgetNode') then
                asset.nodes:erase(i)
            elseif WidgetNode(asset.nodes[i]).name ~= 'Minimap' then
                asset.nodes:erase(i)
            end
        end

        return
    end
    -- Remove Ammo and Health widget
    if asset.name == 'UI/Flow/Screen/HudMPScreen' then
        asset:MakeWritable()
        asset.connections:clear()
        for i = #asset.nodes, 1, -1 do
        if asset.nodes[i]:Is('WidgetNode') then
            if WidgetNode(asset.nodes[i]).name == 'Ammo' or
                WidgetNode(asset.nodes[i]).name == 'Health' or 
                WidgetNode(asset.nodes[i]).name == 'Minimap' then
                    asset.nodes:erase(i)
                end
            end
        end
        return
    end
end

-- do nothing for some hooks (to disable them)
local function doNothing(hook)
    hook:Return()
end

-- when user is about to press a button
local DisconnectInSeconds = 0.0
local function onPlayerInput(player, deltaTime)
    -- show scoreboard
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_Tab) then
        -- show scoreboard on UI
        WebUI:ExecuteJS('showScoreboard(true);')
    end
    -- hide scoreboard
    if InputManager:WentKeyUp(InputDeviceKeys.IDK_Tab) then
        -- hide scoreboard on UI
        WebUI:ExecuteJS('showScoreboard(false);')
    end

    -- quit
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_Escape) then
        WebUI:ExecuteJS('setUserMessage("Hold ESC to disconnect")')
        DisconnectInSeconds = DisconnectInSeconds + deltaTime
        if DisconnectInSeconds >= 0.3 then
            NetEvents:SendLocal(GameMessage.C2S_QUIT_GAME)
        end
    elseif InputManager:WentKeyUp(InputDeviceKeys.IDK_Escape) then
        DisconnectInSeconds = 0.0
        WebUI:ExecuteJS('setUserMessage("")')
    end

    -- show welcome message
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F1) then
        -- show scoreboard on UI
        WebUI:ExecuteJS('showWelcomeMessage();')
    end
end

-- when a player gets killed
local function onPlayerKilled(player)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    local playername = player.name
    -- when killed player is local player
    if player == localPlayer then
        -- hide health bar
        WebUI:ExecuteJS('showHealthBar(false);')
        -- hide hiding keys
        WebUI:ExecuteJS('showHiderKeys(false);')
        -- show spectator keys
        WebUI:ExecuteJS('showSpectatorKeys(true);')
        -- enable spectator mode
        Camera:disable()
        IngameSpectator:disable()
        IngameSpectator:enable()
        -- set playername to localPlayer
        playername = 'You'
    end
    -- add death to killfeed
    WebUI:ExecuteJS('addToKillfeed("' .. playername .. '", ' .. player.teamId .. ', "kill");')
end

-- when a player gets respawned
local function onPlayerRespawn(player)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- if current player is local player
    if player == localPlayer then
        -- disable spectator mode
        IngameSpectator:disable()
        -- show health bar
        WebUI:ExecuteJS('showHealthBar(true);')
    end
end

-- when a new player connects
local function onPlayerConnected(player)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do nothing when it is the local player
    if player == localPlayer then
        return
    end
    -- add connection to killfeed
    WebUI:ExecuteJS('addToKillfeed("' .. player.name .. '", ' .. player.teamId .. ', "connect");')
end

-- when a player disconnects
local function onPlayerDisconnect(player)
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- do nothing when it is the local player
    if player == localPlayer then
        return
    end
    -- add disconnect to killfeed
    WebUI:ExecuteJS('addToKillfeed("' .. player.name .. '", ' .. player.teamId .. ', "disconnect");')
end

-- when level is loaded
local function onLevelLoaded(levelName, gameMode)
    -- show UI
    WebUI:ExecuteJS('showUI(true);')
end

-- when level is destroyed
local function onLevelDestroy(levelName, gameMode)
    -- hide UI
    WebUI:ExecuteJS('showUI(false);')
end

-- all events and hooks
Hooks:Install('UI:CreateKillMessage', 100, doNothing)
Hooks:Install('UI:DrawNametags', 100, doNothing)
Hooks:Install('UI:DrawMoreNametags', 100, doNothing)
Hooks:Install('UI:DrawEnemyNametag', 100, doNothing)
Hooks:Install('UI:RenderMinimap', 100, doNothing)
Hooks:Install('UI:PushScreen', 100, onPushScreen)
Events:Subscribe('Partition:Loaded', onPartitionLoaded)
Events:Subscribe('UI:DrawHud', onUiDrawHud)
Events:Subscribe('Player:UpdateInput', onPlayerInput)
Events:Subscribe('Player:Killed', onPlayerKilled)
Events:Subscribe('Player:Respawn', onPlayerRespawn)
Events:Subscribe('Player:Connected', onPlayerConnected)
Events:Subscribe('Player:Deleted', onPlayerDisconnect)
Events:Subscribe('Level:Loaded', onLevelLoaded)
Events:Subscribe('Level:Destroy', onLevelDestroy)
