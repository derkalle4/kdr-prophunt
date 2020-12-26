-- SoundManager
-- manages sounds and broadcasts them to other players


-- when a client sends a prop sound
local function onPropSound(player, sound)
    -- check whether player is alive
    if not player.alive then
        return
    end
    -- broadcast sound
    NetEvents:Broadcast(GameMessage.S2C_SOUND_SYNC, player.id, sound)
end

-- events and hooks
NetEvents:Subscribe(GameMessage.C2S_PROP_SOUND, onPropSound)
