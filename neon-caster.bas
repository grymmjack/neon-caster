_TITLE "NEON-CASTER"
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE _DISABLE ' Capture the pointer in the window (raw relative motion)
_PRINTMODE _KEEPBACKGROUND

CONST MAP_SIZE = 48 ' Map is MAP_SIZE x MAP_SIZE cells (see MapData)
CONST MM = 3, MMX = 8, MMY = 8 ' Minimap: cell size and top-left corner
CONST PLAYER_R = 0.3 ' Player body radius (keeps the camera off the walls)
' worldMap: 0 floor, 2 door; walls 1 metal (#), 3 neon (N), 4 concrete (C),
' 5 servers (K), 6 pipes (P), 7 biolab (G)
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorOffsets(MAP_SIZE, MAP_SIZE) AS SINGLE
DIM SHARED doorKey(MAP_SIZE, MAP_SIZE) AS INTEGER ' 0 = any door, else the keycard it needs
DIM SHARED doorType(MAP_SIZE, MAP_SIZE) AS INTEGER ' 0 sliding, 1 shutter (rises), 2 split
DIM SHARED floorT(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilT(MAP_SIZE, MAP_SIZE) AS INTEGER ' Texture slots
CONST DOOR_SLIDE = 0, DOOR_SHUTTER = 1, DOOR_SPLIT = 2

' --- Pickups lying on the map ---
CONST IT_HEALTH = 4, IT_CELLS = 5, IT_SHELLS = 6, IT_SCATTER = 7, IT_REPEATER = 8 ' (1-3 keycards)
CONST MAX_ITEMS = 64
DIM SHARED itX(MAX_ITEMS) AS SINGLE, itY(MAX_ITEMS) AS SINGLE
DIM SHARED itK(MAX_ITEMS) AS INTEGER, itOn(MAX_ITEMS) AS INTEGER, nItems AS INTEGER
DIM SHARED hasCard(3) AS INTEGER

' --- Monsters: 1 drone (bites), 2 gunner (shoots bolts), 3 heavy (smashes) ---
CONST MAX_MON = 64, MON_TYPES = 3
CONST MON_SIGHT = 14 ' How far away they notice you
CONST MON_DYING = 24 ' Frames to collapse when killed
DIM SHARED mnX(MAX_MON) AS SINGLE, mnY(MAX_MON) AS SINGLE, mnType(MAX_MON) AS INTEGER
DIM SHARED mnHP(MAX_MON) AS INTEGER, mnState(MAX_MON) AS INTEGER ' 0 idle, 1 hunting, 2 dying, 3 dead
DIM SHARED mnT(MAX_MON) AS INTEGER, mnHurt(MAX_MON) AS INTEGER ' Attack cooldown / dying frames, hit flash
DIM SHARED nMon AS INTEGER
' Per type: hit points, speed (tiles a frame; you walk 0.12), height (of a
' wall), hover height and bob, attack reach, damage (min + random), frames
' between attacks, sprite slots, and sounds
DIM SHARED mtHP(MON_TYPES), mtSpeed(MON_TYPES), mtScale(MON_TYPES), mtLift(MON_TYPES), mtBob(MON_TYPES)
DIM SHARED mtReach(MON_TYPES), mtDmg(MON_TYPES), mtDmgRnd(MON_TYPES), mtCool(MON_TYPES)
DIM SHARED mtSlot(MON_TYPES), mtName$(MON_TYPES)
DIM SHARED mtAlert&(MON_TYPES), mtAtk&(MON_TYPES), mtHitS&(MON_TYPES), mtDie&(MON_TYPES)
CONST GUNNER_NEAR = 3.5, GUNNER_FAR = 7 ' Gunners like to keep this far from you

' --- Energy bolts (gunner shots) ---
CONST MAX_BOLTS = 32, BOLT_SPEED = 0.14
DIM SHARED bX(MAX_BOLTS) AS SINGLE, bY(MAX_BOLTS) AS SINGLE, bDX(MAX_BOLTS) AS SINGLE, bDY(MAX_BOLTS) AS SINGLE
DIM SHARED bOn(MAX_BOLTS) AS INTEGER, bDmg(MAX_BOLTS) AS INTEGER

' --- You: health, two kinds of ammo, three guns ---
CONST MAX_HP = 100
CONST AM_CELLS = 1, AM_SHELLS = 2
DIM SHARED ammoN(2) AS INTEGER, ammoMax(2) AS INTEGER
ammoMax(AM_CELLS) = 99 : ammoMax(AM_SHELLS) = 40
CONST W_BLASTER = 1, W_SCATTER = 2, W_REPEATER = 3
DIM SHARED hasWpn(3) AS INTEGER
' Per gun: name, ammo kind, frames between shots, pellets, spread (of the
' view's width), recoil, sound, picture, and where its muzzle is
DIM SHARED wpName$(3), wpAmmo(3), wpDelay(3), wpPellets(3), wpSpread(3), wpKick(3)
DIM SHARED wpSnd&(3), wpImg&(3), wpMuzX(3), wpMuzY(3), wpScale(3)
wpName$(1) = "BLASTER" : wpAmmo(1) = AM_CELLS : wpDelay(1) = 16 : wpPellets(1) = 1 : wpSpread(1) = 0 : wpKick(1) = 1
wpName$(2) = "SCATTER" : wpAmmo(2) = AM_SHELLS : wpDelay(2) = 40 : wpPellets(2) = 7 : wpSpread(2) = 0.12 : wpKick(2) = 1.7
wpName$(3) = "REPEATER" : wpAmmo(3) = AM_CELLS : wpDelay(3) = 5 : wpPellets(3) = 1 : wpSpread(3) = 0.025 : wpKick(3) = 0.45
CONST SWAP_FRAMES = 14 ' Lowering one gun and raising the next

' --- Sprites (billboards): textures, and the list drawn each frame ---
CONST SPR_TEX = 64, SPR_SLOTS = 15
' 1-3 keycards, 4 medkit, 5 cells, 6 shells, 7 scatter gun, 8 repeater,
' 9/10 drone (/hit), 11/12 gunner, 13/14 heavy, 15 bolt
CONST S_BOLT = 15
CONST CARD_SCALE = 0.3, ITEM_SCALE = 0.3, GUN_ITEM_SCALE = 0.45
DIM SHARED sprTex(SPR_TEX - 1, SPR_TEX - 1, SPR_SLOTS) AS _UNSIGNED LONG, sprSz(SPR_SLOTS) AS INTEGER
DIM SHARED cardImg&(3)
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS
DIM dlX(MAX_DRAW) AS SINGLE, dlY(MAX_DRAW) AS SINGLE, dlD(MAX_DRAW) AS SINGLE
DIM dlSlot(MAX_DRAW) AS INTEGER, dlScale(MAX_DRAW) AS SINGLE, dlLift(MAX_DRAW) AS SINGLE
DIM dlSquash(MAX_DRAW) AS SINGLE, dlMinS(MAX_DRAW) AS INTEGER, ord(MAX_DRAW) AS INTEGER

' --- Render buffer (half-res, scaled 2x to the screen) ---
CONST RW = 400, RH = 300, TEX = 64
' Texture slots: 1 metal wall, 2 sliding door, 3 neon wall, 4 grate floor,
' 5 purple ceiling, 6-8 key doors, 9 concrete, 10 servers, 11 pipes,
' 12 biolab, 13 shutter, 14 split door, 15 plate floor, 16 concrete floor,
' 17 lab floor, 18 light-panel ceiling
CONST T_WALL = 1, T_DOOR = 2, T_WALL2 = 3, T_FLOOR = 4, T_CEIL = 5
CONST T_DOORK = 5 ' Key doors: slot T_DOORK + card (6 red, 7 blue, 8 yellow)
CONST T_SHUTTER = 13, T_SPLIT = 14, T_SLOTS = 18
DIM SHARED TEX(TEX - 1, TEX - 1, T_SLOTS) AS _UNSIGNED LONG
DIM SHARED wallSlot(7) AS INTEGER ' worldMap wall value -> texture slot
wallSlot(1) = T_WALL : wallSlot(3) = T_WALL2 : wallSlot(4) = 9 : wallSlot(5) = 10 : wallSlot(6) = 11 : wallSlot(7) = 12
DIM SHARED floorSlot(4) AS INTEGER, ceilSlot(2) AS INTEGER ' MapData zone numbers -> slots
floorSlot(1) = T_FLOOR : floorSlot(2) = 15 : floorSlot(3) = 16 : floorSlot(4) = 17
ceilSlot(1) = T_CEIL : ceilSlot(2) = 18
DIM SHARED scr(0 TO RW * RH - 1) AS _UNSIGNED LONG
DIM SHARED zBuf(RW - 1) AS SINGLE ' Wall distance per column (sprites hide behind walls)
buf& = _NEWIMAGE(RW, RH, 32)
DIM mBuf AS _MEM, mScr AS _MEM
mBuf = _MEMIMAGE(buf&) : mScr = _MEM(scr())

' --- Load Textures and sprites ---
LoadTex "wall.png", T_WALL
LoadTex "door.png", T_DOOR
LoadTex "wall2.png", T_WALL2
LoadTex "floor.png", T_FLOOR
LoadTex "ceiling.png", T_CEIL
LoadTex "wall-concrete.png", 9
LoadTex "wall-servers.png", 10
LoadTex "wall-pipes.png", 11
LoadTex "wall-biolab.png", 12
LoadTex "door-shutter.png", T_SHUTTER
LoadTex "door-split.png", T_SPLIT
LoadTex "floor-plates.png", 15
LoadTex "floor-concrete.png", 16
LoadTex "floor-lab.png", 17
LoadTex "ceiling-lights.png", 18
LoadCards "keycard.png"
LoadSprite "medkit.png", 4
LoadSprite "ammo.png", 5
LoadSprite "shells.png", 6
LoadSprite "pickup-scatter.png", 7
LoadSprite "pickup-repeater.png", 8
LoadSprite "drone.png", 9
LoadSprite "gunner.png", 11
LoadSprite "heavy.png", 13
FOR t = 9 TO 13 STEP 2 ' Hit flash: each monster washed hot red
    FOR y = 0 TO SPR_TEX - 1 : FOR x = 0 TO SPR_TEX - 1
        sprTex(x, y, t + 1) = Tint~&(sprTex(x, y, t), _RGB32(255, 90, 70), 0.7)
    NEXT : NEXT
    sprSz(t + 1) = sprSz(t)
NEXT
MakeBolt S_BOLT

' The guns, first person (each picture holds it in the left hand, barrel
' pointing right: drawn mirrored, so it's in your right hand)
wpScale(1) = 3 : wpScale(2) = 3.6 : wpScale(3) = 4 ' Drawn this many times their size
CONST GUN_X = 520, GUN_Y = 600 ' Where its bottom centre sits on the screen
LoadGun 1, "gun.png"
LoadGun 2, "gun-scatter.png"
LoadGun 3, "gun-repeater.png"

' --- Load Sounds (PWMSFXR patches, rendered by neon-caster/sfx/make-sfx.sh) ---
sndStep1& = LoadSnd&("step1.wav") : sndStep2& = LoadSnd&("step2.wav")
sndBump& = LoadSnd&("bump.wav") : sndHump& = LoadSnd&("wallhump.wav")
sndDoor& = LoadSnd&("door.wav") : sndShutter& = LoadSnd&("door-shutter.wav") : sndSplit& = LoadSnd&("door-split.wav")
sndCard& = LoadSnd&("keycard.wav") : sndLocked& = LoadSnd&("locked.wav")
sndEmpty& = LoadSnd&("empty.wav") : sndWeapon& = LoadSnd&("weapon.wav")
sndHealth& = LoadSnd&("health.wav") : sndAmmo& = LoadSnd&("ammo.wav") : sndShells& = LoadSnd&("shells.wav")
sndBoltWall& = LoadSnd&("bolt-wall.wav")
sndHurt& = LoadSnd&("hurt.wav") : sndDie& = LoadSnd&("die.wav")
wpSnd&(1) = LoadSnd&("shoot.wav") : wpSnd&(2) = LoadSnd&("scatter.wav") : wpSnd&(3) = LoadSnd&("repeater.wav")
CONST STEP_LEN = 2.6 ' Distance walked per footstep (~2.8 steps a second at full speed)

' Monster types           HP  speed  height lift  bob   reach dmg+rnd cool slot
SetMonType 1, "drone", 3, 0.045, 0.65, 0.2, 0.05, 0.95, 8, 6, 50, 9
SetMonType 2, "gunner", 4, 0.035, 0.8, 0, 0, 0, 9, 6, 90, 11
SetMonType 3, "heavy", 10, 0.028, 0.95, 0, 0, 1.25, 20, 10, 80, 13
mtAlert&(1) = LoadSnd&("drone-alert.wav") : mtAtk&(1) = LoadSnd&("drone-attack.wav")
mtHitS&(1) = LoadSnd&("drone-hit.wav") : mtDie&(1) = LoadSnd&("drone-die.wav")
mtAlert&(2) = LoadSnd&("gunner-alert.wav") : mtAtk&(2) = LoadSnd&("gunner-shoot.wav")
mtHitS&(2) = LoadSnd&("gunner-hit.wav") : mtDie&(2) = LoadSnd&("gunner-die.wav")
mtAlert&(3) = LoadSnd&("heavy-alert.wav") : mtAtk&(3) = LoadSnd&("heavy-attack.wav")
mtHitS&(3) = LoadSnd&("heavy-hit.wav") : mtDie&(3) = LoadSnd&("heavy-die.wav")

DIM x AS LONG, y AS LONG, fu AS LONG, fv AS LONG, tX AS LONG
DIM rowF AS LONG, rowC AS LONG, lStart AS LONG, lEnd AS LONG

MoveSpeed = 0.12 : RotSpeed = 0.003 ' Mouse sensitivity
GOSUB LoadLevel

DO
    _LIMIT 60

    ' --- 1. Input ---
    ' Pointer is captured, so just sum the raw relative motion from each event
    mDX = 0 : wheel = 0
    WHILE _MOUSEINPUT
        mDX = mDX + _MOUSEMOVEMENTX
        wheel = wheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1 ' (a quick click between frames still counts)
    WEND
    fireDown = _MOUSEBUTTON(1) OR clicked OR _KEYDOWN(100305) OR _KEYDOWN(100306) ' Click or Ctrl
    clicked = 0
    spaceDown = _KEYDOWN(32)

    IF dead THEN
        ' Dead: the view stays put; click or Space (after a moment) starts over
        IF TIMER - deadAt! > 1.2 AND ((fireDown AND NOT fireWas) OR (spaceDown AND NOT spaceWas)) THEN GOSUB LoadLevel
        mDX = 0 : wheel = 0
    END IF

    mDX = mDX / DisplayScale! ' Same turn speed windowed or fullscreen
    angle = - mDX * RotSpeed
    oldDirX = pDirX : pDirX = pDirX * COS(angle) - pDirY * SIN(angle) : pDirY = oldDirX * SIN(angle) + pDirY * COS(angle)
    oldPX = planeX : planeX = planeX * COS(angle) - planeY * SIN(angle) : planeY = oldPX * SIN(angle) + planeY * COS(angle)

    ' Guns: 1 / 2 / 3, or the mouse wheel through the ones you have
    want = 0
    IF _KEYDOWN(49) THEN want = 1
    IF _KEYDOWN(50) THEN want = 2
    IF _KEYDOWN(51) THEN want = 3
    IF wheel <> 0 THEN
        want = curW
        DO
            want = want + SGN(wheel) : IF want > 3 THEN want = 1
            IF want < 1 THEN want = 3
        LOOP UNTIL hasWpn(want)
    END IF
    IF want > 0 AND want <> curW AND swapT = 0 THEN
        IF hasWpn(want) THEN nextW = want : swapT = SWAP_FRAMES
    END IF
    IF swapT > 0 THEN
        swapT = swapT - 1
        IF swapT = SWAP_FRAMES \ 2 THEN curW = nextW ' Swapped while it's out of sight
    END IF

    ' --- 2. WASD + Strafe + Backwards ---
    ' Forward/back and strafe combine into one direction at walking speed, so
    ' diagonals aren't faster (and opposite keys cancel out)
    fwd = 0 : strafe = 0
    IF NOT dead THEN
        IF _KEYDOWN(119) OR _KEYDOWN(87) THEN fwd = fwd + 1 ' W
        IF _KEYDOWN(115) OR _KEYDOWN(83) THEN fwd = fwd - 1 ' S
        IF _KEYDOWN(97) OR _KEYDOWN(65) THEN strafe = strafe - 1 ' A (strafe left)
        IF _KEYDOWN(100) OR _KEYDOWN(68) THEN strafe = strafe + 1 ' D (strafe right)
    END IF
    moveX = pDirX * fwd + pDirY * strafe : moveY = pDirY * fwd - pDirX * strafe
    moveLen = SQR(moveX * moveX + moveY * moveY)
    IF moveLen > 0 THEN
        moveX = moveX / moveLen * MoveSpeed : moveY = moveY / moveLen * MoveSpeed
        bob = bob + 0.2
    END IF

    ' Collision (Slide along walls)
    ' Player has a body radius so the camera can't touch the walls
    prevX = pX : prevY = pY
    edgeX = pX + moveX + SGN(moveX) * PLAYER_R
    IF Walkable(edgeX, pY - PLAYER_R) AND Walkable(edgeX, pY + PLAYER_R) THEN pX = pX + moveX
    edgeY = pY + moveY + SGN(moveY) * PLAYER_R
    IF Walkable(pX - PLAYER_R, edgeY) AND Walkable(pX + PLAYER_R, edgeY) THEN pY = pY + moveY
    ' ...and you can't walk through a monster
    FOR i = 1 TO nMon
        IF mnState(i) < 2 THEN
            near = 0.3 + mtScale(mnType(i)) * 0.35
            dNew = (mnX(i) - pX) ^ 2 + (mnY(i) - pY) ^ 2
            IF dNew < near * near AND dNew < (mnX(i) - prevX) ^ 2 + (mnY(i) - prevY) ^ 2 THEN pX = prevX : pY = prevY
        END IF
    NEXT

    ' Footsteps: one every STEP_LEN actually walked, alternating feet
    moved = SQR((pX - prevX) ^ 2 + (pY - prevY) ^ 2)
    IF moved > 0 THEN
        stepDist = stepDist + moved
        IF stepDist >= STEP_LEN THEN
            stepDist = stepDist - STEP_LEN : stepFoot = 1 - stepFoot
            IF stepFoot THEN PlaySfx sndStep1&, 0.35 ELSE PlaySfx sndStep2&, 0.35
        END IF
    ELSE
        stepDist = STEP_LEN * 0.85
    END IF

    ' Bump: once when you push firmly into a wall (not when sliding along one)
    pushing = 0
    IF pX = prevX AND ABS(moveX) > MoveSpeed * 0.5 THEN pushing = -1
    IF pY = prevY AND ABS(moveY) > MoveSpeed * 0.5 THEN pushing = -1
    IF pushing AND NOT wasPushing THEN PlaySfx sndBump&, 0.8
    wasPushing = pushing

    ' Pickups: walk over one (ones you can't use yet stay put)
    FOR i = 1 TO nItems
        IF itOn(i) AND NOT dead AND (itX(i) - pX) ^ 2 + (itY(i) - pY) ^ 2 < 0.45 * 0.45 THEN
            SELECT CASE itK(i)
                CASE 1 TO 3
                    itOn(i) = 0 : hasCard(itK(i)) = -1
                    PlaySfx sndCard&, 0.8
                    ShowMsg "Picked up the " + CardName$(itK(i)) + " keycard"
                CASE IT_HEALTH
                    IF hp < MAX_HP THEN
                        itOn(i) = 0 : hp = hp + 25 : IF hp > MAX_HP THEN hp = MAX_HP
                        PlaySfx sndHealth&, 0.8 : ShowMsg "Health pack (+25)" : pickFlash = 10
                    END IF
                CASE IT_CELLS
                    IF GiveAmmo%(AM_CELLS, 15) THEN itOn(i) = 0 : PlaySfx sndAmmo&, 0.8 : ShowMsg "Energy cells (+15)" : pickFlash = 10
                CASE IT_SHELLS
                    IF GiveAmmo%(AM_SHELLS, 8) THEN itOn(i) = 0 : PlaySfx sndShells&, 0.8 : ShowMsg "Shells (+8)" : pickFlash = 10
                CASE IT_SCATTER, IT_REPEATER
                    w = itK(i) - IT_SCATTER + W_SCATTER
                    IF w = W_SCATTER THEN got = GiveAmmo%(AM_SHELLS, 8) ELSE got = GiveAmmo%(AM_CELLS, 30)
                    IF NOT hasWpn(w) OR got THEN
                        itOn(i) = 0 : PlaySfx sndWeapon&, 0.9 : pickFlash = 10
                        IF NOT hasWpn(w) THEN
                            hasWpn(w) = -1 : nextW = w : swapT = SWAP_FRAMES
                            ShowMsg "You got the " + wpName$(w) + "!  (" + LTRIM$(STR$(w)) + " or mouse wheel to switch)"
                        ELSE
                            ShowMsg wpName$(w) + " ammo"
                        END IF
                    END IF
            END SELECT
        END IF
    NEXT

    ' --- 3. Door & World Logic ---
    IF spaceDown AND NOT spaceWas AND NOT dead THEN ' SPACE TO OPEN (once per press)
        ' March along the view ray; open the first closed door within reach, stop at walls
        FOR reach = 0.05 TO 2 STEP 0.05
            cX = INT(pX + pDirX * reach) : cY = INT(pY + pDirY * reach)
            IF worldMap(cX, cY) = 2 AND doorOffsets(cX, cY) = 0 THEN
                dk = doorKey(cX, cY)
                IF dk = 0 OR hasCard(dk) THEN
                    doorOffsets(cX, cY) = 0.01
                    SELECT CASE doorType(cX, cY)
                        CASE DOOR_SHUTTER : PlaySfx sndShutter&, 0.9
                        CASE DOOR_SPLIT : PlaySfx sndSplit&, 0.9
                        CASE ELSE : PlaySfx sndDoor&, 0.9
                    END SELECT
                ELSE
                    PlaySfx sndLocked&, 0.8
                    ShowMsg "Locked - you need the " + CardName$(dk) + " keycard"
                END IF
                EXIT FOR
            END IF
            IF IsWall(cX, cY) THEN
                IF reach <= 1.2 THEN PlaySfx sndHump&, 0.8 ' Trying to open a plain wall
                EXIT FOR
            END IF
        NEXT
    END IF
    FOR dy = 0 TO MAP_SIZE - 1 : FOR dx = 0 TO MAP_SIZE - 1
        IF doorOffsets(dx, dy) > 0 AND doorOffsets(dx, dy) < 1 THEN
            SELECT CASE doorType(dx, dy) ' Shutters are heavy and slow, split doors snap open
                CASE DOOR_SHUTTER : doorOffsets(dx, dy) = doorOffsets(dx, dy) + 0.025
                CASE DOOR_SPLIT : doorOffsets(dx, dy) = doorOffsets(dx, dy) + 0.06
                CASE ELSE : doorOffsets(dx, dy) = doorOffsets(dx, dy) + 0.04
            END SELECT
            IF doorOffsets(dx, dy) > 1 THEN doorOffsets(dx, dy) = 1
        END IF
    NEXT : NEXT

    ' --- Shooting: hold to fire. Each pellet hits the nearest monster in its
    ' line, unless a wall is closer
    IF fireWait > 0 THEN fireWait = fireWait - 1
    IF fireDown AND NOT dead AND fireWait = 0 AND swapT = 0 THEN
        am = wpAmmo(curW)
        IF ammoN(am) > 0 THEN
            ammoN(am) = ammoN(am) - 1 : fireWait = wpDelay(curW) : gunKick = wpKick(curW) : muzzle = 4
            PlaySfx wpSnd&(curW), 0.7
            invDet = 1 / (planeX * pDirY - pDirX * planeY)
            FOR pel = 1 TO wpPellets(curW)
                aim = (RND * 2 - 1) * wpSpread(curW) ' Across the view, -1 left edge .. 1 right
                IF wpPellets(curW) > 1 THEN aim = ((pel - 1) / (wpPellets(curW) - 1) * 2 - 1) * wpSpread(curW) + (RND - 0.5) * 0.02
                col = INT(RW / 2 * (1 + aim)) : IF col < 0 THEN col = 0
                IF col > RW - 1 THEN col = RW - 1
                best = 0 : bestD = zBuf(col)
                FOR i = 1 TO nMon
                    IF mnState(i) < 2 THEN
                        sx = mnX(i) - pX : sy = mnY(i) - pY
                        trX = invDet * (pDirY * sx - pDirX * sy) : trY = invDet * (- planeY * sx + planeX * sy)
                        IF trY > 0.2 AND trY < bestD THEN
                            IF ABS(RW / 2 * (trX / trY - aim)) < RH / trY * mtScale(mnType(i)) * 0.3 THEN best = i : bestD = trY
                        END IF
                    END IF
                NEXT
                IF best THEN hitMon = best : GOSUB HitMonster
            NEXT
        ELSEIF NOT fireWas THEN
            PlaySfx sndEmpty&, 0.7
            IF am = AM_SHELLS THEN ShowMsg "Out of shells" ELSE ShowMsg "Out of energy cells"
            fireWait = 20
        END IF
    END IF
    fireWas = fireDown : spaceWas = spaceDown

    ' --- Monsters ---
    FOR i = 1 TO nMon
        IF mnHurt(i) > 0 THEN mnHurt(i) = mnHurt(i) - 1
        t = mnType(i)
        SELECT CASE mnState(i)
            CASE 0 ' Idle: wake when it can see you
                IF NOT dead THEN
                    IF (mnX(i) - pX) ^ 2 + (mnY(i) - pY) ^ 2 < MON_SIGHT * MON_SIGHT THEN
                        IF CanSee(mnX(i), mnY(i), pX, pY) THEN
                            mnState(i) = 1 : mnT(i) = 30
                            SfxAt mtAlert&(t), mnX(i), mnY(i), pX, pY
                        END IF
                    END IF
                END IF
            CASE 1 ' Hunting
                IF mnT(i) > 0 THEN mnT(i) = mnT(i) - 1
                ddx = pX - mnX(i) : ddy = pY - mnY(i) : d = SQR(ddx * ddx + ddy * ddy)
                IF NOT dead AND d > 0.01 THEN
                    goX = 0 : goY = 0
                    IF t = 2 THEN
                        ' Gunner: keep its distance, shoot when it has a clear line
                        seen = CanSee(mnX(i), mnY(i), pX, pY)
                        IF d > GUNNER_FAR OR NOT seen THEN goX = ddx / d : goY = ddy / d
                        IF d < GUNNER_NEAR THEN goX = -ddx / d : goY = -ddy / d
                        IF seen AND mnT(i) = 0 AND d < 11 THEN
                            FireBolt mnX(i), mnY(i), ddx / d, ddy / d, mtDmg(t) + INT(RND * mtDmgRnd(t))
                            SfxAt mtAtk&(t), mnX(i), mnY(i), pX, pY
                            mnT(i) = mtCool(t) + INT(RND * 30)
                        END IF
                    ELSEIF d > mtReach(t) THEN
                        goX = ddx / d : goY = ddy / d ' Drone / heavy: close in
                    ELSEIF mnT(i) = 0 THEN ' ...and hit
                        dmg = mtDmg(t) + INT(RND * mtDmgRnd(t)) : mnT(i) = mtCool(t)
                        PlaySfx mtAtk&(t), 0.9
                        GOSUB HurtPlayer
                    END IF
                    IF goX <> 0 OR goY <> 0 THEN
                        nx = mnX(i) + goX * mtSpeed(t) : ny = mnY(i) + goY * mtSpeed(t)
                        IF Walkable(nx + SGN(goX) * PLAYER_R, mnY(i) - PLAYER_R) AND Walkable(nx + SGN(goX) * PLAYER_R, mnY(i) + PLAYER_R) THEN mnX(i) = nx
                        IF Walkable(mnX(i) - PLAYER_R, ny + SGN(goY) * PLAYER_R) AND Walkable(mnX(i) + PLAYER_R, ny + SGN(goY) * PLAYER_R) THEN mnY(i) = ny
                    END IF
                END IF
                ' Keep a little apart from each other
                FOR j = 1 TO nMon
                    IF j <> i AND mnState(j) < 2 THEN
                        sx = mnX(i) - mnX(j) : sy = mnY(i) - mnY(j) : d2 = sx * sx + sy * sy
                        IF d2 < 0.36 AND d2 > 0.0001 THEN
                            nx = mnX(i) + sx * 0.05 : ny = mnY(i) + sy * 0.05
                            IF Walkable(nx, ny) THEN mnX(i) = nx : mnY(i) = ny
                        END IF
                    END IF
                NEXT
            CASE 2 ' Dying: collapse
                mnT(i) = mnT(i) - 1
                IF mnT(i) <= 0 THEN mnState(i) = 3
        END SELECT
    NEXT

    ' --- Bolts: fly straight; burst on walls, or on you
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) THEN
            bX(i) = bX(i) + bDX(i) * BOLT_SPEED : bY(i) = bY(i) + bDY(i) * BOLT_SPEED
            IF NOT Walkable(bX(i), bY(i)) THEN
                bOn(i) = 0 : SfxAt sndBoltWall&, bX(i), bY(i), pX, pY
            ELSEIF NOT dead AND (bX(i) - pX) ^ 2 + (bY(i) - pY) ^ 2 < 0.35 * 0.35 THEN
                bOn(i) = 0 : dmg = bDmg(i) : GOSUB HurtPlayer
            END IF
        END IF
    NEXT
    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
    IF pickFlash > 0 THEN pickFlash = pickFlash - 1

    ' --- 4. Render (into half-res buffer scr()) ---
    ' Floor + ceiling: cast one row at a time, mirrored about the horizon;
    ' each map cell has its own floor and ceiling texture
    rx0 = pDirX - planeX : ry0 = pDirY - planeY
    rx1 = pDirX + planeX : ry1 = pDirY + planeY
    FOR y = RH \ 2 TO RH - 1
        rowDist = (RH / 2) / (y - RH / 2 + 0.5)
        fsX = rowDist * (rx1 - rx0) / RW : fsY = rowDist * (ry1 - ry0) / RW
        fX = pX + rowDist * rx0 : fY = pY + rowDist * ry0
        s& = 256 - rowDist * 16
        IF s& < 0 THEN s& = 0
        rowF = y * RW : rowC = (RH - 1 - y) * RW
        FOR x = 0 TO RW - 1
            cx = INT(fX) : cy = INT(fY)
            IF cx >= 0 AND cx < MAP_SIZE AND cy >= 0 AND cy < MAP_SIZE THEN
                fs = floorT(cx, cy) : cs = ceilT(cx, cy)
            ELSE
                fs = T_FLOOR : cs = T_CEIL
            END IF
            fu = INT(fX * TEX) AND (TEX - 1) : fv = INT(fY * TEX) AND (TEX - 1)
            scr(rowF + x) = Shade~&(TEX(fu, fv, fs), s&)
            scr(rowC + x) = Shade~&(TEX(fu, fv, cs), s&)
            fX = fX + fsX : fY = fY + fsY
        NEXT
    NEXT

    ' Walls + doors
    FOR x = 0 TO RW - 1
        camX = 2 * x / RW - 1
        rDX = pDirX + planeX * camX : rDY = pDirY + planeY * camX
        mX = INT(pX) : mY = INT(pY)
        dDX = ABS(1 / rDX) : dDY = ABS(1 / rDY)

        IF rDX < 0 THEN stX = -1 : sDX = (pX - mX) * dDX ELSE stX = 1 : sDX = (mX + 1 - pX) * dDX
        IF rDY < 0 THEN stY = -1 : sDY = (pY - mY) * dDY ELSE stY = 1 : sDY = (mY + 1 - pY) * dDY

        hit = 0 : side = 0 : ovl = 0
        WHILE hit = 0
            IF sDX < sDY THEN sDX = sDX + dDX : mX = mX + stX : side = 0 ELSE sDY = sDY + dDY : mY = mY + stY : side = 1
            v = worldMap(mX, mY)
            IF v = 2 THEN
                IF side = 0 THEN dd = (mX - pX + (1 - stX) / 2) / rDX : wX = pY + dd * rDY ELSE dd = (mY - pY + (1 - stY) / 2) / rDY : wX = pX + dd * rDX
                wX = wX - INT(wX) : dOpen = doorOffsets(mX, mY)
                SELECT CASE doorType(mX, mY)
                    CASE DOOR_SLIDE ' Slides sideways
                        IF wX > dOpen THEN hit = 2
                    CASE DOOR_SPLIT ' Halves part from the middle
                        IF wX < 0.5 - dOpen / 2 OR wX > 0.5 + dOpen / 2 THEN hit = 2
                    CASE DOOR_SHUTTER ' Rises: shut, it's a wall; rising, you see under it
                        IF dOpen <= 0 THEN
                            hit = 2
                        ELSEIF dOpen < 1 AND ovl = 0 THEN
                            ovl = -1 : ovD = dd : ovU = wX : ovOpen = dOpen : ovSide = side
                        END IF
                END SELECT
            ELSEIF v > 0 THEN
                hit = v
            END IF
        WEND

        IF side = 0 THEN dist = (mX - pX + (1 - stX) / 2) / rDX ELSE dist = (mY - pY + (1 - stY) / 2) / rDY
        IF dist < 0.001 THEN dist = 0.001
        zBuf(x) = dist

        ' Texture column and slot (doors move their texture with them)
        IF side = 0 THEN wallX = pY + dist * rDY ELSE wallX = pX + dist * rDX
        wallX = wallX - INT(wallX)
        IF hit = 2 THEN
            dOpen = doorOffsets(mX, mY)
            SELECT CASE doorType(mX, mY)
                CASE DOOR_SLIDE
                    tX = INT((wallX - dOpen) * TEX)
                    IF doorKey(mX, mY) THEN tSlot = T_DOORK + doorKey(mX, mY) ELSE tSlot = T_DOOR
                CASE DOOR_SPLIT
                    IF wallX < 0.5 THEN tX = INT((wallX + dOpen / 2) * TEX) ELSE tX = INT((wallX - dOpen / 2) * TEX)
                    tSlot = T_SPLIT
                CASE ELSE
                    tX = INT(wallX * TEX) : tSlot = T_SHUTTER
            END SELECT
        ELSE
            tX = INT(wallX * TEX) : tSlot = wallSlot(hit)
            IF side = 0 AND rDX > 0 THEN tX = TEX - 1 - tX
            IF side = 1 AND rDY < 0 THEN tX = TEX - 1 - tX
        END IF
        tX = tX AND (TEX - 1)

        lineH = RH / dist
        lStart = INT(RH / 2 - lineH / 2) : lEnd = INT(RH / 2 + lineH / 2)
        tStep = TEX / lineH : tPos = (lStart - RH / 2 + lineH / 2) * tStep
        IF lStart < 0 THEN tPos = tPos - lStart * tStep : lStart = 0
        IF lEnd > RH - 1 THEN lEnd = RH - 1

        ' Shading: distance fog, darker on Y-facing sides
        s& = 256 - dist * 16
        IF s& < 0 THEN s& = 0
        IF side = 1 THEN s& = s& * 0.7

        FOR y = lStart TO lEnd
            scr(y * RW + x) = Shade~&(TEX(tX, INT(tPos) AND (TEX - 1), tSlot), s&)
            tPos = tPos + tStep
        NEXT

        ' A rising shutter in front: its lower edge has lifted ovOpen of the
        ' way up, so draw only the part still hanging down
        IF ovl THEN
            lineH = RH / ovD
            oTop = INT(RH / 2 - lineH / 2) : lEnd = INT(RH / 2 + lineH / 2 - ovOpen * lineH)
            tStep = TEX / lineH : tPos = ovOpen * TEX
            lStart = oTop
            IF lStart < 0 THEN tPos = tPos - lStart * tStep : lStart = 0
            IF lEnd > RH - 1 THEN lEnd = RH - 1
            s& = 256 - ovD * 16
            IF s& < 0 THEN s& = 0
            IF ovSide = 1 THEN s& = s& * 0.7
            tX = INT(ovU * TEX) AND (TEX - 1)
            FOR y = lStart TO lEnd
                scr(y * RW + x) = Shade~&(TEX(tX, INT(tPos) AND (TEX - 1), T_SHUTTER), s&)
                tPos = tPos + tStep
            NEXT
            IF ovOpen < 0.5 THEN zBuf(x) = ovD ' Mostly down: things behind it stay hidden
        END IF
    NEXT x

    ' --- Sprites: pickups, monsters and bolts, far to near, hidden behind
    ' walls by zBuf
    nDraw = 0
    FOR i = 1 TO nItems
        IF itOn(i) THEN
            nDraw = nDraw + 1 : dlX(nDraw) = itX(i) : dlY(nDraw) = itY(i)
            dlSlot(nDraw) = itK(i) : dlSquash(nDraw) = 1 : dlMinS(nDraw) = 96 ' They glow: less fog
            SELECT CASE itK(i)
                CASE 1 TO 3 : dlScale(nDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER : dlScale(nDraw) = GUN_ITEM_SCALE
                CASE ELSE : dlScale(nDraw) = ITEM_SCALE
            END SELECT
            dlLift(nDraw) = 0.12 + 0.04 * SIN(TIMER * 3 + i) ' Hovering, bobbing
        END IF
    NEXT
    FOR i = 1 TO nMon
        IF mnState(i) < 3 THEN
            t = mnType(i)
            nDraw = nDraw + 1 : dlX(nDraw) = mnX(i) : dlY(nDraw) = mnY(i)
            dlScale(nDraw) = mtScale(t) : dlMinS(nDraw) = 40
            IF mnHurt(i) > 0 THEN dlSlot(nDraw) = mtSlot(t) + 1 ELSE dlSlot(nDraw) = mtSlot(t)
            IF mnState(i) = 2 THEN ' Collapsing to the floor
                dlSquash(nDraw) = mnT(i) / MON_DYING : dlLift(nDraw) = mtLift(t) * dlSquash(nDraw) : dlSlot(nDraw) = mtSlot(t) + 1
            ELSE
                dlSquash(nDraw) = 1 : dlLift(nDraw) = mtLift(t) + mtBob(t) * SIN(TIMER * 2.5 + i * 1.7)
            END IF
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) THEN
            nDraw = nDraw + 1 : dlX(nDraw) = bX(i) : dlY(nDraw) = bY(i)
            dlSlot(nDraw) = S_BOLT : dlScale(nDraw) = 0.22 : dlLift(nDraw) = 0.38
            dlSquash(nDraw) = 1 : dlMinS(nDraw) = 256 ' Glowing: no fog at all
        END IF
    NEXT
    FOR i = 1 TO nDraw
        ord(i) = i : dlD(i) = (dlX(i) - pX) ^ 2 + (dlY(i) - pY) ^ 2
    NEXT
    FOR a = 1 TO nDraw - 1 : FOR b = a + 1 TO nDraw
        IF dlD(ord(b)) > dlD(ord(a)) THEN SWAP ord(a), ord(b)
    NEXT : NEXT
    invDet = 1 / (planeX * pDirY - pDirX * planeY)
    FOR o = 1 TO nDraw
        i = ord(o)
        sx = dlX(i) - pX : sy = dlY(i) - pY
        trX = invDet * (pDirY * sx - pDirX * sy) ' Sideways from the view
        trY = invDet * (- planeY * sx + planeX * sy) ' Depth
        IF trY > 0.1 THEN
            sprW = INT(RH / trY * dlScale(i)) : sprH = INT(sprW * dlSquash(i))
            IF sprH < 1 THEN sprH = 1
            y0 = INT(RH / 2 + (0.5 - dlLift(i)) * RH / trY) - sprH ' Bottom edge lifted off the floor
            x0 = INT(RW / 2 * (1 + trX / trY)) - sprW \ 2
            s& = 256 - trY * 10
            IF s& < dlMinS(i) THEN s& = dlMinS(i)
            sz = sprSz(dlSlot(i)) : sl = dlSlot(i)
            FOR sxp = x0 TO x0 + sprW - 1
                IF sxp >= 0 AND sxp < RW THEN
                    IF trY < zBuf(sxp) THEN
                        u = (sxp - x0) * sz \ sprW
                        FOR syp = y0 TO y0 + sprH - 1
                            IF syp >= 0 AND syp < RH THEN
                                c~& = sprTex(u, (syp - y0) * sz \ sprH, sl)
                                IF _ALPHA32(c~&) > 128 THEN scr(syp * RW + sxp) = Shade~&(c~&, s&)
                            END IF
                        NEXT
                    END IF
                END IF
            NEXT
        END IF
    NEXT

    ' Blit buffer -> 2x screen
    _MEMCOPY mScr, mScr.OFFSET, mScr.SIZE TO mBuf, mBuf.OFFSET
    _PUTIMAGE (0, 0)-(799, 599), buf&, 0

    ' --- 5. Weapon / HUD ---
    ' The gun sways as you walk, kicks when it fires, and dips out of sight
    ' to swap
    IF gunKick > 0 THEN gunKick = gunKick * 0.75 : IF gunKick < 0.02 THEN gunKick = 0
    gImg& = wpImg&(curW)
    gw = _WIDTH(gImg&) * wpScale(curW) : gh = _HEIGHT(gImg&) * wpScale(curW)
    gx = GUN_X - gw \ 2 + COS(bob / 2) * 10
    gy = GUN_Y - gh + ABS(SIN(bob / 2)) * 10 + gunKick * 36 + 12
    IF swapT > 0 THEN gy = gy + (SWAP_FRAMES / 2 - ABS(swapT - SWAP_FRAMES / 2)) * 40
    IF dead THEN gy = gy + (TIMER - deadAt!) * 400 ' Drops out of view
    IF gy < 600 THEN _PUTIMAGE (gx + gw - 1, gy)-(gx, gy + gh - 1), gImg& ' (mirrored)
    IF muzzle > 0 THEN ' Muzzle flash, and a flicker of light on everything
        muzzle = muzzle - 1
        LINE (0, 0)-(799, 599), _RGBA32(120, 255, 255, 18), BF
        fx = gx + gw * wpMuzX(curW) : fy = gy + gh * wpMuzY(curW)
        FillCircle fx, fy, 30 + muzzle * 4, _RGBA32(40, 220, 255, 90)
        FillCircle fx, fy, 18 + muzzle * 3, _RGBA32(150, 255, 255, 170)
        FillCircle fx, fy, 8, _RGBA32(255, 255, 255, 230)
    END IF

    IF NOT dead THEN LINE (395, 300)-(405, 300), _RGB32(255, 0, 0) : LINE (400, 295)-(400, 305), _RGB32(255, 0, 0)
    IF hurtFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 0, 0, hurtFlash * 9), BF
    IF pickFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 255, 160, pickFlash * 4), BF

    ' Minimap: walls (each kind its colour); doors orange (key doors in their
    ' card's colour, dark centre) when shut, white while opening, green when
    ' open; keycards; you
    LINE (MMX - 2, MMY - 2)-(MMX + MAP_SIZE * MM + 1, MMY + MAP_SIZE * MM + 1), _RGBA32(0, 0, 0, 160), BF
    FOR mY = 0 TO MAP_SIZE - 1 : FOR mX = 0 TO MAP_SIZE - 1
        mmC~& = 0
        SELECT CASE worldMap(mX, mY)
            CASE 1 : mmC~& = _RGB32(90, 90, 105)
            CASE 3 : mmC~& = _RGB32(160, 60, 180)
            CASE 4 : mmC~& = _RGB32(120, 115, 105)
            CASE 5 : mmC~& = _RGB32(50, 110, 120)
            CASE 6 : mmC~& = _RGB32(130, 85, 50)
            CASE 7 : mmC~& = _RGB32(60, 150, 80)
            CASE 2
                IF doorOffsets(mX, mY) = 0 THEN
                    IF doorKey(mX, mY) THEN mmC~& = CardRGB~&(doorKey(mX, mY)) ELSE mmC~& = _RGB32(255, 140, 20)
                ELSEIF doorOffsets(mX, mY) < 1 THEN
                    mmC~& = _RGB32(230, 230, 230)
                ELSE
                    mmC~& = _RGB32(40, 200, 80)
                END IF
        END SELECT
        IF mmC~& THEN
            LINE (MMX + mX * MM, MMY + mY * MM)-STEP(MM - 1, MM - 1), mmC~&, BF
            IF doorKey(mX, mY) AND doorOffsets(mX, mY) = 0 THEN PSET (MMX + mX * MM + MM \ 2, MMY + mY * MM + MM \ 2), _RGB32(0, 0, 0)
        END IF
    NEXT : NEXT
    IF (TIMER * 4 AND 1) = 0 THEN ' Keycards blink
        FOR i = 1 TO nItems
            IF itOn(i) AND itK(i) <= 3 THEN LINE (MMX + itX(i) * MM - 1, MMY + itY(i) * MM - 1)-STEP(2, 2), CardRGB~&(itK(i)), BF
        NEXT
    END IF
    mpX = MMX + pX * MM : mpY = MMY + pY * MM
    LINE (mpX, mpY)-(mpX + pDirX * 6, mpY + pDirY * 6), _RGB32(255, 255, 0)
    LINE (mpX - 1, mpY - 1)-STEP(2, 2), _RGB32(255, 255, 0), BF
    HudText MMX, MMY + MAP_SIZE * MM + 6, "KILLS" + STR$(kills) + " /" + STR$(nMon), _RGB32(255, 90, 90)

    ' Keycards you hold, top right
    hx = 800 - 16
    FOR k = 3 TO 1 STEP -1
        IF hasCard(k) THEN hx = hx - 68 : _PUTIMAGE (hx, 8)-STEP(63, 63), cardImg&(k)
    NEXT

    ' Health (bottom left)
    IF hp > 60 THEN hc~& = _RGB32(60, 230, 90) ELSE IF hp > 25 THEN hc~& = _RGB32(255, 200, 40) ELSE hc~& = _RGB32(255, 50, 50)
    HudText 16, 552, "HEALTH" + STR$(hp), hc~&
    LINE (16, 570)-STEP(201, 13), _RGBA32(0, 0, 0, 170), BF
    IF hp > 0 THEN LINE (17, 571)-STEP(hp * 2 - 1, 11), hc~&, BF

    ' Gun and its ammo (bottom right), and which guns you have
    am = wpAmmo(curW)
    IF ammoN(am) = 0 THEN
        ac~& = _RGB32(255, 50, 50)
    ELSEIF am = AM_SHELLS THEN
        ac~& = _RGB32(255, 150, 40)
    ELSE
        ac~& = _RGB32(60, 220, 255)
    END IF
    a$ = wpName$(curW) + "  " + LTRIM$(STR$(ammoN(am)))
    HudText 800 - 16 - 8 * LEN(a$), 552, a$, ac~&
    LINE (800 - 16 - 202, 570)-STEP(201, 13), _RGBA32(0, 0, 0, 170), BF
    IF ammoN(am) > 0 THEN LINE (800 - 16 - 1 - ammoN(am) * 200 \ ammoMax(am), 571)-(800 - 16 - 1, 582), ac~&, BF
    FOR w = 1 TO 3
        wc~& = _RGB32(60, 60, 70)
        IF hasWpn(w) THEN wc~& = _RGB32(150, 150, 160)
        IF w = curW THEN wc~& = _RGB32(255, 255, 255)
        HudText 800 - 16 - 202 + (w - 1) * 20, 534, LTRIM$(STR$(w)), wc~&
    NEXT

    ' Message line
    IF TIMER < msgUntil! AND LEN(msg$) THEN
        HudText 400 - LEN(msg$) * 4, 510, msg$, _RGB32(255, 255, 255)
    END IF

    IF dead THEN
        LINE (0, 0)-(799, 599), _RGBA32(90, 0, 0, 110), BF
        BigText "YOU DIED", 230, 6, _RGB32(255, 60, 60)
        IF TIMER - deadAt! > 1.2 THEN HudText 400 - 15 * 8, 330, "Click or press Space to try again", _RGB32(255, 255, 255)
    END IF

    _DISPLAY
LOOP UNTIL _KEYDOWN(27)
SYSTEM

' --- A shot hits monster hitMon
HitMonster:
mnHP(hitMon) = mnHP(hitMon) - 1 : mnHurt(hitMon) = 8
IF mnState(hitMon) = 0 THEN mnState(hitMon) = 1 : mnT(hitMon) = 30 ' Shot awake
IF mnHP(hitMon) <= 0 THEN
    mnState(hitMon) = 2 : mnT(hitMon) = MON_DYING : kills = kills + 1
    SfxAt mtDie&(mnType(hitMon)), mnX(hitMon), mnY(hitMon), pX, pY
    IF kills = nMon THEN ShowMsg "SECTOR CLEAR - every monster destroyed!"
ELSE
    SfxAt mtHitS&(mnType(hitMon)), mnX(hitMon), mnY(hitMon), pX, pY
END IF
RETURN

' --- You take dmg damage
HurtPlayer:
hp = hp - dmg : hurtFlash = 14
IF hp <= 0 THEN
    hp = 0 : dead = -1 : deadAt! = TIMER
    PlaySfx sndDie&, 1 : ShowMsg ""
ELSE
    PlaySfx sndHurt&, 0.8
END IF
RETURN

' --- Start (or restart) the level: read the map, reset you and everything in it
LoadLevel:
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
    worldMap(x, y) = 0 : doorOffsets(x, y) = 0 : doorKey(x, y) = 0 : doorType(x, y) = 0
    floorT(x, y) = T_FLOOR : ceilT(x, y) = T_CEIL
NEXT : NEXT
nItems = 0 : nMon = 0
FOR k = 1 TO 3 : hasCard(k) = 0 : NEXT
FOR i = 1 TO MAX_BOLTS : bOn(i) = 0 : NEXT
RESTORE MapData
READ nZones ' Floor / ceiling zones: x0, y0, x1, y1, floor, ceiling
FOR k = 1 TO nZones
    READ zx0, zy0, zx1, zy1, zf, zc
    FOR y = zy0 TO zy1 : FOR x = zx0 TO zx1
        floorT(x, y) = floorSlot(zf) : ceilT(x, y) = ceilSlot(zc)
    NEXT : NEXT
NEXT
FOR y = 0 TO MAP_SIZE - 1
    READ row$
    FOR x = 0 TO MAP_SIZE - 1
        cell$ = MID$(row$, x + 1, 1)
        SELECT CASE cell$
            CASE "#" : worldMap(x, y) = 1
            CASE "N" : worldMap(x, y) = 3
            CASE "C" : worldMap(x, y) = 4
            CASE "K" : worldMap(x, y) = 5
            CASE "P" : worldMap(x, y) = 6
            CASE "G" : worldMap(x, y) = 7
            CASE "D" : worldMap(x, y) = 2
            CASE "H" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_SHUTTER
            CASE "X" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_SPLIT
            CASE "R", "B", "Y" ' Key door: needs that keycard
                worldMap(x, y) = 2 : doorKey(x, y) = INSTR("RBY", cell$)
            CASE "r", "b", "y", "+", "a", "e", "2", "3" ' Something to pick up
                IF nItems < MAX_ITEMS THEN
                    nItems = nItems + 1
                    itX(nItems) = x + 0.5 : itY(nItems) = y + 0.5 : itOn(nItems) = -1
                    itK(nItems) = INSTR("rby+ae23", cell$)
                END IF
            CASE "m", "g", "h" ' A monster
                IF nMon < MAX_MON THEN
                    nMon = nMon + 1
                    mnX(nMon) = x + 0.5 : mnY(nMon) = y + 0.5 : mnType(nMon) = INSTR("mgh", cell$)
                    mnHP(nMon) = mtHP(mnType(nMon)) : mnState(nMon) = 0 : mnT(nMon) = 0 : mnHurt(nMon) = 0
                END IF
            CASE "<", ">", "^", "v" ' Player start, facing the arrow's way
                pX = x + 0.5 : pY = y + 0.5
                pDirX = (cell$ = "<") - (cell$ = ">") : pDirY = (cell$ = "^") - (cell$ = "v")
        END SELECT
    NEXT
NEXT
' Camera plane is the view direction turned 90 degrees
planeX = pDirY * 0.66 : planeY = -pDirX * 0.66
hp = MAX_HP : kills = 0 : dead = 0
ammoN(AM_CELLS) = 30 : ammoN(AM_SHELLS) = 0
hasWpn(1) = -1 : hasWpn(2) = 0 : hasWpn(3) = 0 : curW = 1 : swapT = 0
hurtFlash = 0 : pickFlash = 0 : muzzle = 0 : gunKick = 0 : fireWait = 0
bob = 0 : stepDist = STEP_LEN * 0.85 ' First step sounds soon after you start walking
ShowMsg "Find the keycards. Destroy the monsters."
RETURN

MapData:
' Floor / ceiling zones first: how many, then x0, y0, x1, y1, floor, ceiling
' (floors 1 grate, 2 plates, 3 concrete, 4 lab; ceilings 1 purple, 2 light panels)
DATA 4
DATA 19, 19, 28, 28, 2, 1
DATA 5, 5, 21, 21, 3, 2
DATA 26, 5, 42, 21, 2, 2
DATA 30, 26, 42, 42, 4, 2
' Then one string per row, MAP_SIZE characters each:
'   walls: # metal  N neon  C concrete  K servers  P pipes  G biolab
'   doors: D sliding  H shutter (rises)  X split   R B Y need the red / blue / yellow keycard
'   r b y keycard   + health   a energy cells   e shells   2 scatter gun   3 repeater
'   m drone   g gunner   h heavy   . floor   < > ^ v start, facing that way
DATA "################################################"
DATA "################################################"
DATA "##...........................................+##"
DATA "##............................................##"
DATA "##..CCCCHCCCCCCCCCCCCCC..KKKKKKKKKYKKKKKKKKK..##"
DATA "##..C.....e.C.......a.C..K.................K..##"
DATA "##..C.......C.........C..Y..KKK......KKK...K..##"
DATA "##..C...m...H.........C..K......g.......m..K..##"
DATA "##..C.......C.....g...H..Ka................K..##"
DATA "##..C.+.....C...2.....C..KKKDKKKKKKDKKKKKDKK..##"
DATA "##..C.......C.........C..K......K......K...K..##"
DATA "##..CCCCHCCCCCCCCCCCCCC..K......K...g..K.+.K..##"
DATA "##..C...........aCCCCCC..K.K..K.K..K...Ke..K..##"
DATA "##..C.m..........CCCCCC..K.K..K.D..K...K...Y..##"
DATA "##..C............CCCCCC..K..m...K..K...K...K..##"
DATA "##..C...C....C...CCCCCC..K......K......K.m.K..##"
DATA "##..H.....y......CCCCCC..K......K......K...K..##"
DATA "##..C............CCCCCC..KKKKKKKKKKDKKKKKKKK..##"
DATA "##..C...C....C...CNNNNNXNNNNNNK............K..##"
DATA "##..C..e.........CNa.........NK.........b..K..##"
DATA "##..C..........h.CN..........NK..h...3.....K..##"
DATA "##..C............CN..N....N..NK............K..##"
DATA "##..CCCCCCHCCCCCCCN..........NKKKKKKKKYKKKKK..##"
DATA "##................X..........X................##"
DATA "##................N.>........N..............e.##"
DATA "##..PPPPPPRPPPPPPPN..........NGGGGGGBGGGGGGG..##"
DATA "##..P...........aPN..N....N..Na............G..##"
DATA "##..P............PN........+.N....e........G..##"
DATA "##..P..m.........PN..........N.g...........G..##"
DATA "##..P....P..P....PNNNNNXNNNNNN...G.....G...G..##"
DATA "##..R............PP.........aG...........g.G..##"
DATA "##..P.........g..PP..........G.............G..##"
DATA "##..P............PP..........G.............G..##"
DATA "##..P............PP..........G.............G..##"
DATA "##..PPPPHPPPPPPPPPP..........G...G..r..G...B..##"
DATA "##..P............PP..........G.............G..##"
DATA "##..P.+..........PP..........B.............G..##"
DATA "##..P............PP...m......G.............G..##"
DATA "##..P....P..P....PP..........G.............G..##"
DATA "##..P............PP..........G...G.....G...G..##"
DATA "##..P.h..........PP........g.G......h......G..##"
DATA "##..P...e......m.PP..........G.m...........G..##"
DATA "##..P............PP+.........G............+G..##"
DATA "##..PPPPPPPPRPPPPPPPPPPPPHPPPGGGGGGGBGGGGGGG..##"
DATA "##............................................##"
DATA "##a..........................................a##"
DATA "################################################"
DATA "################################################"

SUB LoadTex(f$, slot AS INTEGER)
    p$   = AssetPath$(f$)
    img& = _LOADIMAGE(p$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; p$ : SLEEP : SYSTEM
    t& = _NEWIMAGE(TEX, TEX, 32)                     : _PUTIMAGE, img&, t&
    _SOURCE t&
    FOR y = 0 TO TEX - 1 : FOR x = 0 TO TEX-1 : TEX(x, y, slot) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0            : _FREEIMAGE img&    : _FREEIMAGE t&
END SUB

' Scale a 32-bit colour's RGB by s/256 (s = 0..256)
FUNCTION Shade~&(c AS _UNSIGNED LONG, S AS LONG)
    DIM rb AS _INTEGER64, g AS _INTEGER64
    rb      = c AND &HFF00FF : g = c AND &HFF00&
    Shade~& = &HFF000000~& OR ((rb * S \ 256) AND &HFF00FF) OR ((g * S \ 256) AND &HFF00&)
END FUNCTION

' True if map point (x, y) is open floor or a mostly-open door
FUNCTION Walkable%(x, y)
    cX        = INT(x) : cY = INT(y)
    Walkable% = worldMap(cX, cY) <= 0 OR doorOffsets(cX, cY) > 0.8
END FUNCTION

' neon-caster/<f$>, or the same next to the EXE
FUNCTION AssetPath$(f$)
    p$ = "neon-caster/" + f$
    IF NOT _FILEEXISTS(p$) THEN ' Fall back TO the folder NEXT TO the EXE
        e$ = COMMAND$(0) : i = _INSTRREV(e$, "/") : IF i = 0 THEN i = _INSTRREV(e$, "\")
        p$ = LEFT$(e$, i) + "neon-caster/" + f$
    END IF
    AssetPath$ = p$
END FUNCTION

' A sound effect from neon-caster/sfx/ (0 if it's missing: the game runs silent)
FUNCTION LoadSnd&(f$)
    p$ = AssetPath$("sfx/" + f$)
    IF _FILEEXISTS(p$) THEN LoadSnd& = _SNDOPEN(p$)
END FUNCTION

' Play a copy, so the same sound can overlap itself
SUB PlaySfx(h&, vol!)
    IF h& > 0 THEN _SNDPLAYCOPY h&, vol!
END SUB

' How much the 800x600 screen is stretched on the display. QB64-PE multiplies
' captured-mouse movement by this, so mouse look divides it back out.
FUNCTION DisplayScale!
    DisplayScale! = 1
    IF _FULLSCREEN = 0 THEN EXIT FUNCTION
    sx! = _DESKTOPWIDTH / _WIDTH(0) : sy! = _DESKTOPHEIGHT / _HEIGHT(0)
    IF _FULLSCREEN = 2 AND sy! < sx! THEN sx! = sy! ' _SQUAREPIXELS : letterboxed
    DisplayScale! = sx!
END FUNCTION

' Message line at the bottom of the screen, for a few seconds
SUB ShowMsg(m$)
    SHARED msg$, msgUntil!
    msg$ = m$ : msgUntil! = TIMER + 2.5
END SUB

FUNCTION CardName$(k)
    CardName$ = RTRIM$(MID$("red   blue  yellow", (k - 1) * 6 + 1, 6))
END FUNCTION

FUNCTION CardRGB~&(k)
    SELECT CASE k
        CASE 1 : CardRGB~& = _RGB32(235, 45, 45)
        CASE 2 : CardRGB~& = _RGB32(50, 120, 255)
        CASE 3 : CardRGB~& = _RGB32(255, 215, 30)
    END SELECT
END FUNCTION

' Colour c toward tint t by amount a (0-1), keeping its light and dark
FUNCTION Tint~&(c AS _UNSIGNED LONG, t AS _UNSIGNED LONG, a!)
    lum! = (_RED32(c) + _GREEN32(c) + _BLUE32(c)) / 3 / 255 * 1.6
    r!   = _RED32(c) * (1 - a!) + _RED32(t) * lum! * a!
    g!   = _GREEN32(c) * (1 - a!) + _GREEN32(t) * lum! * a!
    b!   = _BLUE32(c) * (1 - a!) + _BLUE32(t) * lum! * a!
    IF r! > 255 THEN r! = 255
    IF g! > 255 THEN g! = 255
    IF b! > 255 THEN b! = 255
    Tint~& = _RGBA32(r!, g!, b!, _ALPHA32(c))
END FUNCTION

' A sprite from neon-caster/ into sprTex slot (its size up to SPR_TEX)
SUB LoadSprite(f$, slot)
    p$   = AssetPath$(f$)
    img& = _LOADIMAGE(p$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; p$ : SLEEP : SYSTEM
    sz          = _WIDTH(img&)                       : IF sz > SPR_TEX THEN sz = SPR_TEX
    sprSz(slot) = sz
    _SOURCE img&
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz-1
        sprTex(x, y, slot) = POINT(x * _WIDTH(img&) \ sz, y * _HEIGHT(img&) \ sz)
    NEXT      : NEXT
    _SOURCE 0 : _FREEIMAGE img&
END SUB

' The keycard sprite, tinted red / blue / yellow (sprite slots 1-3 and HUD
' images), and the key door textures (the door tinted the same way)
SUB LoadCards(f$)
    LoadSprite f$, 1
    sz = sprSz(1)
    FOR k = 1 TO 3
        sprSz(k)    = sz
        cardImg&(k) = _NEWIMAGE(sz, sz, 32)
        _DONTBLEND cardImg&(k)
        _DEST cardImg&(k)
        FOR y = 0 TO sz - 1 : FOR x = 0 TO sz-1
            IF k = 1 THEN c~& = sprTex(x, y, 1) ELSE c~& = sprTex(x, y, 0)
            IF k = 1 THEN sprTex(x, y, 0) = c~& '(the untinted card, kept in slot 0)
            sprTex(x, y, k) = Tint~&(c~&, CardRGB~&(k), 1)
            PSET (x, y), sprTex(x, y, k)
        NEXT : NEXT
        _BLEND cardImg&(k)
        FOR y = 0 TO TEX - 1 : FOR x = 0 TO TEX-1
            TEX(x, y, T_DOORK + k) = Tint~&(TEX(x, y, T_DOOR), CardRGB~&(k), 0.85)
        NEXT : NEXT
    NEXT
    _DEST 0
END SUB

' Can a monster at (x1, y1) see (x2, y2)? Walls and shut doors block the view.
FUNCTION CanSee(x1, y1, x2, y2)
    dx = x2 - x1 : dy = y2 - y1 : D = SQR(dx * dx + dy * dy)
    n  = INT(D / 0.1) + 1
    FOR i = 1 TO n
        cX = INT(x1 + dx * i / n) : cY = INT(y1 + dy * i / n)
        IF IsWall(cX, cY) THEN EXIT FUNCTION
        IF worldMap(cX, cY) = 2 AND doorOffsets(cX, cY) <= 0.8 THEN EXIT FUNCTION
    NEXT
    CanSee = -1
END FUNCTION

' A sound from (x, y), quieter the further it is from you at (lx, ly)
SUB SfxAt(h&, x, y, lx, ly)
    v! = 1 - SQR((x - lx) ^ 2 + (y-ly) ^ 2) / 18
    IF v! < 0.12 THEN v! = 0.12
    PlaySfx h&, v!
END SUB

SUB FillCircle(cX, cy, r, c~&)
    FOR dy = - r TO r
        W = SQR(r * r - dy * dy)
        LINE (cX - w, cY + dy)-(cX + w, cY + dy), c~&
    NEXT
END SUB

' HUD text with a drop shadow
SUB HudText(x, y, t$, c~&)
    COLOR _RGB32(0, 0, 0) : _PRINTSTRING (x + 1, y + 1), t$
    COLOR c~&             : _PRINTSTRING (x, y), t$
END SUB

' Big centred text: printed small, then scaled up
SUB BigText(t$, y, scale, c~&)
    W  = LEN(t$) * 8
    t& = _NEWIMAGE(w, 16, 32)
    _DEST t&              : _PRINTMODE _KEEPBACKGROUND
    COLOR _RGB32(0, 0, 0) : _PRINTSTRING (1, 1), t$
    COLOR c~&             : _PRINTSTRING (0, 0), t$
    _DEST 0
    _PUTIMAGE (400 - W * scale \ 2, y)-STEP(W * scale - 1, 16 * scale-1), t&
    _FREEIMAGE t&
END SUB

' Any kind of wall (not a door, not floor)?
FUNCTION IsWall (x, y)
    v = worldMap(x, y)
    IsWall = v > 0 AND v <> 2
END FUNCTION

' A monster type's numbers (see the table in the main program)
SUB SetMonType (t, n$, hp, speed, scale, lift, bob, reach, dmg, dmgRnd, cool, slot)
    mtName$(t) = n$ : mtHP(t) = hp : mtSpeed(t) = speed : mtScale(t) = scale
    mtLift(t) = lift : mtBob(t) = bob : mtReach(t) = reach
    mtDmg(t) = dmg : mtDmgRnd(t) = dmgRnd : mtCool(t) = cool : mtSlot(t) = slot
END SUB

' A gunner's energy bolt, from (x, y) heading (dx, dy)
SUB FireBolt (x, y, dx, dy, dmg)
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) = 0 THEN
            bOn(i) = -1 : bX(i) = x + dx * 0.4 : bY(i) = y + dy * 0.4
            bDX(i) = dx : bDY(i) = dy : bDmg(i) = dmg
            EXIT SUB
        END IF
    NEXT
END SUB

' The bolt sprite: a hard-edged glowing magenta ball, white hot in the middle
SUB MakeBolt (slot)
    sprSz(slot) = 16
    FOR y = 0 TO 15 : FOR x = 0 TO 15
        d = SQR((x - 7.5) ^ 2 + (y - 7.5) ^ 2) / 7.5
        IF d < 0.45 THEN
            sprTex(x, y, slot) = _RGB32(255, 240, 255)
        ELSEIF d < 0.75 THEN
            sprTex(x, y, slot) = _RGB32(255, 110, 235)
        ELSEIF d < 1 THEN
            sprTex(x, y, slot) = _RGB32(200, 30, 200)
        ELSE
            sprTex(x, y, slot) = 0
        END IF
    NEXT : NEXT
END SUB

' Gun w's first-person picture, and where its muzzle is: the right-most
' solid pixel in its top part (the picture is drawn mirrored, so that's
' measured from the right)
SUB LoadGun (w, f$)
    p$ = AssetPath$(f$)
    wpImg&(w) = _LOADIMAGE(p$, 32)
    IF wpImg&(w) >= -1 THEN PRINT "Missing texture: "; p$: SLEEP: SYSTEM
    _SOURCE wpImg&(w)
    gw = _WIDTH(wpImg&(w)) : gh = _HEIGHT(wpImg&(w))
    bestX = -1
    FOR y = 0 TO gh * 0.45
        FOR x = gw - 1 TO 0 STEP -1
            IF _ALPHA32(POINT(x, y)) > 128 THEN
                IF x > bestX THEN
                    bestX = x : sumY = y : nY = 1
                ELSEIF x = bestX THEN
                    sumY = sumY + y : nY = nY + 1
                END IF
                EXIT FOR
            END IF
        NEXT
    NEXT
    _SOURCE 0
    IF bestX < 0 THEN bestX = gw / 2 : sumY = 0 : nY = 1
    wpMuzX(w) = 1 - (bestX + 0.5) / gw : wpMuzY(w) = (sumY / nY + 0.5) / gh
END SUB

' Add n of ammo kind k, up to the most you can carry. FALSE if already full.
FUNCTION GiveAmmo% (k, n)
    IF ammoN(k) >= ammoMax(k) THEN EXIT FUNCTION
    ammoN(k) = ammoN(k) + n
    IF ammoN(k) > ammoMax(k) THEN ammoN(k) = ammoMax(k)
    GiveAmmo% = -1
END FUNCTION
