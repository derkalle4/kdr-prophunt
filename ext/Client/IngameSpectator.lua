-- IngameSpectator
-- specator function in case player dies or joined lately

class('IngameSpectator')

function IngameSpectator:__init()
    self._allowSpectateAll = false
    self._spectatedPlayer = nil
    self._firstPerson = true
    self._freecamTrans = LinearTransform()
    self._lastEngineUpdate = 0.0
    self._freecamAutomaticRoute = {}
    self:enable()

    Events:Subscribe('Extension:Unloading', self, self.disable)
    Events:Subscribe('Player:Respawn', self, self._onPlayerRespawn)
    Events:Subscribe('Player:Killed', self, self._onPlayerKilled)
    Events:Subscribe('Player:Deleted', self, self._onPlayerDeleted)
    Events:Subscribe('Engine:Update', self, self._onEngineUpdate)
    Events:Subscribe('Player:UpdateInput', self, self._onPlayerInput)
end

function IngameSpectator:_onPlayerInput(deltaTime)
    local localPlayer = PlayerManager:GetLocalPlayer()
    -- only when player is spectator
    if localPlayer.alive then
        return
    end
    -- spectate previous player
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_1) then
        self:spectateNextPlayer()
    end
    -- spectate next player
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_2) then
        self:switchToFreecam()
    end
end

function IngameSpectator:_onEngineUpdate(deltaTime)
    -- run event only every 0.05 seconds to save CPU time
    if self._lastEngineUpdate >= 0.01 then
        self._lastEngineUpdate = 0.0
        -- automatic route selection for freecam (no real freecam yet just automatic routes for "movie like way to show current round")
        if self:isEnabled() and self._spectatedPlayer == nil then
            -- select new automatic route when round is complete or not started yet
            if #self._freecamAutomaticRoute == 0 or Vec3(self._freecamAutomaticRoute[2][1], self._freecamAutomaticRoute[2][2], self._freecamAutomaticRoute[2][3]):Distance(self._freecamTrans.trans) <= 3.0  then
                -- get new automatic route
                math.randomseed(SharedUtils:GetTimeMS())
                local randomNumber = MathUtils:GetRandomInt(1, #IngameSpectatorRoutes)
                self._freecamAutomaticRoute = IngameSpectatorRoutes[randomNumber]
                local startpoint = self._freecamAutomaticRoute[1]
                local viewpoint = self._freecamAutomaticRoute[3]
                local name = self._freecamAutomaticRoute[5]
                WebUI:ExecuteJS('setSpectatorMessage("' .. name .. '");')
                debugMessage('IngameSpectator loading ' .. name)
                -- set start point of new automatic route
                self._freecamTrans.trans = Vec3(
                    startpoint[1],
                    startpoint[2],
                    startpoint[3]
                )
                -- set view direction of new automatic route
                self._freecamTrans:LookAtTransform(
                    Vec3(
                        startpoint[1],
                        startpoint[2],
                        startpoint[3]
                    ),
                    Vec3(
                        viewpoint[1],
                        viewpoint[2],
                        viewpoint[3]
                    )
                )
            end
            -- if we have a automatic route just go through it
            if #self._freecamAutomaticRoute > 2 then
                -- move Vec3 position forward to goal
                local endpoint = self._freecamAutomaticRoute[2]
                local tempo = self._freecamAutomaticRoute[4]
                self._freecamTrans.trans = Vec3(self._freecamTrans.trans):MoveTowards(
                    Vec3(
                        endpoint[1],
                        endpoint[2],
                        endpoint[3]
                    )
                , tempo)
                -- move player camera
                self:setFreecamTransform(self._freecamTrans)
            end
        end
    end
    -- increase self._lastEngineUpdate value
    self._lastEngineUpdate = self._lastEngineUpdate + deltaTime
end

function IngameSpectator:_onPlayerRespawn(player)
    if not self:isEnabled() then
        return
    end

    -- Disable spectator when the local player spawns.
    local localPlayer = PlayerManager:GetLocalPlayer()

    if localPlayer == player then
        self:disable()
        return
    end

    -- If we have nobody to spectate and this player is spectatable
    -- then switch to them.
    if self._spectatedPlayer == nil then
        if localPlayer.alive and not self._allowSpectateAll and player.teamId ~= localPlayer.teamId then
            return
        end

        self:spectatePlayer(player)
    end
end

function IngameSpectator:_onPlayerKilled(player)
    if not self:isEnabled() then
        return
    end

    -- Handle death of player being spectated.
    if player == self._spectatedPlayer then
        self:spectateNextPlayer()
    end
end

function IngameSpectator:_onPlayerDeleted(player)
    if not self:isEnabled() then
        return
    end

    -- Handle disconnection of player being spectated.
    if player == self._spectatedPlayer then
        self:spectateNextPlayer()
    end
end

function IngameSpectator:_findFirstPlayerToSpectate()
    local playerToSpectate = nil
    local players = PlayerManager:GetPlayers()
    local localPlayer = PlayerManager:GetLocalPlayer()

    for _, player in pairs(players) do
        -- We don't want to spectate the local player.
        if player == localPlayer then
            goto continue_enable
        end

        -- We don't want to spectate players who are dead.
        if player.soldier == nil then
            goto continue_enable
        end

        -- If we don't allow spectating everyone we should check the
        -- player's team to determine if we can spectate them.
        if localPlayer.alive and not self._allowSpectateAll and player.teamId ~= localPlayer.teamId then
            goto continue_enable
        end

        -- Otherwise we're good to spectate this player.
        playerToSpectate = player
        break

        ::continue_enable::
    end

    return playerToSpectate
end

function IngameSpectator:getFreecamTransform()
    return self._freecamTrans
end

function IngameSpectator:setFreecamTransform(trans)
    self._freecamTrans = trans

    if self:isEnabled() and self._spectatedPlayer == nil then
        SpectatorManager:SetFreecameraTransform(self._freecamTrans)
    end
end

function IngameSpectator:getAllowSpectateAll()
    return self._allowSpectateAll
end

function IngameSpectator:setAllowSpectateAll(allowSpectateAll)
    local prevSpectateAll = self._allowSpectateAll
    self._allowSpectateAll = allowSpectateAll

    -- If we no longer allow spectating everyone we will need to make sure
    -- that the player we're currently spectating is in the same team as us.
    if prevSpectateAll ~= allowSpectateAll and self:isEnabled() and not allowSpectateAll then
        local localPlayer = PlayerManager:GetLocalPlayer()

        -- If they're not we'll try to find one we can spectate and switch
        -- to them. If we can't, we'll just switch to freecam.
        if localPlayer.teamId ~= self._spectatedPlayer.teamId then
            local playerToSpectate = self:_findFirstPlayerToSpectate()

            if playerToSpectate == nil then
                self:switchToFreecam()
            else
                self:spectatePlayer(playerToSpectate)
            end
        end
    end
end

function IngameSpectator:getFirstPerson()
    return self._firstPerson
end

function IngameSpectator:setFirstPerson(firstPerson)
    local prevFirstPerson = self._firstPerson
    self._firstPerson = firstPerson

    -- If we're enabled and we switched modes then we also need to switch
    -- spectating modes. We do this just by calling the spectatePlayer
    -- function and it should handle the rest automatically.
    if prevFirstPerson ~= firstPerson and self:isEnabled() and self._spectatedPlayer ~= nil then
        self:spectatePlayer(self._spectatedPlayer)
    end
end

function IngameSpectator:enable()
    if self:isEnabled() then
        return
    end

    -- If we're alive we don't allow spectating.
    local localPlayer = PlayerManager:GetLocalPlayer()

    if localPlayer.alive then
        return
    end

    SpectatorManager:SetSpectating(true)

    local playerToSpectate = self:_findFirstPlayerToSpectate()

    if playerToSpectate ~= nil then
        self:spectatePlayer(playerToSpectate)
        return
    end

    -- If we found no player to spectate then just do freecam.
    self:switchToFreecam()
end

function IngameSpectator:disable()
    if not self:isEnabled() then
        return
    end

    SpectatorManager:SetSpectating(false)

    self._spectatedPlayer = nil
end

function IngameSpectator:spectatePlayer(player)
    debugMessage('IngameSpectator spectatePlayer ')
    if not self:isEnabled() then
        return
    end

    if player == nil then
        self:switchToFreecam()
        return
    end

    local localPlayer = PlayerManager:GetLocalPlayer()

    -- We can't spectate the local player.
    if localPlayer == player then
        return
    end

    -- If we don't allow spectating everyone make sure that this player
    -- is in the same team as the local player.
    if localPlayer.alive or (not self._allowSpectateAll and localPlayer.teamId ~= player.teamId) then
        debugMessage('local player still alive')
        return
    end

    WebUI:ExecuteJS('setSpectatorMessage("' .. player.name .. '");')

    self._spectatedPlayer = player
    SpectatorManager:SpectatePlayer(self._spectatedPlayer, self._firstPerson)
end

function IngameSpectator:spectateNextPlayer()
    if not self:isEnabled() then
        return
    end

    -- If we are not spectating anyone just find the first player to spectate.
    if self._spectatedPlayer == nil then
        local playerToSpectate = self:_findFirstPlayerToSpectate()

        if playerToSpectate ~= nil then
            self:spectatePlayer(playerToSpectate)
        else
            self:switchToFreecam()
        end

        return
    end

    -- Find the index of the current player.
    local currentIndex = 0
    local players = PlayerManager:GetPlayers()
    local localPlayer = PlayerManager:GetLocalPlayer()

    for i, player in players do
        if player == self._spectatedPlayer then
            currentIndex = i
            break
        end
    end

    -- Increment so we start from the next player.
    currentIndex = currentIndex + 1

    if currentIndex > #players then
        currentIndex = 1
    end

    -- Find the next player we can spectate.
    local nextPlayer = nil

    for i = 1, #players do
        local playerIndex = (i - 1) + currentIndex

        if playerIndex > #players then
            playerIndex = playerIndex - #players
        end

        local player = players[playerIndex]

        if player.soldier ~= nil and player ~= localPlayer and (not localPlayer.alive or self._allowSpectateAll or player.teamId == localPlayer.teamId) then
            nextPlayer = player
            break
        end
    end

    -- If we didn't find any players to spectate then switch to freecam.
    if nextPlayer == nil then
        self:switchToFreecam()
    else
        self:spectatePlayer(nextPlayer)
    end
end

function IngameSpectator:spectatePreviousPlayer()
    if not self:isEnabled() then
        return
    end

    -- If we are not spectating anyone just find the first player to spectate.
    if self._spectatedPlayer == nil then
        local playerToSpectate = self:_findFirstPlayerToSpectate()

        if playerToSpectate ~= nil then
            self:spectatePlayer(playerToSpectate)
        end

        return
    end

    -- Find the index of the current player.
    local currentIndex = 0
    local players = PlayerManager:GetPlayers()
    local localPlayer = PlayerManager:GetLocalPlayer()

    for i, player in players do
        if player == self._spectatedPlayer then
            currentIndex = i
            break
        end
    end

    -- Decrement so we start from the previous player.
    currentIndex = currentIndex - 1

    if currentIndex <= 0 then
        currentIndex = #players
    end

    -- Find the previous player we can spectate.
    local nextPlayer = nil

    for i = #players, 1, -1 do
        local playerIndex = (i - (#players - currentIndex))

        if playerIndex <= 0 then
            playerIndex = playerIndex + #players
        end

        local player = players[playerIndex]

        if player.soldier ~= nil and player ~= localPlayer and (not localPlayer.alive or self._allowSpectateAll or player.teamId == localPlayer.teamId) then
            nextPlayer = player
            break
        end
    end

    -- If we didn't find any players to spectate then switch to freecam.
    if nextPlayer == nil then
        self:switchToFreecam()
    else
        self:spectatePlayer(nextPlayer)
    end
end

function IngameSpectator:switchToFreecam()
    debugMessage('IngameSpectator switchToFreecam')
    if not self:isEnabled() then
        debugMessage('spectator disabled')
        return
    end

    self._spectatedPlayer = nil

    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer.alive then
        debugMessage('local player still alive')
        return
    end
    self._freecamAutomaticRoute = {}

    SpectatorManager:SetCameraMode(SpectatorCameraMode.FreeCamera)
    SpectatorManager:SetFreecameraTransform(self._freecamTrans)
end

function IngameSpectator:isEnabled()
    return SpectatorManager:GetSpectating()
end

if g_IngameSpectator == nil then
    g_IngameSpectator = IngameSpectator()
end

return g_IngameSpectator
