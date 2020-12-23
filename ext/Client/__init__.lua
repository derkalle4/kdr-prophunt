-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')
require('__shared/PlayerManager')

-- include client data
Camera = require('Camera')
require('GameSync')
require('PlayerProp')
require('PlayerSeeker')
require('PropPicker')
require('GameUi')

-- player ready event
Events:Subscribe('Extension:Loaded', function()
    -- If we already have a local player we'll assume this is a hot reload and we're already in-game.
    if PlayerManager:GetLocalPlayer() ~= nil then
        debugMessage('Ingame after hot reload. Notifying server that we\'re ready.')
        NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
		-- start web UI
		WebUI:Init()
    end

    -- Wait until we've entered the game to notify the server that we're ready.
    Events:Subscribe('Engine:Message', function(message)
        if message.type == MessageType.CoreEnteredIngameMessage then
            debugMessage('Now ingame. Notifying server that we\'re ready.')
            NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
			-- start web UI
			WebUI:Init()
        end
    end)
end)