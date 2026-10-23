''
' NEON-CASTER - GL/EXTRAS.BI
' =============================================================================
' The OpenGL extras (chapter 24): scorch marks, the gun, light shafts,
' moving lights, particles and heat, handed over each frame.
'

' --- The OpenGL extras (chapter 24): what else each frame hands over ---
'   glSet(id, half)    every setting (SET_ numbers), so SUB _GL sees this
'                      frame's choices
'   glPitch            how far you look up (+) or down (-), in radians
'   glDyn...           up to GL_DYN moving lights - your muzzle flash, blasts,
'                      bolts - and glDynReach(x, y, k, half): 1 if moving
'                      light k reaches cell (x, y), 0 if a wall's in the way
'   glPart...          the particles: sparks, embers, dust
'   glHurt, glRail     how hurt you just were, the railgun's flash (0..1)
'   glHeat...          explosions, for the heat shimmer
'   glShaft...         the light shafts near you: where, colour (as bright
'                      as their light is this frame) and a phase for each
'                      one's slow shimmer
'   glDec...           the decals: shot and scorch marks (as decalX...)
'   glWide             how much wider than 4:3 the view is (WideView: FULL
'                      WIDE), and glSideDim how much to darken the view
'                      beside our 4:3 screen (the menu's darkening only
'                      covers our screen)
'   glGun...           which gun you're holding (0: none in sight) and where
'                      on our 800 x 600 screen, from top left to bottom right,
'                      and the light on it (1 = as bright as its picture)
DIM SHARED glPitch(1) ' (glSet, the settings: with them, chapter 21)
DIM SHARED glWide(1), glSideDim(1), glAspectK
' FULL WIDE's own screen (RENDER/HUD.BM, GLCapture): in play the HUD is drawn
' on hudCanvas&, as wide as the window (scrW across, 600 down) - each part
' VIEWed to its own side of it, so it hugs the window's edge - and a screen
' with the synthwave backdrop gets it all the way across, our 4:3 screen in
' its middle. hudVX: where the middle 800 start; hudViewX: the VIEW's left
' now (HudText adds it - _PRINTSTRING doesn't see VIEW).
DIM SHARED hudCanvas&, scrW, hudVX, hudViewX, hudWideNow, backWant, backT, backDim~&, backScan ' (backDim~&, backScan: BackdropDim's, over it)
scrW = 800
DIM SHARED glNumDecal(1) AS INTEGER, glDecX(MAX_DECALS, 1), glDecY(MAX_DECALS, 1), glDecZ(MAX_DECALS, 1)
DIM SHARED glDecNX(MAX_DECALS, 1), glDecNY(MAX_DECALS, 1), glDecNZ(MAX_DECALS, 1), glDecSize(MAX_DECALS, 1), glDecHeat(MAX_DECALS, 1), glDecKind(MAX_DECALS, 1) AS INTEGER
DIM SHARED glGun(1) AS INTEGER, glGunX0(1), glGunY0(1), glGunX1(1), glGunY1(1), glGunR(1), glGunG(1), glGunB(1)
DIM SHARED glNumShaft(1) AS INTEGER, glShaftX(MAX_LIGHTS, 1), glShaftY(MAX_LIGHTS, 1), glShaftPh(MAX_LIGHTS, 1)
DIM SHARED glShaftR(MAX_LIGHTS, 1), glShaftG(MAX_LIGHTS, 1), glShaftB(MAX_LIGHTS, 1)
DIM SHARED glNumDyn(1) AS INTEGER, glDynX(GL_DYN, 1), glDynY(GL_DYN, 1), glDynZ(GL_DYN, 1), glDynRad(GL_DYN, 1)
DIM SHARED glDynR(GL_DYN, 1), glDynG(GL_DYN, 1), glDynB(GL_DYN, 1), glDynReach(MAP_SIZE, MAP_SIZE, GL_DYN, 1) AS _BYTE
DIM SHARED glDynLoad(1) AS LONG ' (the sector each half's glDynReach was last cleared for: trigLoadN)
DIM SHARED glNumPart(1) AS INTEGER, glPartX(MAX_PART, 1), glPartY(MAX_PART, 1), glPartZ(MAX_PART, 1), glPartSize(MAX_PART, 1)
DIM SHARED glPartR(MAX_PART, 1), glPartG(MAX_PART, 1), glPartB(MAX_PART, 1)
DIM SHARED glHurt(1), glHeatAmt(GL_HEAT, 1), glRail(1), glNumHeat(1) AS INTEGER, glHeatX(GL_HEAT, 1), glHeatY(GL_HEAT, 1)
' The light tables (chapter 24): the light for the graphics card to look up
' itself, every pixel - GL_TABLE x GL_TABLE cells of 4 numbers, for each half
' of the snapshot (half * GL_TABLE_SIZE onwards):
'   glLitData    a cell's red, green and blue light, and 1 if it's open
'   glInfoData   the middle of the light on it (x, y), how much of its
'                light that is (glLitDir), and how high it is
'   glDynData    which of the 4 moving lights reach it (1 or 0 each)
CONST GL_TABLE = 256, GL_TABLE_SIZE = GL_TABLE * GL_TABLE * 4 ' (as many cells as the biggest sector: MAP_SIZE)
DIM SHARED glLitData(2 * GL_TABLE_SIZE) AS SINGLE, glInfoData(2 * GL_TABLE_SIZE) AS SINGLE, glDynData(2 * GL_TABLE_SIZE) AS SINGLE
' (for the moving lights' flood fill: the cells waiting, and which were
' reached this time - fillSeen() = fillStamp)
DIM SHARED fillX(MAP_SIZE * MAP_SIZE) AS INTEGER, fillY(MAP_SIZE * MAP_SIZE) AS INTEGER, fillD(MAP_SIZE * MAP_SIZE) AS INTEGER
DIM SHARED fillSeen(MAP_SIZE, MAP_SIZE) AS LONG, fillStamp AS LONG
