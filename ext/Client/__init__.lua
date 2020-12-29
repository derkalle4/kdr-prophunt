-- client Init
-- initialize all client stuff


-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')
require('__shared/PlayerManager')
require('__shared/IngameSpectator')
require('__shared/SoundManager')
require('__shared/PropsManager')

-- include client data
Camera = require('Camera')
IngameSpectator = require('IngameSpectator')
require('GameSync')
require('PlayerProp')
require('PlayerSeeker')
require('PropPicker')
require('GameUi')
require('NameTags')
require('SoundManager')


-- local variables
local lastSyncUpdate = 0.0 -- initial prop sync update

-- make player ready
local function playerReady()
    debugMessage('player is ready!')
    NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
    -- start web UI
    WebUI:Init()
    -- enable spectator
    IngameSpectator:enable()
    -- show welcome message
    WebUI:ExecuteJS('showWelcomeMessage(true);')
end

-- when engine wrote a message
local function onEngineMessage(message)
    if message.type == MessageType.CoreEnteredIngameMessage then
        -- set player ready
       playerReady()
    end
end

-- when the extension got loaded
local function onExtensionLoaded()
    -- If we already have a local player we'll assume this is a hot reload and we're already in-game.
    if PlayerManager:GetLocalPlayer() ~= nil then
        -- set player ready
        playerReady()
    end
end

-- on engine update
local function onEngineUpdate(deltaTime)
    -- run event after three seconds
    if lastSyncUpdate >= 3.0 then
        -- ask for prop sync
        NetEvents:SendLocal(GameMessage.C2S_CLIENT_SYNC)
        -- reset last engine update
        lastSyncUpdate = -1.0
    elseif lastSyncUpdate >= 0.0 then
        -- increase lastUpdate value
        lastSyncUpdate = lastSyncUpdate + deltaTime
    end
end

-- events and hooks
Events:Subscribe('Engine:Update', onEngineUpdate)
Events:Subscribe('Extension:Loaded', onExtensionLoaded)
Events:Subscribe('Engine:Message', onEngineMessage)