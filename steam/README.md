# NEON-CASTER on Steam

The game has 45 Steam achievements and 12 stats, through the STEAM library
from [QB64_GJ_LIB](https://github.com/grymmjack/QB64_GJ_LIB) (a copy is in
`lib/steam`). They already work without Steam: until the game has a Steam
App ID, or whenever Steam isn't running, the library's stand-in (the
"mock") keeps them in `neon-caster/saves/achievements.txt`, and the game
shows its own pop-up when one unlocks. **GAME > ACHIEVEMENTS** lists them
all, with RECORDS and STATS pages beside them.

This folder has what Steamworks needs, and these steps say what to do with
it once there's an App ID.

## What's here

| File | What it is |
|---|---|
| `achievements.csv` | Every achievement: API name, display name, description, hidden or not, the stat a counted one follows and its goal, and its two icons |
| `stats.csv` | The 12 stats (all INT, set by the client) |
| `achievements/NAME.jpg` | Each achievement's icon, 256 × 256 |
| `achievements/NAME_locked.jpg` | The same, greyed: Steam's "unachieved" icon |
| `badges.txt`, `make_icons.sh` | What each badge shows (the prompt that drew it), and the script that cuts the drawings round and writes both sets of icons |
| `make_tables.py` | Writes the two CSV files from the game's own `AchDef` lines, so they can't drift apart from the code. Run it after changing an achievement. |

The game shows the same icons, smaller, from `neon-caster/achievements/`.

## Going live, step by step

1. **Get an App ID.** Join Steamworks at
   [partner.steamgames.com](https://partner.steamgames.com/) and pay the
   Steam Direct fee for the app. `lib/steam/README.md` describes this in more
   detail, including testing before release.
2. **Enter the stats.** In the app's admin go to *Stats & Achievements >
   Stats* and add each row of `stats.csv`: type INT, *Set By* Client,
   increment only.
3. **Enter the achievements.** Under *Stats & Achievements > Achievements*,
   add each row of `achievements.csv`: the API name exactly as written, the
   display name, the description, *Hidden* where it says yes, and the two
   icons. For a counted one (it has a progress stat), set *Progress Stat* to
   that stat, from 0 to its goal, and Steam shows a progress bar.
4. **Publish** the stats and achievements (*Publish* at the top of the
   admin).
5. **Give the game its App ID.** In `ACH/ACHIEVEMENTS.BI`, set
   `CONST ... NEON_APP_ID = <your App ID>` (beside `NUM_ACH`).
6. **Ship Steam's library with the game.** From the Steamworks SDK's
   `redistributable_bin/`, copy the file for each platform next to the
   program: `steam_api64.dll` (Windows), `libsteam_api.dylib` (macOS),
   `libsteam_api.so` (Linux 64-bit). Valve allows shipping it with the
   game, but don't commit it to this public repo. A CI secret holding the
   SDK, or adding the file to each release download by hand, both work.
7. **While developing,** put a `steam_appid.txt` holding just the App ID
   next to the program, so Steam knows which game it is when you run it
   yourself rather than from your Steam library.

## Testing

| How | Does |
|---|---|
| Play it now | The stand-in: `saves/achievements.txt` fills up, the game's own pop-up shows |
| `achievements` in the console | Every achievement, got or not, and how far a counted one has got |
| `achieve NAME` | Unlock one, to see its pop-up and card. It counts as a cheat. |
| `resetachievements` | Everything back to nothing |
| `NEON_ACH_TEST=1` in the environment | Achievements and records keep counting with cheats on, for scripted test runs |
| `GJ_STEAM_MOCK=1` in the environment | Forces the stand-in even once there's an App ID |

**Cheats.** God mode, `give`, teleporting, the editor and the like hold
achievements (and records) until the next new game. A save remembers
that, so loading a save doesn't clear it. The level's own triggers
(a med station's `give`, say) don't count as cheats.

Once there's an App ID, `lib/steam/README.md`'s *End-to-end testing* walks
through checking the real thing: the overlay pop-ups, stats reaching
Steam's servers, and your profile.

## The achievements

| | API name | Name | How |
|---|---|---|---|
| Story | `NC_SECTOR_1` | First Steps | Finish sector 1 |
| | `NC_ESCAPED` | You Escaped | Finish the original ten, from sector 1 |
| | `NC_NEW_BLOOD` | New Blood | Finish all ten NEW SECTORS, from sector 1 |
| | `NC_REMASTERED` | Old Haunts, New Paint | Finish all ten OLD SECTORS NEW, from sector 1 |
| | `NC_FULL_TOUR` | The Full Tour | All three sets (stat `SetsDone`) |
| | `NC_OVERSEER` | Flesh to Steel | Destroy the overseer |
| | `NC_EXPO` | Every Wonder | Finish THE NEON EXPO (sector 24) |
| | `NC_SHOWCASE` | Gallery Visitor | Five showcase sectors (stat `Showcases`) |
| Fighting | `NC_FIRST_KILL` / `NC_KILLS_100` / `NC_KILLS_1000` | Hostile Takeover / Centurion / Decommissioned | 1 / 100 / 1,000 kills (stat `Kills`) |
| | `NC_HEADSHOT` / `NC_HEADSHOTS_100` | Right Between the Optics / Marksman | 1 / 100 headshots (stat `Headshots`) |
| | `NC_KICK_KILL` | Boot to the Head | A kill with the kick |
| | `NC_OVER_EDGE` | Over the Edge | A machine into a bottomless pit |
| | `NC_CHAIN` | Chain Reaction | Three kills in one explosion |
| | `NC_ARSENAL` | Arsenal | All four guns |
| | `NC_AMPED` | Overclocked | Five kills on one damage amp |
| | `NC_BESTIARY` | Bestiary | One of each of the nine machines (stat `KillKinds`) |
| | `NC_THIEF` | Stop, Thief! | Destroy a thief |
| Skill | `NC_UNTOUCHED` | Untouchable | A sector without taking damage |
| | `NC_CLEAN_SWEEP` / `NC_PACKRAT` / `NC_PERFECT` | Clean Sweep / Packrat / Perfectionist | Every kill / every item / both |
| | `NC_SPEEDRUN` | Speedrunner | One of the thirty sectors in under a minute |
| | `NC_PEASHOOTER` | Peashooter | A sector, 5+ kills, blaster only |
| | `NC_LUB_DUB` | Lub-Dub | Finish with 10 health or less |
| Event rooms | `NC_LOCKDOWN` / `NC_SURVIVOR` / `NC_GALLERY` / `NC_HOARD` / `NC_PEST` | | Win an ambush / a survive room / a gallery; open a hoard; clear a nest |
| Getting about | `NC_JACKED` | Jacked In | Hack a data station |
| | `NC_HELLO` / `NC_PROGRAMMER` | Hello, NEXUS / Programmer | 1 / 10 code terminals (stat `Puzzles`) |
| | `NC_HOT_FOOT` / `NC_CORRODED` | Hot Foot / Corroded | Out of lava alive / armour lost to acid |
| | `NC_BEAM` / `NC_LOOT` / `NC_VANDAL` | Frequent Flyer / Treasure Hunter / Vandal | 25 teleports / 25 loot drops / 100 smashed (stats) |
| Editor | `NC_ARCHITECT` / `NC_BOXED` | Architect / Thinking Inside the Box | Save a sector / stand a block |
| Hidden | `NC_HMPH` / `NC_DEATHS` / `NC_GLASS` | Hmph / Respawn Enthusiast / Bull in a China Shop | 25 wall searches / 10 deaths / 10 panes of glass |
