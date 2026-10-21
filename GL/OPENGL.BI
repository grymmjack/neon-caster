''
' NEON-CASTER - GL/OPENGL.BI
' =============================================================================
' Chapter 24: the OpenGL renderer - what the game hands it each frame,
' and what it keeps for itself.
'

' --- The OpenGL renderer (chapter 24) ---
' With RENDERER set to OPENGL in the menu, the graphics card draws the 3D
' view instead of the pixel loops of chapters 14-16. It draws whenever
' QB64PE puts the window on the screen (SUB _GL), which can happen between
' any two lines of the game, so the game never makes it look at half-done
' work. Each frame it fills in a "snapshot" of what to draw, in one half of
' these arrays (the last index, 0 or 1), while OpenGL may still be drawing
' the other half, and then switches over: "double buffering".
'   glReady       -1 when there's a snapshot to draw; 0 in the menus at the
'                 title, while a level loads, or with the software renderer
'   glBuf         which half holds the newest snapshot (glWrite: which half
'                 this frame is filling in - the other one)
'   glFrameNo     counts frames; glFrame(half) is the frame a snapshot is of
'   glCam... glDir... glPlaneLen glZoom glShake...   the camera: where you
'                 are, the way you face, how wide and tall the view is, and
'                 the screen shake (chapter 17)
'   glLitR...     every cell's light, and glDoor every door's position
'   glSeen()      the cells this frame's rays went through (chapter 15):
'                 glSeen(x, y, half) = glFrame(half) means "seen this frame"
'   glSpr...      the sprites to draw (chapter 16): where, how big, which
'                 picture, and how they're lit
'   glTexVersion  goes up whenever the textures change (a level loads), so
'                 SUB _GL knows to send them to the graphics card again
' GL_NEAR and GL_FAR: the nearest and furthest OpenGL draws (in cells)
CONST GL_NEAR = 0.05, GL_FAR = 100 ' (the fog's black by 16 cells: past that only neon and skies show)
' GL_DYN: how many moving lights; MAX_PART: particles; GL_HEAT: explosions
' for the heat shimmer (all chapter 24)
CONST GL_DYN = 4, MAX_PART = 800, GL_HEAT = 4
DIM SHARED glReady AS INTEGER, glBuf AS INTEGER, glFrameNo AS LONG, glMode AS INTEGER
DIM SHARED glCamZ(1), glEyeZ ' (your eye's height, for OpenGL's camera)
DIM SHARED glFrame(1) AS LONG, glCamX(1), glCamY(1), glDirX(1), glDirY(1), glPlaneLen(1), glZoom(1)
DIM SHARED glShakeX(1), glShakeY(1), glShakeEdge(1), glFullMode(1) AS INTEGER
DIM SHARED glLitR(MAP_SIZE, MAP_SIZE, 1) AS LONG, glLitG(MAP_SIZE, MAP_SIZE, 1) AS LONG, glLitB(MAP_SIZE, MAP_SIZE, 1) AS LONG
DIM SHARED glDoor(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glSeen(MAP_SIZE, MAP_SIZE, 1) AS LONG
DIM SHARED glNumSpr(1) AS INTEGER, glSprX(MAX_DRAW, 1), glSprY(MAX_DRAW, 1), glSprLift(MAX_DRAW, 1)
DIM SHARED glSprHalfW(MAX_DRAW, 1), glSprH(MAX_DRAW, 1), glSprSlot(MAX_DRAW, 1) AS INTEGER, glSprFace(MAX_DRAW, 1) AS INTEGER
DIM SHARED glSprMdl(MAX_DRAW, 1) AS INTEGER, glSprAng(MAX_DRAW, 1) ' (a 3D prop: its model, drawn as itself - GLDrawModel - and the way it faces)
DIM SHARED glSprMZ(MAX_DRAW, 1) ' (its model squashed: a broken prop)
DIM SHARED glSprPitch(MAX_DRAW, 1), glSprHead(MAX_DRAW, 1) AS INTEGER, glSprHAng(MAX_DRAW, 1), glSprHPitch(MAX_DRAW, 1) ' (pitched - a rocket; a turret's head, aimed)
' The turrets' laser sights: a glowing line each (GLSight)
DIM SHARED glNumSight(1) AS INTEGER, glSightX0(MAX_BEAMS, 1), glSightY0(MAX_BEAMS, 1), glSightZ0(MAX_BEAMS, 1), glSightX1(MAX_BEAMS, 1), glSightY1(MAX_BEAMS, 1), glSightZ1(MAX_BEAMS, 1), glSightC(MAX_BEAMS, 1) AS _UNSIGNED LONG
DIM SHARED glSprCap(MAX_DRAW, 1) AS _UNSIGNED LONG, glSprFlip(MAX_DRAW, 1) AS INTEGER, glSprMirror(MAX_DRAW, 1) AS INTEGER, glSprUpX(MAX_DRAW, 1), glSprUpY(MAX_DRAW, 1), glSprUpZ(MAX_DRAW, 1) ' (a turret: its muzzles' colour, upside down, its model's up)
DIM SHARED glSprR(MAX_DRAW, 1), glSprG(MAX_DRAW, 1), glSprB(MAX_DRAW, 1)
DIM SHARED glTexVersion AS LONG
' Bump mapping (chapter 24): each cell's light middle (glLitCX, glLitCY)
' and how much of its light comes from somewhere (glLitDir, 0 all ambient
' .. 1); and the glows - halos round bolts, blasts, lamps and terminals:
' where, how big, what colour. glBump and glGlowOn: the two VIDEO settings.
DIM SHARED glLitCX(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glLitCY(MAP_SIZE, MAP_SIZE, 1) AS SINGLE, glLitDir(MAP_SIZE, MAP_SIZE, 1) AS SINGLE
CONST MAX_GLOWS = MAX_BOLTS * 4 + MAX_BLASTS + MAX_LIGHTS ' (a rocket: three more, its exhaust)
DIM SHARED glNumGlow(1) AS INTEGER, glGlowX(MAX_GLOWS, 1), glGlowY(MAX_GLOWS, 1), glGlowZ(MAX_GLOWS, 1), glGlowSize(MAX_GLOWS, 1)
DIM SHARED glGlowR(MAX_GLOWS, 1), glGlowG(MAX_GLOWS, 1), glGlowB(MAX_GLOWS, 1)
DIM SHARED glWrite AS INTEGER
' What SUB _GL keeps for itself: the graphics card's names for the textures
' (texture slots 1-20, then sprite slots after them), which texture version
' it has, the cells it's drawing, the camera and light it's drawing with,
' the camera as a matrix (chapter 24), and how long it took (for SHOW FPS)
' (one more texture name after the sprites: GL_GLOW_TEX, the glows' soft
' round spot)
' (and before it, the 3D props' pictures - each model from 8 ways round,
' mdlPic: a sprite slot past SPR_SLOTS, SPR_SLOTS + its number, is one)
CONST GL_GLOW_TEX = T_SLOTS + SPR_SLOTS + MAX_MODELS * MDL_ANGLES + 1
DIM SHARED glTexName(GL_GLOW_TEX) AS _UNSIGNED LONG, glTexDone AS LONG
' ...the guns' pictures (GLSendGuns), and two OpenGL numbers QB64PE has no
' name for (it knows OpenGL 1.1's; these came later)
DIM SHARED glGunTex(NUM_GUNS) AS _UNSIGNED LONG
CONST GL_GENERATE_MIPMAP = &H8191&, GL_CLAMP_TO_EDGE = &H812F&
REDIM SHARED glUpload(texSize * texSize - 1) AS _UNSIGNED LONG ' (a picture on its way to the card)
' The world shader (chapter 24): the program, where its uniforms and
' attributes are, whether we've tried to build it, and why it failed (if)
DIM SHARED glWorldProg AS _UNSIGNED LONG, glWorldTried AS INTEGER, glShaderOn AS INTEGER, glShaderError$
DIM SHARED glTanLoc AS LONG, glLightLoc AS LONG, glDynLoc AS LONG
' ...the post-processing shaders and render targets, and how this frame is
' going: post-processing or not, the mirror image drawn, the floor pass on
DIM SHARED glPostProg AS _UNSIGNED LONG, glBrightProg AS _UNSIGNED LONG, glBlurProg AS _UNSIGNED LONG
DIM SHARED glTargScene AS LONG, glTargA AS LONG, glTargB AS LONG, glTargRetro AS INTEGER
DIM SHARED glTargC AS LONG, glTargD AS LONG ' (the phosphor glow's, 400 x 300)
DIM SHARED glPost AS INTEGER, glReflecting AS INTEGER, glFloorPass AS INTEGER, glNeonOn AS INTEGER, glLiquidPass AS INTEGER ' (glLiquidPass: GLLiquids is drawing)
' ...the WORLD MESH (GLBuildMesh): every floor, ceiling and wall face of
' the level, built once and kept in graphics memory (glMeshBuf), sorted by
' kind (0 floors, 1 ceilings, 2 walls) and texture, glMeshFirst/Count saying
' where each kind-and-texture run is; the corners while it's being built
' (glMB...); the doors (they move, so they're drawn each frame); the light
' tables' textures; and whether corners are lit from the tables (cellLit)
' (MESH_START corners to start with - a sector 128 x 128 and 16 walls high,
' every floor, ceiling and step in it - grown as a bigger one needs, up to
' MESH_MAX: GLMeshCorner)
CONST MESH_START = 480000, MESH_MAX = 4000000
DIM SHARED glMeshBuf AS _UNSIGNED LONG, glMeshN AS LONG, glMeshBuilding AS INTEGER, glMeshKind AS INTEGER
DIM SHARED glMeshClient AS INTEGER ' (the mesh is drawn from glMeshData in main memory, not a buffer - GLBuildMesh)
CONST GL_MESH_KINDS = 13 ' (kinds: 0 floors, 1 ceilings, 2 walls, 3 raised or sunken floors, 4-13 floors of a wetness of their own, 0-9: FloorWet)
DIM SHARED glMeshFirst(GL_MESH_KINDS, GL_GLOW_TEX) AS LONG, glMeshCount(GL_MESH_KINDS, GL_GLOW_TEX) AS LONG
REDIM SHARED glMBPos(MESH_START * 3) AS SINGLE, glMBUV(MESH_START * 2) AS SINGLE, glMBN(MESH_START * 3) AS SINGLE, glMBT(MESH_START * 3) AS SINGLE
REDIM SHARED glMBSlot(MESH_START) AS INTEGER, glMBKind(MESH_START) AS INTEGER, glMeshData(MESH_START * 11) AS SINGLE
DIM SHARED glMeshCap AS LONG: glMeshCap = MESH_START
DIM SHARED glNumDoors AS INTEGER, glDoorCX(MAP_SIZE * MAP_SIZE) AS INTEGER, glDoorCY(MAP_SIZE * MAP_SIZE) AS INTEGER
DIM SHARED glLitTex AS _UNSIGNED LONG, glInfoTex AS _UNSIGNED LONG, glDynTex AS _UNSIGNED LONG, glCellLitMode AS INTEGER
' ...and each texture's effects (GLSendTextures)
DIM SHARED glTexShine(GL_GLOW_TEX), glTexReflect(GL_GLOW_TEX), glTexNeon(GL_GLOW_TEX), glTexAnim(GL_GLOW_TEX)
' GL_BUMP: how strongly bumps tilt the light; GL_LIGHT_Z: how high lights
' hang (in walls: the ceiling is 1)
CONST GL_BUMP = 2.5, GL_LIGHT_Z = 0.85
DIM SHARED glVisX(MAP_SIZE * MAP_SIZE) AS INTEGER, glVisY(MAP_SIZE * MAP_SIZE) AS INTEGER, glNumVis AS LONG
DIM SHARED glEyeX, glEyeY, glEyeDX, glEyeDY, glLR, glLG, glLB, glShade
' The corners waiting to be drawn (GLCorner puts them here; GLDraw hands
' them to the card in one go): position (x, y, z), texture spot (u, v) and
' colour (red, green, blue) for up to GL_BATCH corners
CONST GL_BATCH = 16000
DIM SHARED glVerts(GL_BATCH * 3) AS SINGLE, glTexSpots(GL_BATCH * 2) AS SINGLE, glColors(GL_BATCH * 4) AS SINGLE, glNumVerts AS LONG
' ...and for bump mapping: which way the surface faces (its normal), which
' way its texture runs across it (its tangent), and the way to its light
' (x, y, z, and how much of its light that is) - the face's, set by the
' code drawing it (glFace...), and the corner's (glCornerL...)
DIM SHARED glNormals(GL_BATCH * 3) AS SINGLE, glTangents(GL_BATCH * 3) AS SINGLE, glLightVecs(GL_BATCH * 4) AS SINGLE
DIM SHARED glDynMasks(GL_BATCH * 4) AS SINGLE, glShadowA(GL_BATCH) AS SINGLE, glCellDyn(GL_DYN) AS SINGLE
' ...and each corner's texture (glVertSlot): GLDraw groups the corners by
' texture with a list of their numbers (glIndex), so each texture is
' switched to once a pass (glSlotCount, glSlotStart, glSlotFill: how many
' corners each texture has, and where its part of the list starts)
DIM SHARED glVertSlot(GL_BATCH) AS INTEGER, glIndex(GL_BATCH) AS _UNSIGNED LONG, glCurSlot AS INTEGER, glBumpOn AS INTEGER
DIM SHARED glSlotCount(GL_GLOW_TEX) AS LONG, glSlotStart(GL_GLOW_TEX) AS LONG, glSlotFill(GL_GLOW_TEX) AS LONG
DIM SHARED glFaceNX, glFaceNY, glFaceNZ, glFaceTX, glFaceTY, glFaceTZ, glCellLX, glCellLY, glCellDir
DIM SHARED glCornerLX, glCornerLY, glCornerLZ
DIM SHARED glMat(15) AS SINGLE, glMs
