-- shared Init
-- initialize all shared (client and server) stuff


-- when partition got loaded
local function onPartitionLoaded(partition)
    for _, instance in pairs(partition.instances) do
        -- Disable spawn protection.
        if instance.instanceGuid == Guid('705967EE-66D3-4440-88B9-FEEF77F53E77') then
            local healthData = VeniceSoldierHealthModuleData(instance)
            healthData:MakeWritable()

            healthData.immortalTimeAfterSpawn = 0.0
        end
        -- Get rid of the PreRoundEntity. We don't need preround in this gamemode.
        if instance.instanceGuid == Guid('5FA66B8C-BE0E-3758-7DE9-533EA42F5364') then
            local bp = LogicPrefabBlueprint(instance)
            bp:MakeWritable()

            for i = #bp.objects, 1, -1 do
                if bp.objects[i]:Is('PreRoundEntityData') then
                    bp.objects:erase(i)
                end
            end

            for i = #bp.eventConnections, 1, -1 do
                if bp.eventConnections[i].source:Is('PreRoundEntityData') or bp.eventConnections[i].target:Is('PreRoundEntityData') then
                    bp.eventConnections:erase(i)
                end
            end
        end
        -- Disable weapon pickups.
        if instance.instanceGuid == Guid('0D126546-B7A4-4C76-B41F-719B6BFB2053') then
            local data = KitPickupEntityData(instance)
            data:MakeWritable()

            data.enabled = false
            data.allowPickup = false
            data.timeToLive = 0.0
        end
        -- set team size to 127 per team
        if instance:Is('GameModeSettings') then
            local settings = GameModeSettings(instance)
            settings:MakeWritable()

            for _, information in pairs(settings.information) do
                for _, size in pairs(information.sizes) do
                    for _, team in pairs(size.teams) do
                       team.playerCount = 127
                    end
                end
            end
        end
        -- remove spotting
        if instance.instanceGuid == Guid('105707CF-F84E-4A93-B18C-A8EDED291CC4') then
            local spotting = SpottingComponentData(instance)
            spotting:MakeWritable()
            spotting.spottingDistance = 0.0
            spotting.coolDownHistoryTime = 9999.0
            spotting.coolDownAllowedSpotsWithinHistory = 0
        end
    end
end

-- events and hooks
Events:Subscribe('Partition:Loaded', onPartitionLoaded)
