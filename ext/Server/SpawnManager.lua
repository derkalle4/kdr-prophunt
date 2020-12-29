-- SpawnManager
-- manages spawn for all players


-- give player a loadout
function givePlayerLoadout(player)
    local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')

    local p90 = ResourceManager:SearchForDataContainer('Weapons/P90/U_P90')
    local p90Attachments = { 'Weapons/P90/U_P90_Kobra', 'Weapons/P90/U_P90_Targetpointer' }

    local mp7 = ResourceManager:SearchForDataContainer('Weapons/MP7/U_MP7')
    local mp7Attachments = { 'Weapons/MP7/U_MP7_Kobra', 'Weapons/MP7/U_MP7_ExtendedMag' }

    local asval = ResourceManager:SearchForDataContainer('Weapons/ASVal/U_ASVal')
    local asvalAttachments = { 'Weapons/ASVal/U_ASVal_Kobra', 'Weapons/ASVal/U_ASVal_ExtendedMag' }

    local loadouts = {
        { p90, p90Attachments },
        { mp7, mp7Attachments },
        { asval, asvalAttachments },
    }

    local function setAttachments(unlockWeapon, attachments)
        for _, attachment in pairs(attachments) do
            local unlockAsset = UnlockAsset(ResourceManager:SearchForDataContainer(attachment))
            unlockWeapon.unlockAssets:add(unlockAsset)
        end
    end

    local m1911 = ResourceManager:SearchForDataContainer('Weapons/M1911/U_M1911')
    -- Create the seeker customization
    local seekerCustomization = CustomizeSoldierData()
    seekerCustomization.activeSlot = WeaponSlot.WeaponSlot_0
    seekerCustomization.removeAllExistingWeapons = true
    seekerCustomization.overrideCriticalHealthThreshold = 1.0

    -- Pick a random loadout.
    math.randomseed(SharedUtils:GetTimeMS())
    local loadout = loadouts[MathUtils:GetRandomInt(1, #loadouts)]

    local primaryWeapon = UnlockWeaponAndSlot()
    primaryWeapon.weapon = SoldierWeaponUnlockAsset(loadout[1])
    primaryWeapon.slot = WeaponSlot.WeaponSlot_0
    setAttachments(primaryWeapon, loadout[2])

    local secondaryWeapon = UnlockWeaponAndSlot()
    secondaryWeapon.weapon = SoldierWeaponUnlockAsset(m1911)
    secondaryWeapon.slot = WeaponSlot.WeaponSlot_1

    local meleeWeapon = UnlockWeaponAndSlot()
    meleeWeapon.weapon = SoldierWeaponUnlockAsset(knife)
    meleeWeapon.slot = WeaponSlot.WeaponSlot_5

    seekerCustomization.weapons:add(primaryWeapon)
    seekerCustomization.weapons:add(secondaryWeapon)
    seekerCustomization.weapons:add(meleeWeapon)

    player.soldier:ApplyCustomization(seekerCustomization)
end

-- spawns a seeker
function spawnSeeker(player)
    debugMessage('Spawning seeker ' .. player.name)

    local seekerSoldier = ResourceManager:SearchForDataContainer('Gameplay/Kits/USSupport')

    local assaultAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Assault_Appearance01')
    local engiAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Engi_Appearance01')
    local reconAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Recon_Appearance01')
    local supportAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Support_Appearance01')

    local appearances = {
        assaultAppearance,
        engiAppearance,
        reconAppearance,
        supportAppearance,
    }

    local mpSoldierBp = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    -- do not proceed when we have no spawns available
    local level = SharedUtils:GetLevelName()
    if level == nil or PlayerSpawns[level] == nil then
        return
    end

    -- Select spawn point randomly from predetermined list.
    local spawnTransform = LinearTransform()
    math.randomseed(SharedUtils:GetTimeMS())
    spawnTransform.trans = PlayerSpawns[level][MathUtils:GetRandomInt(1, #PlayerSpawns[level])]

    -- bots.spawn Bot1 Team2 Squad2 -100.150360 37.779110 -62.015625
    math.randomseed(SharedUtils:GetTimeMS())
    local randomAppearance = appearances[MathUtils:GetRandomInt(1, #appearances)]

    player:SelectUnlockAssets(seekerSoldier, { randomAppearance })

    if player.soldier == nil then
        local soldier = player:CreateSoldier(mpSoldierBp, spawnTransform)
        player:SpawnSoldierAt(soldier, spawnTransform, CharacterPoseType.CharacterPoseType_Stand)
    end

    givePlayerLoadout(player)

    player.soldier.health = Config.SeekerHealth
    player.soldier.maxHealth = Config.SeekerHealth

    player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
    player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
    player:EnableInput(EntryInputActionEnum.EIAFire, false)
    -- disable spotting
    player:EnableInput(EntryInputActionEnum.EIAThreeDimensionalMap, false)
    player:EnableInput(EntryInputActionEnum.EIAShowCommoRose, false)
    player:EnableInput(EntryInputActionEnum.EIAShowLeaderCommoRose, false)
end

-- spawns a prop player
function spawnProp(player)
    debugMessage('Spawning prop ' .. player.name)

    local hiderSoldier = ResourceManager:SearchForDataContainer('Gameplay/Kits/RUEngineer')
    local engiAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/RU/MP_RU_Engi_Appearance01')

    local mpSoldierBp = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    -- TODO: Select spawn point randomly from predetermined list.
    local spawnTransform = LinearTransform()

    -- do not proceed when we have no spawns available
    local level = SharedUtils:GetLevelName()
    if level == nil or PlayerSpawns[level] == nil then
        return
    end
    math.randomseed(SharedUtils:GetTimeMS())
    spawnTransform.trans = PlayerSpawns[level][MathUtils:GetRandomInt(1, #PlayerSpawns[level])]

    player:SelectUnlockAssets(hiderSoldier, { engiAppearance })

    if player.soldier == nil then
        local soldier = player:CreateSoldier(mpSoldierBp, spawnTransform)
        player:SpawnSoldierAt(soldier, spawnTransform, CharacterPoseType.CharacterPoseType_Stand)
    end

    local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')

    -- Create the infection customization
    local hiderCustomization = CustomizeSoldierData()
    hiderCustomization.activeSlot = WeaponSlot.WeaponSlot_5
    hiderCustomization.removeAllExistingWeapons = true
    hiderCustomization.overrideCriticalHealthThreshold = 1.0

    local unlockWeapon = UnlockWeaponAndSlot()
    unlockWeapon.weapon = SoldierWeaponUnlockAsset(knife)
    unlockWeapon.slot = WeaponSlot.WeaponSlot_5

    hiderCustomization.weapons:add(unlockWeapon)

    player.soldier:ApplyCustomization(hiderCustomization)
    player.soldier.health = Config.HiderHealth
    player.soldier.maxHealth = Config.HiderHealth

    player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
    player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
    player:EnableInput(EntryInputActionEnum.EIAFire, false)
    -- disable spotting
    player:EnableInput(EntryInputActionEnum.EIAThreeDimensionalMap, false)
    player:EnableInput(EntryInputActionEnum.EIAShowCommoRose, false)
    player:EnableInput(EntryInputActionEnum.EIAShowLeaderCommoRose, false)
end

function spawnAllPlayers()
    debugMessage('spawnAllPlayers')
    for _, player in pairs(readyPlayers) do
        if isSeeker(player) then
            spawnSeeker(player)
        elseif isProp(player) then
            spawnProp(player)
        end
    end
end

function setAllPlayersRole()
    debugMessage('setAllPlayersRole')
    for _, player in pairs(readyPlayers) do
        if isSeeker(player) then
            makePlayerSeeker(player)
        elseif isProp(player) then
            makePlayerProp(player)
        end
    end
end

-- This starts the round manually, skipping any preround logic.
-- It also requires the PreRoundEntity to be removed for it to work properly.
local function onEntityFactoryCreateFromBlueprint(hook, blueprint, transform, variation, parentRepresentative)
    if Blueprint(blueprint).name == 'Gameplay/Level_Setups/Complete_setup/Full_TeamDeathmatch' then
        local tdmBus = hook:Call()

        for _, entity in pairs(tdmBus.entities) do
            if entity:Is('ServerInputRestrictionEntity') then
                entity:FireEvent('Deactivate')
            elseif entity:Is('ServerRoundOverEntity') then
                entity:FireEvent('RoundStarted')
            elseif entity:Is('EventGateEntity') and entity.data.instanceGuid == Guid('B7F13498-C61B-47E6-895E-0ED2048E7AF4') then
                entity:FireEvent('Close')
            end
        end
    end
end

Hooks:Install('EntityFactory:CreateFromBlueprint', 100, onEntityFactoryCreateFromBlueprint)
