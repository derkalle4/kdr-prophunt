local function onUiDrawHud()
	-- If we're a prop then render a crosshair.
	if isProp(PlayerManager:GetLocalPlayer()) then
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

local ingameMenuMPGraphGuid = Guid('E4386C4A-D5BB-DE8D-67DA-35456C8C51FD', 'D')

local function onPartitionLoaded(partition)
	for _, instance in pairs(partition.instances) do
		if instance.instanceGuid == ingameMenuMPGraphGuid then
			patchInGameMenuMPGraph(instance)
		end
	end
end

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
end


local function doNothing(hook)
	hook:Return()
end

-- function to run when user is about to press a button
local function onPlayerInput()
	-- show scoreboard
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_Tab) then
		WebUI:ExecuteJS('showScoreboard(true);')
	end
	-- hide scoreboard
	if InputManager:WentKeyUp(InputDeviceKeys.IDK_Tab) then
		WebUI:ExecuteJS('showScoreboard(false);')
	end

	-- quit
	if InputManager:WentKeyDown(InputDeviceKeys.IDK_Escape) then
		NetEvents:SendLocal(GameMessage.C2S_QUIT_GAME)
	end
end

local function onPlayerKilled(player)
	local localPlayer = PlayerManager:GetLocalPlayer()
	if player == localPlayer then
		WebUI:ExecuteJS('showHealthBar(false);')
		WebUI:ExecuteJS('showHiderKeys(false);')
		WebUI:ExecuteJS('showSpectatorKeys(true);')
		IngameSpectator:enable()
		return
	end
	WebUI:ExecuteJS('addToKillfeed("' .. player.name .. '", ' .. player.teamId .. ', "kill");')
end

local function onPlayerRespawn(player)
	local localPlayer = PlayerManager:GetLocalPlayer()
	if player == localPlayer then
		IngameSpectator:disable()
		WebUI:ExecuteJS('showHealthBar(true);')
	end
end

local function onPlayerConnected(player)
	local localPlayer = PlayerManager:GetLocalPlayer()
	if player == localPlayer then
		return
	end
	WebUI:ExecuteJS('addToKillfeed("' .. player.name .. '", ' .. player.teamId .. ', "connect");')
end

local function onPlayerDisconnect(player)
	local localPlayer = PlayerManager:GetLocalPlayer()
	if player == localPlayer then
		return
	end
	WebUI:ExecuteJS('addToKillfeed("' .. player.name .. '", ' .. player.teamId .. ', "disconnect");')
end

local function onLevelLoaded(levelName, gameMode)
	WebUI:ExecuteJS('showUI(true);')
end

local function onLevelDestroy(levelName, gameMode)
	WebUI:ExecuteJS('showUI(false);')
end

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
