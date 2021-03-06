-- client Init
-- initialize all client stuff


-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')
require('__shared/PlayerManager')
require('__shared/IngameCamera')
require('__shared/SoundManager')
require('__shared/PropsManager')

-- include client data
require('IngameCamera')
require('GameSync')
require('PlayerProp')
require('PlayerSeeker')
require('PropPicker')
require('GameUi')
require('NameTags')
require('SoundManager')

ModVersion = 'v0.0.3' -- mod version as long as one could not read it from the mod.json itself (will be displayed in the UI)

-- make player ready
local function playerReady()
    debugMessage('player is ready!')
    NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
    -- start web UI
    WebUI:Init()
    -- set mod version
    WebUI:ExecuteJS('setModVersion("' .. ModVersion .. '");')
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

-- when the level got loaded
local function onLevelLoaded()
    -- enable spectator
    enableIngameCamera()
end

-- events and hooks
Events:Subscribe('Extension:Loaded', onExtensionLoaded)
Events:Subscribe('Engine:Message', onEngineMessage)
Events:Subscribe('Level:Loaded', onLevelLoaded)