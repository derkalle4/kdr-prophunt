-- NameTags
-- sets nametags depending on which team a player is


local nameTagHeight = 1.8 -- height of nameTagHeight
local textColorDefault = Vec4(1, 1, 1, 0.8) -- default text color
local textColorRed = Vec4(1, 0, 0, 0.8) -- text color for hider
local textColorGreen = Vec4(0, 1, 0, 0.8) -- text color for seeker

-- transform soldier to world screen position
local function playerTrans(player, height)
    -- get player trwans
    local playerTrans = player.soldier.transform.trans:Clone()
    -- set height of nametag
    playerTrans.y = playerTrans.y + height
    -- get player world screen position
    return ClientUtils:WorldToScreen(playerTrans)
end

-- on render UI
local function onUiDrawHud()
    -- get all players
    local players = PlayerManager:GetPlayers()
    -- get local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- iterate through all players
    for _, player in pairs(players) do
        -- check whether player does exist
        if player == nil then
            goto continue
        end
        -- check whether local player does exist
        if localPlayer == nil then
            goto continue
        end
        -- only spawned players
        if player.soldier == nil then
            goto continue
        end
        -- check whether player is in same team or if player is spectator or GameState is postRound
        if localPlayer.teamId ~= 0 and localPlayer.teamId ~= player.teamId and currentState.roundState ~= GameState.postRound then
            goto continue
        end
        -- check whether we are that player (we do not need our nametag)
        if localPlayer == player then
            goto continue
        end
        -- get player position for name tag
        local screenPosNameTag = playerTrans(player, nameTagHeight)
        -- check if screenPos is nil
        if screenPosNameTag == nil then
            goto continue
        end
        -- default text color
        local textColor = textColorDefault
        -- default team text
        local teamText = '[UNKNOWN] '
        -- check for team and set text + color
        if player.teamId == 1 then
            teamText = '[SEEKER] '
            textColor = textColorRed
        elseif player.teamId == 2 then
            teamText = '[HIDER] '
            textColor = textColorGreen
        end
        -- overwrite text color to show own team green and other one red (if applicable)
        if localPlayer.teamId == player.teamId then
            textColor = textColorGreen
        elseif localPlayer.teamId ~= 0 then
            textColor = textColorRed
        end
        -- draw nametag
        DebugRenderer:DrawText2D(screenPosNameTag.x, screenPosNameTag.y, teamText .. player.name, textColor, 1.0)
        :: continue ::
    end
end

-- event UI:DrawHud
Events:Subscribe('UI:DrawHud', onUiDrawHud)
