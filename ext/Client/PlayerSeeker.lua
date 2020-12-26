-- PlayerSeeker
-- client side UI logic for making players to seeker


local function onPlayerSync(playerID, teamID)
    debugMessage('[S2C_PLAYER_SYNC] for ' .. playerID)
    local player = PlayerManager:GetPlayerById(playerID)
    local isLocalPlayer = PlayerManager:GetLocalPlayer() == player
    -- check for local player and whether he is in the prop team
    if isLocalPlayer and isSeekerByTeamID(teamID) then
        debugMessage('[S2C_PLAYER_SYNC] local player ' .. playerID .. ' is a seeker')
        -- set user team for UI
        WebUI:ExecuteJS('setUserTeam(1);')
    end
end

-- events and hooks
NetEvents:Subscribe(GameMessage.S2C_PLAYER_SYNC, onPlayerSync)
