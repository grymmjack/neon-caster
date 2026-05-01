_TITLE "NEON-CASTER: WASD + MOUSE + SLIDING DOORS"
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE
_PRINTMODE _KEEPBACKGROUND
 
CONST MAP_SIZE = 24
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorOffsets(MAP_SIZE, MAP_SIZE) AS SINGLE
 
' --- Load Map ---
RESTORE MapData
FOR y = 0 TO MAP_SIZE - 1: FOR x = 0 TO MAP_SIZE - 1: READ worldMap(x, y): NEXT: NEXT
 
' Player Setup
pX = 22.0: pY = 12.0: pDirX = -1.0: pDirY = 0.0
planeX = 0.0: planeY = 0.66
MoveSpeed = 0.12: RotSpeed = 0.003 ' Mouse sensitivity
bob = 0: mouseX = 400 ' Mouse centering
 
DO
  _LIMIT 60
  WHILE _MOUSEINPUT: WEND ' Handle mouse queue
  CLS
 
  ' --- 1. Mouse Look ---
  mDX = _MOUSEX - 400 ' Get delta from center
  _MOUSEMOVE 400, 300 ' Reset mouse to center
  angle = -mDX * RotSpeed
  oldDirX = pDirX: pDirX = pDirX * COS(angle) - pDirY * SIN(angle): pDirY = oldDirX * SIN(angle) + pDirY * COS(angle)
  oldPX = planeX: planeX = planeX * COS(angle) - planeY * SIN(angle): planeY = oldPX * SIN(angle) + planeY * COS(angle)
 
  ' --- 2. WASD + Strafe + Backwards ---
  moveX = 0: moveY = 0
  IF _KEYDOWN(119) OR _KEYDOWN(87) THEN ' W
    moveX = moveX + pDirX * MoveSpeed: moveY = moveY + pDirY * MoveSpeed: bob = bob + 0.2
  END IF
  IF _KEYDOWN(115) OR _KEYDOWN(83) THEN ' S
    moveX = moveX - pDirX * MoveSpeed: moveY = moveY - pDirY * MoveSpeed: bob = bob + 0.2
  END IF
  IF _KEYDOWN(97) OR _KEYDOWN(65) THEN ' A (Strafe Left)
    moveX = moveX - pDirY * MoveSpeed: moveY = moveY + pDirX * MoveSpeed: bob = bob + 0.2
  END IF
  IF _KEYDOWN(100) OR _KEYDOWN(68) THEN ' D (Strafe Right)
    moveX = moveX + pDirY * MoveSpeed: moveY = moveY - pDirX * MoveSpeed: bob = bob + 0.2
  END IF
 
  ' Collision (Slide along walls)
  IF worldMap(INT(pX + moveX), INT(pY)) <= 0 OR doorOffsets(INT(pX + moveX), INT(pY)) > 0.8 THEN pX = pX + moveX
  IF worldMap(INT(pX), INT(pY + moveY)) <= 0 OR doorOffsets(INT(pX), INT(pY + moveY)) > 0.8 THEN pY = pY + moveY
 
  ' --- 3. Door & World Logic ---
  IF _KEYDOWN(32) THEN ' SPACE to Open
    cX = INT(pX + pDirX * 1.2): cY = INT(pY + pDirY * 1.2)
    IF worldMap(cX, cY) = 2 AND doorOffsets(cX, cY) = 0 THEN doorOffsets(cX, cY) = 0.01
  END IF
  FOR dy = 0 TO MAP_SIZE - 1: FOR dx = 0 TO MAP_SIZE - 1
      IF doorOffsets(dx, dy) > 0 AND doorOffsets(dx, dy) < 1 THEN doorOffsets(dx, dy) = doorOffsets(dx, dy) + 0.04
  NEXT: NEXT
 
  ' --- 4. Render ---
  ' Draw Floor/Ceiling Gradient (Pimping it out!)
  FOR y = 0 TO 299
    c = y / 6: LINE (0, y)-(799, y), _RGB32(c / 2, c / 2, c) ' Ceiling
    c = (300 - y) / 4: LINE (0, 599 - y)-(799, 599 - y), _RGB32(c, c, c) ' Floor
  NEXT
 
  FOR x = 0 TO 799
    camX = 2 * x / 800 - 1
    rDX = pDirX + planeX * camX: rDY = pDirY + planeY * camX
    mX = INT(pX): mY = INT(pY)
    dDX = ABS(1 / rDX): dDY = ABS(1 / rDY)
 
    IF rDX < 0 THEN stX = -1: sDX = (pX - mX) * dDX ELSE stX = 1: sDX = (mX + 1 - pX) * dDX
    IF rDY < 0 THEN stY = -1: sDY = (pY - mY) * dDY ELSE stY = 1: sDY = (mY + 1 - pY) * dDY
 
    hit = 0: side = 0
    WHILE hit = 0
      IF sDX < sDY THEN sDX = sDX + dDX: mX = mX + stX: side = 0 ELSE sDY = sDY + dDY: mY = mY + stY: side = 1
      IF worldMap(mX, mY) = 1 OR worldMap(mX, mY) = 3 THEN hit = worldMap(mX, mY)
      IF worldMap(mX, mY) = 2 THEN
        IF side = 0 THEN wX = pY + ((mX - pX + (1 - stX) / 2) / rDX) * rDY ELSE wX = pX + ((mY - pY + (1 - stY) / 2) / rDY) * rDX
        IF (wX - INT(wX)) > doorOffsets(mX, mY) THEN hit = 2
      END IF
    WEND
 
    IF side = 0 THEN dist = (mX - pX + (1 - stX) / 2) / rDX ELSE dist = (mY - pY + (1 - stY) / 2) / rDY
    lineH = INT(600 / dist)
    lStart = -lineH / 2 + 300: lEnd = lineH / 2 + 300
 
    ' Shading
    bright = 255 - (dist * 14): IF bright < 0 THEN bright = 0
    IF side = 1 THEN bright = bright * 0.6
    IF hit = 1 THEN c& = _RGB32(bright, bright, bright)
    IF hit = 2 THEN c& = _RGB32(bright, bright * 0.4, 0)
    IF hit = 3 THEN c& = _RGB32(0, bright * 0.8, bright)
 
    LINE (x, lStart)-(x, lEnd), c&
  NEXT x
 
  ' --- 5. Weapon / HUD ---
  gunBob = SIN(bob) * 10
  'CIRCLE (400, 500 + gunBob), 60, _RGB32(50, 50, 50), , , 0.5, F ' Simple Gun Placeholder
  LINE (395, 300)-(405, 300), _RGB32(255, 0, 0): LINE (400, 295)-(400, 305), _RGB32(255, 0, 0)
 
  ' Minimap
  FOR mY = 0 TO 23: FOR mX = 0 TO 23
      IF worldMap(mX, mY) > 0 THEN LINE (mX * 4, mY * 4)-(mX * 4 + 3, mY * 4 + 3), _RGB32(100, 100, 100), BF
  NEXT: NEXT
  CIRCLE (pX * 4, pY * 4), 1, _RGB32(255, 255, 0)
 
  _DISPLAY
LOOP UNTIL _KEYDOWN(27)
 
MapData:
DATA 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
DATA 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA 1,0,1,1,1,1,1,0,1,1,1,2,1,1,1,0,1,1,1,1,1,1,0,1
DATA 1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1
DATA 1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1
DATA 1,0,2,0,0,0,2,0,2,0,0,0,0,0,2,0,2,0,0,0,0,2,0,1
DATA 1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1
DATA 1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,3,1,1,0,1
DATA 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA 1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,0,1
DATA 1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1
DATA 1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1
DATA 1,0,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,1
DATA 1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1
DATA 1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,0,1
DATA 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA 1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1
DATA 1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1
DATA 1,0,2,0,0,0,2,0,2,0,0,0,0,0,2,0,2,0,0,0,0,2,0,1
DATA 1,0,1,0,0,0,1,0,1,0,0,0,0,0,1,0,1,0,0,0,0,1,0,1
DATA 1,0,1,1,1,1,1,0,1,1,1,2,1,1,1,0,1,1,1,1,1,1,0,1
DATA 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1