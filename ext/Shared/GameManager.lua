-- GameManager
-- shared variables for GameManager


-- game state types
GameState = {
    idle = 0,
    preRound = 1,
    hiding = 2,
    seeking = 3,
    postRound = 4,
    mapChange = 5,
}

-- game message types
GameMessage = {
    C2S_CLIENT_READY = "phclr",
    C2S_PROP_DAMAGE = "phpd",
    C2S_PROP_CHANGE = "phprchange",
    S2C_GAME_SYNC = "phgsync",
    S2C_PLAYER_SYNC = "phpsync",
    S2C_PROP_SYNC = "phprsync",
    C2S_QUIT_GAME = "phpquit",
    C2S_PROP_SOUND = "phpsound",
    S2C_SOUND_SYNC = "phssync",
}
