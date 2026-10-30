# NEON-CASTER Level Editor Guide

A sector takes five minutes to start: **EDIT > SECTORS > NEW SECTOR** (or GAME's), then carve rooms, put things in them and save. You can build from above on the map, or from inside, pointing at walls and floors with the mouse. Everything below is checked against `neon-caster.bas`.

- [Your first sector](#your-first-sector)
- [The EDIT menu](#the-edit-menu)
- [How the editor fits together](#how-the-editor-fits-together)
- [The toolbar and the picker](#the-toolbar-and-the-picker)
- [The 3D view](#the-3d-view)
- [Shaping: the wheel, the arrows, Delete](#shaping-the-wheel-the-arrows-delete)
- [Pictures on faces, and Divide](#pictures-on-faces-and-divide)
- [The properties pane](#the-properties-pane)
- [The map view](#the-map-view)
- [Every map character](#every-map-character)
- [Heights](#heights)
- [Liquids](#liquids)
- [Blocks: less than a cell](#blocks-less-than-a-cell)
- [Lights](#lights)
- [Beyond the editor: the level file](#beyond-the-editor-the-level-file)
- [Building from the console](#building-from-the-console)
- [The monster and HUD editors](#the-monster-and-hud-editors)
- [Gotchas, and a checklist before you save](#gotchas-and-a-checklist-before-you-save)

## Your first sector

A playable sector needs only four things: walls all round the edge, one start, one exit, and a way to walk from the start to the exit. NEW SECTOR gives you all four. Everything else is decoration.

1. Open **GAME > SECTORS**, go into a folder (MAN MADE, or one of your own), and choose **NEW SECTOR**: it's made in that folder. You get the first free sector number - 22, since the examples below are 11 to 21 and 24 - up to 40, saved as `neon-caster/levels/custom/customN.txt`, N ten less than the sector (sector 22 is `custom12.txt`). It's solid wall with one lit 8 × 8 room in the middle, cells 20 to 27 each way. You stand at (21, 24) facing east, and the exit `E` is at (28, 24).
2. You land in the **map view**: the level from above. Press **Tab** (or the **3D** button) to be inside it instead. Either way, the **toolbar** has the tools and the **picker** has everything you can put in a level.
3. **Push a wall back.** In the 3D view, click a wall to select it, then hold **Shift** while you turn the wheel up (away from you): the wall goes back a cell at a time and the room grows. Turn it down, towards you, and the wall comes out towards you - the wall goes the way the top of the wheel goes.
4. **Carve a room from above.** In the map view, choose **PLACE**, open the picker's **SPECIAL** tab and click the floor tile, then hold **Shift** and drag a box. The whole box becomes floor. Make sure it touches the first room.
5. **Add a door.** Picker, **DOORS** tab, click the sliding door, then click the wall cell between the rooms. Doors need a wall either side to slide into.
6. **Put things in it.** The **MONSTERS** and **ITEMS** tabs. In the 3D view a see-through copy shows where each one will go before you click.
7. **Light it.** The **LIGHTS** tab: click an effect and a colour, then click a wall or a floor.
8. **Save** with **SAVE** or **Ctrl+S**. The message warns you if there's no start, no exit, or a gap in the border, but it saves either way.
9. **Play it.** **F2** leaves the editor and the sector plays as a real level. Changes you haven't saved stay while you play: die and it starts again as you edited it, and an edit made on the way keeps the keycards and map you'd picked up. To come back later, it's in **GAME > YOUR SECTORS**.

To rename it, open the console (`` ` ``), type `sectorname MY FIRST MAP`, then `savelevel`.

**Twelve examples to take apart.** SECTORS > AI GENERATED > SHOWCASES holds twelve sectors built to show the editor off (so your first NEW SECTOR is number 22, and there's room for eight of yours - 24 is taken; delete an example's file in `neon-caster/levels/custom/` for more): **11, THE GALLERY** (pictures on single faces, a checkerboard floor laid cell by cell, two-tone pillars, paintings lit and tinted by lights on their faces, statues that wake only when shot and guards that hear it), **12, THE SUNKEN DEPOT** (a walkway a wall up, a shaft with no bottom and a causeway across it, beams hanging from the dark, firelight on the furnace wall, crawler closets, a stalker hunting you from the start), **13, THE RELAY** (chambers only teleporters reach, each pad LINKed to its own, each chamber in pictures of its own), **14, THE CONSERVATORY** (a floor woven from divided cells, a bottomless pond crossed on lifts that each rise and fall at their own pace, a garden behind glass, and the light lab: all six ways a light can go, side by side), **15, THE LISTENING POST** (guards that see four cells but hear a shot from fourteen, crawler closets, a room you must survive for the blue card, an archive locked by a timed trigger and opened by a USE trigger on a terminal) **16, THE OBSERVATORY** (a tower climbed by stairs, an elevator and a lift that rises and falls by itself, glass windows, each ledge lit its own colour, and pads LINKed out of reading order), **17, THE FLOODED ARCHIVE** (a hall under murky water - its floor painted `floor-murky` cell by cell, and a floor's picture says what it does: you wade - crawlers among the shelves, a fallen catwalk, dying lights), **18, THE CORE** (a reactor glowing red on an island in a ring of molten metal painted to burn, bridges that are lifts rising and falling each at its own pace, fire traps, strobing alarms), and three outdoors under skies: **19, THE ROOFTOPS** (night over the neon city, roofs joined by bridges over alleys that are a death pit), **20, THE STORM YARD** (a shipyard under lightning, containers to climb, puddles that slow you) and **21, THE DRIFT** (platforms adrift in orbit over a bottomless void, crossed by catwalks, lifts and LINKed pads), and **24, THE NEON EXPO**: every feature in one sector - eight pavilions round a grand atrium, all thirteen kinds of event room, every kind of trigger, all five liquids, blocks and alcoves, standing decorations, lifts that bob or are called from a console, a skydeck over a street that kills, and the overseer on the summit (built by `neon-caster/levels/megasector.py`). Open one with F2 and click about: the panes show how each thing is set up. They're made by `neon-caster/levels/showcase.py`, which writes them again from scratch, so don't run it once you've changed them.

Undo is **UNDO** or **Ctrl+Z**, up to 40 steps; **REDO** (**Ctrl+Y** or **Ctrl+Shift+Z**) makes again what you undid, until you change something else. One drag, or one run of wheel turns, counts as one step. **F1** (or **HELP**) shows every key for the view you're in. **Alt+L** turns FULL BRIGHT on and off: every cell lit evenly, to see what's going on in a dark corner. The minimap stays out of the editor's way (even with the sector's map picked up); the HUD layout editor still shows it.

**The editor remembers each sector as you saved it.** Every save (Ctrl+S, SAVE) keeps the editor's state with the sector - the view, the tool, the grid, the picker, the brushes, where the map from above was panned and zoomed, and the undo and redo steps - in `neon-caster/saves/editstate/`. Open that sector in the editor again (even after quitting the game) and it's all as you left it: UNDO goes on back past the save. If the level file was changed some other way since (the level kit, another copy of the editor), the undo steps are left out - they'd undo that too - and the rest still comes back.

## The EDIT menu

The main menu's **EDIT** is the editor on its own, for building rather than playing:

- **RESUME LAST EDIT** opens the sector you edited last, in the editor, where you were and in the view you had (the map from above or 3D). Under it are the four sectors you edited before that.
- **SECTORS** is GAME's, but a sector chosen there opens straight in the editor. Every folder has **NEW SECTOR**.
- **TUNER** (every machine's health, each gun's damage, ammo - by difficulty) and **MONSTER KINDS** (each kind's numbers, `monsters.txt`).
- **HUD LAYOUT** (where the health, ammo and map go) and **MUSIC**: the tracks, as in SOUND TEST - press E on one for the **MUSIC ARRANGER** (its clips, a clip launcher, and the arrangement the game plays; `neon-caster/music/README.md` has the rest).

**SECTORS: folders.** GAME > SECTORS and EDIT > SECTORS show every sector in folders: **AI GENERATED** (the five sets of ten and the showcases) and **MAN MADE** (yours - a NEW SECTOR made at the top or from the console goes there). The folders are only the menu's: the sectors stay where they are on disk, and keep their numbers for saves and demos. Make your own, folders inside folders, ten deep at most; a folder can hold sectors, folders or both.

| Key | In SECTORS |
| --- | --- |
| **Enter**, **Right** | open the folder picked (or play / edit the sector) |
| **Left**, **Esc** | back up a folder (Esc at the top leaves) |
| **Right** | forward: down again into the folder you just came back up from, as a browser's |
| **N** | a new folder here - type its name, Enter keeps it, Esc drops it |
| **R** | rename the folder picked |
| **X**, then **V** | pick up a folder or sector, open the folder it should go in, put it there (Esc puts it down) |
| **[** **]** | move the one picked up or down its list |
| **Delete** | take a folder away - what was in it moves up into its place (sectors aren't deleted here) |

The game's folders are `neon-caster/levels/folders.txt`; your first change writes yours to `saves/folders.txt` (delete it to start again from the game's). Both are text, a line each, two spaces in for each folder a line is inside: `folder NAME`, `set original|new|remix|huge|infil`, `sector huge 3`, `custom 2 5-7` (your `custom2.txt`... - sector 12), and `rest` (the folder new sectors of yours go in). A sector left out of the file is put in anyway: yours in the `rest` folder, a set's in a folder named for the set.

A sector opened from EDIT is an **edit session**: NEXUS doesn't greet you, no music plays and NEXUS keeps its taunts to itself. Press F2 to play-test as usual; reaching the exit brings you back to the editor instead of the tally and the next sector. Starting a game from GAME (or loading one) ends the session. The list is kept in `saves/editrecent.txt`.

## How the editor fits together

```mermaid
flowchart LR
    play["Playing the level<br/><small>the game as normal</small>"]
    map["<b>Map view</b><br/><small>the level from above</small>"]
    walk["3D view<br/><small>inside it, pointing at faces</small>"]
    new["NEW SECTOR<br/><small>in GAME or EDIT, SECTORS</small>"]
    mon["Monster kinds editor<br/><small>numbers for every kind</small>"]
    hud["HUD layout editor<br/><small>move the displays</small>"]
    play -- F2 --> map
    map -- "Esc or F2" --> play
    map -- "Tab, 3D" --> walk
    walk -- "Tab, 2D MAP" --> map
    walk -- F2 --> play
    new --> map
    map -- "M, MONSTER KINDS" --> mon
    mon -- "Esc or F2" --> map
    walk -- U --> hud
    hud -- "U or Esc" --> walk
```

Both views edit the same level and share one **selection**, one **tool** and one **brush**, so you can select from above and shape from inside. Esc in the 3D view opens the pause menu instead of leaving.

The world is a grid of cells, 48 × 48. Walls fill whole cells, and each cell has one floor height and one ceiling height. So walls move a whole cell at a time, heights move an eighth of a wall at a time, and **Divide** (below) splits a face's *picture* in two, not the wall itself.

## The toolbar and the picker

**The toolbar** runs along the top of the 3D view, and down the panel on the right of the map view. Point at a button for a line saying what it does.

| Button | Does |
| --- | --- |
| SELECT | A click selects (the default tool) |
| PLACE | A click puts the brush there: a wall, a door, a thing |
| PAINT | A click gives a face the brush's picture |
| LIGHT | A click puts a light on a face |
| HEIGHT | A click raises a floor or ceiling an eighth; Shift+click lowers it. Click one that's selected and the whole selection moves |
| DELETE | Deletes the selection (also **Del**) |
| UNDO, REDO, SAVE | Ctrl+Z, Ctrl+Y (or Ctrl+Shift+Z), Ctrl+S |
| REVERT TO SAVED | Ctrl+Alt+Shift+R - the sector again from its file (Ctrl+Z: your changes back). In play too, when the sector was opened from EDIT: everything you played - machines, doors, pickups - put back, where you stand |
| GRID, and the slider | Lines on every cell's edge, drawn into the world, and how strong they are (also **G**, and **Shift+G**) |
| (no button) | **Alt+L**: FULL BRIGHT - every cell lit evenly, at its pictures' own colours, to see what's what in a dark sector; again for the sector's own lights. Only in the editor (and saved nowhere) |
| (no button) | **Alt+E**: the picture under the pointer (in the picker, or on a face) opened in DRAW or your own paint program - saved there, it's loaded again here (see *New pictures, drawn in DRAW*) |
| (no button) | **Ctrl+E** (from above: **Ctrl+Shift+E**): the picture under the pointer painted in the editor's own painter (see *The painter*) |
| (no button) | **Right-click** a picture in the picker: its menu - RENAME, ANIMATION (how it glows and moves in OpenGL), OPEN IN DRAW, OPEN FOLDER, OPEN IN KALEIDOTRON, DELETE (see *Renaming a picture, and making it glow and move*) |
| PICKER | 3D only: the picker tucked away (it opens when the pointer reaches the bottom of the screen), always open, or off (also **P**) |
| SECTOR | The sector's own pane: its name, its light, and the pictures of its six kinds of wall, four floors and two ceilings |
| VERSIONS | The sector's versions: **REVERT TO SAVED** (back to its file as last saved), **SAVE A VERSION NOW** (a copy as it is now, in `versions/` beside its file, named for when - its own file isn't touched), and the versions saved, newest first, with **BEFORE THE LAST SAVE** (its `.bak`) at the end - click one to load it. A loaded version isn't saved till you SAVE; Ctrl+Z puts back what you had, for REVERT too (**Ctrl+Alt+Shift+R** is REVERT TO SAVED from anywhere in the editor - and in play, in a sector opened from EDIT). (The console's `savesectorcopy` and `loadlevelfromdisk` do the same.) |
| 2D MAP / 3D | The other view (also **Tab**) |
| HELP | The cheatsheet for this view (also **F1**): every key, click and wheel turn, grouped; F1 or a click closes it |
| < SECT, SECT > | Map view only: the sector before or after (PgUp, PgDn). With unsaved changes it asks first: press it again within three seconds to go anyway and lose them. |
| MONSTER KINDS | Map view only: the monster kinds editor (M) |

**The picker** is everything you can put in a level, as pictures: along the bottom in the 3D view (two rows of eight), and under the title in the map view (three rows of four). The wheel over it, or the arrows beside it, scroll it.

| Tab | Has |
| --- | --- |
| WALLS | The six wall types `#` `N` `C` `K` `P` `G` in their pictures, the diagonals, the secret wall, glass; then **+ NEW** (a placeholder to draw - below), **COLOUR** and **GRADIENT** (made colours - below), the sector's own made colours, and every wall picture there is |
| FLOORS, CEILINGS | **+ NEW**, **COLOUR**, **GRADIENT** and the sector's made colours, then every floor and ceiling picture |
| DOORS | Sliding, shutter, split, the three key doors, the sealed door, the exit |
| ITEMS | Keycards, health, armour, ammo, guns, the map, overcharge, the amp |
| MONSTERS | All nine |
| DECOR | All 21 decorations |
| SPECIAL | The start (four ways round), the teleporter pad, the data station, the code terminal, plain floor |
| LIGHTS | The six ways a light can go (steady, flicker, pulse, strobe, fire, dying), each shown going, in the brush's colour; then twelve colours |
| LIQUIDS | DRAIN, then water, poison, slime, lava and acid, each 2, 4 and 6 eighths deep: pick one and PAINT pours it (see [Liquids](#liquids)) |

Click one and it's the **brush** of the tool that uses it - a map character PLACE's, a picture or liquid PAINT's, an effect or colour LIGHT's. The tool never changes by itself: choose it on the toolbar. Each tool keeps its own brush, and the BRUSH box shows the one for the tool you're using. **E** picks up what's under the pointer as the brush of the tool you're using: with PAINT the face's picture, with any other tool what's in that cell. If faces are **selected** when you click a picture, it's painted on every selected face at once, and an effect or colour is given to every selected face's light. A map character is only the brush: nothing is put in until you click with PLACE.

## The 3D view

The game, frozen, with a mouse pointer. Monsters don't move, pickups aren't taken, events and triggers don't run, nothing hurts you, the gun is put away and you fly.

| Input | Does |
| --- | --- |
| Mouse | Points. Whatever's under the pointer is outlined in pulsing cyan and named: a WALL, FLOOR, CEILING, STEP (the face of a floor stepping up) or LINTEL (the face of a ceiling stepping down), its cell and side - or a monster, pickup or decoration by name |
| Right button (hold) | Look round instead; the crosshair picks while you do. With OpenGL you can look nearly straight up and down (the game itself stops at about 34 degrees), to pick a ceiling, a lintel or a ledge right over you |
| Your walk keys | Fly, straight through walls |
| Space, C | Up, down (Shift: faster), as high as a sector goes - 30 walls |
| Look up (or down) and walk | Climb (or sink) as you go - OpenGL, with LOOK UP / DOWN on |
| Left click | The tool (below) |
| Wheel | Shape what's selected (next section) - never just what's under the pointer |
| Ctrl+D | Select nothing |
| Del | Delete the selection |
| H, V | Divide the selected face - or piece - left / right, top / bottom (up to four times) |
| J | Join a selected piece back to what it was divided from |
| R, Shift+R | PAINT: turn the picture a quarter clockwise, or back |
| M, Shift+M | PAINT: flip the picture left-right, or upside down |
| O, Shift+O | Open the door under the pointer (O again shuts it), or hold a lift or crusher at its top or bottom (O again: the other end) - in the editor only, to see and paint it so; Shift+O lets that one go as in play (at nothing: every one) |
| 1-5 | The tools: 1 SELECT, 2 PLACE, 3 PAINT, 4 LIGHT, 5 HEIGHT |
| 6, 7 | 6 THE SECTOR's pane, 7 VERSIONS |
| 8 | The picker, open (and left open - 8 again tucks it away) |
| G, Shift+G | The grid, and how strong it is |
| P | The picker: tucked away, always open, off |
| F1 | The cheatsheet: every key, click and wheel turn, by what it's for |
| Tab | The map view |
| F2 | Leave the editor and play |

**The tools, in 3D:**

| Tool | Click | With Shift | With Ctrl | With Alt |
| --- | --- | --- | --- | --- |
| SELECT | Select the face (or thing) | Add it to the selection, or take it out | The whole floor or ceiling it's part of: every cell joined to it at the same height | |
| PLACE | Put the brush in the cell: a floor's own cell, a wall's the cell in front. Hold the button and sweep to place along the floor. | Take away the thing there | | Pick it up as the brush |
| PAINT | The brush's picture on the face (on the piece, if it's divided) - and selects it, so the PICTURE pane shows it (no picture in the brush: just selects it) | The usual picture again | The whole floor or ceiling | Pick its picture up as the brush |
| LIGHT | A light on the face, as the light brush is. A face that has one is selected instead, for its pane. | Take the face's light away | | |
| HEIGHT | Raise the floor or ceiling an eighth (one that's selected: every selected floor and ceiling) | Lower it | | |

In PLACE, a magenta box on the floor and a see-through copy of the brush show where it will go before you click. Monsters, pickups and decorations can be clicked: they select their cell.

The older keys still work, aimed along the middle of the view: **T** steps every wall of the aimed letter through the wall pictures (Shift: back), **F** the front cell's floor picture, **Z** gives the front cell the next of the level's four floors, **L** a light over the front cell and **K** takes away the light nearest you, **PgUp**/**PgDn** the front cell's floor (Shift: its ceiling), `[` `]` step the brush, **1**-**8** a light preset, **U** the HUD layout editor.

**Every change rebuilds the level.** Killed monsters come back, pickups reappear, doors shut, and your keycards and map are taken away. You stay where you are.

## Shaping: the wheel, the arrows, Delete

**The wheel** works on the selection, and only the selection: with nothing selected it changes nothing (click a face first). The face under the pointer is never changed just because the pointer is on it. A pause of half a second starts a new undo step.

| On | Wheel up / down |
| --- | --- |
| A floor, a step's face | Its floor up / down an eighth (Ctrl: a whole wall) |
| A ceiling, a lintel's face | Its ceiling up / down an eighth (Ctrl: a whole wall) |
| A wall, with Shift | Push the wall back a cell / pull it out towards you (it goes the way the top of the wheel goes). Pushing opens the cell and gives it the floor and ceiling of the cell in front. |
| A wall, with Alt | The other way round: pull it out / push it back |
| A wall, with Ctrl+Shift | Make it a block standing on the floor; keep turning to set its top |
| A wall, with Alt+Shift | Make it a block hanging from the ceiling; keep turning to set its bottom |

Rough a level out this way: Shift+wheel walls back to make rooms and corridors, wheel floors down for pits and up for platforms, Ctrl+Shift for a counter or a crate-sized block, Alt+Shift for a low beam to duck under.

**The arrows** move the selection's cells a cell: in 3D, away from you, back, left and right as you face (whichever way along the grid is nearest); on the map, up the screen is north. Everything in a cell goes with it: what's there, its floor and ceiling, a monster's own settings. A cell left behind becomes like the cell behind it, so a platform slides along leaving floor like the floor round it. Nothing moves into the border, and a start is never copied. On the map, with **SELECT**, you can also press on a selected cell and **drag**: the selection follows the pointer and lands where you let go (one Ctrl+Z puts it back). Only the cells it lands on are replaced - what it passes over on the way is left as it was. To make a two-cell doorway one cell, say, select the door and drag it into the cell beside it: the cell it leaves takes after the room behind it.

**Delete** (Del, or DELETE): a selected wall is opened up (its floor and ceiling like the cell in front), a thing on a selected floor is taken away (never the start), and a selected step or lintel is flattened to the floor or ceiling in front of it.

## Pictures on faces, and Divide

Any face can have a picture of its own: a wall's side, a step's or lintel's face, a floor, a ceiling - and a door's two faces, a lift's top and sides, a block's sides and a diagonal wall's slanted face and straight sides. Choose **PAINT**, pick a picture in the picker and click faces. The face (or piece) you click is the selection after, so the PICTURE pane shows its look to slide, turn or tint; with no picture in the brush, a click only selects. With PAINT on, a kind of wall in the WALLS tab (`#` `N` `C` `K` `P` `G`) is its picture, and so is a door in the DOORS tab (`D` `!` and the key doors `door.png`, `H` the shutter's, `X` the split door's, `E` the exit's) - PAINT never builds one - so to give a divided exit's top half the wall round it, click that wall's kind (or point at the wall itself and press **E**), then the top half. **Ctrl+click** selects the face (or piece) without painting it - **Ctrl+Shift+click** adds it to the selection or takes it out - so its look shows in the PICTURE pane; to paint a whole floor, ceiling or wall side, Ctrl+click it with SELECT (that takes every face along it in the same plane) and pick a picture. **Shift+click** puts back the usual picture, **E** (or Alt+click, where the desktop doesn't take Alt+click for itself - KDE moves windows with it) picks up the picture of the face under the pointer. Picking a picture with faces selected paints them all. From above, PAINT paints a cell's floor (Ctrl: its ceiling), or all four sides of a wall (a diagonal's slanted face and its two straight sides).

**Divide** splits a face into pieces for pictures. Select a face (or several) and press **H** for left | right or **V** for top | bottom; on a face just halved, the same key again makes it whole. Then click one piece and divide *that*: press H, click the right half, press V, and the face is a left half and a right half split top and bottom. Every piece divides again, up to four times (sixteen pieces at most - "as fine as it goes" says when one can't). A piece divided stays selected as its two halves, so H or V again splits them both. **J** joins a selected piece back to what it was divided from (with that piece's look) - press it again to go up another division; with the whole face selected, J makes it whole. The pieces start with the look of the piece they came from. Point at a face and its pieces show faintly, the one under the pointer outlined ("piece 3 of 5"); each can be selected, painted, slid, stretched, turned and tinted on its own. A floor or ceiling divides west | east (H) or north | south (V). Top | bottom splits at the face's middle height, so on a tall wall it may be above your eye.

**Turning and tinting a picture.** With **PAINT** on, **R** turns the picture on the face (or piece) under the pointer a quarter clockwise, **Shift+R** back - the selection's, if that's under the pointer. **M** flips it left-right and **Shift+M** upside down (the pane's FLIP row: LEFT-RIGHT, UPSIDE DOWN) - the bottom of one door's half mirrored to match the other's, say; the pane's label says TURNED and FLIPPED. The PICTURE pane turns it too (`<` `>`), and tints it: **TINT** multiplies the picture by a colour (a white wall goes that colour, dark stays dark), **WASH** mixes the colour in, **GLOW** adds it (it brightens, as a light would). **AMOUNT** is how much (0-100%), **RED**, **GRN**, **BLU** set the colour (16 a click; Shift+click: 1), the swatches are quick colours, and **TYPE** takes any colour as six hex digits - `FF8800` for orange - Enter to keep it. Choosing a colour or amount on a picture that isn't tinted tints it. **AS MADE** puts the picture back: not slid, stretched, turned, tinted or filtered. **USUAL PICTURE** takes away the picture painted on the selection, leaving its usual one (a door's own - a key door's colour too - a wall's kind's), slid, stretched and tinted as it was; Shift+click does it to one face. The pane's **H**, **V** and **J** buttons divide and join as the keys do.

**Filters.** The PICTURE pane's **FILTERS** row (it lists what's on, lit when any is) opens the filters, each with **-** and **+** (Shift+click: finer steps): **BRIGHT** and **CONTRAST** (-100 to +100), **SATURATE** (-100 is grey, +100 twice the colour), **HUE** (the colours turned round the colour wheel, 15 degrees a click), **BLUR**, **SHARPEN** and **EMBOSS** (0-4: emboss lights the picture's shapes from the top left, keeping its colours), **POSTERIZE** (32, 16, 8, 6, 4, 3 or 2 levels of each colour) and **PIXELATE** (the picture in 32, 16, 8 or 4 blocks across), and **INVERT**. **NO FILTERS** takes them all off; **BACK** goes back to the PICTURE pane. They're done in that order - pixelate, blur, sharpen, emboss, bright, contrast, saturate, hue, posterize, invert - and before the picture is turned and tinted, so a tinted, embossed wall is the embossed picture, tinted. Each piece has its own, every selected face changes together, and COPY / PASTE and presets keep them. Both renderers draw them, at either ART (sizes are parts of the picture: a blur looks the same on CLASSIC and MODERN). Each different filtered picture is a copy of its own and counts towards the sector's 200 (below).

**OpenGL's effects, face by face.** Under the filters, **OPENGL, ON THESE FACES:** **NO BUMPS** (no bump mapping: the picture flat, however bumpy its colours), **NO SHINE** (no gloss where the light catches it) and **NO NEON** (its bright colours don't glow) - each on or off for the selected faces or pieces, whatever SETTINGS > EFFECTS says for the rest. They don't change the picture itself (the software renderer draws it as ever); like a filter, each makes a copy that counts towards the 200, and NO FILTERS takes them off too.

**Presets.** At the foot of the PICTURE pane is a shelf of looks kept for the picture on the selected face (its first piece's - `PRESETS: DOOR.PNG`): each a little picture of the whole face as it looked - its pieces, pictures, turns, flips, slides, stretches and tints. **SAVE** keeps the selected face's look as a new one, **REPLACE** puts it over the one picked (its tile outlined), **DELETE** throws the picked one away. Click a tile and every selected face takes that look - divided the same way - in one undo step. More than six, and `^` `v` scroll the shelf. Dress one door up once, save it, then make every door like it with a click. They're kept for every sector, in `neon-caster/presets.txt` (a line each: the picture, then the pieces' shape and looks as a `[faces]` line writes them, split by tabs).

**Solid colours and gradients.** After + NEW the picker has **COLOUR** and **GRADIENT**: pictures the game makes rather than loads, picked like any other (PAINT's brush, and on whatever's selected). They're named by their colours - `#FF2080` is one solid colour, `#FF2080-2040FF-V` a gradient from the first to the second - and the sector's own come after them in the picker, to use again. With nothing selected the PICTURE pane sets the two tiles: **FROM** and **TO** (click one, then a swatch, **RED** / **GRN** / **BLU** - and + (Shift+click: by 1), or **TYPE** six hex digits), the gradient's way - **DOWN** (top to bottom), **ACROSS** (left to right), **SLANT** (top left to bottom right), **ROUND** (the middle out) and **BAND** (the first at top and bottom, the second across the middle: it stacks up a wall with no seam) - and **SWAP**. Select faces with a made colour and the PICTURE pane's **COLOUR: ... (CHANGE...)** row opens the same for them - with **SOLID** and **GRADIENT** to turn one into the other; every selected face with a made colour changes to it (faces with a picture file are left alone), and the picker's tiles follow. Filters, tints, turns, slides and stretches work on them as on any picture - a ROUND gradient posterized to 4 levels is rings; a DOWN gradient stretched 400% tall shows a quarter of it per cell (slide each up a quarter and four cells make one long fade). They're no file, so there's nothing to open in DRAW, rename or delete; each different one counts towards the sector's 200 pictures. In the level file a made colour is just its name where a picture's name goes: `walls = #202030, ...` works too.

**New pictures, drawn in DRAW.** The picker's WALLS, FLOORS and CEILINGS tabs start with **+ NEW**: click it and the editor makes a placeholder picture in `neon-caster/` - `wall-new1.png`, `floor-new2.png`, the next number free - 64 x 64 like the game's own pixel art (**Shift+click**: and a 512 x 512 one in `neon-caster/hd/` too - the HD paintings MODERN art shows, as every picture of the game's has: SETTINGS > VIDEO > ART is CLASSIC for `NAME.png`, MODERN for `hd/NAME.png` where there is one, else `NAME.png`; any size loads), a dark checker saying `PLACEHOLDER 1 WALL 64X64`. It's PAINT's picture straight away (and painted on whatever's selected, as any picker click), so put it where it's going. Then **Alt+E** opens a picture in your paint program: the one under the pointer in the picker (Alt+E on + NEW makes one and opens it), else the one on the face under it, else PAINT's - and the PICTURE pane's **OPEN IN DRAW** opens the selected face's. Alt+E opens the one the game is showing - with MODERN art the HD one, if there is one. Paint it there and save: the editor sees it change within a second and loads it again - on every face it's on, in both renderers, the picker's thumbnail too. DRAW's Ctrl+S on a PNG keeps your layers in a `.draw` beside it (`wall-new1.draw`) and from then on writes only that: the editor watches it too, and writes its flattened picture into the PNG each time it's saved - and next time Alt+E opens the `.draw`, layers and all. Leave the `.draw` files out when you share a sector (they're DRAW's, not the game's). Give it a name that says what it is before you ship the sector: right-click it in the picker (below). Which program: DRAW, if it's in `~/git/DRAW` (`DRAW.run`; on Windows `DRAW.exe`), else the system's own (`xdg-open`, `open`, `start`) - or any you name with the console's `imageeditor PATH` (`imageeditor auto` to go back; kept in `settings.ini` as `image_editor=`). The editor watches each picture it made or opened (up to 32): one you open some other way, open once with Alt+E and it's watched too.

**The colour helper.** Wherever you **TYPE** a colour (a picture's tint, a made colour, a thing's look, a light's colour, a cell light's), a **COLOUR HELPER** panel opens beside the pane while you type. Its palette's colours are swatches: click one and it's used at once, as if typed and kept, and you're still typing, so you can try another (Enter or Esc when done). `<` `>` (or **[** **]**) step through the palettes that come with the game (`neon-caster/palettes/`, 55 GIMP palettes: ENDESGA, DAWNBRINGER, PICO-8, the old computers' and consoles'...), and **LOAD .GPL** (**L**) loads any GIMP palette (`.gpl`) from anywhere. The one you chose is kept in `settings.ini` (`palette=`). The wheel scrolls a long palette; pointing at a swatch shows its hex and name. **PICK FROM THE SCREEN** (**I**) takes the colour of whatever you click next, anywhere on the screen: the lit 3D view as you see it, or a part of the editor (Esc: never mind). **Shift+click** with it takes the colour of the *picture itself* under the pointer: unlit, as painted, averaged over a few pixels. That's the one to use to match a texture: a made colour or a tint goes through the same lighting the picture does, so a colour picked from the lit screen comes out darker again once it's lit. (Shift's colour comes from the face's place on the picture; a picture slid, stretched or turned on the face is near enough for a colour.)

**The painter.** For quick work you needn't leave the game: **Ctrl+E** paints the picture under the pointer - in the picker (on + NEW: a new placeholder first), else on the face under it, else the first selected face's, else PAINT's - in the editor's own little paint program (also the PICTURE pane's **PAINT HERE**, and **PAINT HERE** in the picker's right-click menu; from above, Ctrl+Shift+E). On the left are the tools: **PENCIL** (P, a pixel), **BRUSH** (B, round, **SIZE** with `[` `]`), **LINE** (L), **BOX** (R) and **FILLED BOX** (Shift+R), **ELLIPSE** (O) and **FILLED ELL.** (Shift+O) - drag from corner to corner, and hold Shift for a straight line (across, down or at 45 degrees), a square or a circle - **FILL** (F: everything joined to the pixel that's its colour) and **PICK COLOUR** (I; or Ctrl+click with any tool). The left button paints the left colour, the right button the right one (X swaps them). On the right: the two colours, 32 to choose from (a right-click on one makes it the right colour), **RED** / **GRN** / **BLU** - and + (Shift+click: by 1) and **TYPE** (six hex digits) for the left one, and the picture as it is and tiled 2 x 2. **MIRROR L-R** (M) and **MIRROR U-D** (Shift+M) paint each stroke mirrored too; **WRAP** (W) carries a stroke off one edge in at the other, and **TILED** (T) shows the picture round itself, dimmed, so you can see and paint across its seams - the way it repeats along a wall. **GRID** (G) lines the pixels when zoomed in. The wheel zooms where the pointer is (and + -, **FIT** or 0), the middle button - or Space - drags it about, the arrows too. **Ctrl+Z** / **UNDO** and **Ctrl+Y** / **REDO** (40 steps). **Ctrl+S** / **SAVE** writes the PNG - the one the game is showing, so with MODERN art the `hd/` one if there is one - and the sector shows it at once, in both renderers. **Esc** goes back (asking once if it isn't saved). A made colour (`#...`) has no file: painting one makes it a picture first (`wall-newN.png`, the next free - and on the selected faces that had that colour); leave without saving and it's the colour again, the file gone. It paints the game's own pictures too, if you point it at one: those are the game's files (keep a copy, or make + NEW pictures and paint those).

**Painting across faces.** Select several faces and the PICTURE pane offers **PAINT ACROSS THE n FACES (ONE SHEET)**: the painter opens on one sheet with a 64 x 64 tile for each face, laid out as they sit - floors and ceilings as on the map; walls facing one way along the wall as you see them, a gap left where a face in the line isn't selected (a doorway), and each line of them a row; faces facing different ways in a row, in the order you selected them. Each tile starts as that face's picture, and a stroke, a shape or a fill carries straight across from one face to the next (the gaps aren't painted). **Ctrl+S** writes each tile to a picture of its own - `wall-sheet1-1.png`, `-2`, ... (`floor-`, `ceiling-` for those) - and the first time puts each on its face, whole, and lets go of the face's slide, stretch, turn, tint, filters and pieces: the tile is how it looks now (one step of UNDO in the editor takes them off again). Save again and they're written again. Up to 64 faces, a sheet of up to 32 x 32 of them.

**Renaming a picture, and making it glow and move.** Right-click a picture in the picker - in 3D or from above - for its menu. The pictures that come with the game (listed in `neon-caster/pictures-shipped.txt`) are never renamed, animated or deleted here - their menu says COMES WITH THE GAME and greys those out; you can still open them in DRAW and paint over them.

- **RENAME...**: type the part after `wall-` (letters, digits, `-` and `_`) and press Enter (Esc: never mind): `wall-new1.png` becomes `wall-glowy-gj.png`. The editor renames the file, its `hd/` copy and DRAW's `.draw` beside each, and every use of it: this sector's faces and its own six walls, four floors and two ceilings, undo and redo, every sector file that names it - this one's, your other sectors', their saved versions (written straight away, so none names a picture that's gone) - PAINT's presets, the clipboard, the brush. Type an ending word too (`glowy-gj-pulse`) and that's its animation. DRAW still has the old name open: Alt+E opens it again under the new one.
- **ANIMATION (OPENGL)**: NONE, FLICKER, LIGHT WAVE, PULSE, PULSE NO REFLECTION - the one marked `>` is how it goes now. Choosing one renames the picture with an ending word the OpenGL renderer reads:

| Choice | Its name ends | What it does |
|---|---|---|
| FLICKER | `-flicker` | its lit parts flicker, like the server walls |
| LIGHT WAVE | `-wave` | light chases across it, like the hazard stripes |
| PULSE | `-pulse` | it throbs slowly, like the glow walls |
| PULSE NO REFLECTION | `-pulse-dry` | pulses - and on a floor shows almost no mirror image, as molten floors do (without their burn) |
| NONE | nothing, or `-still` | still: `-still` when the name's own words would make it go (`glow`, `lights`, `reactor`, `servers`, `control`, `hazard`, `stripes`, `warning`...) |

  With an ending, a picture's bright, colourful pixels light themselves at full strength, whatever else its name says: paint the parts that should glow bright and saturated (neon pink, cyan, lime) and the rest dark or grey - grey and white never glow. The software renderer draws every picture still.
- **PAINT HERE**: the picture in the editor's own painter, as Ctrl+E (above). On a made colour, **PAINT IT AS A NEW PICTURE**.
- **OPEN IN DRAW**: as Alt+E.
- **OPEN FOLDER**: the folder it's in, in your file manager (showing the picture, where the file manager can: Dolphin, Nautilus, Explorer, Finder) - the `hd/` one with MODERN art.
- **OPEN IN KALEIDOTRON**: the picture in kaleidotron, if it's built in `~/git/kaleidotron` (greyed out if not).
- **DELETE...**: the menu asks first, and says what uses it - this sector, your other sectors (by file), saved versions. YES - DELETE IT moves the picture, its `hd/` copy and DRAW's `.draw` files to `neon-caster/saves/deleted/` (to get one back, move it back), and everything that used it gets the plain picture of its kind instead: `wall.png`, `floor.png` or `ceiling.png` - written into those sectors' files straight away. PAINT's presets for it go too. NO - KEEP IT goes back to the menu.

**Where a piece's picture starts** (the pane's START AT). **FACE** (as made): the picture is laid across the whole face, from the map's grid, and each piece is a window onto its part of it - divide a wall and the pieces still join up into one picture. **PIECE**: the picture starts at the piece's own top left corner, so two pieces the same size show the same thing wherever they are (the top corners either side of a door, say). **FIT**: one whole picture squeezed into the piece. Slide, stretch, turn and tint work on top of any of them. **COPY** of a piece keeps what you see: a piece that starts at the face is copied as one that starts at its corner, slid to show just what it showed - so pasting it on another piece makes that piece look the same.

**The exit, and doors.** An exit's sides take pictures and Divide like a wall's. Its sign fills whatever it's on: divide a tall exit top | bottom and paint the top half with the wall round it, and the sign below is whole, not stretched. A door (or a pane of glass) stands from its own cell's floor to its own ceiling: for a lintel over a tall door, lower that cell's ceiling with **HEIGHT** (click the ceiling above the door), and paint the lintel's face like any other. A doorway's own floor and ceiling - the strips either side of its door - point and click like any other floor or ceiling in 3D: select or PAINT them (the door's track stays drawn across them). The exit has none: it's flat in its wall.

Every door but the exit is a slab across its doorway, and each of its two faces takes a look of its own - a picture, pieces, slide, stretch, turn, tint - as a wall's side does: point at the door itself. The face's picture rides with the door as it opens (a sliding door's slides into the wall, a shutter's lifts into the ceiling), a piece with no picture of its own shows the door's picture (a keycard door's stripe, a stronghold's dents), and the door's edges take the south (or east) face's look. Tint one green and it's a green door from that side only - do both faces for both. A door's face is its cell's side it looks out of (`N` and `S` for a door across a north-south way, `W` and `E` across an east-west one).

**Open it to paint it.** Doors and lifts move, so the editor holds them still where you want them: **O** opens the door under the pointer (O again shuts it), and sends a lift or crusher to its other end and keeps it there (O again: back to the first end); **Shift+O** lets it go as in play - pointing at nothing, every one. The PICTURE pane (and a door's or lift's own pane) has the same as a button: `SHUT - OPEN IT HERE (O)`, `HELD UP - SEND IT DOWN (O)`. It's only the editor's - nothing's saved, and in play they're as ever. Open, a door's **edges** (a sliding door's one, a split door's two, a lifted shutter's underside) and its **track** (the groove in the floor and ceiling it runs in) are faces of their own: point at them (`DOOR EDGE`, `DOOR TRACK`) and PAINT, turn, flip, slide, stretch and tint them as any face, but whole - they don't divide. An edge with no look of its own takes the door's south (or east) face's, as before; a track's usual is the dark groove.

**Lifts and diagonals.** A lift's top is a floor (PAINT it, divide it, tint it: the lift plate is its usual picture) and its sides are its cell's sides, hanging from its top as they ride up and down (the lift's own hazard-banded side is their usual picture). A crusher's underside is its ceiling and its sides are lintels. A diagonal wall's slanted face is a face of its own (`DIAGONAL` under the pointer): its usual picture is the wall it took after, and its two straight sides (by its solid corner) take looks as any wall's do.

**Sliding and stretching a picture.** With **PAINT** on, hold **Shift** and press the arrows to slide the picture on the face under the pointer four pixels at a time (a sixteenth of the picture; **Ctrl+Shift**: one pixel) - on a wall left, right, up and down as you face it; on a floor or ceiling, up is the way you're facing. **Shift+[** and **Shift+]** make it narrower and wider, **Shift+-** and **Shift+=** shorter and taller (10% to 1000%, by steps: 100, 125, 150, 200, 250, 300...). If the face (or piece) under the pointer is selected, everything selected changes together. **Shift+Home** puts it back as made - not turned or tinted either. A stretch is measured from the map's grid, so faces stretched alike run on into each other: a picture 200% wide across a row of walls covers two cells each, as one big picture, not the same half twice - select the row, then stretch it. Sliding wraps round (64 pixels is where it started) and works on the usual picture as well as one you painted. With faces selected, PAINT's pane is **PICTURE**: LEFT, RIGHT, UP, DOWN slide a pixel (Shift+click: four), WIDE and TALL - and + stretch a step (Shift+click: one percent), AS MADE puts them back. **COPY** takes the first selected face's look - its picture, slide, stretch, turn and tint - and **PASTE** puts it on everything selected; with PAINT on, **Ctrl+C** copies the face under the pointer and **Ctrl+V** pastes onto it (or onto the whole selection, if that face is in it). COPY takes one piece's look when a piece is selected (or pointed at), or the whole face - all its pieces - when the face is: a piece's look pastes onto a piece (or every piece of a face), a whole face's pieces paste onto a face, dividing it the same way. The pane shows what's copied. The face's label says how far it's slid and stretched (`SLID -3,0  STRETCHED 200% X 100%`). In the file it's more numbers on the face's `[faces]` line (below).

A light's lamp picture doesn't cover a ceiling you've painted: the light shines from your picture (the pane's CEILING LAMP: OFF takes the beam away too).

Both renderers draw every picture and piece. A sector can use up to **200** pictures of its own on faces, counting the tinted copies lights make (below) and each turned, tinted or filtered picture (a picture turned, tinted and filtered alike in many places counts once); past that, extra ones are ignored without a message.

## The properties pane

Select something and its pane opens: on the right in the 3D view, over the map's right side in the map view. Changes apply to everything selected of that kind.

The editor's words are in small print (Tiny5, in capitals), so the panes, the picker's names and the cheatsheet show in full instead of being cut short.

With **FULL WIDE** (OpenGL, a screen wider than 4:3) the 3D view's controls use the whole screen: the toolbar and the info box at its left edge, the pane at its right edge, and the picker and messages all the way across the bottom - more thumbnails a row, and the middle of the view clear. The map view stays 4:3 in the middle.

| Selected | The pane |
| --- | --- |
| A door | Its kind: SLIDING, SHUTTER, SPLIT, SEALED, RED KEY, BLUE KEY, YELLOW KEY, EXIT |
| A teleporter pad | Where it goes. **LINK...** and then click another pad to pair the two (saved as `[pads]`); **UNLINK** returns it to pairing in reading order. In 3D every pair is joined by a purple line. |
| A face with a light | Its colour (twelve swatches, or **TYPE** any colour as six hex digits - `FF8800` orange - Enter to keep it; the brush takes it too, for the next light), effect (six), REACH and BRIGHT, CEILING LAMP, REMOVE THE LIGHT. The swatch in the corner shows it going. CEILING LAMP: ON hangs a lamp fixture on the ceiling of the light's cell (its picture replaces the ceiling's, and the light shines down from it in a beam); OFF keeps the ceiling as you painted it, still lit, with no lamp and no beam. |
| A monster | SIGHT, HEARING, HEALTH and SPEED, and what WAKES it; AS ITS KIND IS resets it. Its sight (cyan) and hearing (yellow) are drawn as rings on the floor round it. |
| A pickup, monster, decoration or thing (on its floor's or monster's pane) | **IN DIFFICULTY:** `[x] EASY` `[x] NORMAL` `[x] HARD` `[x] NIGHTMARE` - click one to tick or untick it; any mix will do (only HARD and NIGHTMARE, only EASY...). As made all four are ticked: it's there at every difficulty, and the game thins it as it does everything (fewer pickups at NORMAL and up, NIGHTMARE's twins). Untick any and it's there at exactly the ticked ones, as placed - no thinning, no twin. Changes every selected cell with something in it. Saved as `[difficulty]`. |
| A pane of glass | **REFLECTS - +**: how much it mirrors the room you're in (0 none - 9 a mirror; OpenGL). **BLUR - +**: how soft that reflection is. **FROST - +**: frosted glass - what's behind it blurred and milky (the software renderer smears it up and down). **RIPPLE - +**: reeded glass - what's behind it in wavy bands (OpenGL). Each 0-9. **STYLE < >**: its picture - STREAKS (as made), CLEAR (no streaks), SHEER (no frame either), PANES (a window of four), GRID (sixteen small panes), BRICKS (glass blocks), LEADED (diamonds in lead), PRIVACY (a frosted band across the middle). **THROUGH BENT / CLEAR**: CLEAR keeps what's seen through it sharp - its frost and ripple go only on its reflection. **STRONG < >**: how much it takes before it breaks - AS TUNED (the tuner's GLASS), a number, or UNBREAKABLE: bulletproof, shots chip and crack it but nothing gets through, rockets included. All kept in its `[glass]` line. As made, REFLECTS and STYLE are the sector's (GLASS REFLECTS and GLASS STYLE, on the sector pane), the rest 0 and THROUGH BENT. |
| A pickup, monster, decoration or thing - or a pane of glass or bars | **ITS LOOK:** `NONE` `TINT` `WASH` `GLOW` tint it as a face's picture is tinted - TINT multiplies it by the colour, WASH mixes the colour in, GLOW adds it. **AMOUNT** (- and +: 10, Shift: 1), the quick colours, and **TYPE** for any colour as six hex digits (Enter keeps it). **SIZE** (- and +: 10%, Shift: 1%, 10-400%) draws it bigger or smaller - only how it looks: it's hit, blocks and picks up as ever. On glass, the tint colours what you see through it (TINT is coloured glass, WASH frosted, GLOW lit up); on bars, the bars. A monster keeps its look as it walks about, and its body too. Changes every selected cell that can have one. Saved as `[looks]`. |
| A floor of a lift | LOW, HIGH and SPEED in eighths, the mode (click it: UP AND DOWN, ELEVATOR, ON A TRIGGER - moves only on `liftgo`, CRUSHER, SMASHER - see below), REMOVE |
| An event room (EVENT ROOM... on a floor's pane) | Its kind (AMBUSH, SURVIVE, TRAP, GALLERY, NEST, CLOSET, HOARD, PLATE, LASER, CUTTER, BLACKOUT, FIRETRAP, DEATHPIT - switching kind gives it numbers that suit), its two numbers by what they mean for that kind (how many monsters and of what kind, how long, live and safe times, how often), the PRIZE for winning it (ambush, survive, trap, gallery), REMOVE THE EVENT, BACK (to the floor's pane). The table under `[events]` below says what each kind does. |
| A block's side | Its edges in eighths; PUSH IN and PULL OUT move the selected side an eighth (every block side selected); LOOKS LIKE THE WALL: `#` `N` `C` `K` `P` `G`; REMOVE THE BLOCK; ADD A LIGHT TO IT |
| Floor | MAKE A LIFT OF IT (the selected cells' box, from their floor up a wall), MAKE AN EVENT ROOM (the same box, an ambush to start with) - or, on a floor already in one, EVENT ROOM: its kind..., which opens that room's pane, ADD A PILLAR (a block a quarter of a cell square, in the middle), CELL LIGHT... (the cells' own ambient light - see Lights), ADD A LIGHT TO IT - and, with a decoration on it, MOVE IT `<` `>` `^` `v`, an eighth at a time, and which way it faces: TURNS TO FACE YOU (as every sprite does), or STANDS, FACING EAST / SOUTH / WEST / NORTH (these rows are on a light's pane too, when the light is over the decoration) |
| A plain wall | MAKE IT A BLOCK (the wall becomes a block filling its cell, its sides' pictures kept, and the side you clicked stays selected, ready to PUSH IN), ADD A LIGHT TO IT |
| Any other face | ADD A LIGHT TO IT |
| TRIGGERS... (on a door's, a floor's, a wall's pane) | The triggers about the selection: an enter or clear box taking it in, a use of it, and the timed ones (which are everywhere), each with an **x** to take it away. Then a new one: ENTER (walking into the selection's box - for a wall, the cells in front of it), USE (Space facing the first face's cell: a wall, a door, a terminal), CLEAR (every monster that started in the box is dead), TIME (seconds into the level), HACK, ALARM or CALM (the alarm stops); JUST ONCE or EVERY TIME; TYPE its commands as in the console, `;` between them, or click the action buttons (+25 HP, -25 HP, DIE, +CELLS, -CELLS, +SHELLS, -SHELLS, GIVE ALL, TAKE ALL; and the lights' LAMP O/I, AREA RED, AREA OFF) to add theirs; ADD IT. |
| Nothing (the SECTOR button) | NAME: type the sector's name, Enter to keep it (Esc not). LIGHT: the ambient light, brighter or darker (below 0, down to -255, it dims every light in the sector instead - see Lighting), and twelve colours to tint it. DROIDS: how many service droids roam it (0-12). ALL FLOORS / ALL CEILINGS: every floor (or ceiling) in the sector down or up an eighth - Shift, a whole wall. LOOT: what every breakable leaves, at once - AS MADE (the game's table), NONE, LITTLE (half the chances), PLENTY (half again), LOTS (twice); the console's `loot` sets one kind exactly. ROOM W x H (- and +; Shift for its depth) and MAKE THE MAP THIS ROOM: the whole map wall again but for one room that size in its middle, you at its west end, the exit in its east wall - the quick start for a new sector (Ctrl+Z undoes it). ITS PICTURES, under WALLS, FLOORS and CEILINGS: the six kinds of wall (`#` `N` `C` `K` `P` `G`), the four floors (1-4) and two ceilings (1-2) the level's zones use - click one, and the picker opens at its tab, showing only the picture files (the one it has now lit): the next picture you click is that one's, everywhere it's used. |

**Monsters, for ambushes.** Each monster can be set apart from its kind:

| Setting | Means | As its kind |
| --- | --- | --- |
| SIGHT | How far away it notices you, in cells | 14 |
| HEARING | How far away your shots wake it, in cells; 0 is deaf | deaf |
| HEALTH, SPEED | Against its kind's, in % | 100% |
| WAKES WHEN: IT SEES YOU | Seeing you within its sight | yes |
| YOU'RE NEAR | You coming within its sight, seen or not: round a corner, behind a door | |
| IT'S HIT | Only being hit; nothing else wakes it | |
| HUNTING | Nothing: it's hunting you from the start | |
| WEAPON (a turret's) | What it fires - click `<` `>` round them: PLASMA (bursts of bolts), LASER (aims a red line that lags behind you, then fires - step out of it), LIGHTNING (crackles as it charges, then strikes if it still sees you), FLAME (a stream of fire, 5 cells), POISON (a green spray, 6 cells - the hazmat suit keeps it out), ACID (a yellow mist that eats armour first - the suit keeps it out too), MISSILES (slow, they turn after you, and burst) | PLASMA |
| TRACKING (a turret's) | How fast it turns to you, in degrees a second, `-` `+` by 10 (10 to 360). It only fires once it's on you: a slow one is easy to outrun. | 90 |
| EJECT (a turret's) | How many frames it takes to come out of its housing (and go back in), `-` `+` by 6 (6 to 240; 60 is a second) | 36 |
| STARTS (a turret's) | Click it round: OUT WHEN IT WAKES (hidden in its housing till it sees you, as every turret was), FOLDED AWAY (it stays in, can't be seen or hit, till a `turret` command - a trigger's - brings it out), OUT (out from the start) | OUT WHEN IT WAKES |

**Turret ambushes.** A FOLDED AWAY turret waits for a trigger: give the room an ENTER trigger with `turret at X Y R eject` (every turret within R cells of X Y comes out), or `turret all eject`, and they slide out together as you walk in. The `turret` command does more - `retract` (back in, folded away again), `off` and `on` (out but still), `weapon NAME`, `track N`, `ejectspeed N` - and on its own in the console it lists every turret by number, with how it is. A folded-away turret nothing ever brings out still counts in the tally's kills.

To check an ambush, play it and type `mons` in the console: it says which monsters are still asleep. A closet of YOU'RE NEAR crawlers with a sight of 2 springs as you pass; a heavy with HEARING 12 comes running at the first shot. The settings are kept by the cell the monster starts in, so moving it with the arrows takes them along, but deleting it and placing a new one doesn't.

## The map view

**Size.** A sector is a square of cells: the game's own are 48 x 48, yours can be anything from 16 to 256 each way. The SECTOR pane's **MAP SIZE** (- and +, then MAKE IT) or the console's `mapsize N` grows it (new cells are wall, with the border all round) or cuts it down (lights, rooms, lifts and the rest past the new edge go with it; a room or lift across it is cut short). A big sector opens fitted to the view; **hold Space and drag** to pan the map, **hold Space and turn the wheel** to zoom in and out where the mouse is. In play, the minimap shows the 48 cells round you, and Tab's map the whole sector.

The whole 48 × 48 map from above, one square per cell, with the picker, the toolbar and the help line in the panel on the right.

**Carving a room bigger, fast.** Choose **PLACE**, point at a floor cell and press **E** (or right-click it): the brush is open floor (it's also the first entry in the **FLOORS** tab). Then hold **Shift** and drag a box over the walls you want gone: let go and it's floor. Or **SELECT**, drag a box over them and press **Del**. Then go into 3D (Tab) to set heights and pictures. The panel's **CELL** lines show what's under the mouse, its pictures (a wall's, or its floor's and ceiling's) and its light (see Lights). With PAINT, **E** picks up the cell's floor picture (Ctrl+E: its ceiling's; on a wall: the wall's). From above, **Ctrl+Shift+E** opens the painter (Ctrl+E in 3D). PAINT on a wall cell only changes its picture: a floor picture there does nothing, and the message says to PLACE open floor instead.

| Tool | Left button | Right button | Shift |
| --- | --- | --- | --- |
| SELECT | Select the cell; drag a box to select it all | | Add to the selection (Shift+click one cell: in or out) |
| PLACE | Put the brush in the cell; drag to keep going | Pick up what's in the cell as the brush | Drag a box: fill it when you let go |
| PAINT | The picture on the cell's floor, or a wall's four sides; drag on across cells (Ctrl: the ceiling) | | The usual picture again |
| LIGHT | A light in the middle of the cell, as the light brush is | Take away the nearest light within 1.5 cells | |
| HEIGHT | Raise the floor an eighth (a selected cell: every selected cell's) | Lower it | The ceiling instead |

| Input | Does |
| --- | --- |
| Wheel | Over the picker: scroll it. Over the map, with something selected: the selected floors up / down an eighth (Ctrl: ceilings). Otherwise the brush, back and forth. |
| `[` `]` | The brush, back and forth |
| Arrows | Move the selection a cell (up the screen is north) |
| Drag a selected cell (SELECT) | Move the selection with the mouse - it lands where you let go |
| Del, Ctrl+D | Delete the selection, select nothing |
| L, H | The LIGHT tool, the HEIGHT tool (again: back to PLACE) |
| 1–5 | The tools: SELECT, PLACE, PAINT, LIGHT, HEIGHT |
| 6, 7, 8 | THE SECTOR's pane, VERSIONS, the picker open |
| G, Shift+G | The grid lines, and how strong |
| T | Move yourself to the cell under the mouse. It doesn't check for walls. |
| PgUp / PgDn | Previous / next sector |
| M | The monster kinds editor |
| U | The HUD layout editor |
| Tab | The 3D view |
| Esc, F2 | Leave the editor and play |
| F1 | Help |

You can't change the outer ring of cells (x or y of 0, or the map's size less one - 47 in a sector the game's size), so the border always stays wall (a file with an open edge gets wall there when it loads). Placing a new start (`<` `>` `^` `v`) turns the old one into floor, so there's never more than one.

**A light's colour and effect** come from the picker's LIGHTS tab (the keys 1-8 were light presets once; they're the tools now).

**What the map shows.** Walls are drawn in their picture's average colour and floor is dark blue. Pickups are green squares, monsters red, decorations gold, and you're a yellow circle with a line showing which way you face. Lights are a ring in their colour; with the LIGHT tool their full reach is drawn too. Event rooms have a magenta outline and triggers an orange one. With the HEIGHT tool, raised floors are shaded brown (brighter is higher), sunken floors purple, an unusual ceiling gets two cyan dots, and lifts get a green outline. The selection is outlined in orange.

The line under the map names the cell under the mouse, as `x,y name`, with its floor and ceiling if they're not the usual. x counts 0–47 left to right and y counts 0–47 top to bottom (in a sector the game's size: 0 to its size less one in a bigger one).

## Every map character

Each cell of the map is one character, and case matters: `m` is a drone, `M` is the map pickup. Any character not listed here is plain floor. In the file, in this order (the picker shows them as pictures, by tab):

```
. # N C K P G /
\ D H X R B Y E
! = @ $ % ? & ;
r b y + * u a e
2 3 4 5 M q j 8
9 ( { } ` , m g
h c s k w z T 1
) 6 7 0 ~ _ | ]
o i p t x l n f
S d A F I J L O
Q U W Z V : [ '
" - < > ^ v
```

**Walls and structure**

| Char | What | Notes |
| --- | --- | --- |
| `.` | Floor | |
| `#` `N` `C` `K` `P` `G` | Solid walls | They differ only in looks: pictures 1–6 of the level's `walls =` list, in that order. `#`'s picture is also used for the steps between floor heights. |
| `/` `\` | Diagonal walls | Half wall, half floor, corner to corner. The solid half is chosen from the walls next to it, and it takes their look (PAINT gives it one of its own). You can't walk through one. |
| `%` | Closet wall | Looks like the walls around it. Slides away when a closet event (kind 6) within 3 cells goes off. Once every monster from the closet is dead, something clicks at the back of it: a stash in the wall behind, opened with Space (it counts as a secret). |
| `?` | Secret wall | Looks like the walls around it, on the map too. Space on it slides it away: *YOU FOUND A SECRET!*, and the tally's SECRETS row counts it. Touching `?` cells are one secret. A trigger with `secret X Y` in its commands opens it instead (and then Space doesn't): a switch to shoot, say. What's behind it stays rock on the map pickup's map until you've seen it. |
| `=` | Glass | A see-through pane. Put it in a straight wall one cell thick. 4 hits break it. In OpenGL it reflects the room you're in, as much as it says (REFLECTS on its pane; the sector's GLASS REFLECTS). |
| `-` | Bars | Iron bars across a window: see through them, but nothing passes, and shots ping off them. They never break. Put them where glass would go. |
| `@` | Data station | A wall you jack into with Space. Hacking it opens nearby `!` doors. In the network: grab the data cores before the clock runs out. Hunters (cyan ICE) chase you; deeper in a set of ten there are sentinels (orange: still, firing), tracers (yellow: quick, they watch you) and black ICE (dark, slow, hits hard). Laser firewalls across the ways switch on and off (a flicker first) - through one lit, you're burnt and lose time. ICE that sees you raises the TRACE; full, NEXUS sends more hunters. |
| `$` | Code terminal | A wall with a QB64 puzzle: the next name from `puzzles =`, in reading order. |
| `;` | Turret control | A wall you hack with Space: a screen of junk with words hidden in it, one the password. Pick a word and it tells you how many of its letters are right, in the right places; pick a pair of brackets with only junk between them for a dud taken away (or, now and then, your tries back). Four wrong and it locks for good - and every turret near it comes for you. Get it, and every turret within 12 cells goes off for good (counted as killed). |
| `&` | Teleporter | Pads pair up in reading order: 1st with 2nd, 3rd with 4th. Up to 32 (16 pairs). |

**Doors.** A door must sit between two walls.

| Char | What | Opens |
| --- | --- | --- |
| `D` | Sliding door | Space; stays open 4 s |
| `H` | Shutter, rolls up | Space; slower, open 6 s |
| `X` | Split door | Space; fastest, open 3 s |
| `R` `B` `Y` | Key door | Needs the red, blue or yellow keycard |
| `!` | Sealed door | Opens when the nearest data station `@` is hacked |
| `E` | **The exit** | Never opens; Space on it ends the level. Gets a green pulsing light. |

**Stronghold and keypad doors.** Any door but the exit has two more settings on its pane (a line of `[doors]` in the file):

- **KICKS** - a *stronghold door*: Space won't open it, but your boot will. Each kick (F) dents it; halfway it cracks, and on its last kick it gives way for good, with a crash that wakes everything near. 0 is an ordinary door. With the damage amp on, a kick counts twice.
- **KEYPAD CODE** - a *keypad door*: Space brings up a keypad, and only its code opens it. TYPE sets the digits (up to 8); RANDOM makes it `?` - a new four-digit code every time the sector starts, so the only way to know it is to find it out: a note can say it (`{code X Y}` in a note's words is the code of the door or safe at X, Y). A hacked computer, a trigger's `door X Y open`, or `unlock` opens it too.

A door can be both: kick it down, or find the code.

**Pickups.** Up to 256 per level (the level kit keeps its own sectors to 64, 160 in a sector over 64 cells across).

| Char | Pickup | | Char | Pickup |
| --- | --- | --- | --- | --- |
| `r` `b` `y` | Red / blue / yellow keycard | | `u` | Armour +50 |
| `+` | Health +25 (up to 100) | | `*` | Big medkit +50 |
| `a` | Energy cells +15 (the blaster's, 99 at most) | | `4` | Railgun, +6 slugs |
| `e` | Shells +8 | | `M` | The map |
| `2` | Scatter gun, +8 shells | | `q` | Overcharge +100, up to 200 |
| `3` | Repeater, +60 rounds | | `j` | Damage amp: double damage for 30 s |
| `8` | Night vision headset: yours till you die, as a gun is. N switches it on and off | | | |
| `9` | Hazmat suit: poison, slime and acid wear it instead of you (about 45 seconds of poison, 20 of acid). Fire and lava go straight through it. Lost when you die | | | |
| `5` | Rocket launcher (gun 5), +5 rockets: a rocket bursts on whatever it hits - and the blast hurts you too, close up. Hold the right button to zoom right in | | `(` | Rockets +5 (50 at most) |
| `{` | Repeater rounds +40 (200 at most) | | `}` | Railgun slugs +5 (25 at most) |
| `` ` `` | Jetpack: a booster - hold FLY / JET UP (E as made), or look up and walk, and it fires, pushing you up and burning fuel (a full tank: about 7 seconds of thrust); let go and you fall, floaty as after a rocket jump (no hard landing) - fire it again to slow the fall | | `,` | Jet fuel +40 (a jetpack's tank holds 100). Each jetpack and can can have its own: FUEL - + on its pane (`[fuel]`) - give a level just enough to reach the next can |
| `"` repairkit | Computer repair kit (up to 3): Space on a broken computer with one fixes it | | `"` invuln | Invulnerability: nothing hurts you for 5 seconds (a golden glow round the screen) |
| `"` flashlight | Flashlight: yours till you die, as the headset is - on as you pick it up, L switches it. It lights a cone where you look, even in complete darkness, while its battery lasts (BATTERY LIFE, 5 minutes as made); a second one is a spare battery. Its beam, colour and effect are the player's, in SETTINGS > GAMEPLAY > FLASHLIGHT | | `"` battery | A spare battery for the flashlight (4 at most): one goes in as the battery runs out - straight away, if it's already dead |

Each gun has its own ammo: cells for the blaster, shells for the scatter gun, rounds for the repeater, slugs for the railgun, rockets for the launcher. Cells that come out of something - loot, a monster's drop, a prize - come out as ammo for one of the guns you have that shoot energy (the blaster, the repeater, the railgun); cells you place stay cells.

**Monsters.** Up to 192 per level, counting ones events spawn (the level kit places 64 at most, 128 in a sector over 64 cells across).

| Char | Monster | Hits to kill |
| --- | --- | --- |
| `m` | drone | 3 |
| `g` | gunner | 4 |
| `h` | heavy | 10 |
| `c` | crawler | 2 |
| `s` | sentry | 8 |
| `k` | stalker | 3 |
| `w` | spitter | 6 |
| `z` | overseer (boss) | 80 |
| `T` | thief | 5 - grabs your ammo and gun and runs for its hoard (event 7). Each hit knocks some loose; if it gets home, the hoard is locked for good |
| `1` | sniper | 4 - keeps well back and aims a laser: a faint red line that follows you, a little behind, then a white-hot beam. Step out of the line (or out of sight) before it fires |
| `)` | trooper | 6 - a burst rifle: three bolts at a time |
| `6` | ripper | 3 - fast (quicker than you walk), all claws: it lunges in, slashes and leaps back out of reach |
| `7` | warden (field boss) | 60 - a laser, then a ring of ten bolts and three at you, turn about. Drops an overcharge, armour and a gun you haven't got |
| `0` | colossus (field boss) | 90 - comes on and on: up close, a slam that shakes the floor; further off, heavy bolts. Drops a damage amp, a big medkit, cells and shells |
| `~` | turret, in the ceiling | 6 - a 3D model: hidden till it sees you (and can't be hit till it's out), then it slides down out of the ceiling, turns its barrels on you and fires bursts. A turret control panel (`;`) switches it off |
| `_` | turret, in the floor | the same, rising out of the floor |
| `]` | mimic | 8 - asleep it looks just like a treasure chest (its lock glows pink, not cyan). Space on it, coming right up to it or a shot wakes it, and it bites |
| `"` robodog | robot guard dog | 5 - fast, all teeth. When it sees you it barks, and every machine within 10 cells that hears it comes |
| `"` guard | guard | 4 - a cyborg with a plasma pistol, quicker than you walk. When it sees you it runs for the nearest alarm switch that's on (40 steps at most) and sets the alarm off; then it fights. Shoot the switch first, or switch the alarms off |
| `"` eyebot | eyebot | 3 - a flying cybernetic eye. Its eye says what it's doing: blue, idle; yellow, hunting you; red, rushing you. It keeps five to eight cells off and zaps you with a laser, rising or dropping to you (a jetpack won't lose it); after two zaps, or if you come within 3.5 cells, it dives at you, beeping faster, and blows up - a rocket's blast, about a quarter of your health. Shoot it down mid-dive and it blows up where it is |
| `\|` | turret, in a wall | the same, sliding out of a wall beside its cell at chest height (it can only turn so far from the wall). With no wall beside it, it's a floor turret. Any turret's WEAPON is set in its pane: plasma, laser, lightning, flame, poison, acid or missiles |

**Decorations.** Up to 160 per level (the level kit's own: 64, 160 in a sector over 64 cells across). They block your way, and most can be shot to pieces.

| Char | Thing | | Char | Thing |
| --- | --- | --- | --- | --- |
| `o` | Barrel (explodes) | | `A` | Control console (glows) |
| `i` | Lamp (cyan light) | | `F` | Wall of screens (glows) |
| `p` | Plant | | `I` | Specimen tank (glows) |
| `t` | Terminal (green pulse) | | `J` | Lab bench |
| `x` | Crate | | `L` | Generator (fire glow) |
| `l` | Server rack (blinks) | | `O` | Cryo pod (glows) |
| `n` | Vending machine (pink) | | `Q` | Hologram (glows) |
| `f` | Coolant tank (explodes) | | `U` | Lockers |
| `S` | Spawner (the portal nest events use) | | `W` | Bench |
| `d` | Desk | | `Z` | Chair |
| `:` | Barrel of a liquid (its pane: LIQUID - water, poison, slime, lava, acid) | | `V` | Body (doesn't block, can't break) |
| `[` | Treasure chest: Space opens it | | `'` | A note: Space reads it - its words, and a picture if it has one (its pane) |

A **barrel of a liquid** (`:`) shot springs a leak, hisses for a moment, then bursts: a blast (water's just a pop), a pool of what was in it, and its own harm - poison leaves a cloud of gas, lava sets everything near alight (you too), acid eats armour and stains the walls, slime burns, water puts fires out. Fire near one cooks it off. **Barrels stack**: a barrel's pane (`o` or `:`) has STACK - and + for up to eight standing on each other, as many as fit under the ceiling (a room one wall high holds two); when the one under them goes, the rest drop. A **treasure chest** (`[`) opens on Space and throws out its loot (armour, a medkit, rounds, an overcharge, each by its own chance - `[loot]` with `chest = ...`). Don't trust every chest: a **mimic** (`]`) is one with teeth.

**Things** (`"`). There are more things than characters left, so one character, `"`, stands for any of them: what each one is, is on its pane (the `<` `>` beside its name), or `[things]` in the file. The picker's decorations tab has them all at its end.

| Thing | What it does |
| --- | --- |
| table | A table knocked on its side: cover. It stops shots, it's low enough to see over, and it takes 10 hits to break |
| brokenmonitor | A smashed monitor on the floor (lies flat) |
| deadscientist, deadguard, deadcyborg | More bodies (lie flat, don't block, never break) |
| alarm | An alarm switch, chest high on its wall. Set off - by a guard, a hunting gunner, heavy, stalker, sniper or trooper slapping it as it passes, or by you - it sounds the alarm: a siren, red at the screen's edges, and every machine within 24 cells woken and coming for you, for 12 seconds. Press it again while it sounds and it's off; point at one and it says ON or OFF. Two hits break it. Its pane: ON AT FIRST / OFF AT FIRST |
| alarmpc | A security console: Space switches its alarm off (or on again) - every alarm in the sector, or the one its pane's ALARM (X, Y) names. Off, a sounding alarm stops. A hacked computer whose OPENS names a switch turns it off too |
| bookshelf | Space searches it, once: maybe something useful (its `[loot]`, `bookshelf = ...` - as made, a repair kit, a medkit, cells or shells), and any note in it |
| safe | A safe. Its pane: CODE - the keypad's (digits, or `?` for one made up each time). With no code, only a computer opens it. Opened, it throws out its loot (`safe = ...`: armour, an overcharge, rounds, a damage amp, each by its chance) and any note in it |
| brokenpc | A broken computer. Space on it with a repair kit fixes it: then it's a computer |
| computer | Space on it: the word hack (as the turret control panel's). Get in and it opens what its pane's OPENS says - X, Y of a door (any lock) or a safe - and runs any `hack X Y` trigger on it. Locked out, it's dead for good, and its alarm wakes everything near |
| camera | A security camera, up by the ceiling. It turns and tilts to follow you while it can see you (as far as its mount lets it), and sweeps slowly when it can't. Three shots bring it down - and its feed with it. Its pane: NAME (shown on its feed; CAM1, CAM2... as made) |
| secmon | A security monitor. USE (Space as made) on it shows what the cameras see, Duke-style: USE again the next camera, past the last (or a step) back to you. While you watch, nothing else works - no shooting, turning or jumping - but the world goes on. With the map pickup every camera is marked on the map (a red eye and the way it looks); without it, the ones you've seen |
| jumppad | A jump pad, flat on the floor: step on its plate and it SHOOTS you through the air - its pane's DIR (degrees: 0 east, 90 south, 180 west, 270 north), ANGLE (up from the floor, 5-90) and POWER (hundredths of a cell a frame, 5-100). In the air you can look and shoot, not walk; the sector's gravity brings you down, and a long drop hurts as any fall (water, or the jetpack fired on the way down, softens it). Monsters that walk onto one are shot off too. How far, on the level: POWER x POWER x sin(2 x ANGLE) / (100 x gravity%) cells - POWER 30, ANGLE 45: 9 cells |
| padpc | A launch control: Space opens its pad's numbers (its pane's PAD (X, Y)) - click - and +, or the arrows, or type them; SET. Point at it (or at a pad) and its numbers show without a Space. A note with a target's coordinates, and a player works the shot out. Pads with no console keep the numbers you gave them |
| repairkit, invuln, flashlight, battery, robodog, guard, eyebot | The pickups and the monsters above |

A **desk** (`d`) is searched with Space as a bookshelf is. A note can be in a desk, a bookshelf or a safe as well as lying about (`'`): its pane on any of them has NOTE - WORDS, PICTURE, NONE. In a note's words, `|` starts a new line, and `{code X Y}` shows the code of the door or safe at X, Y.

Some do more than break. Space at a **vending machine** (`n`) is a pull on a **slot machine**: three reels, and three alike pays out - three bombs, a big bang (stand back); three monsters, three come out of it; three guns, a gun you haven't got; three medkits, cells or armour, plenty of it; three 7s, the jackpot. A pair gives a little of it; nothing alike, nothing. One pull a machine. Space at a **computer** (`t`, `A`, `F`) plays NEON PONG (first to 3; win and it pays out). A **specimen tank** (`I`) broken open lets out what's in it half the time. Monsters' bolts break things too, and what's inside still drops.

**The start.** `<` `>` `^` `v` put you there, facing left, right, up or down the map. Keep exactly one.

## Heights

Every cell has its own floor and ceiling height, measured in **eighths of a wall**. The usual floor is 0 and the usual ceiling is 8 (one wall up). You can step up 2 eighths, but 3 eighths blocks you, so make stairs from 2-eighth steps.

**Raising and lowering**

- **3D view:** select a floor or ceiling (or several) and turn the **wheel**; Ctrl moves a whole wall at a time. Or the HEIGHT tool: click to raise, Shift+click to lower - click a face that's part of the selection and every selected floor and ceiling moves (each its own way: floors with floors, ceilings with ceilings); click one outside it and only that one moves.
- **Map view:** select cells and turn the wheel (Ctrl: ceilings); or the HEIGHT tool: click to raise a cell's floor, right-click to lower it, Shift for the ceiling - on a selected cell, every selected cell moves together. Walls have no heights: the HEIGHT tool and the wheel leave wall cells alone, and a wall carved into floor starts at the usual floor and ceiling.
- **Console:** `raise X Y EIGHTHS` for one cell, or `raise X0 Y0 X1 Y1 EIGHTHS` for a box; add `ceil` for the ceiling.

| Rule | Value |
| --- | --- |
| Highest a floor or ceiling goes | 240 eighths: 30 walls up |
| Highest step you can walk up | 2 eighths (the limit is 0.32 of a wall) |
| Lowest gap you can walk under | 6 eighths of room between floor and ceiling |
| A floor can't go above | its ceiling minus 2 eighths |
| A floor can't go below | −8, a bottomless pit: fall in and you die |
| A drop that hurts | about 8 eighths (a whole wall); 7 doesn't. Only a fall that hurts lands with a thud; stepping down is silent but for your footsteps. |

With the usual ceiling, a floor tops out at 6 eighths. Raise the ceiling first to build higher. When the editor refuses a change, it says nothing, so if a click seems to do nothing, check the ceiling.

**In the level file**, heights are two extra maps, `[floor]` and `[ceiling]`, one character a cell:

| Char | Means |
| --- | --- |
| `.` | The usual: floor 0, ceiling 8 |
| `0`–`9`, `a`–`z` | 0 to 35 eighths up: `8` is one wall, `g` is two, `z` is 4⅜ |
| `A`–`H` | 1 to 8 eighths down; `H` is a pit |
| (past `z`) | 36 to 240 up: the row keeps the last digit (base 36, `0`–`z`), and an extra `[floor high]` / `[ceiling high]` section, one digit a cell, says how many 36s more - written only when a sector has them |

Case matters here too: `a` is 10 up, `A` is 1 down. A level with neither section is flat and draws the fast classic way.

**Outdoors: skies.** A ceiling picture whose name starts `sky-` isn't laid on the ceiling: it's drawn by the way you look, like Doom's sky, so it seems endlessly far off and stays put as you walk. Four come with the game: `sky-neon-night` (the city at night, a moon), `sky-dusk` (a sunset behind the skyline), `sky-storm` (clouds and lightning) and `sky-orbit` (a ringed planet in a nebula). Put one in the sector's ceilings (the SECTOR pane, or `ceilings =`) and give the open-air cells that ceiling with a zone (or PAINT single ceilings with it from the CEILINGS tab); everywhere else keeps a roof. Raise those ceilings well up (two to four walls) so walls don't hide the horizon. Under a sky there are no lamp fixtures or light beams, and a step in the ceiling between two sky cells is sky, not a wall in the air. A sky is a panorama: 360 degrees across, from the horizon to 72 degrees up; `neon-caster/levels/skies.py` paints them (2560 × 512, squeezed square), so copy it to make your own.

**Floor hazards** come from the floor picture's name: a floor whose picture name contains `molten` or `lava` burns you, and `murky` or `slime` slows you down. That goes for a picture PAINTed on a single floor too, so a river of lava or a flooded aisle is a matter of painting it. For a real pool, with a surface you wade in, use a liquid (next).

## Liquids

A liquid is a pool lying on the floor: it has a surface (its depth above the floor), you see the floor through it in OpenGL, and it ripples. Five kinds:

| Liquid | What it does | See-through (OpenGL) |
| --- | --- | --- |
| Water | Slows you | Mostly |
| Slime | Slows you a lot, stings a little | Hardly |
| Poison | Hurts steadily, turns everything green | Some |
| Acid | Eats your armor first (twice as fast as it would hurt you), then you | Some |
| Lava | Burns hard, glows and lights the room round it | No |

You wade slower the deeper it is. In anything deeper than three eighths you float, head above it, so the deepest pools don't drown the view. A fall into one is softened. Monsters never walk into the harmful ones, are slowed by all of them, and get hurt if you kick them in; hovering ones don't care. Harmful pools bubble as you come near.

**Pouring one.** Open the picker's **LIQUIDS** tab and pick a kind and depth (2, 4 or 6 eighths); that's PAINT's brush now.

| | 3D view | Map view |
| --- | --- | --- |
| Pour | Click a floor | Click or drag over cells |
| A whole floor | Ctrl+click (every cell joined to it at its height) | Select a box, then pick the liquid |
| Drain | Shift+click, or the DRAIN entry | Shift+click or drag, or DRAIN |
| Into the selection | Pick the liquid with floors selected | The same |

A liquid lies only on floor cells (with or without something standing on them), never on a wall, a door or a lift. The usual way to make a pool is a sunken floor (lower it with the wheel or the HEIGHT tool) filled to near the top. A liquid standing higher than the floor beside it shows its sides, so a pool on flat ground looks like a slab of water. The software renderer draws the surface solid, moving.

## Blocks: less than a cell

Walls fill whole cells. A **block** is a solid box standing inside one open cell, its edges anywhere on an eighth of a cell, from the floor to the ceiling: a pillar, a wall an eighth thick, a half-width ledge, the back of an alcove. It blocks you, monsters, shots and sight, and looks like one of the level's six walls (`#` `N` `C` `K` `P` `G`). Each of its four sides is a face of its own: PAINT puts a picture on it, Divide splits it, and a light on it tints it, just as on a wall. A side shows the part of its picture that its place in the cell says, as a wall there would, so a block against a wall lines up with it and a pillar a quarter wide shows a quarter of the picture.

**Making one.** Select a plain wall and press **MAKE IT A BLOCK**: the wall becomes a block filling its cell, and the side you clicked is still selected. Now **PUSH IN** moves that side back an eighth at a time. Or select a floor and press **ADD A PILLAR** for a block a quarter of a cell square in the middle of it, then click any side and PUSH IN or PULL OUT. A block is at least an eighth each way and stays inside its cell; DELETE (or REMOVE THE BLOCK) takes it away. One block per cell.

**An alcove with a computer in it,** two lit pillars beside it and a light pulsing over it, in a wall facing south:

1. Click the wall cell where the alcove goes, then **MAKE IT A BLOCK**, then **PUSH IN** four times: the back half of the cell stays solid, the front half is a recess.
2. Raise the alcove cell's floor to half a wall and drop its ceiling to seven-eighths (HEIGHT, or the wheel), so the recess runs from the middle of the wall up to just under the top.
3. PLACE a terminal (`t`) in the alcove cell, select it, **MOVE IT** down an eighth or two so it stands in the open half, and click the facing button until it says **STANDS, FACING SOUTH**: now it's fixed to the wall instead of turning to follow you.
4. In each room cell beside the alcove, **ADD A PILLAR**; then PUSH IN its sides until it's a slim post against the wall. PAINT its sides with `wall-lightstrip`, and put a light on a side for a glow.
5. With the LIGHTS brush on **PULSE**, put a light on the alcove's floor or ceiling.

**Decorations off-centre, and standing still.** A decoration stands in its cell's middle unless it's moved: select it, and its pane's **MOVE IT** row nudges it up to three eighths each way. That's how one stands in an alcove or against a block. Most decorations are **3D props**: models, not pictures, so you walk round them and see their sides and backs (OpenGL draws the model; the software renderer shows it from the nearest of 8 ways round, as DOOM did). Which way one faces: furniture built against a wall (a terminal, console, screen, locker, vending machine, rack, desk, bench, lab bench, generator or cryo pod) has its back to that wall, as it would be built; a chair faces the desk, console, terminal, screens or lab bench beside it; anything else is turned a way of its own. The button under MOVE IT picks the way for yourself: **AS BUILT** (that), or **STANDS, FACING** east, south, west or north. **TURNS TO FACE YOU** is for the decorations that are still pictures - the hologram, and any prop whose model you've taken out of `neon-caster/models/` - which then always face you; a 3D prop set to it is turned a way of its own (or, a chair, to its desk).

The console makes blocks too: `block X Y X0 Y0 X1 Y1 [WALL]` (edges in eighths, WALL 1-6 for `#` to `G`), `block X Y none` to take one away. Blocks are saved as `[blocks]`, moved decorations as `[nudges]` (below).

## Lights

A level is lit by one **ambient** level everywhere (unless a cell has a **cell light** of its own, below), plus up to 1024 **lights** that stop at walls.

**Lights on faces.** With the LIGHT tool, a click puts a light just in front of the middle of the face you click, in the light brush's colour and effect. The **LIGHTS** tab sets the brush (each effect is shown going, as it will in the game), and a face's pane sets its light's colour, effect, reach (in cells) and brightness, or removes it. A light on a wall's face also **tints the face itself** its colour: a coloured copy of its picture, which OpenGL lights by itself and pulses or flickers with the light. So a red light shows red on its wall even in a room already as bright as it can be, where light alone would add nothing. A light on a floor or ceiling, or in the middle of a cell, lights the room round it the usual way. Each light is a little star in its colour in the 3D view.

Lights add to what's there, and the brightest a pixel can be is its picture's own colours. So in a brightly lit room a coloured light shows mostly on the face it's on. For moody colour, lower the ambient.

**`ambient = brightness, red, green, blue`** sets the base light. Brightness runs 0–256, where 256 shows every picture in its own colours; the other three tint it (0–255). NEW SECTOR uses `165, 225, 220, 255`, a cool dim blue.

**Below 0 (down to -255), the sector has no light of its own and every light in it is turned down** - lamps, their glows and shafts, and cell lights, all by the same share: -100 takes 100/255 of each away (about 40%), -255 puts them all out, pitch black but for a flashlight, muzzle flashes and explosions. It keeps your lights' balance while making the whole sector darker. `ambient -200` does it in play.

**`[lights]`** has one line per light: `x, y, radius, brightness, red, green, blue, effect`.

| Field | Meaning |
| --- | --- |
| `x`, `y` | Where, in cells. `20.5` is the middle of cell 20. A light on a wall's face sits 0.12 in front of it (`26.12`, `19.88`...), and that's how the game knows to tint the face. |
| `radius` | How far it reaches, in cells. It fades to nothing at the edge. |
| `brightness` | 0–400, added on top of the ambient light |
| `red`, `green`, `blue` | Its colour, 0–255 each |
| `effect` | 0 steady · 1 flickering tube · 2 slow pulse · 3 alarm strobe · 4 firelight · 5 dying tube |
| (a 9th) | `1`: no lamp - the light's cell keeps its own ceiling picture and has no beam (the pane's CEILING LAMP: OFF). Left off, the light hangs a lamp there as always. |

**The 1024-light budget includes automatic lights.** Lamps, terminals, server racks, glowing decorations, the exit and teleporter pads each add a light of their own. Past 1024, extra lights are dropped without a message, and the editor can't warn you because it only counts the level's own list. If a light you placed doesn't show, you've probably hit the limit.

**Lights that change as the sector plays.** The console - so a trigger too - can change the light while you play (N counts the `[lights]` lines from 1):

| Command | What it does |
| --- | --- |
| `light N on` / `off` / `toggle` | Switch a light (its lamp goes dark with it). `light N` alone says how it is |
| `light N colour RRGGBB` | Its colour (`FF2020` red) |
| `light N bright 0-400` | Its brightness |
| `light N fx steady\|flicker\|pulse\|strobe\|fire\|dying` | Its effect |
| `ambient BRIGHT [RRGGBB] [FX]` | The sector's own light: every cell with no cell light of its own (below 0, to -255: none, and every light dimmer). `ambient` alone says how it is |
| `cell-light X0 Y0 X1 Y1 BRIGHT RRGGBB [FX]` | Those cells a light of their own (0 is dark) - `cell-light X0 Y0 X1 Y1 off` gives them the sector's light again |

A **light switch** is a trigger on a wall: `use 12 8 repeat : light 3 toggle` (put `wall-switch.png` on the face). An **alarm that turns a room red**: `alarm : cell-light 10 4 18 9 150 FF2020 pulse` and, when it stops, `calm : cell-light 10 4 18 9 off`. A power cut: `enter 30 2 34 6 : ambient 20 4060FF flicker`. The TRIGGERS pane has three buttons for these: **LAMP O/I** (switch the light nearest the selection), **AREA RED** and **AREA OFF** (the selection's cells). The changes are light only - the game plays the same - and a saved game keeps them.

**Cell lights: ambient light, cell by cell.** A cell light isn't a lamp. It replaces the sector's ambient light in the cells it covers, so a room can be dim and red, or a corridor bright and cold blue, while the rest of the sector keeps its own light. Lights still add on top. Select floor cells (drag a box, or Shift+click several; in 3D, Ctrl+click a floor takes the whole room's floor at that height), and the floor pane's **CELL LIGHT...** opens their pane - with two or more cells selected it's at the top of whatever pane shows (**CELL LIGHT (ALL SELECTED)...**), so a light, a monster or a door in the box doesn't hide it: **-** and **+** for brightness, a colour (twelve swatches, or **TYPE** any as six hex digits, `FF8800` orange, Enter to keep it), and **EFFECT** (steady, flicker, pulse, strobe, fire, dying - every cell with the same effect goes as one, so a room flickers together). A cell with no light of its own starts from the sector's light when you change it; **BACK TO THE SECTOR'S** gives it the sector's light again. They cost nothing: there's no budget, as there is for lights. **To see a cell's light**, point at it: the 3D view's info box (top left) and the map view's **CELL** lines say `LIGHT 48 ITS OWN` (a cell light, and its effect) or `LIGHT 0 THE SECTOR'S`, then `LIT 112 NOW` - how bright it is with every light and glow reaching it (256 shows a picture in its own colours), in its light's colour. A dark patch in a lit room is usually a cell the cell light missed.

**`[cell lights]`** has one line per box of cells lit alike: `x0, y0, x1, y1, brightness, red, green, blue, effect` - brightness 0-256, the colour 0-255 each, the effect as a light's (0 steady to 5 dying). Later lines win where they overlap. The editor writes them as few boxes as it can.

## Beyond the editor: the level file

Only the puzzles have no editor tool yet. Write them into the level file, `neon-caster/levels/custom/customN.txt`, in any text editor, then reload the sector. The file is plain text: `key = value` lines at the top, then `[sections]`, and lines starting with `'` are comments.

Ctrl+S rewrites the whole file in a fixed layout. Only the comments at the very top survive, so keep your notes there.

**Pictures.** `walls =` needs exactly 6 picture names (for `# N C K P G`), `floors =` 4 and `ceilings =` 2. A misspelled name is drawn as the plain `wall.png`, and the console says "Missing texture" with the name (only a missing `wall.png` itself stops the game). These are the pictures in `neon-caster/`:

- **Walls:** wall, wall2, wall-adverts, wall-biolab, wall-brick, wall-coils, wall-concrete, wall-control, wall-core, wall-cryo, wall-datastream, wall-frost, wall-furnace, wall-girders, wall-graffiti, wall-grate, wall-greenhouse, wall-greenpipes, wall-hazard, wall-hull, wall-ice, wall-lightstrip, wall-moss, wall-obsidian, wall-pipes, wall-reactor, wall-rusty, wall-servers, wall-slime, wall-stripes, wall-terminals, wall-tiles, wall-transit, wall-vault, wall-viewport, wall-vines, wall-white. (`wall-jack` and `wall-code` are the data station's and code terminal's own.)
- **Floors:** floor, floor-circuit, floor-cobbles, floor-concrete, floor-core, floor-deck, floor-frostgrate, floor-glow, floor-hazard, floor-ice, floor-lab, floor-molten (burns), floor-murky (slows), floor-plates, floor-platform, floor-rustgrate, floor-scorched, floor-soil, floor-white.
- **Ceilings:** ceiling, ceiling-cables, ceiling-core, ceiling-frost, ceiling-girders, ceiling-growlights, ceiling-hull, ceiling-lights, ceiling-pipes, ceiling-stone, ceiling-tunnel, ceiling-vents, ceiling-warning.

All end in `.png`. The picker's WALLS, FLOORS and CEILINGS tabs show them all, and PAINT puts any of them on any face (`[faces]`, below) without changing the lists.

**`[zones]`** choose which of the 4 floor and 2 ceiling pictures each area uses: `x0, y0, x1, y1, floor, ceiling, shape`. `floor` is 1–4 and `ceiling` 1–2 (0 leaves it alone). `shape` 0 is the whole rectangle; 1–4 is the top-left, top-right, bottom-right or bottom-left triangle of a square. Later zones win where they overlap. The 3D view's **Z** gives a cell the next floor picture with a one-cell zone (Z again on the same cell changes that zone rather than adding another). Up to 256.

**`puzzles = NAME, NAME, …`** gives each `$` code terminal its puzzle, in reading order, from `neon-caster/puzzles/`: countdown, function, hello, multiply, password, pythagoras, reverse, select, sum, wrap.

**Draining a pool.** `drain X Y [SPEED]` drains the pool at cell X, Y - every liquid cell joined to it, lava too - SPEED eighths a second (4) till the floor's dry; a lava pool's glow goes out with it. A switch to drain an enclosed room: put `wall-switch.png` on a wall's face (PAINT) and a trigger on it - `use 12 30 : drain 20 30 ; message THE LAVA DRAINS AWAY`. (`liquid KIND X0 Y0 X1 Y1` floods a rectangle at once; `liquid none ...` empties one at once.)

**`gravity = N`** (the sector pane's GRAVITY): the sector's gravity, N percent of the usual (1-300; 100 as made, and then left out of the file - a few percent is near zero-g, Quake's low gravity is about 12). Lower, you fall slower, jump higher (JUMP, Q as made) and a jetpack lifts you more easily; higher, the other way. A trigger can change it as you play: `enter 20 4 30 10 : gravity 30 ; message LOW GRAVITY`.

**`wetness = N`** (the sector pane's WETNESS): how wet the sector's floors look - how much of OpenGL's mirror image shows in them (WET FLOORS): `0` dry to `9` soaked. Left out (WETNESS AUTO), each floor is as its picture is - concrete hardly, ice a lot. Floors can have their own, below. Only the look: nothing slips.

**`glass_reflect = N`** (the sector pane's GLASS REFLECTS): how much the sector's glass mirrors the room you're in (OpenGL's GLASS REFLECTIONS, in EFFECTS): `0` none to `9` a mirror. Left out, `2` - a faint image, stronger the more slantwise you look, as real glass is. What's reflected is lit as it really is: the flashlight's beam, muzzle flashes and explosions show in it, and a flashlight pointed at the glass glares back at you. A pane can have its own, below. In the console, `glassreflect N` (the sector's) and `glassreflect X Y N` (one pane's; `auto` back to the sector's).

**`glass_style = N`** (the sector pane's GLASS < >): the picture the sector's glass shows - `0` streaks (left out), `1` clear, `2` sheer, `3` panes, `4` grid, `5` bricks, `6` leaded, `7` privacy. A pane can have its own, below. In the console, `glass style N` (or a name).

**`droids = N`** says how many service droids roll about the sector, 0 to 6. Leave it out for the usual three. In the console, `droids N` sets it for the sector you're in (save to keep it), and `droids` on its own lists where they are.

**`[events]`** (MAKE AN EVENT ROOM, and an event's pane) are rooms that do something when you walk in: `kind, x0, y0, x1, y1, a, b, reward`. Doors within 5 cells of the room belong to it. Up to 32.

| Kind | Event | `a` | `b` |
| --- | --- | --- | --- |
| 1 | Ambush | How many monsters | Monster type (0 = a mix) |
| 2 | Survive | Seconds | Frames between arrivals |
| 3 | Trap (electric) | Frames live | Frames safe |
| 4 | Gallery | Seconds to break every decoration in the room | |
| 5 | Nest | Monster type | Frames between spawns |
| 6 | Closet | | (opens `%` walls within 3 cells) |
| 7 | Hoard | | (sealed until every thief is dead) |
| 8 | Plate | Frames until the blast | Frames until it re-arms |
| 9 | Laser | Frames on | Frames off (0 = always on) |
| 10 | Cutter | Frames per sweep | |
| 11 | Blackout | Seconds | Number of monsters |
| 12 | Trap (fire) | Frames live | Frames safe |
| 13 | Death pit: land on its lowest floor, from any height, and you die - a pit with a bottom you can see, or the streets under rooftops (higher floors in its room are safe). Never locks or ends. | | |

A trap's floor gets its own picture (a glowing wire grid, or a burner grate), and it warns you for half a second before it goes live: crackles and short arcs, or smoke and embers. While live it arcs or blazes, lights the room and buzzes or roars. Use kind 12 in hot places (reactors, foundries), kind 3 elsewhere.

Monster types are numbered in the order of the monster table: 1 drone to 9 thief. `reward` is a pickup given when you win, numbered in this order: 1 red card, 2 blue card, 3 yellow card, 4 health, 5 cells, 6 shells, 7 scatter gun, 8 repeater, 9 armour, 10 medkit, 11 railgun, 12 map, 13 overcharge, 14 amp. Use 0 for none. Only ambush, survive, trap and gallery give one. A trap or cutter with `a` of 0 is a mistake: it logs an error.

**`[lifts]`** (MAKE A LIFT, and a lift's pane): `x0, y0, x1, y1, low, high, mode, speed`. `low` and `high` are in eighths and `speed` is eighths a second. `mode` 1 goes up and down by itself, 2 is an elevator (step on and it takes you to its other end; it comes up to meet you when you wait by it at the top, and goes back down when nobody is about up there), and 3 moves only when a `liftgo` command says so. Modes 4 and 5 move the box's **ceiling** instead, as DOOM's crushers do: `low` is how far down it comes, `high` its top. 4 is a **CRUSHER**: down slowly at its speed and back up, over and over, and while it's lower than you are tall it crushes you - 10 every 8 frames, about 75 a second, so stand under one for long and you're dead. 5 is a **SMASHER**: it waits up top for a second and a half, slams down six times as fast with a bang and a shake - 45 at once - and grinds back up. Monsters under them are crushed too. Make one in the editor by making a lift of the floor cells, then clicking its mode round to CRUSHER (DOWN TO an eighth off the floor, UP TO the ceiling). Up to 16 lifts and crushers between them.

**`[faces]`** (PAINT and Divide): a picture of its own on one face, one line each: `x, y, face, divided, picture, second picture`. `face` is `E` `S` `W` `N` for a side of the cell (a wall's, or a step's face), `LE` `LS` `LW` `LN` for a lintel's, `F` the floor, `C` the ceiling, `BE` `BS` `BW` `BN` for a side of the cell's block, `DG` a diagonal wall's slanted face, `DE` a door's edges (and a shutter's underside), `DT` its track. A door's faces are its cell's sides (`N` `S`, or `W` `E`); a lift's top is its `F`, its sides its `E` `S` `W` `N`. `divided` is 0 for the whole face, 1 for left | right, 2 for top | bottom; the second picture is the second half's (left out: the usual picture). A face in more pieces than that - or turned, or tinted - is `divided` 3: its first picture is the pieces' shape and its second each piece's look. The shape is written H (split left | right), V (top | bottom) and `.` (a piece), first to last as you read it - `H.V..` is a left half and a right half split top and bottom. Each piece is `picture*turn*slide*stretch*tint*amount*colour*start*filters`, the pieces joined by `|`: turn 0-3 quarters clockwise (4-7 the same, flipped left-right first: 6 is upside down), slide and stretch as one number each (across + 64 × up, across + 2048 × up; 0 as made), tint 0 none, 1 TINT, 2 WASH, 3 GLOW, amount 0-100, colour `RRGGBB`, start 0 the face's grid, 1 the piece's corner, 2 fitted to the piece, filters a letter each with its number (`X` pixelate - blocks across, `L` blur, `R` sharpen, `E` emboss, `B` bright, `C` contrast, `S` saturate, `H` hue in degrees, `P` posterize - levels, `I` invert, then OpenGL's effects off: `F` no bumps, `M` no shine, `N` no neon: `E2B20I`, `FN`) - and anything left as made dropped off the end: `28, 9, S, 3, H.V.., |wall-biolab.png|*1*0*0*2*80*00FF88` (the left half the usual picture, the top right `wall-biolab.png`, the bottom right turned a quarter and washed green). Two more numbers after it slide the picture (PAINT + Shift+arrows): 64ths of the picture - its pixels, at 64 - along the face and up it, 0-63 - `28, 22, W, 0, wall-biolab.png, , 16, 0` (the second picture left empty). Two more after those stretch it, percent across and up: `28, 22, W, 0, wall-biolab.png, , 0, 0, 200, 100`. A face whose picture is only slid or stretched has an empty picture: `x, y, W, 0, , , 8, 0`. Up to 4000.

```
26, 26, W, 0, wall-adverts.png
25, 18, S, 2, wall-adverts.png, wall-brick.png
24, 23, F, 1, floor-circuit.png, floor-cobbles.png
```

**`[blocks]`** (MAKE IT A BLOCK, ADD A PILLAR, a block's pane): `x, y, x0, y0, x1, y1, wall`. `x0` to `x1` is where it runs across its cell and `y0` to `y1` down it, in eighths (0 to 8, low before high); `wall` is 1-6, the look of `#` `N` `C` `K` `P` `G`. Only in an open cell, one to a cell. Up to 256.

```
24, 19, 0, 0, 8, 4, 1
23, 20, 5, 0, 8, 3, 4
```

**`[barrels]`** (a barrel's pane: LIQUID, STACK): `x, y, liquid, stack` - liquid 0 for a plain barrel `o`, 1 water, 2 poison, 3 slime, 4 lava, 5 acid for a `:` barrel (poison if it has no line), stack 1-8 standing on each other (as many as fit under the ceiling: the rest are left off). Up to 96.

**`[doors]`** (a door's pane: KICKS, KEYPAD CODE): `x, y, kicks, code` - kicks a stronghold door takes to break (0: none), code a keypad's digits (up to 8; `?` one made up each time the sector starts; nothing after the comma: no keypad).

**`[things]`** (a `"` cell's pane): `x, y, kind[, more]` - kind one of `table`, `brokenmonitor`, `deadscientist`, `deadguard`, `deadcyborg`, `bookshelf`, `safe`, `brokenpc`, `computer`, `camera`, `secmon`, `alarm`, `alarmpc`, `jumppad`, `padpc`, `repairkit`, `invuln`, `robodog`, `guard`, `eyebot` (or any decoration, pickup or monster by its name). After it: a safe's code (digits or `?`); a computer's (fixed or broken) `x, y` of the door, safe or alarm switch it opens (or switches off); a camera's name; `off` for an alarm switch off at first; a security console's `x, y` of its alarm (none: every alarm); a jump pad's `DIR, ANGLE, POWER`; a launch control's `x, y` of its pad. A `"` with no line is a table on its side.

**`[notes]`** (NOTE on a `'` note's, a desk's, a bookshelf's or a safe's pane): `x, y, picture, words` - picture a file in `neon-caster/` (`-` for none: say `achievements/NC_BESTIARY.png`), then the words, commas and all; `|` starts a new line, `{code X Y}` is the code of the door or safe at X, Y.

**`[fuel]`** (a jetpack's or fuel can's pane: FUEL): `x, y, amount` - its own fuel, 1-100 (as made: a jetpack's tank full, 100; a can 40).

**`[liquid opacity]`** (a liquid cell's pane: LIQUID - +): a map of one character a cell, as `[liquid depth]` is - `.` as its kind is made, `1`-`9` that many tenths more solid, `x` solid: you can't see the bottom of that pool (OpenGL; the software renderer draws liquids solid anyway). Select the cells (a pool, or part of one) and step it; `liquid KIND X0 Y0 X1 Y1 DEPTH SOLID%` from the console or a trigger.

**`[floor wetness]`** (a floor cell's pane: WET - +): a map of one character a cell - `.` the sector's wetness, `0` dry to `9` soaked. A dry office beside a flooded corridor, a puddle under a leak. `wet X0 Y0 X1 Y1 N` from the console does the same - in the editor, into the level; from a trigger, as you play (the rain coming in: `enter 10 4 20 8 : wet 10 4 30 20 9`).

**`[smears]`**: `x, y, face, what` - blood or oil: on a wall's side (x, y a wall cell, face `E` `S` `W` `N` the side facing into the room), or an open cell's floor (`F`) or ceiling (`C`); what `blood1` `blood2` `blood3` `oil1` `oil2`. Up to 128. (In the editor: PAINT with one of the blood or oil pictures at the end of the walls, floors and ceilings tabs - painting a face with any other picture wipes it off.)

**`[difficulty]`** (IN DIFFICULTY on a pickup's, monster's, decoration's or thing's pane): `x, y, words` - which difficulties what starts at x, y is in: any of `easy` `normal` `hard` `nightmare` (spaces or commas between), or `none` (in none: put away for later). No line: every difficulty, thinned as the game thins everything; a line: exactly those, as placed (no thinning, no NIGHTMARE twin). A keycard must be in every one - the level kit says so. A sector that leaves its harder pickups out at EASY: `12, 30, hard nightmare`.

**`[looks]`** (ITS LOOK on a pickup's, monster's, decoration's, thing's or glass's pane): `x, y, tint, amount, colour, size` - how what starts at x, y looks: tint 0 none, 1 TINT, 2 WASH, 3 GLOW, amount 0-100, colour `RRGGBB`, size percent (10-400; left off, 100). A monster, pickup or decoration takes the look of the cell it starts in; what comes later (a dropped pickup, a spawned monster) has none. Red glass: `13, 11, 1, 80, FF2020`; a giant green monster: `6, 13, 1, 100, 00FF00, 150`.

**`[glass]`** (REFLECTS, BLUR, FROST, RIPPLE, STYLE, THROUGH on a pane of glass's pane): `x, y, amount[, blur, frost, ripple[, style[, through[, strength]]]]` - how much that pane reflects, `0` none to `9` a mirror (`.` the sector's `glass_reflect`; no line, all as made), then how blurred its reflection is, how frosted it is and how rippled (reeded), each `0`-`9`, its style (`.` the sector's `glass_style`, or `0`-`7` as above) `1` to keep what's seen through it clear, and its strength (`0` as tuned, `999` unbreakable) - left off from the end while they're as made. A mirror in a washroom is a pane at 9 in front of a wall; a bathroom window `13, 11, ., 0, 7, 0`; a wall of glass bricks `13, 11, ., 0, 3, 0, 5`. In the console, `glass X Y` shows a pane's settings and `glass X Y frost 7` (or `reflect`, `blur`, `ripple`, `style bricks`, `through clear`, `strength unbreakable`) sets one. Shots crack glass where they land.

Together `[doors]`, `[things]`, `[notes]`, `[smears]`, `[fuel]`, `[difficulty]`, `[looks]` and `[glass]` hold up to 512 lines.

**`[nudges]`** (MOVE IT): a decoration moved off its cell's middle, `x, y, dx, dy, facing` - `dx` and `dy` in eighths across and down, -3 to 3; `facing` 0 (or left out) is as built (furniture against a wall stands flat with its back to it; anything else turns to face you), 1-4 stands it flat facing east, south, west or north, 5 turns it to face you always. Up to 160.

**`[pads]`** (LINK): teleporter pads paired by hand, `x1, y1, x2, y2`. Pads in no pair here pair up as ever, in reading order. Up to 16.

**`[monsters]`** (a monster's pane): `x, y, sight, hearing, health, speed, wake`, by the cell the monster starts in. Sight and hearing are in cells, health and speed in % of its kind's, and wake is 0 seeing you, 1 you near, 2 being hit, 3 hunting from the start. A turret can have more: an eighth number, its weapon (0 plasma, 1 laser, 2 lightning, 3 flame, 4 poison, 5 acid, 6 missiles), a ninth, how fast it turns (degrees a second, 0 as made), a tenth, how many frames it takes to come out (0 as made, 36), and an eleventh, how it starts (0 out when it wakes, 1 folded away till a `turret` command, 2 out). Numbers past the last one that isn't 0 are left off.

**`[triggers]`** (TRIGGERS... in a pane) run console commands when something happens: `WHEN [repeat] : COMMAND ; COMMAND`.

| WHEN | Fires when |
| --- | --- |
| `enter X0 Y0 X1 Y1` | You step into the rectangle |
| `use X Y` | You press Space facing that cell |
| `shoot X Y` | You shoot (or kick) the wall or the thing in that cell. Put `wall-switch.png` on that wall's face (PAINT, or `[faces]`) and it's a switch. Not in the pane's buttons yet: TYPE it in the level file or with the console's `trigger` |
| `clear X0 Y0 X1 Y1` | Every monster that started in the rectangle is dead |
| `time S` | S seconds into the level |
| `hack X Y` | The computer (a `"` computer) at that cell is hacked (HACK in the pane) |
| `alarm [X Y]` | The alarm switch at that cell sets the alarm off - or, with no cell, any switch (ALARM in the pane) |
| `calm` | The alarm stops - run out, shut off at a switch or a console (CALM in the pane) |

Without `repeat`, a trigger fires once (`alarm` and `calm` can take it: the alarm can go off again). Don't put `repeat` on `time` or `clear`: once true they stay true, so the trigger fires every frame. If you start inside an `enter` rectangle, it waits until you leave and come back. Up to 96. For example:

```
enter 20 20 22 22 : message AMBUSH! ; spawn stalker 24 21 3
enter 12 30 12 34 : door 15 32 open ; spawn crawler 16 32 4
use 30 14 : door 31 14 open ; sound alarm ; item medkit 31 16
shoot 27 19 : secret 21 15 ; message The sealed vault's wall slides open...
```

The last is NEW SECTORS 7's sealed vault: shoot the red button across the corridor and the secret wall at (21, 15) slides away.

A trigger box one cell thick across a corridor (the second line) is a line: cross it and the closet door beside it opens, with its crawlers already inside.

**`[liquid]`** and **`[liquid depth]`** (the LIQUIDS tab): two more maps like `[floor]`, one character a cell. `[liquid]` is `.` for none, or `w` water, `p` poison, `s` slime, `l` lava, `a` acid; `[liquid depth]` is `.` for three eighths, or `1` to `8`. Both are left out when there's no liquid.

**`[loot]`** says what breakables leave behind. One line per kind: `BREAKABLE = DROP, DROP, DROP, DROP`, up to four drops (A to D), each `pickup:chance` with the chance in percent, or `-` for an empty slot. Breaking one rolls 1 to 100 once, shared out in order: drop A has the first A%, B the next B%, and so on, so each drop's chance is as written and the chance of anything at all is them added up (`crate = ammo:20, shells:20, medkit:20, armor:10` gives something 70% of the time). The one it lands on is tossed out of the wreck. It goes any way at all if the thing was shot or blown up, and back your way if you kicked it. It lands where you can see it and walk over to it, never at your feet, and can't be caught in mid-air. When your guns are down to under a quarter of their ammo, every chance is doubled.

```
crate    = ammo:20, shells:20, medkit:20, armor:10
locker   = amp:10, -, medkit:30, armor:30
plant    =
```

The third line makes plants leave nothing. A breakable is any decoration's name: `barrel`, `crate`, `desk`, `locker`, `labbench`, `vending`, `console`, `plant`, `terminal`, `rack`, `generator` and so on. The pickups are the `item` command's names (`ammo` is energy cells). Kinds the section doesn't name keep the game's own table:

| Breakable | A | B | C | D |
| --- | --- | --- | --- | --- |
| barrel | ammo 10% | shells 10% | medkit 5% | armor 5% |
| console | ammo 5% | shells 5% | | |
| crate | ammo 20% | shells 20% | medkit 20% | armor 10% |
| desk | ammo 10% | shells 10% | medkit 10% | armor 5% |
| locker | amp 10% | overcharge 10% | medkit 30% | armor 30% |
| labbench | ammo 5% | shells 5% | medkit 10% | armor 5% |
| vending | ammo 50% | shells 50% | medkit 25% | armor 10% |
| plant | ammo 5% | shells 5% | medkit 5% | |

The console's `loot` lists the sector's table; `loot crate ammo:20 shells:20 - armor:10` sets one kind, `loot crate none` empties it, and `loot default` puts the game's table back. Then **savelevel** (or Ctrl+S) writes it into the level's `[loot]`.

## Building from the console

The console (`` ` ``, in the game or the 3D view) can build with exact coordinates, which is quicker than clicking for big shapes. Put several commands on one line with `;`, and press Tab to finish a command's name. The building commands work even outside the editor, but each one rebuilds the level, so monsters and pickups reset.

| Command | Does | Kept by Ctrl+S? |
| --- | --- | --- |
| `edit` / `edit walk` / `edit off` | Open the editor at the map or 3D view, or close it | |
| `put X Y CHAR` | Put one character in a cell | Yes |
| `box X0 Y0 X1 Y1 CHAR` | Fill a rectangle (one undo step) | Yes |
| `raise X Y EIGHTHS [ceil]` | Raise (or lower, with a minus) one cell's floor or ceiling | Yes |
| `raise X0 Y0 X1 Y1 EIGHTHS [ceil]` | The same for a rectangle | Yes |
| `lamp X Y [1-8]` | A light over a cell, in a preset | Yes |
| `lift X0 Y0 X1 Y1 LOW HIGH [MODE] [SPEED]` | Add a lift (mode 2 and speed 8 unless you say) | Yes |
| `block X Y X0 Y0 X1 Y1 [WALL]` | A block in open cell X Y, edges in eighths, WALL 1-6 (`#` `N` `C` `K` `P` `G`); `block X Y none` takes it away | Yes |
| `trigger WHEN : CMD \| CMD` | Add a trigger; `\|` separates its commands. `trigger del N` removes one. | Yes, but Ctrl+Z can't remove it |
| `triggers` | List the level's triggers | |
| `undo` / `redo` / `savelevel` | Same as Ctrl+Z / Ctrl+Y / Ctrl+S | |
| `newsector` | A new blank sector of your own, in the editor | |
| `sectorname NAME` | Rename the sector you're in | After `savelevel` |
| `map 11` / `maps` | Go to a sector by number (or part of its name) / list them all | |
| `resetlevel` | The sector as it starts - its monsters, doors and pickups back - as it is in the editor now (anything not saved yet kept), and you where you are | |
| `reloadlevel` | The sector from its file, as you last saved it - what you've changed since is gone - and you where you are | |
| `savesectorcopy` | A copy of the sector as it is now, in a `versions/` folder beside its file, named for when (`custom3-2026-10-20-081500.txt`): save one before a big change, and you've a history to go back to | |
| `saveleveltodisk [FILE]` | Save the sector as it is now to any file - a dialog to choose it, or FILE | |
| `loadlevelfromdisk [FILE]` | A level file - a copy from `versions/`, or any - into this sector in place of its own (a dialog opens in `versions/`, or give FILE). It isn't saved till you `savelevel` (Ctrl+S): then it's the sector's own | After `savelevel` |

These only change the running level, so they're for testing and for triggers rather than building:

| Command | Does |
| --- | --- |
| `door X Y open\|close\|lock\|unlock\|toggle` | Work a door |
| `program NAME` | A computer runs `neon-caster/programs/NAME.bas` - any QB64PE program, built by qb64pe the first time and again whenever the `.bas` changes (SETTINGS > QB64PE COMPILER), kept in `saves/programs/`. No qb64pe on the computer? A box says how to get it (GET QB64PE opens its download page, FIND IT looks again, SET ITS PATH points at it). The program takes the game's place: the game hides and waits, and tells it how it was showing - `--fullscreen` or `--window` on its command line (`COMMAND$`). If it ends with `SYSTEM 1` you beat it, and the computer pays out. Put it on a computer with a trigger: `use 31 8 repeat : program invaders` (THE NEON EXPO's terminal plays NEON INVADERS) |
| `secret X Y` | Open the secret wall (`?`) at X Y - found, counted. `secret` alone lists the sector's secrets and what opens each |
| `wall X Y CHAR` | Swap a wall (`#` `.` `N` `C` `K` `P` `G`) until the next rebuild |
| `light N on\|off` | Switch one of the level's lights |
| `liftgo N up\|down` | Send a lift |
| `message TEXT` | Show a message |
| `give health N` / `give armor N` / `give ammo cells N` / `give ammo shells N` | N more (no N: full); `give all` everything |
| `take health N` / `take armor N` / `take ammo cells N` / `take ammo shells N` | N less: `take health` ignores armour and can kill; `take all` leaves only the blaster; `take keys`, `take key red`, `take gun N`, `take map` |
| `die [MESSAGE]` | You die (never in god mode or the editor) |
| `spawn TYPE X Y [N]` | N monsters teleported into cell X Y, hunting (sparks and a sound): an ambush from nowhere. `summon TYPE [N]` puts them in front of you instead |
| `item KIND X Y` | A pickup appears in cell X Y: health, medkit, armor, cells, shells, scatter, repeater, rail, map, overcharge, amp, goggles, red, blue, yellow (or its map character) |
| `liquid KIND X0 Y0 X1 Y1 [DEPTH]` | A pool over that rectangle's floor: water, poison, slime, lava or acid, DEPTH 1-8 eighths (3); `none` drains it. In a trigger, it floods a room |
| `loot` / `loot BREAKABLE DROPS` / `loot default` | What breakables leave in this sector: list it, set one kind (`loot crate ammo:20 shells:20 - armor:10`), or the game's own table back (see `[loot]`) |
| `mons` | List every monster: where it is, asleep or hunting, its health, and its own sight, hearing, speed and waking |
| `sound NAME` | Play `sfx/NAME.wav` |

`help` doesn't list most of these yet, but Tab completes them all. A trigger's commands can use your aliases only if the player has them - a sector you share should spell its commands out. Two worth knowing for testing: `summon TYPE [N]` puts monsters in front of you, and `god` stops them hurting you - it also lets you fly (E up, C down) and makes the monsters ignore you (`fly` and `notarget` do those on their own).

A room by console, as an example (sector made with NEW SECTOR):

```
box 29 21 36 27 . ; put 28 24 D ; put 37 24 E ; lamp 32 24 2 ; savelevel
```

That carves a second room east of the first (both corners are included), turns the old exit at (28, 24) into a door between the rooms, puts the exit in the new room's east wall, and lights the room cyan. There's still exactly one exit.

## The monster and HUD editors

Both change files that every sector shares, not the sector you're in.

**Monster kinds editor** (**M** or MONSTER KINDS in the map view, or `monsters` in the console) sets the numbers for each kind of monster (one monster's own settings are its pane, above), saved to `neon-caster/monsters.txt`. Changes take effect at once, except hit points, which apply to monsters placed after the change.

| Key | Does |
| --- | --- |
| PgUp / PgDn | Choose the monster |
| Up / Down | Choose the number |
| Left / Right | Change it; Shift changes it 10 steps at a time |
| S | Save `monsters.txt` |
| Esc, F2 | Back |

The numbers: hit points (1–200), speed, height, hover, bob, reach, damage (plus a random extra up to a limit), cooldown between attacks, whether it shoots, what it drops and the chance it drops it.

**HUD layout editor** (**U** in either view, HUD LAYOUT in the main menu's EDIT, or `hud` in the console) moves the on-screen displays, over the frozen game, and saves to `neon-caster/hud.txt`. From EDIT with no game going, it opens over the sector you edited last; when you're done (**U**) you're in the 3D editor. With FULL WIDE (OpenGL on a screen wider than 4:3) you can drag a part anywhere across the window. It keeps to the side it's dropped on (left edge, middle or right edge, by the middle of its box), so it stays put on any width of screen; **A** changes that side by hand. Delete that file to get the game's own layout back.

| Key | Does |
| --- | --- |
| Drag | Move the part under the mouse |
| Tab | Next part |
| Arrows | Nudge 1 pixel; Shift, 8 |
| V | Show or hide it |
| C | Next colour |
| `+` / `-` | Wider / narrower (the minimap and keycards: bigger / smaller) |
| `[` / `]` | Shorter / taller |
| A | Which side of a wide window it keeps to: left edge, middle, right edge (saved as `anchor`) |
| S | Save `hud.txt` |
| R | The game's own layout (S to keep it) |
| U, Esc | Leave |

The parts are health, armour, ammo, guns, kills, minimap, keycards, message, subtitle, amp, night vision, hazmat, jetpack, flashlight, poisoned, god mode, invulnerable, alarm, event, network, demo (REC, PLAYING and the demo's keys), achievement (the pop-up), readout (an alarm switch's or launch control's panel), FPS and timer.

While you're editing, every part shows sample text (a message, a subtitle, an event, an achievement and so on), even the ones that only show now and then in play. That way there's always something to see while you move it or colour it. Older `hud.txt` files that have no night vision, hazmat, jetpack, flashlight or poisoned lines put those parts beside the amp and health bars, as before.

## Gotchas, and a checklist before you save

The editor trusts you: it saves a level with no start, no exit or a gap in its walls, and only warns. Nothing in the game checks that keys can be reached or that doors have walls on both sides.

**Before you save:**

- [ ] Exactly one start (`<` `>` `^` `v`) and exactly one exit `E`
- [ ] The exit sits in a wall, with floor in front of it
- [ ] You can walk from the start to the exit, using only keycards you can reach first
- [ ] Every door has a wall on both sides
- [ ] Glass is in a straight wall one cell thick
- [ ] Steps are 2 eighths or less, and gaps you walk under are at least 6 eighths
- [ ] A map pickup `M` somewhere, or the minimap never appears
- [ ] Picture names in the file are spelled right (a wrong one in `walls =`, `floors =` or `ceilings =` quits the game; in `[faces]` it's just ignored)

**The other sets.** NEW SECTORS, OLD SECTORS NEW, HUGE SECTORS and INFILTRATION are plain level files too, in `neon-caster/levels/new/`, `remix/`, `huge/` and `infil/`. Play one and press F2, and the editor edits that set's file (Ctrl+S saves it there; `sectorset` waits till you've left the editor, so a save can't land in another set's file). They're built by `newsectors.py`, `remaster.py`, `hugesectors.py` and `maker.py`, and their `--write` rewrites all ten, so copy a change you want to keep into the script first.

**Check it with the level kit.** `levels.py --check` only checks the game's own ten sectors, but its checker works on one of yours too. From `neon-caster/levels/`:

```
python3 -c "import lvlkit; lvlkit.check_level(lvlkit.read_level_file('custom/custom1.txt','custom1'), '..')"
```

It reports anything you can't reach (following your `[pads]` pairs), doors without walls, a missing start or exit, and more. Never run `levels.py --write` on a level you've edited by hand or in the editor: it regenerates all ten game sectors from the kit and overwrites them. Your own sectors in `custom/` are safe from it.

**Dress it with the level kit's looks pass.** The game's four sets are dressed by `lvldress.py`, and it will dress one of yours too: every room gets a job and a colour (the start, the exit's green, a keycard's room in the card's colour, a hazard in its liquid's), a dark skirting and a neon line in pieces round its walls (a second line high up in the rooms that matter), wall lights that are a lit strip on the wall with a light in front, a light of its colour each side of every key door, sealed door and the exit, with the floor in front tinted to match, its own ambient leaning to its colour, wetter floors by liquid and its glowing props tinted. It changes only looks - nothing you walk on, shoot or pick up - and leaves anything you set yourself alone. From `neon-caster/levels/`:

```
python3 lvldress.py custom/custom22.txt -o custom/custom23.txt    a dressed copy, as sector 33
python3 lvldress.py custom/custom22.txt --report                  what it would do
python3 lvldress.py custom/custom22.txt --style cold              neon infernal cold toxic data clinical outdoor
```

A dressed file says so in a comment line near its top (`lvldress:`); `--redo` takes the old dressing off before dressing it again.

**Things that lose your work:**

- Leaving the editor doesn't save. You play the edited level, but dying, taking the exit, loading a game or quitting reloads it from the file.
- Ctrl+Z can't undo you back to "saved": after any undo the sector still counts as changed. Save, or press PgUp/PgDn twice and lose the edits.

**Other surprises:**

- Every edit rebuilds the level: dead monsters come back and your keycards are taken away.
- Walls and heights are per cell, so a wall moves a cell at a time and Divide only splits pictures. For less than a cell, use a block.
- Ctrl+S keeps only the comments at the very top of the file; everything else is rewritten in a fixed layout.
- Lights over 96 in total (automatic ones included), and pictures on faces past 24 different ones, are dropped. ADD A LIGHT TO IT says when the level's own are full; the automatic ones (a lamp's, an exit's, a pool's glow) just stop.
- Undo covers everything the editor changes: the map, heights, zones, lights, lifts, events, triggers, faces, pad pairs, monsters' settings, blocks, moved decorations, the name and the ambient light.
- A block, a moved decoration, a pool and a light belong to their cell, like a monster's settings: the arrows carry them along, and putting a wall or a door in the cell takes its block away.
- A monster's own settings belong to the cell it starts in: the arrows carry them along, and putting something else in the cell drops them.
- Esc in the 3D view opens the pause menu; the editor keeps going underneath it.
- Opening the editor puts cheats on for that game: achievements and records wait until the next new game. The editor's own two achievements, Architect (save a sector) and Thinking Inside the Box (stand a block), still count.
- There's no in-game way to delete one of your sectors: delete its file in `neon-caster/levels/custom/`. The `.bak` file next to it is the editor's backup copy of the level.
