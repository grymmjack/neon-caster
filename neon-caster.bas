_TITLE "NEON-CASTER: WASD + MOUSE + SLIDING DOORS"
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE
_PRINTMODE _KEEPBACKGROUND
 
CONST MAP_SIZE = 24
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorOffsets(MAP_SIZE, MAP_SIZE) AS SINGLE

' --- Render buffer (half-res, scaled 2x to the screen) ---
CONST RW = 400, RH = 300, TEX = 64
CONST T_WALL = 1, T_DOOR = 2, T_WALL2 = 3, T_FLOOR = 4, T_CEIL = 5
DIM SHARED tex(TEX - 1, TEX - 1, 5) AS _UNSIGNED LONG
DIM SHARED scr(0 TO RW * RH - 1) AS _UNSIGNED LONG
buf& = _NEWIMAGE(RW, RH, 32)
DIM mBuf AS _MEM, mScr AS _MEM
mBuf = _MEMIMAGE(buf&): mScr = _MEM(scr())

' --- Load Textures ---
LoadTex "wall.png", T_WALL
LoadTex "door.png", T_DOOR
LoadTex "wall2.png", T_WALL2
LoadTex "floor.png", T_FLOOR
LoadTex "ceiling.png", T_CEIL

DIM x AS LONG, y AS LONG, fu AS LONG, fv AS LONG, tX AS LONG
DIM rowF AS LONG, rowC AS LONG, lStart AS LONG, lEnd AS LONG

' --- Load Map ---
RESTORE MapData
FOR y = 0 TO MAP_SIZE - 1: FOR x = 0 TO MAP_SIZE - 1: READ worldMap(x, y): NEXT: NEXT
 
' Player Setup
pX = 22.0: pY = 12.0: pDirX = -1.0: pDirY = 0.0
planeX = 0.0: planeY = 0.66
MoveSpeed = 0.12: RotSpeed = 0.003 ' Mouse sensitivity
bob = 0
_MOUSEMOVE 400, 300: lastMX = 400: warpPending = 1: warpWait = 0 ' Mouse centering

DO
  _LIMIT 60

  ' --- 1. Mouse Look ---
  ' Accumulate per-event deltas: no events = no turn (no stale _MOUSEX drift)
  mDX = 0
  WHILE _MOUSEINPUT
    mx = _MOUSEX
    IF warpPending THEN
      ' Events nearer the center than the warp origin are post-warp
      IF ABS(mx - 400) < ABS(mx - lastMX) THEN lastMX = 400: warpPending = 0
    END IF
    mDX = mDX + mx - lastMX
    lastMX = mx
  WEND
  IF warpPending THEN
    warpWait = warpWait + 1: IF warpWait > 30 THEN warpPending = 0 ' Warp never landed
  ELSEIF _WINDOWHASFOCUS AND (lastMX < 150 OR lastMX > 650) THEN
    _MOUSEMOVE 400, 300: warpPending = 1: warpWait = 0 ' Re-center only near the edges
  END IF
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
    ' March along the view ray; open the first closed door within reach, stop at walls
    FOR reach = 0.05 TO 2 STEP 0.05
      cX = INT(pX + pDirX * reach): cY = INT(pY + pDirY * reach)
      IF worldMap(cX, cY) = 2 AND doorOffsets(cX, cY) = 0 THEN doorOffsets(cX, cY) = 0.01: EXIT FOR
      IF worldMap(cX, cY) = 1 OR worldMap(cX, cY) = 3 THEN EXIT FOR
    NEXT
  END IF
  FOR dy = 0 TO MAP_SIZE - 1: FOR dx = 0 TO MAP_SIZE - 1
      IF doorOffsets(dx, dy) > 0 AND doorOffsets(dx, dy) < 1 THEN doorOffsets(dx, dy) = doorOffsets(dx, dy) + 0.04
  NEXT: NEXT
 
  ' --- 4. Render (into half-res buffer scr()) ---
  ' Floor + ceiling: cast one row at a time, mirrored about the horizon
  rx0 = pDirX - planeX: ry0 = pDirY - planeY
  rx1 = pDirX + planeX: ry1 = pDirY + planeY
  FOR y = RH \ 2 TO RH - 1
    rowDist = (RH / 2) / (y - RH / 2 + 0.5)
    fsX = rowDist * (rx1 - rx0) / RW: fsY = rowDist * (ry1 - ry0) / RW
    fX = pX + rowDist * rx0: fY = pY + rowDist * ry0
    s& = 256 - rowDist * 16
    IF s& < 0 THEN s& = 0
    rowF = y * RW: rowC = (RH - 1 - y) * RW
    FOR x = 0 TO RW - 1
      fu = INT(fX * TEX) AND (TEX - 1): fv = INT(fY * TEX) AND (TEX - 1)
      scr(rowF + x) = Shade~&(tex(fu, fv, T_FLOOR), s&)
      scr(rowC + x) = Shade~&(tex(fu, fv, T_CEIL), s&)
      fX = fX + fsX: fY = fY + fsY
    NEXT
  NEXT

  ' Walls + doors
  FOR x = 0 TO RW - 1
    camX = 2 * x / RW - 1
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
    IF dist < 0.001 THEN dist = 0.001

    ' Texture column (doors slide: shift by their open offset)
    IF side = 0 THEN wallX = pY + dist * rDY ELSE wallX = pX + dist * rDX
    wallX = wallX - INT(wallX)
    IF hit = 2 THEN
      tX = INT((wallX - doorOffsets(mX, mY)) * TEX)
    ELSE
      tX = INT(wallX * TEX)
      IF side = 0 AND rDX > 0 THEN tX = TEX - 1 - tX
      IF side = 1 AND rDY < 0 THEN tX = TEX - 1 - tX
    END IF
    tX = tX AND (TEX - 1)

    lineH = RH / dist
    lStart = INT(RH / 2 - lineH / 2): lEnd = INT(RH / 2 + lineH / 2)
    tStep = TEX / lineH: tPos = (lStart - RH / 2 + lineH / 2) * tStep
    IF lStart < 0 THEN tPos = tPos - lStart * tStep: lStart = 0
    IF lEnd > RH - 1 THEN lEnd = RH - 1

    ' Shading: distance fog, darker on Y-facing sides
    s& = 256 - dist * 16
    IF s& < 0 THEN s& = 0
    IF side = 1 THEN s& = s& * 0.7

    FOR y = lStart TO lEnd
      scr(y * RW + x) = Shade~&(tex(tX, INT(tPos) AND (TEX - 1), hit), s&)
      tPos = tPos + tStep
    NEXT
  NEXT x

  ' Blit buffer -> 2x screen
  _MEMCOPY mScr, mScr.OFFSET, mScr.SIZE TO mBuf, mBuf.OFFSET
  _PUTIMAGE (0, 0)-(799, 599), buf&, 0

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

SUB LoadTex (f$, slot AS INTEGER)
  p$ = "neon-caster/" + f$
  IF NOT _FILEEXISTS(p$) THEN ' Fall back to the folder next to the EXE
    e$ = COMMAND$(0): i = _INSTRREV(e$, "/"): IF i = 0 THEN i = _INSTRREV(e$, "\")
    p$ = LEFT$(e$, i) + "neon-caster/" + f$
  END IF
  img& = _LOADIMAGE(p$, 32)
  IF img& >= -1 THEN PRINT "Missing texture: "; p$: SLEEP: SYSTEM
  t& = _NEWIMAGE(TEX, TEX, 32): _PUTIMAGE , img&, t&
  _SOURCE t&
  FOR y = 0 TO TEX - 1: FOR x = 0 TO TEX - 1: tex(x, y, slot) = POINT(x, y): NEXT: NEXT
  _SOURCE 0: _FREEIMAGE img&: _FREEIMAGE t&
END SUB

' Scale a 32-bit colour's RGB by s/256 (s = 0..256)
FUNCTION Shade~& (c AS _UNSIGNED LONG, s AS LONG)
  DIM rb AS _INTEGER64, g AS _INTEGER64
  rb = c AND &HFF00FF: g = c AND &HFF00&
  Shade~& = &HFF000000~& OR ((rb * s \ 256) AND &HFF00FF) OR ((g * s \ 256) AND &HFF00&)
END FUNCTION
