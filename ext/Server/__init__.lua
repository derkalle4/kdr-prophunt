-- server Init
-- initialize all server stuff


-- include shared data
require('__shared/DebugMessage')
require('__shared/GameManager')
require('__shared/PlayerManager')

-- include server data
require('configuration')
require('PropDamage')
require('PropsManager')
require('SpawnManager')
require('PlayerManager')
require('GameManager')
require('SoundManager')

-- set custom gamemode name
ServerUtils:SetCustomGameModeName('Prop Hunt')

-- when a chat message gets send
local function onPlayerChat(player, recipientMask, message)
    -- do nothing when empty
    if message == '' or player == nil then
        return
    end

    -- when message is 'pos'
    if message == 'pos' then
        -- when player is not spawned return nothing
        if player.soldier == nil then
            return
        end
        -- print player soldier position
        print(player.soldier.transform)
    end
end

-- events and hooks
Events:Subscribe('Player:Chat', onPlayerChat)
