-- whitelist
-- shared functions for checking whether a prop is allowed or not


local PlayerPropsBlacklist = {
    ['Levels/XP2_Skybar/XP2_Skybar'] = {
        'invisiblecollision_',
        '/floor_',
        'facade_',
        'backdrop_',
        'cloth_',
        'rooftop_',
        'roofmodules',
        'waterplane_',
        'pillar_',
        'stairs_',
        'stairwall_',
        'trellis_',
        'carpet_',
        'decal',
        'debris',
        'destruction',
        'roof_',
        'splineoutside_',
        'beam_',
        'skybarwindows_',
        'rail_',
        'doorframe_',
        'pillarplaster_',
        'wallmodules',
        'smallpillow',
        'barshelves',
        'glasswall',
        'flower',
        'hoteldoor',
        'spotlight',
        'wallprops',
        'light_01',
        'plant_01',
        'bonsai',
        'bushfern',
        --'planters_01',
        'skybarsigns',
        'elevator',
        'mousekeyboard',
        'paperpile',
        'ziba_sign',
        'wallsquares',
        'pooltrim',
        --'floorvase',
        'ceilingpanel',
        'painting_01',
        'walldecoration_01',
        'walldecoration_02',
        'signrestaurantleft',
        'doorgeneric',
        'spline',
        --'parasol',
        'skybarrooflights',
        'showermodule',
        'palace_nightstand',
        'paintingbig_01',
        'paintingpanel',
        'skybarroomdivider',
        --'luxurybed_02',
        'kitchen_ventilation',
        'pergola',
        'railing_',
        'binder_01',
        'sprinkler',
        'ventilationsmall',
    },
    ['Levels/XP2_Office/XP2_Office'] = {
        'invisiblecollision_',
        'floor',
        'wall',
        'corridor',
        'laptop',
        'painting',
        'van',
        'car',
        'roof',
        'light',
        'street',
        'garage',
        'shell',
        'sprinkler',
        'binder',
        'ventilation',
        'door',
        'mouse',
        'keyboard',
        'elevator',
        'decall',
        'stairs',
        'spline',
        'shower',
        'pool',
        'sign',
        'carpet',
        'ceiling',
        'beam',
        'cloth',
        'facade',
        'water',
        'cafe',
        'section',
        'sky',
        'ground',
        'pipe',
        'copper',
    }
}

-- random prop blueprint list to choose from
RandomPropsBlueprints =  {
    ['Levels/XP2_Skybar/XP2_Skybar'] = {
        'XP2/Objects/SkybarBarStool_01/SkybarBarStool_01',
        'XP2/Objects/SunBed/SunBed',
        'XP2/Objects/SkybarBarDesk_01/SkybarBarDesk_01',
        'XP2/Objects/SkybarSofa_01/SkybarSofa_01',
        'XP2/Objects/LowTable_01/LowTable_01',
        'XP2/Objects/SkybarArmchair_02/SkybarArmchair_02',
        'XP2/Objects/SkybarArmchair_01/SkybarArmchair_01',
        'XP2/Objects/SkybarDiner/SkybarDiner_Chair',
        'XP2/Objects/LampFloor_01/LampFloor_01_Medium',
        'XP2/Objects/LampFloor_01/LampFloor_01_Big',
        'XP2/Objects/Towel_01/Towel_01',
        'Objects/Computer_01/Computer_SP_Paris_01',
        'XP2/Objects/SkybarDesk_01/SkybarDesk_01',
        'XP2/Objects/SkybarDesk_01/SkybarDeskCorner_01',
    },
    ['Levels/XP2_Office/XP2_Office'] = {
        'XP2/Objects/SkybarBarStool_01/SkybarBarStool_01',
    },
}

local function isMeshWhitelisted(mesh)
    local meshName = mesh.name
    meshName = string.lower(meshName)
    debugMessage('isMeshWhitelisted: ' .. meshName)
    local level = SharedUtils:GetLevelName()

    if level == nil then
        debugMessage('Level not found. Skipping prop change.')
        return false
    end

    local PlayerPropsBlacklistedMeshes = PlayerPropsBlacklist[level]

    if PlayerPropsBlacklistedMeshes == nil then
        debugMessage('No blacklisted found. Skipping prop change.')
        return false
    end

    for _, blacklistedMesh in pairs(PlayerPropsBlacklistedMeshes) do
        if string.find(meshName, blacklistedMesh) then
            debugMessage('prop blacklisted. Skipping prop change.')
            return false
        end
    end

    return true
end

return isMeshWhitelisted
