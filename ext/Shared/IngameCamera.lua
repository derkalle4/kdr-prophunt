-- IngameSpectator
-- shared variables for the ingame spectator


-- automatic routes for the freecam (will randomly cycle through when player joined the round without a player on it)
IngameSpectatorRoutes = {
    -- Vec3(x, y, z)
    -- Vec3(startpoint), Vec3(endpoint), Vec3(camera direction), tempo, title
    -- from outdoor pool to terrace
    ['Levels/XP2_Skybar/XP2_Skybar'] = {
        {{40, 34, 0}, {-5, 54, 0}, {41, 35, 0}, 0.05, "Outdoor"},
        -- left upper doorway (outdoor pool) to elevator
        {{23, 17, 16}, {-25, 17, 16}, {24, 17, 16}, 0.05, "Left Upper Doorway"},
        -- right upper doorway (outdoor pool) to elevator
        {{29, 17, -20}, {-10, 17, -20}, {30, 17, -20}, 0.05, "Right Upper Doorway"},
        -- from elevator to upper doorway end
        {{-19, 17, 19}, {-19, 17, -29}, {-19, 17, 20}, 0.05, "Upper Elevator Way"},
        -- conference rooms end to end
        {{-32, 17, -30}, {-35, 17, 6}, {-33, 17, -47}, 0.05, "Conference Rooms"},
        -- indoor pool to elevator
        {{-50, 13, -11}, {-26, 13, 23}, {-51, 13, -13}, 0.05, "Indoor Pool"},
        -- patio from building to outdoor pool
        {{-23, 13, 8}, {35, 15, 8}, {-24, 13, 8}, 0.05, "Outdoor Pool"},
        -- left side terrace way
        {{26, 17, 40}, {0, 17, 40}, {27, 17, 40}, 0.05, "Terrace Way"},
        -- upper terrace way
        {{-20, 22, 12}, {-20, 22, -5}, {-20, 22, 12}, 0.05, "Upper Terrace Way"},
    },
    ['Levels/XP2_Office/XP2_Office'] = {
        {{32, 9, -4}, {32, 9, -60}, {32, 9, -3}, 0.05, "Conference Rooms"},
        {{32, 9, -60}, {12, 9, -60}, {33, 9, -60}, 0.05, "Cafe Holo"},
        {{7, 9, -54}, {-33, 9, -54}, {6, 9, -54}, 0.05, "Office Area"},
        {{-85, 6, -10}, {-85, 6, -56}, {-85, 6, -9}, 0.05, "Main Entrance"},
    },
}
