-- IngameSpectator
-- shared variables for the ingame spectator


-- automatic routes for the freecam (will randomly cycle through when player joined the round without a player on it)
IngameSpectatorRoutes = {
    -- Vec3(x, y, z)
    -- Vec3(startpoint), Vec3(endpoint), Vec3(camera direction), tempo, title
    -- from outdoor pool to terrace
    {{40, 14, 0}, {-20, 24, 0}, {41, 15, 0}, 0.05, "Outdoor"},
    -- left upper doorway (outdoor pool) to elevator
    {{23, 17, 16}, {-35, 17, 16}, {24, 17, 16}, 0.05, "Left Upper Doorway"},
    -- right upper doorway (outdoor pool) to elevator
    {{29, 17, -20}, {-20, 17, -20}, {30, 17, -20}, 0.05, "Right Upper Doorway"},
    -- from elevator to upper doorway end
    {{-19, 17, 19}, {-19, 17, -29}, {-19, 17, 20}, 0.05, "Upper Elevator Way"},
    -- conference rooms end to end
    {{-32, 17, -30}, {-35, 17, 6}, {-33, 17, -47}, 0.05, "Conference Rooms"},
    -- indoor pool to elevator
    {{-50, 13, -11}, {-26, 13, 23}, {-51, 13, -13}, 0.05, "Indoor Pool"},
    -- patio from building to outdoor pool
    {{-23, 13, 8}, {50, 15, 8}, {-24, 13, 8}, 0.05, "Outdoor Pool"},
    -- left side terrace way
    {{26, 17, 40}, {0, 17, 40}, {27, 17, 40}, 0.05, "Terrace Way"},
    -- upper terrace way
    {{-20, 22, 12}, {-20, 22, -15}, {-20, 22, 12}, 0.05, "Upper Terrace Way"},
}
