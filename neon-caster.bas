_TITLE "NEON-CASTER"
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE _DISABLE ' Capture the pointer in the WINDOW(raw relative motion)
_PRINTMODE _KEEPBACKGROUND

CONST MAP_SIZE = 48 ' Map IS MAP_SIZE x MAP_SIZE cells(see MapData)
CONST MM = 3, MMX = 8, MMY = 8 ' Minimap : cell size AND top - left corner
CONST PLAYER_R = 0.3 ' Player body radius(keeps the camera OFF the walls)
' worldMap: 0 floor, 2 door; walls 1 (#), 3 (N), 4 (C), 5 (K), 6 (P), 7 (G):
' six kinds of wall, whose textures each level picks (see MapData)
DIM SHARED worldMap(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorOffsets(MAP_SIZE, MAP_SIZE) AS SINGLE
DIM SHARED doorKey(MAP_SIZE, MAP_SIZE) AS INTEGER ' 0 = ANY door, ELSE the keycard it needs
DIM SHARED doorType(MAP_SIZE, MAP_SIZE) AS INTEGER ' 0 sliding, 1 shutter(rises), 2 split
' Diagonal walls: the cell is cut corner to corner, and this says which corner's
' half is solid (0 not diagonal, 1 top-left, 2 top-right, 3 bottom-right,
' 4 bottom-left). Its worldMap value is the wall it looks like.
DIM SHARED diagK(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED floorT(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilT(MAP_SIZE, MAP_SIZE) AS INTEGER ' Texture slots
' Floor / ceiling diagonals: a cell's floor (or ceiling) can be split corner
' to corner like a diagonal wall. fK (cK) is the corner whose half uses
' floorT2 (ceilT2) instead; 0 = the whole cell is floorT (ceilT).
DIM SHARED floorT2(MAP_SIZE, MAP_SIZE) AS INTEGER, ceilT2(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED fK(MAP_SIZE, MAP_SIZE) AS INTEGER, cK(MAP_SIZE, MAP_SIZE) AS INTEGER
CONST DOOR_SLIDE = 0, DOOR_SHUTTER = 1, DOOR_SPLIT = 2, DOOR_EXIT = 3
CONST NUM_LEVELS = 4

' --- Pickups lying on the map ---
CONST IT_HEALTH = 4, IT_CELLS = 5, IT_SHELLS = 6, IT_SCATTER = 7, IT_REPEATER = 8 '(1 - 3 keycards)
CONST IT_ARMOR = 9, IT_BIGMED = 10, IT_RAIL = 11
CONST MAX_ITEMS = 64
DIM SHARED itX(MAX_ITEMS) AS SINGLE, itY(MAX_ITEMS) AS SINGLE
DIM SHARED itK(MAX_ITEMS) AS INTEGER, itOn(MAX_ITEMS) AS INTEGER, nItems AS INTEGER
DIM SHARED hasCard(3) AS INTEGER

' --- Decorations: 1 barrel (explodes when shot), 2 lamp, 3 plant, 4 terminal.
' You, monsters and bolts can't pass through them; shots fly past (except
' into barrels). ---
CONST MAX_DECO = 64, DECO_R = 0.3
DIM SHARED dcX(MAX_DECO) AS SINGLE, dcY(MAX_DECO) AS SINGLE, dcK(MAX_DECO) AS INTEGER
DIM SHARED dcOn(MAX_DECO) AS INTEGER, dcFuse(MAX_DECO) AS INTEGER, nDeco AS INTEGER
DIM SHARED decoCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' Which decoration stands in a cell
CONST BOOM_R = 2.2 ' A barrel's blast reaches this far
CONST MAX_BOOM = 8, BOOM_FRAMES = 18 ' Explosions on show at once, AND how long each lasts
DIM SHARED bmX(MAX_BOOM) AS SINGLE, bmY(MAX_BOOM) AS SINGLE, bmT(MAX_BOOM) AS INTEGER

' --- Monsters: 1 drone (bites), 2 gunner (shoots bolts), 3 heavy (smashes),
' 4 crawler (fast, bites), 5 sentry (a turret: stays put, shoots bolts) ---
CONST MAX_MON = 64, MON_TYPES = 5
CONST MON_SIGHT = 14 ' How far away they notice you
CONST MON_DYING = 24 ' Frames TO collapse when killed
DIM SHARED mnX(MAX_MON) AS SINGLE, mnY(MAX_MON) AS SINGLE, mnType(MAX_MON) AS INTEGER
DIM SHARED mnHP(MAX_MON) AS INTEGER, mnState(MAX_MON) AS INTEGER ' 0 idle, 1 hunting, 2 dying, 3 dead
DIM SHARED mnT(MAX_MON) AS INTEGER, mnHurt(MAX_MON) AS INTEGER ' Attack cooldown / dying frames, hit flash
DIM SHARED nMon AS INTEGER
' Per type: hit points, speed (tiles a frame; you walk 0.12), height (of a
' wall), hover height and bob, attack reach, damage (min + random), frames
' between attacks, sprite slots, whether it shoots bolts, and sounds
DIM SHARED mtHP(MON_TYPES), mtSpeed(MON_TYPES), mtScale(MON_TYPES), mtLift(MON_TYPES), mtBob(MON_TYPES)
DIM SHARED mtReach(MON_TYPES), mtDmg(MON_TYPES), mtDmgRnd(MON_TYPES), mtCool(MON_TYPES)
DIM SHARED mtSlot(MON_TYPES), mtName$(MON_TYPES), mtRanged(MON_TYPES)
DIM SHARED mtAlert&(MON_TYPES), mtAtk&(MON_TYPES), mtHitS&(MON_TYPES), mtDie&(MON_TYPES)
CONST GUNNER_NEAR = 3.5, GUNNER_FAR = 7 ' Gunners like TO keep this far from you

' --- Energy bolts (gunner shots) ---
CONST MAX_BOLTS = 32, BOLT_SPEED = 0.14
DIM SHARED bX(MAX_BOLTS) AS SINGLE, bY(MAX_BOLTS) AS SINGLE, bDX(MAX_BOLTS) AS SINGLE, bDY(MAX_BOLTS) AS SINGLE
DIM SHARED bOn(MAX_BOLTS) AS INTEGER, bDmg(MAX_BOLTS) AS INTEGER

' --- You: health, armour, two kinds of ammo, four guns ---
CONST MAX_HP = 100, MAX_ARMOR = 100
CONST AM_CELLS = 1, AM_SHELLS = 2
DIM SHARED ammoN(2) AS INTEGER, ammoMax(2) AS INTEGER
ammoMax(AM_CELLS) = 99 : ammoMax(AM_SHELLS) = 40
CONST W_BLASTER = 1, W_SCATTER = 2, W_REPEATER = 3, W_RAIL = 4, NUM_W = 4
DIM SHARED hasWpn(NUM_W) AS INTEGER
' Per gun: name, ammo kind, ammo per shot, frames between shots, pellets,
' spread (of the view's width), damage per hit, whether a shot goes through
' every monster in its line, recoil, sound, picture, and where its muzzle is
DIM SHARED wpName$(NUM_W), wpAmmo(NUM_W), wpCost(NUM_W), wpDelay(NUM_W), wpPellets(NUM_W), wpSpread(NUM_W)
DIM SHARED wpDmg(NUM_W), wpPierce(NUM_W), wpKick(NUM_W)
DIM SHARED wpSnd&(NUM_W), wpImg&(NUM_W), wpMuzX(NUM_W), wpMuzY(NUM_W), wpScale(NUM_W)
'           name        ammo       cost delay pellets spread damage pierce recoil
SetGun 1, "BLASTER", AM_CELLS, 1, 16, 1, 0, 1, 0, 1
SetGun 2, "SCATTER", AM_SHELLS, 1, 40, 7, 0.12, 1, 0, 1.7
SetGun 3, "REPEATER", AM_CELLS, 1, 5, 1, 0.025, 1, 0, 0.45
SetGun 4, "RAILGUN", AM_CELLS, 5, 55, 1, 0, 5, -1, 2.2
CONST SWAP_FRAMES = 14 ' Lowering one gun AND raising the NEXT
CONST TEST_ALL_GUNS = -1 ' -1: start with every gun AND full ammo (FOR testing), 0: normal
CONST CHEAT_KEYS = -1 ' -1: K gives you every keycard, G toggles god mode (FOR testing), 0: off

' --- Sprites (billboards): textures, and the list drawn each frame ---
CONST SPR_TEX = 64, SPR_SLOTS = 27
' 1-3 keycards, 4 medkit, 5 cells, 6 shells, 7 scatter gun, 8 repeater,
' 9/10 drone (/hit), 11/12 gunner, 13/14 heavy, 15/16 crawler, 17/18 sentry,
' 19 bolt, 20-23 decorations (barrel, lamp, plant, terminal), 24 explosion,
' 25 armour, 26 big medkit, 27 railgun
CONST S_BOLT = 19, S_DECO = 19, S_BOOM = 24
CONST CARD_SCALE = 0.3, ITEM_SCALE = 0.3, GUN_ITEM_SCALE = 0.45
DIM SHARED sprTex(SPR_TEX - 1, SPR_TEX-1, SPR_SLOTS) AS _UNSIGNED LONG, sprSz(SPR_SLOTS) AS INTEGER
DIM SHARED cardImg&(3)
CONST MAX_DRAW = MAX_ITEMS + MAX_MON + MAX_BOLTS + MAX_DECO + MAX_BOOM
DIM dlX(MAX_DRAW) AS SINGLE, dlY(MAX_DRAW) AS SINGLE, dlD(MAX_DRAW) AS SINGLE
DIM dlSlot(MAX_DRAW) AS INTEGER, dlScale(MAX_DRAW) AS SINGLE, dlLift(MAX_DRAW) AS SINGLE
DIM dlSquash(MAX_DRAW) AS SINGLE, dlMinS(MAX_DRAW) AS INTEGER, ord(MAX_DRAW) AS INTEGER

' --- Render buffer (half-res, scaled 2x to the screen) ---
CONST RW = 400, RH = 300, TEX = 64
' Texture slots: 1-6 the level's six walls (# N C K P G), 7 sliding door,
' 8-10 key doors, 11 shutter, 12 split door, 13 exit, 14-17 the level's four
' floors, 18-19 its two ceilings
CONST T_DOOR = 7, T_DOORK = 7 ' KEY doors : slot T_DOORK + card(8 red, 9 blue, 10 yellow)
CONST T_SHUTTER = 11, T_SPLIT = 12, T_EXIT = 13
CONST T_FLOOR = 13, T_CEIL = 17 ' Floor n is slot T_FLOOR + n, ceiling n T_CEIL + n
CONST T_SLOTS = 19
DIM SHARED TEX(TEX - 1, TEX-1, T_SLOTS) AS _UNSIGNED LONG
DIM SHARED wallSlot(7) AS INTEGER, wallCol(7) AS _UNSIGNED LONG ' worldMap wall value -> texture slot, minimap colour
wallSlot(1) = 1 : wallSlot(3) = 2 : wallSlot(4) = 3 : wallSlot(5) = 4 : wallSlot(6) = 5 : wallSlot(7) = 6
DIM SHARED scr(0 TO RW * RH - 1) AS _UNSIGNED LONG
DIM SHARED zBuf(RW - 1) AS SINGLE ' wall distance per column(sprites HIDE behind walls)
buf& = _NEWIMAGE(RW, RH, 32)
DIM mBuf AS _MEM, mScr AS _MEM
mBuf = _MEMIMAGE(buf&) : mScr = _MEM(scr())

' --- Load Textures and sprites (each level loads its own walls, floors and
' ceilings) ---
LoadTex "door.png", T_DOOR
LoadTex "door-shutter.png", T_SHUTTER
LoadTex "door-split.png", T_SPLIT
LoadTex "exit.png", T_EXIT : ExitSign
LoadCards "keycard.png"
LoadSprite "medkit.png", 4
LoadSprite "ammo.png", 5
LoadSprite "shells.png", 6
LoadSprite "pickup-scatter.png", 7
LoadSprite "pickup-repeater.png", 8
LoadSprite "drone.png", 9
LoadSprite "gunner.png", 11
LoadSprite "heavy.png", 13
LoadSprite "crawler.png", 15
LoadSprite "sentry.png", 17
FOR t = 9 TO 17 STEP 2 ' hit flash : each monster washed hot RED
    FOR y = 0 TO SPR_TEX - 1 : FOR x = 0 TO SPR_TEX-1
        sprTex(x, y, t + 1) = Tint~&(sprTex(x, y, t), _RGB32(255, 90, 70), 0.7)
    NEXT : NEXT
    sprSz(t + 1) = sprSz(t)
NEXT
MakeBolt S_BOLT
LoadSprite "barrel.png", S_DECO + 1
LoadSprite "lamp.png", S_DECO + 2
LoadSprite "plant.png", S_DECO + 3
LoadSprite "terminal.png", S_DECO + 4
LoadSprite "explosion.png", S_BOOM
LoadSprite "armor.png", 25
LoadSprite "bigmed.png", 26
LoadSprite "pickup-rail.png", 27

' The guns, first person, drawn just as their pictures are (barrel pointing
' into the screen)
wpScale(1) = 3 : wpScale(2) = 3.6 : wpScale(3) = 4 : wpScale(4) = 3.6 ' Drawn this many times their size
CONST GUN_Y = 600 ' Its bottom sits here, its muzzle straight below the crosshair
LoadGun 1, "gun.png"
LoadGun 2, "gun-scatter.png"
LoadGun 3, "gun-repeater.png"
LoadGun 4, "gun-rail.png"

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
wpSnd&(4) = LoadSnd&("rail.wav")
sndBarrel& = LoadSnd&("barrel.wav") : sndArmor& = LoadSnd&("armor.wav") : sndExit& = LoadSnd&("exit.wav")
CONST STEP_LEN = 2.6 ' distance walked per footstep(~2.8 steps a second at full speed)

' Monster types           HP  speed  height lift  bob   reach dmg+rnd cool slot
SetMonType 1, "drone", 3, 0.045, 0.65, 0.2, 0.05, 0.95, 8, 6, 50, 9
SetMonType 2, "gunner", 4, 0.035, 0.8, 0, 0, 0, 9, 6, 90, 11
SetMonType 3, "heavy", 10, 0.028, 0.95, 0, 0, 1.25, 20, 10, 80, 13
SetMonType 4, "crawler", 2, 0.07, 0.4, 0, 0.02, 0.75, 5, 4, 35, 15
SetMonType 5, "sentry", 8, 0, 0.75, 0, 0, 0, 7, 5, 50, 17
mtRanged(2) = -1 : mtRanged(5) = -1
mtAlert&(1) = LoadSnd&("drone-alert.wav") : mtAtk&(1) = LoadSnd&("drone-attack.wav")
mtHitS&(1) = LoadSnd&("drone-hit.wav") : mtDie&(1) = LoadSnd&("drone-die.wav")
mtAlert&(2) = LoadSnd&("gunner-alert.wav") : mtAtk&(2) = LoadSnd&("gunner-shoot.wav")
mtHitS&(2) = LoadSnd&("gunner-hit.wav") : mtDie&(2) = LoadSnd&("gunner-die.wav")
mtAlert&(3) = LoadSnd&("heavy-alert.wav") : mtAtk&(3) = LoadSnd&("heavy-attack.wav")
mtHitS&(3) = LoadSnd&("heavy-hit.wav") : mtDie&(3) = LoadSnd&("heavy-die.wav")
mtAlert&(4) = LoadSnd&("crawler-alert.wav") : mtAtk&(4) = LoadSnd&("crawler-attack.wav")
mtHitS&(4) = LoadSnd&("crawler-hit.wav") : mtDie&(4) = LoadSnd&("crawler-die.wav")
mtAlert&(5) = LoadSnd&("sentry-alert.wav") : mtAtk&(5) = LoadSnd&("sentry-shoot.wav")
mtHitS&(5) = LoadSnd&("sentry-hit.wav") : mtDie&(5) = LoadSnd&("sentry-die.wav")

DIM x AS LONG, y AS LONG, fu AS LONG, fv AS LONG, tX AS LONG
DIM rowF AS LONG, rowC AS LONG, lStart AS LONG, lEnd AS LONG
DIM svWpn(NUM_W) ' What you had on entering the level (you get it back if you die)

MoveSpeed = 0.12 : RotSpeed = 0.003 ' Mouse sensitivity
GOSUB NewGame

DO
    _LIMIT 60

    ' --- 1. Input ---
    ' Pointer is captured, so just sum the raw relative motion from each event
    mDX = 0 : WHEEL = 0
    WHILE _MOUSEINPUT
        mDX = mDX + _MOUSEMOVEMENTX
        WHEEL = WHEEL + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1 '(a quick click between Frames still counts)
    WEND
    fireDown = _MOUSEBUTTON(1) OR clicked OR _KEYDOWN(100305) OR _KEYDOWN(100306) ' click OR Ctrl
    clicked = 0
    spaceDown = _KEYDOWN(32)

    IF dead THEN
        ' Dead: the view stays put; click or Space (after a moment) starts over
        IF TIMER - deadAt! > 1.2 AND ((fireDown AND NOT fireWas) OR (spaceDown AND NOT spaceWas)) THEN GOSUB RestartLevel
        mDX = 0 : WHEEL = 0
    END IF

    mDX = mDX / DisplayScale! ' Same turn speed windowed OR FULLSCREEN
    angle = - mDX * RotSpeed
    oldDirX = pDirX : pDirX = pDirX * COS(angle) - pDirY * SIN(angle) : pDirY = oldDirX * SIN(angle) + pDirY * COS(angle)
    oldPX = planeX : planeX = planeX * COS(angle) - planeY * SIN(angle) : planeY = oldPX * SIN(angle) + planeY * COS(angle)

    ' Guns: 1 / 2 / 3 / 4, or the mouse wheel through the ones you have
    want = 0
    IF _KEYDOWN(49) THEN want = 1
    IF _KEYDOWN(50) THEN want = 2
    IF _KEYDOWN(51) THEN want = 3
    IF _KEYDOWN(52) THEN want = 4
    IF WHEEL <> 0 THEN
        want = curW
        DO
            want = want + SGN(WHEEL) : IF want > NUM_W THEN want = 1
            IF want < 1 THEN want = NUM_W
        LOOP UNTIL hasWpn(want)
    END IF
    IF want > 0 AND want <> curW AND swapT = 0 THEN
        IF hasWpn(want) THEN nextW = want : swapT = SWAP_FRAMES
    END IF
    IF swapT > 0 THEN
        swapT = swapT - 1
        IF swapT = SWAP_FRAMES \ 2 THEN curW = nextW ' Swapped WHILE it's OUT of sight
    END IF

    ' --- 2. WASD + Strafe + Backwards ---
    ' Forward/back and strafe combine into one direction at walking speed, so
    ' diagonals aren't faster (and opposite keys cancel out)
    fwd = 0 : strafe = 0
    IF NOT dead THEN
        IF _KEYDOWN(119) OR _KEYDOWN(87) THEN fwd = fwd + 1 ' W
        IF _KEYDOWN(115) OR _KEYDOWN(83) THEN fwd = fwd - 1 ' S
        IF _KEYDOWN(97) OR _KEYDOWN(65) THEN strafe = strafe - 1 ' a(strafe left)
        IF _KEYDOWN(100) OR _KEYDOWN(68) THEN strafe = strafe + 1 ' D(strafe right)
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
    IF godMode THEN ' No clipping: straight through anything, but stay inside the border
        pX = pX + moveX : pY = pY + moveY
        IF pX < 1.01 THEN pX = 1.01
        IF pX > MAP_SIZE - 1.01 THEN pX = MAP_SIZE - 1.01
        IF pY < 1.01 THEN pY = 1.01
        IF pY > MAP_SIZE - 1.01 THEN pY = MAP_SIZE - 1.01
    ELSE
        MoveBody pX, pY, moveX, moveY
    END IF
    ' ...and you can't walk through a monster
    FOR i = 1 TO nMon
        IF mnState(i) < 2 AND NOT godMode THEN
            near = 0.3 + mtScale(mnType(i)) * 0.35
            dNew = (mnX(i) - pX) ^ 2 + (mnY(i) -pY) ^ 2
            IF dNew < near * near AND dNew <(mnX(i) - prevX) ^ 2 + (mnY(i) -prevY) ^ 2 THEN pX = prevX : pY = prevY
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
        IF itOn(i) AND NOT dead AND (itX(i) - pX) ^ 2 + (itY(i) -pY) ^ 2 < 0.45 * 0.45 THEN
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
                CASE IT_BIGMED
                    IF hp < MAX_HP THEN
                        itOn(i) = 0 : hp = hp + 50 : IF hp > MAX_HP THEN hp = MAX_HP
                        PlaySfx sndHealth&, 0.9 : ShowMsg "Big medkit (+50)" : pickFlash = 14
                    END IF
                CASE IT_ARMOR
                    IF armor < MAX_ARMOR THEN
                        itOn(i) = 0 : armor = armor + 50 : IF armor > MAX_ARMOR THEN armor = MAX_ARMOR
                        PlaySfx sndArmor&, 0.8 : ShowMsg "Armour (+50)" : pickFlash = 10
                    END IF
                CASE IT_CELLS
                    IF GiveAmmo%(AM_CELLS, 15) THEN itOn(i) = 0 : PlaySfx sndAmmo&, 0.8 : ShowMsg "Energy cells (+15)" : pickFlash = 10
                CASE IT_SHELLS
                    IF GiveAmmo%(AM_SHELLS, 8) THEN itOn(i) = 0 : PlaySfx sndShells&, 0.8 : ShowMsg "Shells (+8)" : pickFlash = 10
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL
                    IF itK(i) = IT_RAIL THEN W = W_RAIL ELSE W = itK(i) - IT_SCATTER + W_SCATTER
                    IF W = W_SCATTER THEN got = GiveAmmo%(AM_SHELLS, 8) ELSE got = GiveAmmo%(AM_CELLS, 30)
                    IF NOT hasWpn(W) OR got THEN
                        itOn(i) = 0 : PlaySfx sndWeapon&, 0.9 : pickFlash = 10
                        IF NOT hasWpn(W) THEN
                            hasWpn(W) = -1 : nextW = W : swapT = SWAP_FRAMES
                            ShowMsg "You got the " + wpName$(w) + "!  (" + LTRIM$(STR$(w)) + " or mouse wheel to switch)"
                        ELSE
                            ShowMsg wpName$(W) + " ammo"
                        END IF
                    END IF
            END SELECT
        END IF
    NEXT

    ' K: every keycard (testing)
    kDown = _KEYDOWN(107) OR _KEYDOWN(75)
    IF CHEAT_KEYS AND kDown AND NOT kWas AND NOT dead THEN
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT
        PlaySfx sndCard&, 0.8 : ShowMsg "All keycards"
    END IF
    kWas = kDown
    ' G: god mode on / off - no damage, and you walk through walls (testing)
    gDown = _KEYDOWN(103) OR _KEYDOWN(71)
    IF CHEAT_KEYS AND gDown AND NOT gWas AND NOT dead THEN
        godMode = NOT godMode
        IF godMode THEN ShowMsg "God mode ON - no damage, no clipping" ELSE ShowMsg "God mode OFF"
        PlaySfx sndCard&, 0.8
    END IF
    gWas = gDown

    ' --- 3. Door & World Logic ---
    IF spaceDown AND NOT spaceWas AND NOT dead THEN ' SPACE TO OPEN(once per press)
        ' March along the view ray; open the first closed door within reach, stop at walls
        FOR reach = 0.05 TO 2 STEP 0.05
            cX = INT(pX + pDirX * reach) : cY = INT(pY + pDirY * reach)
            IF worldMap(cX, cY) = 2 AND doorOffsets(cX, cY) = 0 THEN
                dk = doorKey(cX, cY)
                IF doorType(cX, cY) = DOOR_EXIT THEN
                    GOSUB LevelDone
                ELSEIF dk = 0 OR hasCard(dk) THEN
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
            IF SolidAt(pX + pDirX * reach, pY + pDirY * reach) THEN
                IF reach <= 1.2 THEN PlaySfx sndHump&, 0.8 ' Trying TO OPEN a plain wall
                EXIT FOR
            END IF
        NEXT
    END IF
    FOR dy = 0 TO MAP_SIZE - 1 : FOR dx = 0 TO MAP_SIZE-1
        IF doorOffsets(dx, dy) > 0 AND doorOffsets(dx, dy) < 1 THEN
            SELECT CASE doorType(dx, dy) ' Shutters are heavy AND slow, split doors snap OPEN
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
        IF ammoN(am) >= wpCost(curW) THEN
            ammoN(am) = ammoN(am) - wpCost(curW) : fireWait = wpDelay(curW) : gunKick = wpKick(curW) : muzzle = 4
            PlaySfx wpSnd&(curW), 0.7
            hitDmg = wpDmg(curW) : IF wpPierce(curW) THEN railBeam = 8
            invDet = 1 /(planeX * pDirY - pDirX * planeY)
            FOR pel = 1 TO wpPellets(curW)
                aim = (RND * 2 - 1) * wpSpread(curW) ' Across the view, -1 left edge..1 right
                IF wpPellets(curW) > 1 THEN aim = ((pel - 1) /(wpPellets(curW) -1) * 2 - 1) * wpSpread(curW) + (RND - 0.5) * 0.02
                col = INT(RW / 2 * (1 + aim)) : IF col < 0 THEN col = 0
                IF col > RW - 1 THEN col = RW-1
                ' (a piercing shot hits everything in its line that's nearer than
                ' the wall; any other the nearest monster or barrel)
                best = 0 : bestB = 0 : bestD = zBuf(col)
                FOR i = 1 TO nMon
                    IF mnState(i) < 2 THEN
                        sx = mnX(i) - pX : sy = mnY(i) -pY
                        trX = invDet * (pDirY * sx - pDirX * sy) : trY = invDet * (-planeY * sx + planeX * sy)
                        IF trY > 0.2 AND trY < bestD THEN
                            IF ABS(RW / 2 * (trX / trY - aim)) < RH / trY * mtScale(mnType(i)) * 0.3 THEN
                                IF wpPierce(curW) THEN hitMon = i : GOSUB HitMonster ELSE best = i : bestD = trY
                            END IF
                        END IF
                    END IF
                NEXT
                FOR i = 1 TO nDeco
                    IF dcOn(i) AND dcK(i) = 1 THEN
                        sx = dcX(i) - pX : sy = dcY(i) -pY
                        trX = invDet * (pDirY * sx - pDirX * sy) : trY = invDet * (-planeY * sx + planeX * sy)
                        IF trY > 0.2 AND trY < bestD THEN
                            IF ABS(RW / 2 * (trX / trY - aim)) < RH / trY * DecoScale(1) * 0.35 THEN
                                IF wpPierce(curW) THEN
                                    IF dcFuse(i) = 0 THEN dcFuse(i) = 1
                                ELSE
                                    bestB = i : best = 0 : bestD = trY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                IF best THEN hitMon = best : GOSUB HitMonster
                IF bestB THEN IF dcFuse(bestB) = 0 THEN dcFuse(bestB) = 1
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
        IF mnHurt(i) > 0 THEN mnHurt(i) = mnHurt(i) -1
        t = mnType(i)
        SELECT CASE mnState(i)
            CASE 0 ' Idle : wake when it can see you
                IF NOT dead THEN
                    IF (mnX(i) - pX) ^ 2 + (mnY(i) -pY) ^ 2 < MON_SIGHT * MON_SIGHT THEN
                        IF CanSee(mnX(i), mnY(i), pX, pY) THEN
                            mnState(i) = 1 : mnT(i) = 30
                            SfxAt mtAlert&(t), mnX(i), mnY(i), pX, pY
                        END IF
                    END IF
                END IF
            CASE 1 ' Hunting
                IF mnT(i) > 0 THEN mnT(i) = mnT(i) -1
                ddx = pX - mnX(i) : ddy = pY - mnY(i) : D = SQR(ddx * ddx + ddy * ddy)
                IF NOT dead AND D > 0.01 THEN
                    goX = 0 : goY = 0
                    IF mtRanged(t) THEN
                        ' Gunner: keep its distance, shoot when it has a clear line
                        ' (a sentry can't move, so it just shoots)
                        seen = CanSee(mnX(i), mnY(i), pX, pY)
                        IF D > GUNNER_FAR OR NOT seen THEN goX = ddx / D : goY = ddy / D
                        IF D < GUNNER_NEAR THEN goX = - ddx / D : goY = -ddy / D
                        IF seen AND mnT(i) = 0 AND D < 11 THEN
                            FireBolt mnX(i), mnY(i), ddx / d, ddy / d, mtDmg(t) + INT(RND * mtDmgRnd(t))
                            SfxAt mtAtk&(t), mnX(i), mnY(i), pX, pY
                            mnT(i) = mtCool(t) + INT(RND * 30)
                        END IF
                    ELSEIF D > mtReach(t) THEN
                        goX = ddx / D : goY = ddy / D ' Drone / heavy : CLOSE in
                    ELSEIF mnT(i) = 0 THEN '...and hit
                        dmg = mtDmg(t) + INT(RND * mtDmgRnd(t)) : mnT(i) = mtCool(t)
                        PlaySfx mtAtk&(t), 0.9
                        GOSUB HurtPlayer
                    END IF
                    IF goX <> 0 OR goY <> 0 THEN MoveBody mnX(i), mnY(i), goX * mtSpeed(t), goY * mtSpeed(t)
                END IF
                ' Keep a little apart from each other
                FOR j = 1 TO nMon
                    IF j <> i AND mnState(j) < 2 AND mtSpeed(t) > 0 THEN
                        sx = mnX(i) - mnX(j) : sy = mnY(i) -mnY(j) : d2 = sx * sx + sy * sy
                        IF d2 < 0.36 AND d2 > 0.0001 THEN
                            nx = mnX(i) + sx * 0.05 : ny = mnY(i) + sy * 0.05
                            IF Walkable(nx, ny) THEN mnX(i) = nx : mnY(i) = ny
                        END IF
                    END IF
                NEXT
            CASE 2 ' dying : collapse
                mnT(i) = mnT(i) -1
                IF mnT(i) <= 0 THEN mnState(i) = 3
        END SELECT
    NEXT

    ' --- Bolts: fly straight; burst on walls, or on you
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) THEN
            bX(i) = bX(i) + bDX(i) * BOLT_SPEED : bY(i) = bY(i) + bDY(i) * BOLT_SPEED
            IF NOT Walkable(bX(i), bY(i)) THEN
                bOn(i) = 0 : SfxAt sndBoltWall&, bX(i), bY(i), pX, pY
            ELSEIF NOT dead AND (bX(i) - pX) ^ 2 + (bY(i) -pY) ^ 2 < 0.35 * 0.35 THEN
                bOn(i) = 0 : dmg = bDmg(i) : GOSUB HurtPlayer
            END IF
        END IF
    NEXT
    ' --- Barrels: a lit fuse counts down, then it blows; explosions fade ---
    FOR i = 1 TO nDeco
        IF dcFuse(i) > 0 THEN
            dcFuse(i) = dcFuse(i) - 1
            IF dcFuse(i) = 0 THEN boomI = i : GOSUB Explode
        END IF
    NEXT
    FOR i = 1 TO MAX_BOOM
        IF bmT(i) > 0 THEN bmT(i) = bmT(i) - 1
    NEXT
    IF railBeam > 0 THEN railBeam = railBeam - 1

    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
    IF pickFlash > 0 THEN pickFlash = pickFlash - 1

    ' --- 4. Render (into half-res buffer scr()) ---
    ' Floor + ceiling: cast one row at a time, mirrored about the horizon;
    ' each map cell has its own floor and ceiling texture
    rx0 = pDirX - planeX : ry0 = pDirY - planeY
    rx1 = pDirX + planeX : ry1 = pDirY + planeY
    FOR y = RH \ 2 TO RH - 1
        rowDist = (RH / 2) /(y - RH / 2 + 0.5)
        fsX = rowDist * (rx1 - rx0) / RW : fsY = rowDist * (ry1 - ry0) / RW
        fX = pX + rowDist * rx0 : fY = pY + rowDist * ry0
        s& = 256 - rowDist * 16
        IF s& < 0 THEN s& = 0
        rowF = y * RW : rowC = (RH - 1 - y) * RW
        FOR x = 0 TO RW - 1
            cX = INT(fX) : cY = INT(fY)
            IF cX >= 0 AND cX < MAP_SIZE AND cY >= 0 AND cY < MAP_SIZE THEN
                fs = floorT(cX, cY) : cs = ceilT(cX, cY)
                IF fK(cX, cY) THEN IF DiagIn(fK(cX, cY), fX - cX, fY - cY) THEN fs = floorT2(cX, cY)
                IF cK(cX, cY) THEN IF DiagIn(cK(cX, cY), fX - cX, fY - cY) THEN cs = ceilT2(cX, cY)
            ELSE
                fs = T_FLOOR + 1 : cs = T_CEIL + 1
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
        ddx = ABS(1 / rDX) : ddy = ABS(1 / rDY)

        IF rDX < 0 THEN stX = -1 : sDX = (pX - mX) * ddx ELSE stX = 1 : sDX = (mX + 1 - pX) * ddx
        IF rDY < 0 THEN stY = -1 : sDY = (pY - mY) * ddy ELSE stY = 1 : sDY = (mY + 1 - pY) * ddy

        hit = 0 : side = 0 : ovl = 0 : dgHit = 0
        IF diagK(mX, mY) THEN ' Standing in a diagonal wall's open half
            tOut = sDX : IF sDY < tOut THEN tOut = sDY
            dgT = DiagHit(diagK(mX, mY), mX, mY, pX, pY, rDX, rDY, 0, tOut)
            IF dgT >= 0 THEN hit = worldMap(mX, mY) : dgHit = diagK(mX, mY) : dist = dgT
        END IF
        WHILE hit = 0
            IF sDX < sDY THEN sDX = sDX + ddx : mX = mX + stX : side = 0 ELSE sDY = sDY + ddy : mY = mY + stY : side = 1
            v = worldMap(mX, mY)
            IF diagK(mX, mY) THEN
                ' Diagonal wall: came in through its solid half, that's a plain
                ' wall face; else it hits the diagonal if it crosses it in here
                IF side = 0 THEN tIn = sDX - ddx ELSE tIn = sDY - ddy
                tOut = sDX : IF sDY < tOut THEN tOut = sDY
                IF DiagIn(diagK(mX, mY), pX + (tIn + 0.001) * rDX - mX, pY + (tIn + 0.001) * rDY - mY) THEN
                    hit = v
                ELSE
                    dgT = DiagHit(diagK(mX, mY), mX, mY, pX, pY, rDX, rDY, tIn, tOut)
                    IF dgT >= 0 THEN hit = v : dgHit = diagK(mX, mY) : dist = dgT
                END IF
            ELSEIF v = 2 THEN
                IF side = 0 THEN dd = (mX - pX + (1 - stX) / 2) / rDX : wX = pY + dd * rDY ELSE dd = (mY - pY + (1 - stY) / 2) / rDY : wX = pX + dd * rDX
                wX = wX - INT(wX) : dOpen = doorOffsets(mX, mY)
                SELECT CASE doorType(mX, mY)
                    CASE DOOR_SLIDE ' Slides sideways
                        IF wX > dOpen THEN hit = 2
                    CASE DOOR_SPLIT ' Halves part from the MIDDLE
                        IF wX < 0.5 - dOpen / 2 OR wX > 0.5 + dOpen / 2 THEN hit = 2
                    CASE DOOR_EXIT ' Never opens
                        hit = 2
                    CASE DOOR_SHUTTER ' rises : shut, it's a wall;rising, you see under it
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

        IF dgHit = 0 THEN
            IF side = 0 THEN dist = (mX - pX + (1 - stX) / 2) / rDX ELSE dist = (mY - pY + (1 - stY) / 2) / rDY
        END IF
        IF dist < 0.001 THEN dist = 0.001
        zBuf(x) = dist

        ' Texture column and slot (doors move their texture with them)
        IF side = 0 THEN wallX = pY + dist * rDY ELSE wallX = pX + dist * rDX
        wallX = wallX - INT(wallX)
        IF dgHit THEN ' Along the diagonal, left to right as you see it
            wallX = pX + dist * rDX - mX
            IF dgHit <= 2 THEN wallX = 1 - wallX
            tX = INT(wallX * TEX) : tSlot = wallSlot(hit)
        ELSEIF hit = 2 THEN
            dOpen = doorOffsets(mX, mY)
            SELECT CASE doorType(mX, mY)
                CASE DOOR_SLIDE
                    tX = INT((wallX - dOpen) * TEX)
                    IF doorKey(mX, mY) THEN tSlot = T_DOORK + doorKey(mX, mY) ELSE tSlot = T_DOOR
                CASE DOOR_SPLIT
                    IF wallX < 0.5 THEN tX = INT((wallX + dOpen / 2) * TEX) ELSE tX = INT((wallX - dOpen / 2) * TEX)
                    tSlot = T_SPLIT
                CASE DOOR_EXIT ' (turned like a wall, so its sign reads the right way)
                    tX = INT(wallX * TEX) : tSlot = T_EXIT
                    IF side = 0 AND rDX > 0 THEN tX = TEX - 1 - tX
                    IF side = 1 AND rDY < 0 THEN tX = TEX - 1 - tX
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
        IF lEnd > RH - 1 THEN lEnd = RH-1

        ' Shading: distance fog, darker on Y-facing sides
        s& = 256 - dist * 16
        IF s& < 0 THEN s& = 0
        IF dgHit THEN s& = s& * 0.85 ELSE IF side = 1 THEN s& = s& * 0.7

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
            IF lEnd > RH - 1 THEN lEnd = RH-1
            s& = 256 - ovD * 16
            IF s& < 0 THEN s& = 0
            IF ovSide = 1 THEN s& = s& * 0.7
            tX = INT(ovU * TEX) AND (TEX - 1)
            FOR y = lStart TO lEnd
                scr(y * RW + x) = Shade~&(TEX(tX, INT(tPos) AND (TEX - 1), T_SHUTTER), s&)
                tPos = tPos + tStep
            NEXT
            IF ovOpen < 0.5 THEN zBuf(x) = ovD ' Mostly down : things behind it stay hidden
        END IF
    NEXT x

    ' --- Sprites: pickups, monsters and bolts, far to near, hidden behind
    ' walls by zBuf
    nDraw = 0
    FOR i = 1 TO nItems
        IF itOn(i) THEN
            nDraw = nDraw + 1 : dlX(nDraw) = itX(i) : dlY(nDraw) = itY(i)
            dlSlot(nDraw) = ItemSlot(itK(i)) : dlSquash(nDraw) = 1 : dlMinS(nDraw) = 96 ' they glow : less fog
            SELECT CASE itK(i)
                CASE 1 TO 3 : dlScale(nDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL : dlScale(nDraw) = GUN_ITEM_SCALE
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
            IF mnState(i) = 2 THEN ' Collapsing TO the floor
                dlSquash(nDraw) = mnT(i) / MON_DYING : dlLift(nDraw) = mtLift(t) * dlSquash(nDraw) : dlSlot(nDraw) = mtSlot(t) + 1
            ELSE
                dlSquash(nDraw) = 1 : dlLift(nDraw) = mtLift(t) + mtBob(t) * SIN(TIMER * 2.5 + i * 1.7)
            END IF
        END IF
    NEXT
    FOR i = 1 TO nDeco
        IF dcOn(i) THEN
            nDraw = nDraw + 1 : dlX(nDraw) = dcX(i) : dlY(nDraw) = dcY(i)
            dlSlot(nDraw) = S_DECO + dcK(i) : dlScale(nDraw) = DecoScale(dcK(i)) : dlLift(nDraw) = 0
            dlSquash(nDraw) = 1 : dlMinS(nDraw) = 40
            IF dcK(i) = 2 THEN dlMinS(nDraw) = 200 ' Lamps glow
        END IF
    NEXT
    FOR i = 1 TO MAX_BOOM
        IF bmT(i) > 0 THEN ' Explosions swell as they fade
            nDraw = nDraw + 1 : dlX(nDraw) = bmX(i) : dlY(nDraw) = bmY(i)
            dlSlot(nDraw) = S_BOOM : dlScale(nDraw) = 0.6 + 0.7 * (1 - bmT(i) / BOOM_FRAMES) : dlLift(nDraw) = 0.05
            dlSquash(nDraw) = 1 : dlMinS(nDraw) = 256
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) THEN
            nDraw = nDraw + 1 : dlX(nDraw) = bX(i) : dlY(nDraw) = bY(i)
            dlSlot(nDraw) = S_BOLT : dlScale(nDraw) = 0.22 : dlLift(nDraw) = 0.38
            dlSquash(nDraw) = 1 : dlMinS(nDraw) = 256 ' Glowing : no fog at ALL
        END IF
    NEXT
    FOR i = 1 TO nDraw
        ord(i) = i : dlD(i) = (dlX(i) - pX) ^ 2 + (dlY(i) -pY) ^ 2
    NEXT
    FOR a = 1 TO nDraw - 1 : FOR b = a + 1 TO nDraw
        IF dlD(ord(b)) > dlD(ord(a)) THEN SWAP ord(a), ord(b)
    NEXT : NEXT
    invDet = 1 /(planeX * pDirY - pDirX * planeY)
    FOR o = 1 TO nDraw
        i = ord(o)
        sx = dlX(i) - pX : sy = dlY(i) -pY
        trX = invDet * (pDirY * sx - pDirX * sy) ' sideways from the VIEW
        trY = invDet * ( - planeY * sx + planeX * sy) ' Depth
        IF trY > 0.1 THEN
            sprW = INT(RH / trY * dlScale(i)) : sprH = INT(sprW * dlSquash(i))
            IF sprH < 1 THEN sprH = 1
            y0 = INT(RH / 2 + (0.5 - dlLift(i)) * RH / trY) -sprH ' bottom edge lifted OFF the floor
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
                                c~& = sprTex(u,(syp - y0) * sz \ sprH, sl)
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
    gx = 400 - gw * wpMuzX(curW) + COS(bob / 2) * 10
    gy = GUN_Y - gh + ABS(SIN(bob / 2)) * 10 + gunKick * 36 + 12
    IF swapT > 0 THEN gy = gy + (SWAP_FRAMES / 2 - ABS(swapT - SWAP_FRAMES / 2)) * 40
    IF dead THEN gy = gy + (TIMER - deadAt!) * 400 ' Drops OUT of VIEW
    IF gy < 600 THEN _PUTIMAGE (gx, gy)-(gx + gw - 1, gy + gh - 1), gImg&
    IF muzzle > 0 THEN ' muzzle flash, AND a flicker of light ON everything
        muzzle = muzzle - 1
        LINE (0, 0)-(799, 599), _RGBA32(255, 120, 120, 18), BF
        fX = gx + gw * wpMuzX(curW) : fY = gy + gh * wpMuzY(curW)
        FillCircle fx, fy, 30 + muzzle * 4, _RGBA32(255, 40, 40, 90)
        FillCircle fx, fy, 18 + muzzle * 3, _RGBA32(255, 150, 150, 170)
        FillCircle fx, fy, 8, _RGBA32(255, 255, 255, 230)
    END IF
    IF railBeam > 0 THEN ' The railgun's beam, from the muzzle to the crosshair
        fX = gx + gw * wpMuzX(curW) : fY = gy + gh * wpMuzY(curW)
        FOR k = -3 TO 3
            LINE (fX + k, fY)-(400 + k / 3, 300), _RGBA32(255, 60 + 30 * (3 - ABS(k)), 60 + 30 * (3 - ABS(k)), railBeam * 28)
        NEXT
    END IF

    IF NOT dead THEN LINE (395, 300)-(405, 300), _RGB32(255, 0, 0) : LINE (400, 295)-(400, 305), _RGB32(255, 0, 0)
    IF hurtFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 0, 0, hurtFlash * 9), BF
    IF pickFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 255, 160, pickFlash * 4), BF
    IF godMode THEN HudText 16, 498, "GOD MODE", _RGB32(255, 215, 30)

    ' Minimap: walls (each kind its texture's colour); doors orange (key doors
    ' in their card's colour, dark centre) when shut, white while opening,
    ' green when open; the exit blinking green; keycards; you
    LINE (MMX - 2, MMY - 2)-(MMX + MAP_SIZE * MM + 1, MMY + MAP_SIZE * MM + 1), _RGBA32(0, 0, 0, 160), BF
    FOR mY = 0 TO MAP_SIZE - 1 : FOR mX = 0 TO MAP_SIZE-1
        mmC~& = 0
        SELECT CASE worldMap(mX, mY)
            CASE 1, 3 TO 7 : mmC~& = wallCol(worldMap(mX, mY))
            CASE 2
                IF doorType(mX, mY) = DOOR_EXIT THEN
                    IF (TIMER * 4 AND 1) = 0 THEN mmC~& = _RGB32(80, 255, 120) ELSE mmC~& = _RGB32(20, 120, 50)
                ELSEIF doorOffsets(mX, mY) = 0 THEN
                    IF doorKey(mX, mY) THEN mmC~& = CardRGB~&(doorKey(mX, mY)) ELSE mmC~& = _RGB32(255, 140, 20)
                ELSEIF doorOffsets(mX, mY) < 1 THEN
                    mmC~& = _RGB32(230, 230, 230)
                ELSE
                    mmC~& = _RGB32(40, 200, 80)
                END IF
        END SELECT
        IF mmC~& <> 0 AND diagK(mX, mY) <> 0 THEN ' Diagonal: just its solid half
            FOR dqy = 0 TO MM - 1 : FOR dqx = 0 TO MM - 1
                IF DiagIn(diagK(mX, mY), (dqx + 0.5) / MM, (dqy + 0.5) / MM) THEN PSET (MMX + mX * MM + dqx, MMY + mY * MM + dqy), mmC~&
            NEXT : NEXT
        ELSEIF mmC~& THEN
            LINE (MMX + mX * MM, MMY + mY * MM)-STEP(MM - 1, MM-1), mmC~&, BF
            IF doorKey(mX, mY) AND doorOffsets(mX, mY) = 0 THEN PSET (MMX + mX * MM + MM \ 2, MMY + mY * MM + MM \ 2), _RGB32(0, 0, 0)
        END IF
    NEXT : NEXT
    IF (TIMER * 4 AND 1) = 0 THEN ' keycards BLINK
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
    FOR k = 3 TO 1 STEP - 1
        IF hasCard(k) THEN hx = hx - 68 : _PUTIMAGE (hx, 8)-STEP(63, 63), cardImg&(k)
    NEXT

    ' Armour and health (bottom left)
    IF armor > 0 THEN
        HudText 16, 516, "ARMOR" + STR$(armor), _RGB32(90, 160, 255)
        LINE (16, 534)-STEP(201, 9), _RGBA32(0, 0, 0, 170), BF
        LINE (17, 535)-STEP(armor * 2 - 1, 7), _RGB32(90, 160, 255), BF
    END IF
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
    FOR W = 1 TO NUM_W
        wc~& = _RGB32(60, 60, 70)
        IF hasWpn(W) THEN wc~& = _RGB32(150, 150, 160)
        IF W = curW THEN wc~& = _RGB32(255, 255, 255)
        HudText 800 - 16 - 202 + (W - 1) * 20, 534, LTRIM$(STR$(W)), wc~&
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

' --- A shot (or blast) hits monster hitMon for hitDmg
HitMonster:
mnHP(hitMon) = mnHP(hitMon) - hitDmg : mnHurt(hitMon) = 8
IF mnState(hitMon) = 0 THEN mnState(hitMon) = 1 : mnT(hitMon) = 30 ' Shot awake
IF mnHP(hitMon) <= 0 AND mnState(hitMon) < 2 THEN
    mnState(hitMon) = 2 : mnT(hitMon) = MON_DYING : kills = kills + 1
    SfxAt mtDie&(mnType(hitMon)), mnX(hitMon), mnY(hitMon), pX, pY
    IF kills = nMon THEN ShowMsg "SECTOR CLEAR - every monster destroyed!"
ELSE
    SfxAt mtHitS&(mnType(hitMon)), mnX(hitMon), mnY(hitMon), pX, pY
END IF
RETURN

' --- You take dmg damage (armour soaks up a third of it while it lasts)
HurtPlayer:
IF godMode THEN RETURN
ab = dmg \ 3 : IF ab > armor THEN ab = armor
armor = armor - ab : dmg = dmg - ab
hp = hp - dmg : hurtFlash = 14
IF hp <= 0 THEN
    hp = 0 : dead = -1 : deadAt! = TIMER
    PlaySfx sndDie&, 1 : ShowMsg ""
ELSE
    PlaySfx sndHurt&, 0.8
END IF
RETURN

' --- Barrel boomI explodes: it hurts everything near it that it can see,
' and sets off other barrels close by (a moment later)
Explode:
dcOn(boomI) = 0 : dcFuse(boomI) = 0 : decoCell(INT(dcX(boomI)), INT(dcY(boomI))) = 0
SfxAt sndBarrel&, dcX(boomI), dcY(boomI), pX, pY
FOR j = 1 TO MAX_BOOM
    IF bmT(j) = 0 THEN bmX(j) = dcX(boomI) : bmY(j) = dcY(boomI) : bmT(j) = BOOM_FRAMES : EXIT FOR
NEXT
FOR j = 1 TO nMon
    IF mnState(j) < 2 THEN
        D = SQR((mnX(j) - dcX(boomI)) ^ 2 + (mnY(j) - dcY(boomI)) ^ 2)
        IF D < BOOM_R THEN
            IF CanSee(dcX(boomI), dcY(boomI), mnX(j), mnY(j)) THEN hitMon = j : hitDmg = INT(8 * (1 - D / BOOM_R)) + 1 : GOSUB HitMonster
        END IF
    END IF
NEXT
D = SQR((pX - dcX(boomI)) ^ 2 + (pY - dcY(boomI)) ^ 2)
IF D < BOOM_R AND NOT dead THEN
    IF CanSee(dcX(boomI), dcY(boomI), pX, pY) THEN dmg = INT(40 * (1 - D / BOOM_R)) + 5 : GOSUB HurtPlayer
END IF
FOR j = 1 TO nDeco
    IF dcOn(j) AND dcK(j) = 1 AND dcFuse(j) = 0 THEN
        IF (dcX(j) - dcX(boomI)) ^ 2 + (dcY(j) - dcY(boomI)) ^ 2 < BOOM_R * BOOM_R THEN dcFuse(j) = 8
    END IF
NEXT
RETURN

' --- A new game: level 1, just the blaster
NewGame:
level = 1 : totKills = 0 : totMon = 0 : totTime! = 0
hp = MAX_HP : armor = 0
ammoN(AM_CELLS) = 30 : ammoN(AM_SHELLS) = 0
FOR W = 1 TO NUM_W : hasWpn(W) = 0 : NEXT
hasWpn(W_BLASTER) = -1 : curW = W_BLASTER
IF TEST_ALL_GUNS THEN ' Testing: every gun, full ammo
    FOR W = 1 TO NUM_W : hasWpn(W) = -1 : NEXT
    ammoN(AM_CELLS) = ammoMax(AM_CELLS) : ammoN(AM_SHELLS) = ammoMax(AM_SHELLS)
END IF
GOSUB EnterLevel
RETURN

' --- Into level `level`, remembering what you bring with you
EnterLevel:
svHp = hp : svArmor = armor : svCells = ammoN(AM_CELLS) : svShells = ammoN(AM_SHELLS) : svCur = curW
FOR W = 1 TO NUM_W : svWpn(W) = hasWpn(W) : NEXT
GOSUB LoadLevel
RETURN

' --- You died: the level starts over, and you have what you came in with
RestartLevel:
hp = svHp : armor = svArmor : ammoN(AM_CELLS) = svCells : ammoN(AM_SHELLS) = svShells : curW = svCur
FOR W = 1 TO NUM_W : hasWpn(W) = svWpn(W) : NEXT
GOSUB LoadLevel
RETURN

' --- You used the exit: the level's tally, then on to the next level (after
' the last, the game's totals, and a new game)
LevelDone:
PlaySfx sndExit&, 0.9
lvTime! = TIMER - lvStart! : IF lvTime! < 0 THEN lvTime! = lvTime! + 86400
totKills = totKills + kills : totMon = totMon + nMon : totTime! = totTime! + lvTime!
got = 0
FOR i = 1 TO nItems
    IF itOn(i) = 0 THEN got = got + 1
NEXT
shot& = _COPYIMAGE(0) : tStart! = TIMER
DO
    _LIMIT 30
    _PUTIMAGE , shot&, 0
    LINE (0, 0)-(799, 599), _RGBA32(0, 0, 0, 180), BF
    IF level = NUM_LEVELS THEN BigText "YOU ESCAPED!", 110, 5, _RGB32(80, 255, 140) ELSE BigText "SECTOR CLEAR", 110, 5, _RGB32(80, 255, 140)
    HudText 400 - LEN(lvName$) * 4, 210, lvName$, _RGB32(255, 255, 255)
    TallyLine 260, "KILLS", LTRIM$(STR$(kills)) + " / " + LTRIM$(STR$(nMon))
    TallyLine 285, "ITEMS", LTRIM$(STR$(got)) + " / " + LTRIM$(STR$(nItems))
    TallyLine 310, "TIME", TimeText$(lvTime!)
    IF level = NUM_LEVELS THEN
        TallyLine 360, "TOTAL KILLS", LTRIM$(STR$(totKills)) + " / " + LTRIM$(STR$(totMon))
        TallyLine 385, "TOTAL TIME", TimeText$(totTime!)
    END IF
    IF TIMER - tStart! > 1 THEN
        IF level = NUM_LEVELS THEN c$ = "Click or press Space to play again" ELSE c$ = "Click or press Space for the next sector"
        HudText 400 - LEN(c$) * 4, 450, c$, _RGB32(255, 255, 255)
    END IF
    _DISPLAY
    click = 0
    WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN click = -1
    WEND
    IF _KEYDOWN(27) THEN SYSTEM
    IF TIMER - tStart! > 1 AND (click OR _KEYDOWN(32)) THEN EXIT DO
LOOP
_FREEIMAGE shot&
IF level >= NUM_LEVELS THEN
    GOSUB NewGame
ELSE
    level = level + 1 : GOSUB EnterLevel
END IF
RETURN

' --- Start (or restart) the level: read its map, and reset everything in it
LoadLevel:
FOR y = 0 TO MAP_SIZE : FOR x = 0 TO MAP_SIZE
    worldMap(x, y) = 0 : doorOffsets(x, y) = 0 : doorKey(x, y) = 0 : doorType(x, y) = 0 : diagK(x, y) = 0
    floorT(x, y) = T_FLOOR + 1 : ceilT(x, y) = T_CEIL + 1 : fK(x, y) = 0 : cK(x, y) = 0 : decoCell(x, y) = 0
NEXT : NEXT
nItems = 0 : nMon = 0 : nDeco = 0
FOR k = 1 TO 3 : hasCard(k) = 0 : NEXT
FOR i = 1 TO MAX_BOLTS : bOn(i) = 0 : NEXT
FOR i = 1 TO MAX_BOOM : bmT(i) = 0 : NEXT
SELECT CASE level
    CASE 1 : RESTORE Level1
    CASE 2 : RESTORE Level2
    CASE 3 : RESTORE Level3
    CASE ELSE : RESTORE Level4
END SELECT
READ lvName$
FOR k = 1 TO 6 : READ f$ : LoadTex f$, k : NEXT ' Walls # N C K P G
FOR k = 1 TO 4 : READ f$ : LoadTex f$, T_FLOOR + k : NEXT
FOR k = 1 TO 2 : READ f$ : LoadTex f$, T_CEIL + k : NEXT
FOR k = 1 TO 7
    IF k <> 2 THEN wallCol(k) = MapCol~&(wallSlot(k))
NEXT
READ nZones ' Floor / ceiling zones : x0, y0, x1, y1, floor, ceiling, shape
FOR k = 1 TO nZones
    READ zx0, zy0, zx1, zy1, zf, zc, zs
    zn = zx1 - zx0
    FOR y = zy0 TO zy1 : FOR x = zx0 TO zx1
        ' Is the cell in the zone (1), outside it (0), or cut by its diagonal
        ' (2: its zs corner's half is in)?
        i = x - zx0 : j = y - zy0 : part = 1
        SELECT CASE zs
            CASE 1 : IF i + j > zn THEN part = 0 ELSE IF i + j = zn THEN part = 2
            CASE 2 : IF j > i THEN part = 0 ELSE IF j = i THEN part = 2
            CASE 3 : IF i + j < zn THEN part = 0 ELSE IF i + j = zn THEN part = 2
            CASE 4 : IF i > j THEN part = 0 ELSE IF i = j THEN part = 2
        END SELECT
        IF part = 1 THEN
            IF zf THEN floorT(x, y) = T_FLOOR + zf : fK(x, y) = 0
            IF zc THEN ceilT(x, y) = T_CEIL + zc : cK(x, y) = 0
        ELSEIF part = 2 THEN
            IF zf THEN floorT2(x, y) = T_FLOOR + zf : fK(x, y) = zs
            IF zc THEN ceilT2(x, y) = T_CEIL + zc : cK(x, y) = zs
        END IF
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
            CASE "/" : diagK(x, y) = -1 ' Diagonal wall (which half is solid: below)
            CASE "\" : diagK(x, y) = -2
            CASE "E" : worldMap(x, y) = 2 : doorType(x, y) = DOOR_EXIT
            CASE "R", "B", "Y" ' Key door: needs that keycard
                worldMap(x, y) = 2 : doorKey(x, y) = INSTR("RBY", cell$)
            CASE "r", "b", "y", "+", "a", "e", "2", "3", "u", "*", "4" ' Something to pick up
                IF nItems < MAX_ITEMS THEN
                    nItems = nItems + 1
                    itX(nItems) = x + 0.5 : itY(nItems) = y + 0.5 : itOn(nItems) = -1
                    itK(nItems) = INSTR("rby+ae23u*4", cell$)
                END IF
            CASE "o", "i", "p", "t" ' A decoration
                IF nDeco < MAX_DECO THEN
                    nDeco = nDeco + 1 : decoCell(x, y) = nDeco
                    dcX(nDeco) = x + 0.5 : dcY(nDeco) = y + 0.5 : dcK(nDeco) = INSTR("oipt", cell$) : dcOn(nDeco) = -1 : dcFuse(nDeco) = 0
                END IF
            CASE "m", "g", "h", "c", "s" ' A monster
                IF nMon < MAX_MON THEN
                    nMon = nMon + 1
                    mnX(nMon) = x + 0.5 : mnY(nMon) = y + 0.5 : mnType(nMon) = INSTR("mghcs", cell$)
                    mnHP(nMon) = mtHP(mnType(nMon)) : mnState(nMon) = 0 : mnT(nMon) = 0 : mnHurt(nMon) = 0
                END IF
            CASE "<", ">", "^", "v" ' Player start, facing the arrow's way
                pX = x + 0.5 : pY = y + 0.5
                pDirX = (cell$ = "<") - (cell$ = ">") : pDirY = (cell$ = "^") - (cell$ = "v")
        END SELECT
    NEXT
NEXT
' Diagonal walls: of its two halves, the solid one is the one with more wall
' beside it (a whole wall counts 2, another diagonal 1). It looks like the
' wall beside its solid half; standing on its own, neon.
FOR y = 1 TO MAP_SIZE - 2 : FOR x = 1 TO MAP_SIZE - 2
    IF diagK(x, y) < 0 THEN
        dSc = -1
        FOR k = -diagK(x, y) TO 4 STEP 2 ' "/" corners 1 AND 3, "\" 2 AND 4
            IF k <= 2 THEN ny = y - 1 ELSE ny = y + 1
            IF k = 2 OR k = 3 THEN nx = x + 1 ELSE nx = x - 1
            sc = 0
            IF diagK(x, ny) THEN sc = sc + 1 ELSE IF IsWall(x, ny) THEN sc = sc + 2
            IF diagK(nx, y) THEN sc = sc + 1 ELSE IF IsWall(nx, y) THEN sc = sc + 2
            IF sc > dSc THEN dSc = sc : dK = k : dnx = nx : dny = ny
        NEXT
        diagK(x, y) = dK : worldMap(x, y) = 3
        IF IsWall(x, dny) THEN worldMap(x, y) = worldMap(x, dny) ELSE IF IsWall(dnx, y) THEN worldMap(x, y) = worldMap(dnx, y)
    END IF
NEXT : NEXT
' Camera plane is the view direction turned 90 degrees
planeX = pDirY * 0.66 : planeY = - pDirX * 0.66
kills = 0 : dead = 0 : swapT = 0
hurtFlash = 0 : pickFlash = 0 : muzzle = 0 : gunKick = 0 : railBeam = 0
fireWait = 20 ' (so the click that started the level doesn't fire)
bob = 0 : stepDist = STEP_LEN * 0.85 ' First STEP sounds soon after you start walking
lvStart! = TIMER
ShowMsg lvName$ + "  -  find the EXIT"
RETURN

'=============================================================================
' MapData - the levels (Level1: to Level4:). LoadLevel reads one every time
' it starts or restarts; you go from one to the next through its exit.
'=============================================================================
'
' Coordinates: x runs left to right (0 to MAP_SIZE - 1), y runs top to bottom
' (row 0 is the top line). Each map cell is one "tile": a wall block, a door,
' or a square of floor. You walk around in the same units (moving at 0.12
' tiles a frame), and things on the map stand in the middle of their tile.
'
' Each level is, in order:
'
' --- Part 1: its name and textures ------------------------------------------
'
'   DATA "SECTOR 2: REACTOR CORE"            shown as you arrive, and on the tally
'   DATA six wall pictures                   for # N C K P G, in that order
'   DATA four floor pictures                 floors 1-4 (for the zones below)
'   DATA two ceiling pictures                ceilings 1-2
'
' (all from neon-caster/, 64x64; doors, keycards and the exit are the same
' in every level). On the minimap each wall kind is its picture's colour.
'
' --- Part 2: floor / ceiling zones -----------------------------------------
'
' First a count, then that many lines of: x0, y0, x1, y1, floor, ceiling, shape
'
'   x0, y0, x1, y1   a rectangle of tiles, corners included
'   floor            1-4 (the level's floors), or 0 to leave the floor alone
'   ceiling          1-2 (the level's ceilings), or 0 to leave it alone
'   shape            0  the whole rectangle
'                    1-4 a triangle: the half of the rectangle (which must
'                    be square) on the top-left (1), top-right (2),
'                    bottom-right (3) or bottom-left (4) side of its
'                    diagonal. The tiles the diagonal runs through are
'                    split corner to corner, like diagonal walls: half the
'                    new texture, half what was there before.
'
' Every tile starts as floor 1 + ceiling 1; each zone then paints its area,
' in order, so a later zone wins where two overlap. Only floor tiles show
' this (it's what you see underfoot and overhead), so a zone can safely
' include the walls around a room. Two triangles make a diagonal stripe:
' paint one texture on the far side of one diagonal, then the old texture
' back past another diagonal beside it (level 3's water channel does this).
'
' --- Part 3: the map, one string per row ------------------------------------
'
' Exactly MAP_SIZE strings of exactly MAP_SIZE characters. Anything not
' listed below (or a missing character) is plain floor.
'
' WALLS - solid blocks; you, monsters, shots and bolts can't pass, and
' monsters can't see through them. They only differ in looks (texture, and
' colour on the minimap), and each level picks the six textures (Part 1):
'   #  N  C  K  P  G
'
' DIAGONAL WALLS - a cell cut corner to corner at 45 degrees, half wall and
' half floor. Which half is solid is worked out from what's beside it: the
' side with more wall. So draw them where a wall turns a corner, and they
' cut it off. Two make a longer slope (with a wall in the corner behind
' them); four make a freestanding diamond pillar:  /\
'                                                  \/
' The slope looks like the wall beside its solid half (N if it stands on
' its own), a little darker, and it's a half-filled cell on the minimap. A
' doorway or passage can't go through one: carve the passage up to the
' slope and replace the diagonal it meets with floor.
'   /  diagonal from bottom-left to top-right
'   \  diagonal from top-left to bottom-right
'
' DOORS - closed until you face one within 2 tiles and press Space; then
' they open for good (they never close again). They block you, monsters and
' sight while mostly shut, and count as open once 80% of the way. A door
' must sit in a wall one tile thick: walls on two opposite sides (left and
' right, or above and below) and floor on the other two - that's the way
' you walk through it.
'   D  sliding door: slides sideways into the wall (~0.4 s). (door.png)
'   H  heavy shutter: rolls up from the floor, slowly (~0.7 s), with a
'      rumble; while it rises you can see (and walk, once it's high enough)
'      under it. (door-shutter.png)
'   X  split door: the two halves part from the middle, fast (~0.3 s), with
'      a double hiss. (door-split.png)
'   R  B  Y  key door (a sliding door) that needs the red / blue / yellow
'      keycard. Without it, Space just says "Locked" and buzzes. It's drawn
'      tinted in its card's colour, and on the minimap it's that colour
'      with a dark dot in the middle.
'   E  the exit (exit.png, with a lit EXIT sign). It never opens: face it
'      and press Space to finish the level. It can go in any wall with
'      floor in front of it, and blinks green on the minimap. One a level.
'
' PICKUPS - hover over the floor; walk onto one to take it. Health, armour
' and ammo stay where they are while you're already full, so you can come
' back.
'   r  b  y  red / blue / yellow keycard: kept for the rest of the level, it
'            opens every door of its colour. Shown top right once you
'            have it, and blinks on the minimap until then.
'   +        health pack: +25 health (up to 100)
'   *        big medkit: +50 health (up to 100)
'   u        armour: +50 armour (up to 100). Armour takes a third of the
'            damage you'd take, until it runs out.
'   a        energy cells: +15 cells (up to 99) - ammo for the blaster, the
'            repeater and the railgun
'   e        shells: +8 shells (up to 40) - ammo for the scatter gun
'   2        scatter gun (+8 shells): 7 pellets in a spread, 1 shot every
'            2/3 s. You switch to it when you first pick it up.
'   3        repeater (+30 cells): fast automatic fire, about 12 shots a
'            second. Picked up again later, a gun is just ammo.
'   4        railgun (+30 cells): 5 cells a shot, about 1 a second; each
'            shot does 5 damage to every monster in its line (up to the
'            wall), and sets off every barrel in it.
'
' MONSTERS - each waits where it stands until it can see you (within 14
' tiles, with no wall or shut door in the way) or until you shoot it. Then
' it hunts you for good. Numbers are in the SetMonType lines.
'   m  drone:   hovers, 3 hits. Flies straight at you (about a third of
'               your speed) and bites up close for 8-13, about once a second.
'   g  gunner:  walks, 4 hits. Keeps 3.5 to 7 tiles away (backs off if you
'               get close) and, when it can see you, fires a magenta energy
'               bolt for 9-14 every 1.5-2 s. Bolts fly straight and burst on
'               walls - you can dodge them.
'   h  heavy:   walks slowly, 10 hits. Closes in and smashes for 20-29 about
'               every 1.3 s. Big enough that a scatter blast hits it with
'               more pellets.
'   c  crawler: a small spider bot, 2 hits, low to the ground. Scuttles at
'               you at over half your speed and nips for 5-8 about twice a
'               second. They come in packs.
'   s  sentry:  a gun turret, 8 hits. Never moves; when it can see you it
'               fires a bolt for 7-11 about every second.
'
' DECORATIONS - stand on the floor; you, monsters and bolts can't go through
' them, but they don't block sight, and shots fly past (except barrels).
'   o  barrel:   explodes when shot: up to 45 damage to you and 8 to
'                monsters within 2.2 tiles (less further away, and not
'                through walls), and sets off other barrels near it.
'   i  lamp      (it glows)
'   p  plant
'   t  terminal
'
' THE START
'   <  >  ^  v  you start here, facing left / right / up / down. Use one;
'               with several, the last one read wins.
'   .           floor (any other character is floor too)
'
' TESTING (switched by constants at the top): TEST_ALL_GUNS starts you with
' every gun and full ammo; CHEAT_KEYS lets K give you every keycard, and G
' switch god mode on and off (no damage, and you walk through walls, doors
' and monsters - though not out past the map's border).
'
' Rules: the outer border must be all walls (nothing else stops a ray or a
' monster from leaving the map). Up to MAX_ITEMS pickups, MAX_MON monsters
' and MAX_DECO decorations; extra ones are ignored.
'
' The level kit: neon-caster/levels/levels.py builds these levels (rooms
' carved with exact 45-degree edges) and checks them - doors between walls,
' every keycard reachable before its doors, the exit reachable, textures
' present. "python3 levels.py --check" checks the DATA below as it stands;
' "--write" rebuilds it from levels.py (replacing any edits made here).
'
Level1:
' Level 1: the station. Exit: behind the red doors, in the pipe room.
DATA "SECTOR 1: NEON STATION"
DATA "wall.png", "wall2.png", "wall-concrete.png", "wall-servers.png", "wall-pipes.png", "wall-biolab.png"
DATA "floor.png", "floor-plates.png", "floor-concrete.png", "floor-lab.png"
DATA "ceiling.png", "ceiling-lights.png"
DATA 5
DATA 19, 19, 28, 28, 2, 1, 0
DATA 5, 5, 21, 21, 3, 2, 0
DATA 26, 5, 42, 21, 2, 2, 0
DATA 30, 26, 42, 42, 4, 2, 0
DATA 30, 30, 42, 42, 2, 0, 3
DATA "################################################"
DATA "################################################"
DATA "###/.......................................+\###"
DATA "##/..........................................\##"
DATA "##..CCCCHCCCCCCCCCCCCCC..KKKKKKKKKYKKKKKKKKK..##"
DATA "##..C/....e\C.......a.C..K.................K..##"
DATA "##..C.......C.........C..Y..KKK......KKK...K..##"
DATA "##..C...m...H.........C..K.oo...g.......m..K..##"
DATA "##..C.......C.....g...H..Ka................K..##"
DATA "##..C.+.....C...2.....C..KKKDKKKKKKDKKKKKDKK..##"
DATA "##..C\...../C.........C..K......K......K...K..##"
DATA "##..CCCCHCCCCCCCCCCCCCC..K......K...g..K.+.K..##"
DATA "##..C...........aCCCCCC..K.K..K.K..K...Ke..K..##"
DATA "##..C.m.....o....CCCCCC..KtK..K.D..K...K...Y..##"
DATA "##..C............CCCCCC..K..m...K..K...K...K..##"
DATA "##..C...C....C...CCCCCC..K......K......K.m.K..##"
DATA "##..H.....y......CCCCCC..K......K......K...K..##"
DATA "##..C............CCCCCC..KKKKKKKKKKDKKKKKKKK..##"
DATA "##..C...C....C...CNNNNNXNNNNNNK............K..##"
DATA "##..C..e.........CNN/......\NNK.........b..K..##"
DATA "##..C..........h.CN/..a...p.\NK..h...3.....K..##"
DATA "##..C............CN..N....N..NK............K..##"
DATA "##..CCCCCCHCCCCCCCN..........NKKKKKKKKYKKKKK..##"
DATA "##................X..........X................##"
DATA "##................N.>........N..............e.##"
DATA "##..PPPPPPRPPPPPPPN..........NGGGGGGBGGGGGGG..##"
DATA "##..PP/.........aPN..N....N..Na............G..##"
DATA "##..P/...........PN\.p.....+/N.i..e........G..##"
DATA "##..P..m.........PNN\....../NN.g...........G..##"
DATA "##..P....P..P....PNNNNNXNNNNNN...G.....G...G..##"
DATA "##..R............EP.........aG...........g.G..##"
DATA "##..P.........g..PP..........G......s......G..##"
DATA "##..P.........../PP..........G.............G..##"
DATA "##..P........../PPP..........G.............G..##"
DATA "##..PPPPHPPPPPPPPPP..........G...G..r..G...B..##"
DATA "##..P............PP..........G.............G..##"
DATA "##..P.+u.........PP..........B.............G..##"
DATA "##..P............PP...m......G....../\.....G..##"
DATA "##..P....P..P....PP..........G......\/.....G..##"
DATA "##..P............PP..........G...G.....G...G..##"
DATA "##..P.h...c.c....PP........g.G......h......G..##"
DATA "##..P...e......m.PP..........G.m...........G..##"
DATA "##..P............PP+.........G............+G..##"
DATA "##..PPPPPPPPRPPPPPPPPPPPPHPPPGGGGGGGBGGGGGGG..##"
DATA "##\........................................../##"
DATA "###\a......................................a/###"
DATA "################################################"
DATA "################################################"

Level2:
' Level 2: the reactor. Red key in the storage bay (west), yellow and
' blue in the coolant wing (east, red door); the exit is in the control
' room (north, yellow door); the armoury (south-east, blue) has the railgun.
DATA "SECTOR 2: REACTOR CORE"
DATA "wall-reactor.png", "wall-coils.png", "wall-rusty.png", "wall-control.png", "wall-hazard.png", "wall-stripes.png"
DATA "floor-glow.png", "floor-scorched.png", "floor-hazard.png", "floor-plates.png"
DATA "ceiling-vents.png", "ceiling-warning.png"
DATA 11
DATA 15, 15, 32, 32, 1, 2, 0
DATA 15, 15, 22, 22, 3, 0, 1
DATA 25, 15, 32, 22, 3, 0, 2
DATA 25, 25, 32, 32, 3, 0, 3
DATA 15, 25, 22, 32, 3, 0, 4
DATA 3, 3, 13, 33, 2, 1, 0
DATA 34, 3, 45, 33, 4, 1, 0
DATA 34, 3, 45, 14, 1, 0, 2
DATA 15, 3, 32, 13, 4, 2, 0
DATA 3, 35, 45, 45, 2, 1, 0
DATA 39, 35, 45, 45, 3, 2, 0
DATA "################################################"
DATA "################################################"
DATA "##CCCCCCCCCCCCKKKKKKKKKKEKKKKKKKKKPPPPPPPPPPPPP#"
DATA "##CC/.......\CKKK/............\KKKP/........\PP#"
DATA "##C/.........\KK/.......+......\KK/..........\P#"
DATA "##C.......oo..K/.t............t.\K......y.....P#"
DATA "##C..r....o...K..................K..s.........P#"
DATA "##C...........K....K........K....K.../\.......P#"
DATA "##C...........K....K....h...K....K...\/.......P#"
DATA "##C.....e.....K....K........K....K............P#"
DATA "##C...........K..................K......./\...P#"
DATA "##C...........K\..g...........g./K...a...\/...P#"
DATA "##C..oo.......KK\....t.....t.../KK..........s.P#"
DATA "##C...........KKK\............/KKK.../\.......P#"
DATA "##C...........KKKKKKKKKKYKKKKKKKKK...\/.......P#"
DATA "##C...........NNNNN/........\NNNNN............P#"
DATA "##C...........NNNN/..........\NNNN......./\...P#"
DATA "##C...........NNN/......a.....\NNN..o....\/m..P#"
DATA "##C...c..c....NN/...g..........\NN..o.........P#"
DATA "##C...........N/................\N.../\.......P#"
DATA "##C........o..N...............m..N...\/.......P#"
DATA "##C........o..N......../\........N............P#"
DATA "##C...........N..o..../NN\.......N......./\...P#"
DATA "##C...........N....../NNNN\......N......g\/...P#"
DATA "##C....c......D......\NNNN/......R..........o.P#"
DATA "##C...........N.......\NN/.......N.../\.......P#"
DATA "##C...........N...m....\/......o.N...\/.......P#"
DATA "##C...........N..................N............P#"
DATA "##C.o.....h...N\................/N......./\...P#"
DATA "##C...........NN\............../NN.......\/...P#"
DATA "##C...........NNN\..........g./NNN..s......b..P#"
DATA "##C.+.......u.NNNN\.....+..../NNNN............P#"
DATA "##C\........./NNNNN\......../NNNNN\.........e/P#"
DATA "##CC\......./CNNNNNNNNNNXNNNNNNNNNP\......../PP#"
DATA "##GGGGGGHGGGGGGGGGGGGGGG.GGGGGGGGGGGGGGGGGGGGGG#"
DATA "##G...................................GG/...\GG#"
DATA "##G...................................G/.....\G#"
DATA "##G...a.....m......i.........i.e......G.u.....G#"
DATA "##G...................................G.......G#"
DATA "##G.......G.....G.....G.....G.....G...G.......G#"
DATA "##G.......G.....G.....G.....G.....G...B...4...G#"
DATA "##G...................................G.......G#"
DATA "##G.............................m.....G.......G#"
DATA "##G..........+......c...^.c...........G..a..*.G#"
DATA "##G..oo.............................o.G\...../G#"
DATA "##G...................................GG\.../GG#"
DATA "##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#"
DATA "################################################"

Level3:
' Level 3: the sewers - one long tunnel at 45 degrees with water down its
' middle. Red key in the nest (left), yellow in the pump hall (red door),
' blue in the cistern; the exit is in the outflow (yellow door).
DATA "SECTOR 3: UNDERCITY"
DATA "wall-brick.png", "wall-graffiti.png", "wall-moss.png", "wall-grate.png", "wall-greenpipes.png", "wall-slime.png"
DATA "floor-cobbles.png", "floor-murky.png", "floor-rustgrate.png", "floor-concrete.png"
DATA "ceiling-stone.png", "ceiling-pipes.png"
DATA 9
DATA 2, 3, 44, 45, 2, 0, 2
DATA 3, 2, 45, 44, 1, 0, 2
DATA 12, 3, 22, 7, 4, 2, 0
DATA 26, 3, 45, 14, 3, 2, 0
DATA 34, 18, 45, 28, 2, 1, 0
DATA 3, 12, 7, 22, 4, 1, 0
DATA 3, 26, 14, 45, 2, 1, 0
DATA 3, 26, 14, 37, 4, 0, 1
DATA 18, 34, 28, 45, 3, 2, 0
DATA "################################################"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CCCCCCCCCC#############PPPPPPPPPPPPPPPPPPPPPPP#"
DATA "#CC...\CCCC#...........#PPPP/..............\PPP#"
DATA "#CC....\CCC#..u.....g..#PPP/................\PP#"
DATA "#CC..>....D.......e....#PP/..oo...h........y.\P#"
DATA "#CC\.....\C#....o....a.#PP..g.................P#"
DATA "#CCC\.....\#...........#PP..../\.../\.../\....P#"
DATA "#CCCC\.....\############PP....\/...\/...\/....P#"
DATA "#CCCCC\..c..\CCCCCCCCCCPPP....................P#"
DATA "#CCCCCC\............R.......................s.P#"
DATA "#CCCCCCC\i....\CCCCCCCCPPP....................P#"
DATA "#CC.....C\.....\CCCCCCCPPP\t.....t....g...a../P#"
DATA "#CC.....D.....c.\CCCCCCPPPP\................/PP#"
DATA "#CC..+..CCC\.....\CCCCCPPPPP\............../PPP#"
DATA "#CC.c...CCCC\o....\CCCCPPPPPPPPPPPPPPPPP.PPPPPP#"
DATA "#CC.....CCCCC\....i\CCCCCCCCCCCCCGGGGGGGHGGGGGG#"
DATA "#CC...c.CCCCCC\....a\CCCCCCCCCCCCGGGGGGG.GGGGGG#"
DATA "#CC.....CCCCCCC\.c...\CCCCCCCCCCCGG/........\GG#"
DATA "#CC.c...CCCCCCCC\.....\CCCCCCCCCCG/m........m\G#"
DATA "#CC...c.CCCCCCCCC\.....\CCCCCCCCCG............G#"
DATA "#CC..r..CCCCCCCCCC\...m.\CCCCCCCCG...../\.....G#"
DATA "#CC.....CCCCCCCCCCC\....i\CCCCCCCG..../GG\....G#"
DATA "#CCCCCCCCCCCCCCCCCCC\....o\CCCCCCG.e..\GG/....G#"
DATA "#CCCCCCCCCCCCCCCCCCCC\.........D.......\/.....G#"
DATA "#KKKKKKKKKKKKKKKCCCCCC\.....\CCCCG............G#"
DATA "#KKK/........\KKCCCCCCC\.....\CCCG............G#"
DATA "#KK/a.........\KCCCCCCCC\.....\CCG\.g.......b/G#"
DATA "#KK..........e......B......c...\CGG\......../GG#"
DATA "#KK............KCCCCCCCCCC\.....\GGGGGGGGGGGGGG#"
DATA "#KK............KCCCCCCCCCCC\.....\CCCCCCCCCCCCC#"
DATA "#KK...#....#...KCCCCCCCCCCCC\.m...\CCCCCCCCCCCC#"
DATA "#KK............KCCCCCCCCCCCCC\.....\CCCCCCCCCCC#"
DATA "#KK.....h......KCNNNNNNNNNNNNN\i....\CCCCCCCCCC#"
DATA "#KK............KCNN/.......\NNC\...c.\CCCCCCCCC#"
DATA "#KK............KCN/.........\NCC\.....\CCCCCCCC#"
DATA "#KK...#....#...KCN..h......g.NCCC\.....\CCCCCCC#"
DATA "#KK............KCN...........NCCCC\.o...\CCCCCC#"
DATA "#KK.....p......KCN.............Y........i\CCCCC#"
DATA "#KK............KCN...........NCCCCCC\.....\CCCC#"
DATA "#KK............KCN...........NCCCCCCC\c....\CCC#"
DATA "#KK...#....#...KCN......s....NCCCCCCCC\....+\CC#"
DATA "#KK......h.....KCN...........NCCCCCCCCC\.m...CC#"
DATA "#KK............KCN..........aNCCCCCCCCCC\....CC#"
DATA "#KK\*........u/KCN\+......../NCCCCCCCCCCC\.c.CC#"
DATA "#KKK\......../KKCNN\......./NNCCCCCCCCCCCCCCCCC#"
DATA "#KKKKKKKKKKKKKKKCNNNNNNENNNNNNCCCCCCCCCCCCCCCCC#"
DATA "################################################"

Level4:
' Level 4: the lab. A diamond atrium and four labs: SW (open) has the
' red key, NW (red) blue, SE (blue) yellow, and NE (yellow) the exit.
DATA "SECTOR 4: CRYO LAB"
DATA "wall-white.png", "wall-terminals.png", "wall-frost.png", "wall-tiles.png", "wall-cryo.png", "wall-ice.png"
DATA "floor-white.png", "floor-frostgrate.png", "floor-ice.png", "floor-lab.png"
DATA "ceiling-lights.png", "ceiling-frost.png"
DATA 11
DATA 2, 2, 45, 45, 2, 2, 0
DATA 12, 12, 36, 36, 1, 1, 0
DATA 16, 16, 32, 32, 4, 0, 0
DATA 16, 16, 23, 23, 1, 0, 1
DATA 25, 16, 32, 23, 1, 0, 2
DATA 25, 25, 32, 32, 1, 0, 3
DATA 16, 25, 23, 32, 1, 0, 4
DATA 3, 3, 15, 15, 4, 1, 0
DATA 33, 3, 45, 15, 1, 1, 0
DATA 3, 33, 15, 45, 4, 1, 0
DATA 33, 33, 45, 45, 3, 2, 0
DATA "################################################"
DATA "###############KKKKKKKKKKKKKKKKKPPPPPPPPPPPPPPPP"
DATA "###############KKKKKKKKKKKKKKKKKPPPPPPPEPPPPPPPP"
DATA "#####/.......\#KKK.............KPPP/.......\PPPP"
DATA "####/.........\KKK..i......c...KPP/.+.....a.\PPP"
DATA "###/.b......s..\KK.............KP/.....h.....\PP"
DATA "###.............KK.e..m.....i..KP.............PP"
DATA "###..............R.............Y.....P...P....PP"
DATA "###......h......KKKKKKKK.KKKKKKKP.............PP"
DATA "###.t...........KKKKKKKK.KKKKKKKP..s........s.PP"
DATA "###.............########X#######P.............PP"
DATA "###.........u...CCCCCCCC.CCCCCCCP....P...P....PP"
DATA "###...g.........CCCCCCC/.CCCCCCCP.............PP"
DATA "###\....a....t./CCCCCC/..\CCCCCCP\t....g....t/PP"
DATA "####\........./CCCCCC/....\CCCCCPP\........./PPP"
DATA "#KKKK\......./CCCCCC/...p..\CCCCPPP\......./PPPP"
DATA "#KKKKKK.KK#CCCCCCCC/........\CCCPPPPPPPPP.PPPPPP"
DATA "#KKKKKKRKK#CCCCCCC/..........\CCCCCCCC#KKYKKKKKK"
DATA "#KK.....KK#CCCCCC/......+.....\CCCCCCC#KK.....KK"
DATA "#KK.....KK#CCCCC/..............\CCCCCC#KK.....KK"
DATA "#KK.i...KK#CCCC/....g.......h...\CCCCC#KK...i.KK"
DATA "#KK.....KK#CCC/..................\CCCC#KK.+...KK"
DATA "#KK.....KK#CC/........./\.........\CCC#KK.....KK"
DATA "#KK.....KK#C/........./NN\.........\CC#KK.....KK"
DATA "#KK.g.....X....p..c...\NN/....c..p./..X.......KK"
DATA "#KK.....KK#CC\.........\/........./CCC#KK...g.KK"
DATA "#KK.....KK#CCC\................../CCCC#KK.....KK"
DATA "#KK.....KK#CCCC\................/CCCCC#KK.....KK"
DATA "#KK...i.KK#CCCCC\...s.......g../CCCCCC#KK.i...KK"
DATA "#KK..a..KK#CCCCCC\............/CCCCCCC#KK.....KK"
DATA "#KK.....KK#CCCCCCC\.....m..../CCCCCCCC#KK.....KK"
DATA "#KKKKKKDKK#CCCCCCCC\.....a../CCCCCCCCC#KKBKKKKKK"
DATA "#KKKKKK.KK#CCCCCCCCC\....../CCCCGGGGGGGGG.GGGGGG"
DATA "#KKKK/.......\CCCCCCC\..p./CCCCCGGG/.......\GGGG"
DATA "####/.........\CCCCCCC\../CCCCCCGG/.........\GGG"
DATA "###/.......t...\CCCCCCC\/CCCCCCCG/..h........\GG"
DATA "###..g..e.......CCCCCCCC.CCCCCCCG...........s.GG"
DATA "###.............CCCCCCCC.CCCCCCCG..a../\......GG"
DATA "###.............########X#######G..../GG\.....GG"
DATA "###.........m...KKKKKKKK.KKKKKKKG....\GG/.....GG"
DATA "###.t...........KKKKKKKK.KKKKKKKG.....\/...*..GG"
DATA "###..........+...D.............B..............GG"
DATA "###...r.........KK..i.m.....i..KG....c.....y..GG"
DATA "###\.........../KK......^......KG\.........../GG"
DATA "####\....c...c/KKK.a.........e.KGG\g......../GGG"
DATA "#####\......./#KKK.............KGGG\......./GGGG"
DATA "###############KKKKKKKKKKKKKKKKKGGGGGGGGGGGGGGGG"
DATA "###############KKKKKKKKKKKKKKKKKGGGGGGGGGGGGGGGG"

SUB LoadTex(f$, slot AS INTEGER)
    p$ = AssetPath$(f$)
    img& = _LOADIMAGE(p$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; p$ : SLEEP : SYSTEM
    t& = _NEWIMAGE(TEX, TEX, 32) : _PUTIMAGE, img&, t&
    _SOURCE t&
    FOR y = 0 TO TEX - 1 : FOR x = 0 TO TEX-1 : TEX(x, y, slot) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0 : _FREEIMAGE img& : _FREEIMAGE t&
END SUB

' Scale a 32-bit colour's RGB by s/256 (s = 0..256)
FUNCTION Shade~&(c AS _UNSIGNED LONG, S AS LONG)
    DIM rb AS _INTEGER64, g AS _INTEGER64
    rb = c AND &HFF00FF : g = c AND &HFF00&
    Shade~& = &HFF000000~& OR ((rb * S \ 256) AND &HFF00FF) OR ((g * S \ 256) AND &HFF00&)
END FUNCTION

' True if map point (x, y) is open floor or a mostly-open door (and not
' inside a decoration)
FUNCTION Walkable%(x, y)
    cX = INT(x) : cY = INT(y)
    IF diagK(cX, cY) THEN Walkable% = NOT DiagIn(diagK(cX, cY), x - cX, y - cY) : EXIT FUNCTION
    i = decoCell(cX, cY)
    IF i THEN
        IF (x - dcX(i)) ^ 2 + (y - dcY(i)) ^ 2 < DECO_R * DECO_R THEN EXIT FUNCTION
    END IF
    Walkable% = worldMap(cX, cY) <= 0 OR doorOffsets(cX, cY) > 0.8
END FUNCTION

' Is map point (x, y) inside a wall (doors don't count)?
FUNCTION SolidAt(x, y)
    cX = INT(x) : cY = INT(y)
    IF diagK(cX, cY) THEN SolidAt = DiagIn(diagK(cX, cY), x - cX, y - cY) ELSE SolidAt = IsWall(cX, cY)
END FUNCTION

' Is (u, v), a point inside a diagonal wall's cell (0-1 each way), in its
' solid half? k is the solid corner (see diagK).
FUNCTION DiagIn(k, u, v)
    SELECT CASE k
        CASE 1 : DiagIn = u + v < 1
        CASE 2 : DiagIn = u > v
        CASE 3 : DiagIn = u + v > 1
        CASE 4 : DiagIn = u < v
    END SELECT
END FUNCTION

' How far along a ray from (px, py) heading (rx, ry) it crosses the diagonal
' of the diagonal wall cell (cx, cy) with solid corner k, if that's between
' tIn and tOut (while the ray is inside the cell); -1 if it doesn't
FUNCTION DiagHit(k, cx, cy, px, py, rx, ry, tIn, tOut)
    DiagHit = -1
    IF k = 1 OR k = 3 THEN ' "/" : u + v = 1
        dn = rx + ry : IF dn = 0 THEN EXIT FUNCTION
        t = (cx + cy + 1 - px - py) / dn
    ELSE ' "\" : u = v
        dn = rx - ry : IF dn = 0 THEN EXIT FUNCTION
        t = (cx - cy - px + py) / dn
    END IF
    IF t >= tIn AND t <= tOut THEN DiagHit = t
END FUNCTION

' Is the edge from (x1, y1) to (x2, y2) clear? Checks both ends and the
' middle (the middle catches the point of a diagonal wall poking in between).
FUNCTION EdgeFree(x1, y1, x2, y2)
    EdgeFree = Walkable(x1, y1) AND Walkable(x2, y2) AND Walkable((x1 + x2) / 2, (y1 + y2) / 2)
END FUNCTION

' Is a body (radius PLAYER_R) at (x, y) clear of walls all round?
FUNCTION BoxFree(x, y)
    r = PLAYER_R
    BoxFree = EdgeFree(x - r, y - r, x + r, y - r) AND EdgeFree(x - r, y + r, x + r, y + r) AND Walkable(x - r, y) AND Walkable(x + r, y)
END FUNCTION

' Any diagonal wall in the 3 x 3 cells around (x, y)?
FUNCTION NearDiag(x, y)
    FOR cY = INT(y) - 1 TO INT(y) + 1 : FOR cX = INT(x) - 1 TO INT(x) + 1
        IF diagK(cX, cY) THEN NearDiag = -1 : EXIT FUNCTION
    NEXT : NEXT
END FUNCTION

' Move a body (radius PLAYER_R) at (x, y) by (mx, my). One axis at a time, so
' it slides along walls; stopped dead by a diagonal wall, it slides along that.
SUB MoveBody(x, y, mx, my)
    ox = x : oy = y
    ex = x + mx + SGN(mx) * PLAYER_R
    IF EdgeFree(ex, y - PLAYER_R, ex, y + PLAYER_R) THEN x = x + mx
    ey = y + my + SGN(my) * PLAYER_R
    IF EdgeFree(x - PLAYER_R, ey, x + PLAYER_R, ey) THEN y = y + my
    IF x = ox AND y = oy AND (mx <> 0 OR my <> 0) AND NearDiag(x, y) THEN
        FOR sl = -1 TO 1 STEP 2 ' The move along each 45 degree line, (1, sl)
            pr = (mx + my * sl) / 2
            IF BoxFree(x + pr, y + pr * sl) THEN x = x + pr : y = y + pr * sl : EXIT SUB
        NEXT
    END IF
END SUB

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
    r! = _RED32(c) * (1 - a!) + _RED32(t) * lum! * a!
    g! = _GREEN32(c) * (1 - a!) + _GREEN32(t) * lum! * a!
    b! = _BLUE32(c) * (1 - a!) + _BLUE32(t) * lum! * a!
    IF r! > 255 THEN r! = 255
    IF g! > 255 THEN g! = 255
    IF b! > 255 THEN b! = 255
    Tint~& = _RGBA32(r!, g!, b!, _ALPHA32(c))
END FUNCTION

' A sprite from neon-caster/ into sprTex slot (its size up to SPR_TEX)
SUB LoadSprite(f$, slot)
    p$ = AssetPath$(f$)
    img& = _LOADIMAGE(p$, 32)
    IF img& >= -1 THEN PRINT "Missing texture: "; p$ : SLEEP : SYSTEM
    sz = _WIDTH(img&) : IF sz > SPR_TEX THEN sz = SPR_TEX
    sprSz(slot) = sz
    _SOURCE img&
    FOR y = 0 TO sz - 1 : FOR x = 0 TO sz-1
        sprTex(x, y, slot) = POINT(x * _WIDTH(img&) \ sz, y * _HEIGHT(img&) \ sz)
    NEXT : NEXT
    _SOURCE 0 : _FREEIMAGE img&
END SUB

' The keycard sprite, tinted red / blue / yellow (sprite slots 1-3 and HUD
' images), and the key door textures (the door tinted the same way)
SUB LoadCards(f$)
    LoadSprite f$, 1
    sz = sprSz(1)
    FOR k = 1 TO 3
        sprSz(k) = sz
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
    n = INT(D / 0.1) + 1
    FOR i = 1 TO n
        cX = INT(x1 + dx * i / n) : cY = INT(y1 + dy * i / n)
        IF SolidAt(x1 + dx * i / n, y1 + dy * i / n) THEN EXIT FUNCTION
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
    COLOR c~& : _PRINTSTRING (x, y), t$
END SUB

' Big centred text: printed small, then scaled up
SUB BigText(t$, y, scale, c~&)
    W = LEN(t$) * 8
    t& = _NEWIMAGE(w, 16, 32)
    _DEST t& : _PRINTMODE _KEEPBACKGROUND
    COLOR _RGB32(0, 0, 0) : _PRINTSTRING (1, 1), t$
    COLOR c~& : _PRINTSTRING (0, 0), t$
    _DEST 0
    _PUTIMAGE (400 - W * scale \ 2, y)-STEP(W * scale - 1, 16 * scale-1), t&
    _FREEIMAGE t&
END SUB

' Any kind of wall (not a door, not floor)?
FUNCTION IsWall(x, y)
    v = worldMap(x, y)
    IsWall = v > 0 AND v <> 2
END FUNCTION

' A monster type's numbers (see the table in the main program)
SUB SetMonType(t, n$, hp, speed, scale, lift, bob, reach, dmg, dmgRnd, cool, slot)
    mtName$(t) = n$ : mtHP(t) = hp : mtSpeed(t) = speed : mtScale(t) = scale
    mtLift(t) = lift : mtBob(t) = bob : mtReach(t) = reach
    mtDmg(t) = dmg : mtDmgRnd(t) = dmgRnd : mtCool(t) = cool : mtSlot(t) = slot
END SUB

' A gunner's energy bolt, from (x, y) heading (dx, dy)
SUB FireBolt(x, y, dx, dy, dmg)
    FOR i = 1 TO MAX_BOLTS
        IF bOn(i) = 0 THEN
            bOn(i) = -1 : bX(i) = x + dx * 0.4 : bY(i) = y + dy * 0.4
            bDX(i) = dx : bDY(i) = dy : bDmg(i) = dmg
            EXIT SUB
        END IF
    NEXT
END SUB

' The bolt sprite: a hard-edged glowing magenta ball, white hot in the middle
SUB MakeBolt(slot)
    sprSz(slot) = 16
    FOR y = 0 TO 15 : FOR x = 0 TO 15
        D = SQR((x - 7.5) ^ 2 + (y-7.5) ^ 2) / 7.5
        IF D < 0.45 THEN
            sprTex(x, y, slot) = _RGB32(255, 240, 255)
        ELSEIF D < 0.75 THEN
            sprTex(x, y, slot) = _RGB32(255, 110, 235)
        ELSEIF D < 1 THEN
            sprTex(x, y, slot) = _RGB32(200, 30, 200)
        ELSE
            sprTex(x, y, slot) = 0
        END IF
    NEXT : NEXT
END SUB

' Gun w's first-person picture, and where its muzzle is: the middle of the
' top-most row that's at least MUZ_MIN solid pixels wide (so a thin sight
' post sticking up above the barrel doesn't count)
SUB LoadGun(w, f$)
    CONST MUZ_MIN = 4
    p$ = AssetPath$(f$)
    wpImg&(W) = _LOADIMAGE(p$, 32)
    IF wpImg&(W) >= -1 THEN PRINT "Missing texture: "; p$: SLEEP: SYSTEM
    _SOURCE wpImg&(W)
    gw = _WIDTH(wpImg&(W)) : gh = _HEIGHT(wpImg&(W))
    FOR y = 0 TO gh - 1
        bestN = 0 : n = 0
        FOR x = 0 TO gw ' (one past the edge, to end a run touching it)
            solid = 0
            IF x < gw THEN solid = _ALPHA32(POINT(x, y)) > 128
            IF solid THEN
                n = n + 1
            ELSE
                IF n > bestN THEN bestN = n : runEnd = x - 1
                n = 0
            END IF
        NEXT
        IF bestN >= MUZ_MIN THEN EXIT FOR
    NEXT
    _SOURCE 0
    IF bestN < MUZ_MIN THEN y = 0 : runEnd = gw / 2 : bestN = 1
    wpMuzX(W) = (runEnd - bestN / 2 + 1) / gw : wpMuzY(W) = (y + 0.5) / gh
END SUB

' Add n of ammo kind k, up to the most you can carry. FALSE if already full.
FUNCTION GiveAmmo%(k, n)
    IF ammoN(k) >= ammoMax(k) THEN EXIT FUNCTION
    ammoN(k) = ammoN(k) + n
    IF ammoN(k) > ammoMax(k) THEN ammoN(k) = ammoMax(k)
    GiveAmmo% = -1
END FUNCTION

' A gun's numbers (see the table in the main program)
SUB SetGun(w, n$, ammo, cost, delay, pellets, spread, dmg, pierce, kick)
    wpName$(w) = n$ : wpAmmo(w) = ammo : wpCost(w) = cost : wpDelay(w) = delay
    wpPellets(w) = pellets : wpSpread(w) = spread : wpDmg(w) = dmg : wpPierce(w) = pierce : wpKick(w) = kick
END SUB

' Pickup kind k's sprite slot
FUNCTION ItemSlot(k)
    IF k <= IT_REPEATER THEN ItemSlot = k ELSE ItemSlot = 16 + k
END FUNCTION

' How tall decoration kind k stands (in walls)
FUNCTION DecoScale(k)
    SELECT CASE k
        CASE 1 : DecoScale = 0.45 ' Barrel
        CASE 2 : DecoScale = 0.85 ' Lamp
        CASE 3 : DecoScale = 0.6 ' Plant
        CASE ELSE : DecoScale = 0.55 ' Terminal
    END SELECT
END FUNCTION

' A texture's average colour, a little brighter (for the minimap)
FUNCTION MapCol~&(slot)
    FOR y = 0 TO TEX - 1 STEP 2 : FOR x = 0 TO TEX - 1 STEP 2
        c~& = TEX(x, y, slot) : r& = r& + _RED32(c~&) : g& = g& + _GREEN32(c~&) : b& = b& + _BLUE32(c~&) : n& = n& + 1
    NEXT : NEXT
    MapCol~& = _RGB32(r& / n& * 1.4, g& / n& * 1.4, b& / n& * 1.4)
END FUNCTION

' Print "EXIT" on a lit sign at the top of the exit door's texture
SUB ExitSign
    t& = _NEWIMAGE(TEX, TEX, 32)
    _DEST t&
    FOR y = 0 TO TEX - 1 : FOR x = 0 TO TEX - 1 : PSET (x, y), TEX(x, y, T_EXIT) : NEXT : NEXT
    LINE (13, 5)-(50, 24), _RGB32(10, 40, 20), BF
    LINE (13, 5)-(50, 24), _RGB32(60, 255, 120), B
    _PRINTMODE _KEEPBACKGROUND : COLOR _RGB32(110, 255, 150) : _PRINTSTRING (16, 7), "EXIT"
    _SOURCE t&
    FOR y = 0 TO TEX - 1 : FOR x = 0 TO TEX - 1 : TEX(x, y, T_EXIT) = POINT(x, y) : NEXT : NEXT
    _SOURCE 0 : _DEST 0 : _FREEIMAGE t&
END SUB

' One line of the level-done tally: a label, and its number on the right
SUB TallyLine(y, l$, v$)
    HudText 270, y, l$, _RGB32(160, 200, 255)
    HudText 530 - LEN(v$) * 8, y, v$, _RGB32(255, 255, 255)
END SUB

' Seconds as m:ss
FUNCTION TimeText$(t!)
    m = INT(t! / 60) : sec = INT(t!) MOD 60
    TimeText$ = LTRIM$(STR$(m)) + ":" + RIGHT$("0" + LTRIM$(STR$(sec)), 2)
END FUNCTION
