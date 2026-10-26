''
' NEON-CASTER - GAME/PHOTO.BI
' =============================================================================
' F10: PHOTO MODE's working variables (GAME/PHOTO.BM).
'

' PHOTO MODE: the game stopped dead where it is - shots in the air, sparks,
' flickering lamps, OpenGL's ripples - and you a camera, flying round it
' to look from anywhere and take screenshots. Where you were (ph...) is
' put back as you leave, cellSeen too (the autopilot reads it), so the
' game carries on exactly as it would have
DIM SHARED photoOn AS INTEGER, photoKeyWas AS INTEGER, photoHands AS INTEGER, photoHint AS INTEGER, photoQuiet AS INTEGER
DIM SHARED photoZoom AS SINGLE, photoKeys(4) AS INTEGER ' (the wheel's zoom; 1-4: P, H, F12, Esc held last frame)
DIM SHARED phX, phY, phZ, phVZ, phEye, phDX, phDY, phPX, phPY, phPitch, phZoom, phAim, phViewH
DIM SHARED phSeen(MAP_SIZE, MAP_SIZE) AS INTEGER
photoHands = -1 : photoZoom = 1
