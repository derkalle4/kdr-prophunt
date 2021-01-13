-- configuration
-- complete gamemode configuration. Change to anything you want

Config = {
    IdleTime = 16, -- 16 - time in seconds in which the idle round will start (even on a new round. Should be above 10 secs to allow all players to load game)
    PreRoundTime = 15, -- 15 - time in seconds in which players are spawned and before round begins
    HidingTime = 30, -- 30 - time Hiders do have to hide themselves without being catched by Seekers
    SeekingTime = 300, -- 300 - time Seekers have to find all Hiders
    RevengeTime = 60, -- 60 - time the revenge mode lasts
    PostRoundTime = 15, -- 15 - time before map reload
    MinPlayers = 2, -- 2 - Minimum amount of players required to start a game
    AmountHiderForRevenge = 1, -- 1 - number of left alive hiders which will go into revenge mode
    MinTotalHiderForRevenge = 8, -- 2 - minimal number of hiders which have to be spawned during round before activating mode when AmountHiderForRevenge is reached
    PercenTageSeeker = 35, -- 35 - Percentage of seeker from users connected
    BulletShootDamage = 1, -- 2 - amount of damage a Seeker gets when he is not shooting at a player prop
    DamageToPlayerProp = 8, -- 8 - amount of damage a Seeker makes to a Hider with each bullet
    SeekerDamageFromPlayerProp = -10, -- -10 - amount of "damage" a Seeker gets when hitting a player (usually below 0 to gain health)
    SeekerHealth = 100, -- health of seeker
    HiderHealth = 50, -- health of hider when it cannot be determined automatically
    MaxHiderHealth = 300, -- maximum health of hider
}
