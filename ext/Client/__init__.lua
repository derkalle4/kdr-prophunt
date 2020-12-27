-- client Init
-- initialize all client stuff


-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')
require('__shared/PlayerManager')
require('__shared/IngameSpectator')
require('__shared/SoundManager')

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

-- events and hooks
Events:Subscribe('Extension:Loaded', onExtensionLoaded)
Events:Subscribe('Engine:Message', onEngineMessage)
