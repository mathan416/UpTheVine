# Up the Vine

`Up the Vine` is a Playdate arcade platformer about climbing, bouncing, and scrambling through a jungle canopy while collecting diamonds and dodging enemies.

Start on a platform, grab vines, collect every diamond, and survive long enough for the jungle to grow around you. Each cleared set of collectables advances the level, restores your lives, and adds another vine to the screen.

## Controls

| Input | Action |
| --- | --- |
| A | Start from the splash screen |
| D-pad Left / Right | Move on the platform or while airborne |
| D-pad Up / Down | Climb while attached to a vine |
| A | Jump from the ground or from a vine |
| B | Ground pound while airborne |
| B | Drop from a vine into a ground pound |
| System Menu | Toggle mute or view credits |

## Gameplay

- Collect diamonds to score points.
- Clear all diamonds to advance to the next level.
- New vines and collectables appear as levels progress.
- Avoid vine enemies and flying enemies.
- Getting hit costs one life and gives the player a short invincibility window.
- The game ends when lives reach zero.
- High scores are saved with Playdate datastore support.

## Features

- Splash, gameplay, game over, and credits screens.
- Animated player, collectables, vine enemies, and flying enemies.
- Procedurally placed vines, diamonds, and enemies.
- Title music, pickup sounds, hit sounds, game over audio, and movement shuffle audio.
- Mute toggle in the Playdate system menu.
- Persistent high score storage.

## Project Structure

| Path | Purpose |
| --- | --- |
| `main.lua` | Entry point required by `pdc`; imports `UpTheVine.lua` |
| `UpTheVine.lua` | Main game loop, state transitions, HUD, menu items, and lifecycle hooks |
| `player.lua` | Player movement, climbing, jumping, ground pound, collisions, and animation |
| `level.lua` | Level setup, vine spawning, collectable spawning, and level progression |
| `vine.lua` | Vine sprite drawing and geometry helpers |
| `collectable.lua` | Diamond collectable animation and cleanup |
| `vineenemy.lua` | Enemy that patrols vertically along vines |
| `flyingenemy.lua` | Enemy that moves horizontally across the screen |
| `platform.lua` | Platform collision sprite |
| `particle.lua` | Hit and bounce particle effects |
| `sound.lua` | Music, SFX, mute state, and audio lifecycle handling |
| `highscore.lua` | Saved high score data |
| `constants.lua` | Collision groups and debug flag |
| `images/` | Playdate image assets |
| `sounds/` | Launch/title audio |
| `pdxinfo` | Playdate package metadata |

## Development

This project is a Playdate Lua game. You need the [Playdate SDK](https://play.date/dev/) installed, with `pdc` and the Playdate Simulator available from the SDK.

Build the game from the project directory:

```sh
pdc -k . UpTheVine.pdx
```

Run the built game in the Playdate Simulator:

```sh
open UpTheVine.pdx
```

If your SDK tools are not on your shell path, use the full path to `pdc`, for example:

```sh
~/Developer/PlaydateSDK/bin/pdc -k . UpTheVine.pdx
```

## Credits

- Created by: Iain Bennett
- Programming: Iain Bennett
- Art and design: Chris Hagen, Iain Bennett
- Music and sound: Iain Bennett, Aaron Sheppard

## Package Metadata

- Name: `Up the Vine`
- Author: `Mathan Games`
- Bundle ID: `com.mathanca.utv2`
- Version: `1.0`
- Build number: `13`
