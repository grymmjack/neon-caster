''
' NEON-CASTER - WORLD/HEIGHTS.BI
' =============================================================================
' Heights (chapter 22's [floor] and [ceiling]): every cell's floor and
' ceiling height, and floors that burn or slow you.
'

' --- Heights (chapter 22's [floor] and [ceiling]): every cell's floor and
' ceiling, in walls (0 and 1 unless the level says otherwise). In the
' level file, a map of one character a cell: . the usual, 0-9 and a-z
' that many eighths of a wall up, A-H that many eighths down (a pit).
' levelFlat: none anywhere - the game as it was, and the software
' renderer's classic way (chapter 15). You (playerZ, your feet) step up
' anything up to STEP_UP, fall off anything higher, and need BODY_H of
' room; your eye is EYE_H above your feet (eyeZ, eased up steps). walkZ:
' the height of whoever Walkable is asked about (-999: don't care).
CONST H_STEP = 0.125, H_UP$ = "0123456789abcdefghijklmnopqrstuvwxyz", H_DOWN$ = "ABCDEFGH"
' Higher than z (35 eighths), up to H_MAX eighths (30 walls): in memory,
' one of the characters no other height uses - the (eighths - 35)th of
' H_HIGH$ (HeightOf, HeightChar$); in the level file, the height's last
' digit in base 36 in [floor] / [ceiling] as ever, and how many 36s in
' [floor high] / [ceiling high] (only if there are any)
CONST H_MAX = 240
DIM SHARED H_HIGH$
FOR hk = 1 TO 255 ' (every character but . 0-9 a-z A-H - and none the editor's undo or a file line could trip on)
    hc$ = CHR$(hk)
    IF INSTR(".ABCDEFGH" + H_UP$, hc$) = 0 AND hk <> 3 AND hk <> 10 AND hk <> 13 THEN H_HIGH$ = H_HIGH$ + hc$
NEXT
CONST STEP_UP = 0.32, EYE_H = 0.5, BODY_H = 0.7, FALL_G = 0.01, PIT_DEPTH = -0.99
' A sector's own gravity (gravity = in its file: percent of FALL_G, 1-300 (a few: near zero-g) -
' 100 as made); a jump's push off the floor (JUMP: as high as half a wall,
' at 100); jumpWas: the key held last frame
CONST JUMP_V = 0.1
DIM SHARED lvlGravity AS INTEGER, jumpWas AS INTEGER
lvlGravity = 100
' Floors that do something (FloorHazard, by the floor's picture): molten or
' lava burns (BURN_DAMAGE every BURN_EVERY frames you stand in it); murky
' water or slime slows you (SLOW_WADE: how much of your speed you keep).
' Monsters won't walk into the burning ones (walkFromHaz, Walkable).
CONST HAZ_BURN = 1, HAZ_WADE = 2, BURN_DAMAGE = 5, BURN_EVERY = 30, SLOW_WADE = 0.7
DIM SHARED burnWait AS INTEGER, walkFromHaz AS INTEGER ' (sndSizzle&: with the other sounds, chapter 6)
DIM SHARED floorH(MAP_SIZE, MAP_SIZE) AS SINGLE, ceilH(MAP_SIZE, MAP_SIZE) AS SINGLE, levelFlat AS INTEGER
DIM SHARED lvlFloorRow$(MAP_SIZE - 1), lvlCeilRow$(MAP_SIZE - 1)
