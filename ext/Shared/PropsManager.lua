-- whitelist
-- shared functions for checking whether a prop is allowed or not

-- initialize empty RandomPropsBlueprints
RandomPropsBlueprints = {}

--whitelisted props
PlayerPropsWhitelist = {
    ['Levels/XP2_Skybar/XP2_Skybar'] = {
        ['XP2/Objects/FloorVase_01/FloorVase_01'] = {
            ['name'] = 'Floor Vase',
            ['additionalMeshes'] = {
                ['XP2/Objects/Plant_01/Plant_01'] = {
                    ['position'] = Vec3(0, 0, 0)
                },
            }
        },
        ['XP2/Objects/SkybarPlanters_01/SkybarPlanterRound_01'] = {
            ['name'] = 'Planter Round',
            ['additionalMeshes'] = {
                ['XP2/Objects/BushPlant_01/BushPlant_01'] = {
                    ['position'] = Vec3(0, 0.8, 0)
                },
            }
        },
        -- pool
        ['XP2/Objects/SunBed/SunBed'] = {['name'] = 'Sun Bed'},
        ['XP2/Objects/Parasol_01/Parasol_01'] = {['name'] = 'Parasol'},
        -- bar
        ['XP2/Objects/SkybarBarDesk_01/SkybarBarDesk_01'] = {['name'] = 'Desk'},
        ['XP2/Objects/SkybarBarDesk_01/SkybarBarDeskCorner_01'] = {['name'] = 'Desk Corner'},
        ['XP2/Objects/SkybarDesk_01/SkybarDesk_01'] = {['name'] = 'Desk'},
        ['XP2/Objects/SkybarDesk_01/SkybarDeskCorner_01'] = {['name'] = 'Desk Corner'},
        ['XP2/Objects/SkybarBarStool_01/SkybarBarStool_01'] = {['name'] = 'Bar Stool'},
        -- diner
        ['XP2/Objects/SkybarDiner/SkybarDiner_Table'] = {['name'] = 'Dining Table'},
        ['XP2/Objects/SkybarDiner/SkybarDiner_Chair'] = {['name'] = 'Dining Chair'},
        -- interior
        ['XP2/Objects/SkybarArmchair_01/SkybarArmchair_01']  = {['name'] = 'Arm Chair'},
        ['XP2/Objects/SkybarArmchair_02/SkybarArmchair_02']  = {['name'] = 'Arm Chair'},
        ['XP2/Objects/SkybarSofa_01/SkybarSofa_01'] = {['name'] = 'Sofa'},
        ['XP2/Objects/SkybarSofa_02/SkybarSofa_02'] = {['name'] = 'Sofa'},
        ['XP2/Objects/LowTable_01/LowTable_01'] = {['name'] = 'Table small'},
        ['XP2/Objects/LampFloor_01/LampFloor_01_Medium'] = {['name'] = 'Lamp Medium'},
        ['XP2/Objects/LampFloor_01/LampFloor_01_Big'] = {['name'] = 'Lamp Small'},
        -- small objects
        ['XP2/Objects/Glassware/bottles_02'] = {['name'] = 'Bottles'},
        ['XP2/Objects/Towel_01/Towel_01'] = {['name'] = 'Towel'},
        ['XP2/Objects/Skybar_Decoration/Skybar_dec_vase_01'] = {['name'] = 'Decoration Vase'},
        ['XP2/Objects/Skybar_Decoration/Skybar_dec_vase_02'] = {['name'] = 'Decoration Vase'},
        ['XP2/Objects/Skybar_Decoration/Skybar_dec_vase_03'] = {['name'] = 'Decoration Vase'},
        ['XP2/Objects/Skybar_Decoration/Skybar_Artwork_01'] = {['name'] = 'Artwork 01'},
        ['Objects/Computer_01/Computer_SP_Paris_01'] = {['name'] = 'Computer Monitor'},
        ['Objects/Binders_01/BinderCluster_03'] = {['name'] = 'Books'},
        -- kitchen
        ['XP2/Objects/Kitchen/Kitchen_GrillTable_01'] = {['name'] = 'Grill Table'},
        ['Objects/StoveLuxury_01/StoveLuxury_02'] = {['name'] = 'Luxury Stove'},
        ['XP2/Objects/Kitchen/Kitchen_Oven_01'] = {['name'] = 'Kitchen Oven'},
        ['XP2/Objects/Kitchen/Kitchen_Oven_02'] = {['name'] = 'Kitchen Oven'},
        ['XP2/Objects/Kitchen/Kitchen_Drawers_01'] = {['name'] = 'Kitchen Drawers'},
        ['XP2/Objects/Kitchen/Kitchen_CupBoard_01'] = {['name'] = 'Kitchen cup board small'},
        ['XP2/Objects/Kitchen/Kitchen_CupBoard_02'] = {['name'] = 'Kitchen cup board big'},
        ['XP2/Objects/Kitchen/Kitchen_Bench_01'] = {['name'] = 'Kitchen bench'},
        ['XP2/Objects/Kitchen/Kitchen_Sink_01'] = {['name'] = 'Kitchen sink'},
        ['XP2/Objects/Kitchen/Kitchen_Fridge_01'] = {['name'] = 'Fridge'},
        -- office
        ['XP2/Objects/Television_01/Television_01'] = {['name'] = 'Television'},
        ['XP2/Objects/Cabinet_01/Cabinet01_01'] = {['name'] = 'Cabinet'},
        ['XP2/Objects/Chair_01/Chair_01'] = {['name'] = 'Ôffice Chair'},
        ['XP2/Objects/ConferenceTable_01/ConferenceTable_01'] = {['name'] = 'Conference Table'},
        ['XP2/Objects/ConferenceTable_02/ConferenceTable_02'] = {['name'] = 'Conference Table'},
        -- bathroom
        ['XP2/Objects/BathroomZinkDouble_01/BathroomZinkDouble_01'] = {['name'] = 'Bath double sink'},
        ['XP2/Objects/Toilet_01/Toilet_01'] = {['name'] = 'Toilet'},
        ['XP2/Objects/Toilet_02/Toilet_02'] = {['name'] = 'Toilet'},
        -- bedroom
        ['XP2/Objects/LuxuryBed_02/Luxury_Bed_02'] = {['name'] = 'Luxury Bed'},
        ['XP2/Objects/LuxuryBed_02/LuxuryBed_02_Gavel'] = {['name'] = 'Bed Gavel'},
        ['XP2/Objects/Trellis/Trellis_01'] = {['name'] = 'Trellis'},
        ['XP2/Objects/Trellis/Trellis_02'] = {['name'] = 'Trellis'},
        ['XP2/Objects/SkybarRoomDivider/SkybarRoomDivider'] = {['name'] = 'Room Divider'},
        -- misc
        ['XP2/Objects/Painting_01/Painting_01'] = {['name'] = 'Painting', ['position'] = Vec3(0, 0.6, 0)},
        ['XP2/Objects/Painting_01/Painting_02'] = {['name'] = 'Painting', ['position'] = Vec3(0, 0.6, 0)},
        ['Objects/AntennaParts_01/AntennaSet_2'] = {['name'] = 'Big Antenna'},
    },
}

-- populate random props for all levels
for level, props in pairs(PlayerPropsWhitelist) do
    if RandomPropsBlueprints[level] == nil then
        RandomPropsBlueprints[level] = {}
    end
    for id, prop in pairs(props) do
        table.insert(RandomPropsBlueprints[level], id)
    end
end

function isMeshWhitelisted(mesh)
    local level = SharedUtils:GetLevelName()
    -- if mesh is nil return false
    if mesh == nil then
        return false
    end
    -- when level is nil return false
    if level == nil then
        return false
    end
    -- get whitelist for this level
    local tmpWhitelist = PlayerPropsWhitelist[level]
    -- return false when there is no whitelist for this level
    if tmpWhitelist == nil then
        return false
    end
    -- iterate through the whitelist and return meshData when we found the prop
    for id, meshData in pairs(tmpWhitelist) do
        if string.find(string.lower(mesh), string.lower(id)) then
            return meshData
        end
    end
    -- return false otherwise
    return false
end

return isMeshWhitelisted
