''
' NEON-CASTER - WORLD/GLASS.BI
' =============================================================================
' Glass (= on the map): panes you can see and shoot through.
'

' --- Glass: = on the map, a pane across the middle of its cell (in a
' wall one cell thick, like a door). You, monsters and bolts can't pass
' it; sight and light can. glassHP: hits left (0: none there, or broken);
' glassDir: 1 if the pane runs along x (you look through it north or
' south), 2 along y. glassList: where they all are. Per column of the
' view, the nearest pane the ray went through (glassT: how far, 0 for
' none; glassU: where along it; glassCX, glassCY: its cell) - drawn over
' the wall behind it after the sprites behind it (chapters 15 and 16).
CONST GLASS_HP = 4, GLASS_HALF = 0.1, MAX_GLASS = 240 ' (GLASS_HALF: half the thickness you bump into)
DIM SHARED glassHP(MAP_SIZE, MAP_SIZE) AS INTEGER, glassDir(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED numGlass AS INTEGER, glassListX(MAX_GLASS) AS INTEGER, glassListY(MAX_GLASS) AS INTEGER
