-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')

-- include client data
require('PlayerProp')
require('PlayerSeeker')
require('PlayerInput')
require('PropPicker')
require('GameUi')

-- global variables
isProp = false

-- player ready event
Events:Subscribe('Extension:Loaded', function()
    -- If we already have a local player we'll assume this is a hot reload and we're already in-game.
    if PlayerManager:GetLocalPlayer() ~= nil then
        debugMessage('Ingame after hot reload. Notifying server that we\'re ready.')
        NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
    end

    -- Wait until we've entered the game to notify the server that we're ready.
    Events:Subscribe('Engine:Message', function(message)
        if message.type == MessageType.CoreEnteredIngameMessage then
            debugMessage('Now ingame. Notifying server that we\'re ready.')
            NetEvents:SendLocal(GameMessage.C2S_CLIENT_READY)
        end
    end)
end)