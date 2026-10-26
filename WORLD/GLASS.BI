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
CONST GLASS_HP = 4, GLASS_HALF = 0.1, MAX_GLASS = 240
CONST BARS_HP = 999 ' (bars across a window, -: glass that never breaks - a shot pings off them; drawn with S_BARS) ' (GLASS_HALF: half the thickness you bump into)
DIM SHARED glassHP(MAP_SIZE, MAP_SIZE) AS INTEGER, glassDir(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED glassFull AS INTEGER ' (a whole pane's hits, this sector: AssignGlass)
DIM SHARED numGlass AS INTEGER, glassListX(MAX_GLASS) AS INTEGER, glassListY(MAX_GLASS) AS INTEGER
' How much each pane reflects (OpenGL's GLASS REFLECTIONS - GL/OPENGL.BM's
' GLMirrors): 0 none to 9 a mirror, for glassList's k (glassRefK, GlassRefBuild):
' its [glass] line's (x, y, amount), else the sector's (glass_reflect =, lvlGlassRef:
' -1 in the file left out - GLASS_REF_USUAL). glassRefAny: a pane that does.
' A pane's [glass] line goes on: x, y, reflects (. the sector's), BLUR (its
' reflection's, 0 sharp - 9 a smear), FROST (what's behind it blurred, 0
' clear - 9 shapes and light), RIPPLE (reeded glass: what's behind it
' wobbling in bands) - glassBlurK, glassFrostK, glassRipK; glassFrostC by
' cell for the software renderer (GlassColumn). glassFxAny: a pane frosted
' or rippled.
CONST GLASS_REF_USUAL = 2
DIM SHARED lvlGlassRef AS INTEGER, glassRefK(MAX_GLASS) AS _BYTE, glassRefAny AS INTEGER
DIM SHARED glassBlurK(MAX_GLASS) AS _BYTE, glassFrostK(MAX_GLASS) AS _BYTE, glassRipK(MAX_GLASS) AS _BYTE, glassFxAny AS INTEGER
DIM SHARED glassFrostC(MAP_SIZE, MAP_SIZE) AS _BYTE
REDIM SHARED gfBuf(0) AS _UNSIGNED LONG ' (a frosted pane's column, as it was behind it: GlassColumn)
' Then its STYLE (. or left out: the sector's, glass_style = - lvlGlassSty,
' -1 left out: 0) - which picture, GLASS_STYLES of them (GlassStyleName$;
' glassStyC by cell, GlassSlot) - and THROUGH: 1 CLEAR, its frost and
' ripple only on its reflection, what's seen through it sharp (glassClrK)
DIM SHARED lvlGlassSty AS INTEGER, glassStyC(MAP_SIZE, MAP_SIZE) AS _BYTE, glassClrK(MAX_GLASS) AS _BYTE
lvlGlassRef = -1 : lvlGlassSty = -1
' Where it was shot: GLASS_HITS panes at a time (the ones hit most lately)
' each have a picture of their own, S_GHIT + i - 1, with a hole and cracks
' drawn where each shot struck (GlassMark, GlassHitDraw - looks only; the
' rest show MakeGlass's ready-made cracks, as a pane does after a load).
' glassAtZ: how high the shot struck (-999 not known: halfway up). Pane i's
' marks: ghU across it 0-1 (the way GLPaneQuad lays its picture), ghV down
' from its top, ghS the stage it was at (1-3); ghVer counts its redraws, for
' OpenGL (ghGLVer: the one it has - GLSendGlassHits)
CONST GLASS_HITS = 24, GLASS_MARKS = 12
' STRENGTH (the [glass] line's 9th): how much a pane takes before it breaks -
' 0 or left out as tuned (the tuner's GLASS, glassFull), GLASS_UNBREAKABLE
' never (bulletproof: shots chip and crack it, nothing gets through).
' glassMax by cell: its whole (0 unbreakable) - AssignGlass
CONST GLASS_UNBREAKABLE = 999
DIM SHARED glassMax(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED glassAtZ, glassHitSlot(MAP_SIZE, MAP_SIZE) AS _BYTE
DIM SHARED ghCX(GLASS_HITS) AS INTEGER, ghCY(GLASS_HITS) AS INTEGER, ghN(GLASS_HITS) AS INTEGER, ghAge(GLASS_HITS) AS LONG, ghClock AS LONG
DIM SHARED ghU(GLASS_HITS, GLASS_MARKS) AS SINGLE, ghV(GLASS_HITS, GLASS_MARKS) AS SINGLE, ghS(GLASS_HITS, GLASS_MARKS) AS _BYTE
DIM SHARED ghVer(GLASS_HITS) AS LONG, ghGLVer(GLASS_HITS) AS LONG
glassAtZ = -999
