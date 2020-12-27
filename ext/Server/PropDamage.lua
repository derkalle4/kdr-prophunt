-- PropDamage
-- everything related to make props damage


-- list of items that got hit
local itemsHit = {}

-- hooking the soldier damage function
local function onSoldierDamage(hook, soldier, info, giverInfo)
    -- do nothing when we are not seeking (no damage at all)
    if currentState.roundState == GameState.idle
        or currentState.roundState == GameState.postRound
        or currentState.roundState == GameState.mapChange then
        hook:Return()
        return
    end
    -- Prevent players on Team2 (hiders) from taking damage from other players.
    if giverInfo.giver ~= nil and isProp(soldier.player) then
        hook:Return()
        return
    end
end

local function onEngineUpdate()
    itemsHit = {}
end

-- give seeker damage when shot with bullets
local function onBulletEntityCollision(hook, entity, hit, giverInfo)
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
        playerDamage.damage = Config.BulletShootDamage
        giverInfo.giver.soldier:ApplyDamage(playerDamage)
    end
end

-- give prop player damage and heal seeker
local function onPropDamage(player, targetId)
    debugMessage('[C2S_PROP_DAMAGE] from ' .. player.name .. ' to [Unknown yet] (name should be in next line)')
    local targetPlayer = PlayerManager:GetPlayerById(targetId)
    if targetPlayer == nil or not isProp(targetPlayer) or targetPlayer.soldier == nil or player.soldier == nil then
        return
    end
    debugMessage('[C2S_PROP_DAMAGE] from ' .. player.name .. ' to ' .. targetPlayer.name)
    -- Damage the prop player
    local propDamage = DamageInfo()
    propDamage.damage = Config.DamageToPlayerProp
    targetPlayer.soldier:ApplyDamage(propDamage)
    -- heal the seeker
    local shooterHeal = DamageInfo()
    shooterHeal.damage = Config.SeekerDamageFromPlayerProp
    player.soldier:ApplyDamage(shooterHeal)
end

-- events and hooks
Events:Subscribe('Engine:Update', onEngineUpdate)
NetEvents:Subscribe(GameMessage.C2S_PROP_DAMAGE, onPropDamage)
Hooks:Install('BulletEntity:Collision', 100, onBulletEntityCollision)
Hooks:Install('Soldier:Damage', 100, onSoldierDamage)
