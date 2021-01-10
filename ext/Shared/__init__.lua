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
        -- remove blue background
        if instance.instanceGuid == Guid('9CDAC6C3-9D3E-48F1-B8D9-737DB28AE936') then -- menu UI/Assets/MenuVisualEnvironment
            local s_Instance = ColorCorrectionComponentData(instance)
            s_Instance:MakeWritable()
            s_Instance.enable = false
            s_Instance.brightness = Vec3(1, 1, 1)
            s_Instance.contrast = Vec3(1, 1, 1)
            s_Instance.saturation = Vec3(1, 1, 1)
        end
        -- remove blur
        if instance.instanceGuid == Guid('52FD86B6-00BA-45FC-A87A-683F72CA6916') then -- menu UI/Assets/MenuVisualEnvironment
            local s_Instance = DofComponentData(instance)
            s_Instance:MakeWritable()
            s_Instance.enable = false
            s_Instance.blurAdd = 0.0
        end
        -- remove outofcombat color correction
        if instance.instanceGuid == Guid('46FE1C37-5B7E-490C-8239-2EB2D6045D7B') then -- oob FX/VisualEnviroments/OutofCombat/OutofCombat
            local s_Instance = ColorCorrectionComponentData(instance)
            s_Instance:MakeWritable()
            s_Instance.enable = false
            s_Instance.brightness = Vec3(1, 1, 1)
            s_Instance.contrast = Vec3(1, 1, 1)
            s_Instance.saturation = Vec3(1, 1, 1)
        end
        -- remove out of combat filmgrain
        if instance.instanceGuid == Guid('36C2CEAE-27D2-45F3-B3F5-B831FE40ED9B') then -- FX/VisualEnviroments/OutofCombat/OutofCombat
            local s_Instance = FilmGrainComponentData(instance)
            s_Instance:MakeWritable()
            s_Instance.enable = false
        end
       -- remove water from being considered physically, so bullet entity collisions occur on props hiding in water too
        if instance:Is('WaterAsset') then
            if instance:Is('WaterAsset') then
                partition:RemoveInstance(instance)
            end
        end
        -- make soldier world collision model smaller in radius so you can get closer to objects
            -- soldier has a cylindrical model, you can also set CharacterPoseData.height to something higher for manipulating the height
            -- of the cylinder - this is not done because you never know where players can get if they're that small in height)
        -- all default values available in https://github.com/EmulatorNexus/Venice-EBX/blob/master/Characters/Soldiers/DefaultSoldierPhysics.txt
        if instance:Is('CharacterPhysicsData') then
            local s_Instance = CharacterPhysicsData(instance)
            s_Instance:MakeWritable()
            s_Instance.physicalRadius = 0.05
        end
    end
end

-- events and hooks
Events:Subscribe('Partition:Loaded', onPartitionLoaded)
