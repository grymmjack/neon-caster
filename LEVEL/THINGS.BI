''
' NEON-CASTER - LEVEL/THINGS.BI
' =============================================================================
' A level's lines about single cells, kept as the file has them (text):
'   [doors]  x, y, kicks, code - a stronghold door (kicks: how many it takes
'            to break it down) and a keypad door (its code: digits; ? for
'            one made up each time you play - a note can tell it: {code x y})
'   [things] x, y, kind[, more] - what a " in the map stands for: a table
'            on its side, a safe, a computer, a camera, a robot dog... (its
'            name - ThingCode), and its own numbers after
'   [notes]  x, y, picture, words - what a note (') says, or one found in
'            a desk, a bookshelf or a safe at x, y (picture: - for none)
'   [smears] x, y, face, kind - blood or oil on a wall's side (E S W N),
'            the floor (F) or the ceiling (C): blood1-3, oil1-2
'
CONST MAX_XTRA = 512
DIM SHARED lvlNumXtra AS INTEGER, lvlXSec$(MAX_XTRA), lvlXtra$(MAX_XTRA)
' A thing's code (ThingCode): a decoration's kind, THING_ITEM + a pickup's,
' THING_MON + a monster's type
CONST THING_ITEM = 100, THING_MON = 200
