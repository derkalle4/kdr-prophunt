-- GameManager
-- shared variables for GameManager


-- game state types
GameState = {
    idle = 0,
    preRound = 1,
    hiding = 2,
    seeking = 3,
    revenge = 4,
    postRound = 5,
    mapChange = 6,
}

-- game message types
GameMessage = {
    C2S_CLIENT_READY = "phclr",
    C2S_CLIENT_SYNC = "phcls",
    C2S_PROP_DAMAGE = "phpd",
    C2S_PROP_CHANGE = "phprchange",
    S2C_GAME_SYNC = "phgsync",
    S2C_PLAYER_SYNC = "phpsync",
    S2C_PROP_SYNC = "phprsync",
    C2S_QUIT_GAME = "phpquit",
    C2S_PROP_SOUND = "phpsound",
    S2C_SOUND_SYNC = "phssync",
}

-- the current state of the game (will be synced to client)
currentState = {
    roundTimer = 0.0,
    roundState = GameState.idle,
    roundStatusMessage = 'Waiting',
    numPlayer = 0,
    totalNumSeeker = 0,
    numSeeker = 0,
    totalNumHider = 0,
    numHider = 0,
    numSpectator = 0,
    winner = 0
}
