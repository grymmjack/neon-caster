''
' NEON-CASTER - RENDER/LIGHT.BI
' =============================================================================
' Light (chapter 14): every cell's light, and the level's lights.
'

' Light (chapter 14). Every cell has a light level for red, green and blue
' (litR, litG, litB): 256 shows a texture in its own colours, less is
' darker, more is brighter, and different amounts tint it. It's worked out
' fresh every frame: the level's ambient light, plus each of its lights,
' plus things that glow (lamps, terminals, the exit, muzzle flashes,
' explosions, bolts).
DIM SHARED litR(MAP_SIZE, MAP_SIZE) AS LONG, litG(MAP_SIZE, MAP_SIZE) AS LONG, litB(MAP_SIZE, MAP_SIZE) AS LONG
DIM SHARED ambientR AS LONG, ambientG AS LONG, ambientB AS LONG
' ...and each cell's own (a cell light - [cell lights] - or the sector's):
' the light it starts from, each frame, and its effect (FX_ below)
DIM SHARED cellAmbR(MAP_SIZE, MAP_SIZE) AS LONG, cellAmbG(MAP_SIZE, MAP_SIZE) AS LONG, cellAmbB(MAP_SIZE, MAP_SIZE) AS LONG, cellAmbFx(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED ambFxNow(5) AS SINGLE, ambFxTimer(5) AS INTEGER ' (how bright each effect has the cell lights this frame - one for all of a kind, so a room flickers as one)
' Where each cell's light comes from, for the OpenGL renderer's bump mapping
' (chapter 24): every light adds its position times its strength, so
' litSumX / litSumW, litSumY / litSumW is the middle of the light falling
' on the cell - the way a bump there should face to catch it
DIM SHARED litSumX(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumY(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumW(MAP_SIZE, MAP_SIZE) AS SINGLE
' The level's lights: where, how far they reach, their light (brightness
' times colour) for red, green and blue, their effect (FX_ below), and -
' for a lamp or terminal's own light - which decoration it belongs to (so
' it goes out when you break it)
' LIGHT_NEAR: how far from you the cells are lit afresh each frame (the
' fog's black by 16 cells: past that nothing shows the light), litX0 to
' litX1, litY0 to litY1 - all of a sector its first frames (UpdateLight)
CONST LIGHT_NEAR = 40
' RAY_FAR: how far the raycaster's rays go (chapter 15) before they give up - fog-black long before
CONST RAY_FAR = 64
DIM SHARED litX0, litY0, litX1, litY1
CONST MAX_LIGHTS = 1024 ' (a sector 256 cells across: its own lights, its lamps, an acid sea's glow - HUGE 8 has 290)
DIM SHARED lightX(MAX_LIGHTS), lightY(MAX_LIGHTS), lightRadius(MAX_LIGHTS)
DIM SHARED lightR(MAX_LIGHTS), lightG(MAX_LIGHTS), lightB(MAX_LIGHTS), lightPhase(MAX_LIGHTS)
DIM SHARED lightEffect(MAX_LIGHTS) AS INTEGER, lightDeco(MAX_LIGHTS) AS INTEGER, lightTimer(MAX_LIGHTS) AS INTEGER
DIM SHARED numLightsBase AS INTEGER ' (the level's own lights - those after them are pools flooded in play: LiquidGlows)
' Lights a sector changes as it plays (light N colour/bright/fx, ambient,
' celllight - LightCmd$, RENDER/LIGHT.BM): each light's brightness and
' colour (lightBri, lightHue~&: lightR/G/B are made from them), the
' sector's own light (ambBri, ambHue~&, ambFx), which cells have a light
' of their own (cellAmbOwn: a [cell lights] cell, or a celllight's) - and
' every change made, a line each (lightLog$), for a saved game to make again
DIM SHARED lightBri(MAX_LIGHTS) AS SINGLE, lightHue(MAX_LIGHTS) AS _UNSIGNED LONG
DIM SHARED ambDim AS SINGLE ' (1 - or less, a sector's light below 0: every light in it turned down by that much, -255 out - UpdateLight)
ambDim = 1
DIM SHARED ambBri AS INTEGER, ambHue AS _UNSIGNED LONG, ambFx AS INTEGER, cellAmbOwn(MAP_SIZE, MAP_SIZE) AS _BYTE, lightLog$
DIM SHARED lightNoLamp(MAX_LIGHTS) AS INTEGER ' (a level's light set to hang no lamp: its ceiling keeps its own picture, no beam)
DIM SHARED lightLow(MAX_LIGHTS) AS INTEGER ' (a glow from the floor - a pool of lava: no lamp on the ceiling over it, no beam)
DIM SHARED lightNow(MAX_LIGHTS) ' How bright its effect has it this frame (0 off .. 1 full): for its glow
DIM SHARED numLights AS INTEGER
' ...and which of the level's ceiling lamps you've shot out (BreakLight)
DIM SHARED lightBroken(MAX_LIGHTS) AS INTEGER
' FX_ = a light's effect: steady, a flickering fluorescent tube, a slow
' pulse, an alarm strobe, firelight, or a dying tube that sputters on now
' and then
CONST FX_STEADY = 0, FX_FLICKER = 1, FX_PULSE = 2, FX_STROBE = 3, FX_FIRE = 4, FX_DYING = 5
' Which cells each light reaches, and how strongly - worked out once when
' the level loads (BuildLights, chapter 23), since walls don't move:
' light number l's cells are entries lightFirst(l) to lightFirst(l) +
' lightCount(l) - 1 of the lit... arrays
CONST MAX_LIT = 100000
DIM SHARED lightFirst(MAX_LIGHTS) AS LONG, lightCount(MAX_LIGHTS) AS LONG, numLit AS LONG
DIM SHARED litCellX(MAX_LIT) AS INTEGER, litCellY(MAX_LIT) AS INTEGER, litWeight(MAX_LIT) AS SINGLE
DIM SHARED litCyberWas AS INTEGER, litAll AS INTEGER ' (UpdateLight: in the network last frame? and frames left to light all of the sector)
