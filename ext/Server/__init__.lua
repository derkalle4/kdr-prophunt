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

ServerUtils:SetCustomGameModeName('Prop Hunt')

Events:Subscribe('Player:Chat', function(player, recipientMask, message)
	if message == '' or player == nil then
		return
	end

    if message == 'pos' then
        if player.soldier == nil then
            return
        end

        print(player.soldier.transform)
    end
end)