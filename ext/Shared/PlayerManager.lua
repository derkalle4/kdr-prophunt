-- PlayerManager
-- shared functions for the player manager


-- check whether a player is seeker
function isSeeker(player)
    if player == nil then
        return false
    end
    return player.teamId == TeamId.Team1
end

-- check whether a player is seeker by TeamID
function isSeekerByTeamID(teamID)
    if teamID == nil then
        return false
    end
    return teamID == TeamId.Team1
end

-- check whether a player is prop
function isProp(player)
    if player == nil then
        return false
    end
    return player.teamId == TeamId.Team2
end

-- check whether a player is prop by TeamID
function isPropByTeamID(teamID)
    if teamID == nil then
        return false
    end
    return teamID == TeamId.Team2
end

-- check whether a player is spectator
function isSpectator(player)
    if player == nil then
        return false
    end
    return player.teamId == TeamId.TeamNeutral
end
