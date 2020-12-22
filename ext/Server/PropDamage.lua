local itemsHit = {}

-- hooking the soldier damage function
Hooks:Install('Soldier:Damage', 100, function(hook, soldier, info, giverInfo)
	-- do nothing when we are not seeking (no damage at all)
	if currentState.roundState ~= GameState.seeking then
		hook:Return()
		return
	end
	-- Prevent players on Team2 (hiders) from taking damage from other players.
	if giverInfo.giver ~= nil and isProp(soldier.player) then
		hook:Return()
		return
	end
end)

Events:Subscribe('Engine:Update', function()
	itemsHit = {}
end)

-- give seeker damage when shot with bullets
Hooks:Install('BulletEntity:Collision', 100, function(hook, entity, hit, giverInfo)
	if giverInfo.giver == nil or hit.rigidBody == nil then
		return
	end
	-- Only apply one damage per tick.
	local hitId = tostring(giverInfo.giver.id) .. tostring(hit.rigidBody.instanceId)
	if itemsHit[hitId] then
		return
	end
	-- set hit to true
	itemsHit[hitId] = true
	-- Damage the player on each hit.
	if giverInfo.giver.soldier ~= nil then
		local playerDamage = DamageInfo()
		playerDamage.damage = 3
		giverInfo.giver.soldier:ApplyDamage(playerDamage)
	end
end)

-- give prop player damage and heal seeker
NetEvents:Subscribe(GameMessage.C2S_PROP_DAMAGE, function(player, targetId)
	debugMessage('[C2S_PROP_DAMAGE] from ' .. player.name .. ' to [Unknown yet] (name should be in next line)')
	local targetPlayer = PlayerManager:GetPlayerById(targetId)
	if targetPlayer == nil or not isProp(targetPlayer) or targetPlayer.soldier == nil or player.soldier == nil then
		return
	end
	debugMessage('[C2S_PROP_DAMAGE] from ' .. player.name .. ' to ' .. targetPlayer.name)
	-- Damage the prop player
	local propDamage = DamageInfo()
	propDamage.damage = 8
	targetPlayer.soldier:ApplyDamage(propDamage)
	-- heal the seeker
	local shooterHeal = DamageInfo()
	shooterHeal.damage = -8
	player.soldier:ApplyDamage(shooterHeal)
end)
