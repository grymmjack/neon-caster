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
' Where each cell's light comes from, for the OpenGL renderer's bump mapping
' (chapter 24): every light adds its position times its strength, so
' litSumX / litSumW, litSumY / litSumW is the middle of the light falling
' on the cell - the way a bump there should face to catch it
DIM SHARED litSumX(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumY(MAP_SIZE, MAP_SIZE) AS SINGLE, litSumW(MAP_SIZE, MAP_SIZE) AS SINGLE
' The level's lights: where, how far they reach, their light (brightness
' times colour) for red, green and blue, their effect (FX_ below), and -
' for a lamp or terminal's own light - which decoration it belongs to (so
' it goes out when you break it)
CONST MAX_LIGHTS = 96
DIM SHARED lightX(MAX_LIGHTS), lightY(MAX_LIGHTS), lightRadius(MAX_LIGHTS)
DIM SHARED lightR(MAX_LIGHTS), lightG(MAX_LIGHTS), lightB(MAX_LIGHTS), lightPhase(MAX_LIGHTS)
DIM SHARED lightEffect(MAX_LIGHTS) AS INTEGER, lightDeco(MAX_LIGHTS) AS INTEGER, lightTimer(MAX_LIGHTS) AS INTEGER
DIM SHARED numLightsBase AS INTEGER ' (the level's own lights - those after them are pools flooded in play: LiquidGlows)
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
CONST MAX_LIT = 16000
DIM SHARED lightFirst(MAX_LIGHTS) AS LONG, lightCount(MAX_LIGHTS) AS LONG, numLit AS LONG
DIM SHARED litCellX(MAX_LIT) AS INTEGER, litCellY(MAX_LIT) AS INTEGER, litWeight(MAX_LIT) AS SINGLE
