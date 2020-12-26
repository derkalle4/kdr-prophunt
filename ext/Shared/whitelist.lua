-- whitelist
-- shared functions for checking whether a prop is allowed or not


local blacklist = {
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


local function isMeshWhitelisted(mesh)
    local meshName = mesh.name
    meshName = string.lower(meshName)
    debugMessage('isMeshWhitelisted: ' .. meshName)
    local level = SharedUtils:GetLevelName()

    if level == nil then
        debugMessage('Level not found. Skipping prop change.')
        return false
    end

    local blacklistedMeshes = blacklist[level]

    if blacklistedMeshes == nil then
        debugMessage('No blacklist found. Skipping prop change.')
        return false
    end

    for _, blacklistedMesh in pairs(blacklistedMeshes) do
        if string.find(meshName, blacklistedMesh) then
            debugMessage('prop blacklisted. Skipping prop change.')
            return false
        end
    end

    return true
end

return isMeshWhitelisted
