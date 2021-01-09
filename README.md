# Kandru Prophunt for Battlefield 3

This mod is a working Prophunt solution for Battlefield 3. This will only work with [Venice Unleashed](https://veniceunleashed.net). Feel free to open issues and create pull requests. There is a lot of room for further improvement. Some of them are listed below.

## Installation and usage

Just copy all the kdr-prophunt to the Mods folder and add the mod name to the servers mod list and check on the configuration.lua on the server side folder. Join our [Discord](https://discord.kandru.net) for help.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change. Join our [Discord](https://discord.kandru.net) to discuss new contributions with us.

## Features
- different camera modes
  - free cam
  - automatic camera
  - third person camera
- improved UI
  - shows you all keys that can be used
  - improved scoreboard
- whistling
  - using ingame sounds to expose own position
  - automatically make whistle sounds every 30 to 60 seconds
- revenge mode
  - the last x hiders will get a weapon to be able to shoot back
  - the seekers still can shoot the hiders at this point but may get killed, too
- random prop
  - you can change your prop randomly every few seconds

## Roadmap
This is a list of things we are currently improving. Please contact me first via [Discord](https://discord.kandru.net) when you want to help me with a specific bug / improvement / feature to avoid double work.

### Known bugs
- hitbox of hider is sometimes bigger than a prop (not able to correctly align with the wall or other stuff to hide properly)
- props do not get synchronised when joining server (client is requesting prop data too early)
- scoreboard does not show correct ping of players (seems to be VU sync issue)
- hiders can reach higher map points due to higher jump ability due to third person camera
- increased rubber banding when much seekers are online and shooting
- some props are "lagging" when moving

### Improvements
- show hider name of seeker when seeker is closer then X metres
- stamina
- hider without soldier PhysicEntity to avoid collisions (only prop physics)
- slow mode for hiders for better availability to position the prop
- crouch indicator
- jump indicator
- show message in which distance a sound got made
- working statistics (score, kills, deaths)

### Features
- spawn random props on map to avoid "knowing" where props normally spawn
- spawn into existing props (e.g. Witch It style)