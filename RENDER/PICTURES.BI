''
' NEON-CASTER - RENDER/PICTURES.BI
' =============================================================================
' Chapter 5: pictures in arrays - sprite and texture slots (S_, T_),
' and how big pictures are kept.
'

' How far a body or a wreck sinks into the floor, as a share of its height.
' Its picture stands upright at its middle, but its bottom edge is the near
' side of the heap - which, lying flat, would meet the floor nearer you.
' Sunk a little, it sits on the floor instead of hovering over it (OpenGL
' hides what's under the floor).
CONST CORPSE_SINK = 0.18
'-----------------------------------------------------------------------------
' CHAPTER 5: PICTURES IN ARRAYS
'-----------------------------------------------------------------------------
' Drawing 120,000 pixels a frame one PSET at a time would be far too slow, and
' so would reading textures back with POINT. So the game keeps its pictures
' in plain arrays of colours and draws the 3D view into another array,
' pixels(), at half size: 400 x 300. Reading and writing array elements is
' fast. Once the whole view is in pixels(), it's copied into an image in one
' go with _MEMCOPY and stretched onto the window with _PUTIMAGE (chapter 17).
'
'   texture(x, y, slot)     64 x 64 wall, floor and ceiling pictures,
'                           numbered by "slot" (the T_ constants below)
'   spriteTex(x, y, slot)   up to 64 x 64 pictures of things: monsters,
'                           pickups, decorations (the S_ constants)
'   pixels(y * 400 + x)     the 3D view being drawn this frame
'   zBuffer(x)              how far away the wall is in each column - so
'                           sprites can hide behind walls (chapter 16)
'
' The HUD and the gun are drawn later, on the window itself at full size,
' with ordinary QB64PE graphics (chapter 18).

' --- Sprites (billboards): pictures, and the list drawn each frame ---
' SPR_ = SPRite picture storage: each picture is up to sprTex pixels square
' (64, or 256 for MODERN art with OpenGL - ArtReload, chapter 23),
' and there are SPR_SLOTS of them. A "slot" is just a picture's number - the
' third index of spriteTex(x, y, slot):
'   1-3 keycards, 4 medkit, 5 cells, 6 shells, 7 scatter gun, 8 repeater,
'   9/10 drone (/hit), 11/12 gunner, 13/14 heavy, 15/16 crawler, 17/18 sentry,
'   19 bolt, 20-23 decorations (barrel, lamp, plant, terminal), 24 explosion,
'   25 armour, 26 big medkit, 27 railgun, 28 map - and after those, each
'   block worked out from the one before (so a new monster or decoration
'   only has to change MON_TYPES or DECO_KINDS): every monster's body,
'   lying where it fell (S_CORPSE + type: MakeCorpse); a scorch mark (the
'   software renderer's decals: S_DECAL); every decoration, broken
'   (S_WRECK + kind: MakeWreck); the monsters' animation, five frames each
'   - four of moving, then one of attacking (MonFrame); an explosion's six
'   frames (S_BOOM + 1..6: MakeBoomFrames); then the pictures of the
'   monsters, decorations and pickups added after the first ones (types
'   6 on - their picture and their hurt picture, S_MONX; decorations 5 on,
'   S_DECOX; pickups 13 on, S_ITEMX)
CONST BOOM_FRAMES = 6
CONST ANIM_FRAMES = 4, ATTACK_FRAMES = 12 ' (frames a monster shows its attack frame)
' S_ = Sprite slot: names for a few of those numbers. S_DECO + kind is one
' of the first four decorations' slot (barrel = S_DECO + 1 = 20, and so on:
' DecoSlot has them all).
CONST S_BOLT = 19, S_DECO = 19, S_BLAST = 24, S_CORPSE = 28
CONST S_DECAL = S_CORPSE + MON_TYPES + 1, S_WRECK = S_DECAL, S_ANIM = S_WRECK + DECO_KINDS
CONST S_BOOM = S_ANIM + MON_TYPES * (ANIM_FRAMES + 1), S_MONX = S_BOOM + BOOM_FRAMES
CONST S_DECOX = S_MONX + (MON_TYPES - 5) * 2, S_ITEMX = S_DECOX + DECO_KINDS - 4
CONST S_TRAP = S_ITEMX + ITEM_KINDS - 12, S_PLATE = S_TRAP + 1, S_LASER = S_TRAP + 2 ' (traps: a pressure plate, a laser beam)
CONST S_GLASS = S_TRAP + 3 ' (glass: whole, then cracked)
CONST S_PAD = S_GLASS + 2 ' (a teleporter's pad)
CONST S_DROID = S_PAD + 1 ' (the droids: the two kinds, then each broken)
' 3D props (RENDER/MODELS.BM): each model's texture, for OpenGL (its 8
' pictures round it, for the software renderer, are kept apart: mdlPic)
CONST MAX_MODELS = 96
CONST S_BEAM = S_DROID + 4, S_BEAM_AIM = S_BEAM + 1 ' (a laser's beam, firing and aiming: a glowing dot each - MakeBeamDot)
CONST S_PUFF = S_BEAM_AIM ' (S_PUFF + a bolt's kind, 1 to BOLT_KINDS: a rocket's, a missile's, a spray's glowing picture - MakePuff)
CONST S_SIGHT = S_PUFF + BOLT_KINDS + 1 ' (S_SIGHT + a turret's weapon: its laser sight's dot, in the weapon's colour)
CONST S_TURTOP = S_SIGHT + TURRET_WEAPONS + 1 ' (a turret from above: a wall turret's picture, from the room)
CONST S_GIB = S_TURTOP ' (S_GIB + monster type, then + MON_TYPES + decoration kind: a piece of it, for when a rocket blows it apart - MakeGib)
CONST S_ACID = S_GIB + MON_TYPES + DECO_KINDS + 1 ' (an acid stain: OpenGL's - its strength in its colour - then the software renderer's, a picture: MakeAcid)
CONST S_MIMICNAP = S_ACID + 2 ' (the mimic asleep: the chest, all but its lock)
CONST S_BARS = S_ACID + 3 ' (bars across a window: -)
' Blood and oil smeared on a wall, a floor, a ceiling ([smears]): decals of
' kind DK_SMEAR + 0 to SMEAR_KINDS - 1 - blood1-3, oil1-2 - each its picture
CONST SMEAR_KINDS = 5, DK_SMEAR = 2, S_SMEAR = S_ACID + 4
CONST S_EYE = S_ACID + 4 + SMEAR_KINDS ' (the eyebot's eye: hunting, yellow - then rushing you, red: eyebot-hunt.png, eyebot-rush.png)
CONST S_MODEL = S_EYE + 2
CONST SPR_SLOTS = S_MODEL + MAX_MODELS - 1
' How big each picture is kept: textures texSize, sprites up to sprTex
' pixels across. ART (SETTINGS > VIDEO) picks them: CLASSIC, the pixel art
' in neon-caster/, at 128 and 64; MODERN, the paintings in neon-caster/hd/,
' at 512 and 256 with OpenGL (shrunk to 128 and 64 for the software
' renderer). artNow: what's loaded (0 classic, 1 modern small, 2 modern
' big); artWant: what the settings ask for (ApplySettings); artHold: the
' pictures are being reloaded - OpenGL keeps its hands off (glArtAck: it has)
DIM SHARED texSize AS LONG, sprTex AS LONG, artNow AS INTEGER, artWant AS INTEGER, artHold AS INTEGER, glArtAck AS INTEGER
texSize = 128 : sprTex = 64 : artNow = -1
DIM SHARED glGunVersion AS LONG, glGunDone AS LONG, monK ' (monK: MakeMonFrames' picture size over 64)
' How tall pickups stand (in walls): keycards, other pickups, guns
CONST CARD_SCALE = 0.3, ITEM_SCALE = 0.3, GUN_ITEM_SCALE = 0.45
REDIM SHARED spriteTex(sprTex - 1, sprTex - 1, SPR_SLOTS) AS _UNSIGNED LONG
DIM SHARED spriteSize(SPR_SLOTS) AS INTEGER
DIM SHARED cardImg&(3) ' The keycards as images, for the HUD
' T_ = Texture slot: which picture in texture(x, y, slot). The slots are:
'   1-6 the level's six walls (# N C K P G), 7 sliding door, 8-10 key doors,
'   11 shutter, 12 split door, 13 exit, 14-17 the level's four floors,
'   18-19 its two ceilings, 20 a ceiling lamp (over each of the level's
'   lights - BuildShafts, chapter 24), 21 the lamp, shot out (MakeLampOff)
' T_DOORK + card is a key door (8 red, 9 blue, 10 yellow); T_FLOOR + n is
' floor n, and T_CEIL + n ceiling n; T_SLOTS is how many slots there are.
CONST T_DOOR = 7, T_DOORK = 7
CONST T_SHUTTER = 11, T_SPLIT = 12, T_EXIT = 13
CONST T_FLOOR = 13, T_CEIL = 17, T_LAMP = 20, T_LAMPOFF = 21, T_JACK = 22 ' (T_JACK: a data station's wall, @)
CONST T_CODE = 23 ' (a code terminal's wall, $)
CONST T_LIFT = 24, T_LIFTSIDE = 25 ' (a lift's top and sides: made from the level's own - MakeLiftTex)
CONST T_TRAP = 26, T_FIRE = 27 ' (a trap's floor: a live wire grid, a burner grate - MakeTrapTex)
CONST T_LIQUID = 27 ' (the liquids' surfaces, T_LIQUID + 1 to + LQ_KINDS: water, poison, slime, lava, acid - MakeLiquidTex)
CONST T_CUSTOM = 32, T_CUSTOMN = 56 ' (after those: slots for pictures put on single faces in the editor - [faces])
CONST T_JACKOK = T_CUSTOM + T_CUSTOMN + 1, T_CODEOK = T_CUSTOM + T_CUSTOMN + 2 ' (a hacked station's wall - CLEARED - and a solved terminal's - UNLOCKED, its lights gone green: MakeDoneTex)
CONST T_TCTRL = T_CUSTOM + T_CUSTOMN + 3, T_TCTRLOK = T_CUSTOM + T_CUSTOMN + 4 ' (a turret control panel's wall, ; - and one that's switched its turrets off: OFFLINE)
CONST T_STRONG = T_CUSTOM + T_CUSTOMN + 5, T_STRONGHURT = T_CUSTOM + T_CUSTOMN + 6, T_KEYPAD = T_CUSTOM + T_CUSTOMN + 7 ' (a stronghold door, and kicked half in; a keypad door - DoorSlot)
CONST T_SLOTS = T_CUSTOM + T_CUSTOMN + 7
REDIM SHARED texture(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG
REDIM SHARED texBak(texSize - 1, texSize - 1, T_SLOTS) AS _UNSIGNED LONG ' (the real pictures, kept while you're in the network)
' For each worldMap wall value: its texture slot, and its colour on the minimap
DIM SHARED wallTexSlot(10) AS INTEGER, wallMapColor(10) AS _UNSIGNED LONG
wallTexSlot(1) = 1 : wallTexSlot(3) = 2 : wallTexSlot(4) = 3 : wallTexSlot(5) = 4 : wallTexSlot(6) = 5 : wallTexSlot(7) = 6 : wallTexSlot(8) = T_JACK : wallTexSlot(9) = T_CODE : wallTexSlot(10) = T_TCTRL ' (8: a data station; 9: a code terminal; 10: a turret control panel)
' Each texture slot's file name (LoadTex), so OpenGL can tell what a
' texture is - a floor that should shine, a screen that should flicker
DIM SHARED texName$(T_SLOTS)
DIM SHARED texHD(T_SLOTS) AS INTEGER, texSky(T_SLOTS) AS INTEGER ' (each texture slot: a MODERN painting from hd/? OpenGL draws those smooth)
DIM SHARED texFile$(T_SLOTS)
