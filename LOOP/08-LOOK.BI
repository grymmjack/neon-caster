''
' NEON-CASTER - LOOP/08-LOOK.BI
' =============================================================================
' Chapter 8 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 8: LOOKING AROUND
    '-------------------------------------------------------------------------
    ' Where you are and which way you face are two pairs of numbers:
    '
    '   (playerX, playerY)  your position on the map
    '   (dirX, dirY)        a direction one cell long, the way you face
    '   (planeX, planeY)    the "camera plane": a short line at right angles
    '                       to dirX, dirY. It's the screen, laid flat in the
    '                       world - its left end is the left edge of what
    '                       you see, its right end the right edge.
    '
    ' Which way is right? On our map y grows DOWNWARD (row 0 of a level file
    ' is the top, the north), so your right is your direction turned a
    ' quarter clockwise: (-dirY, dirX). Facing east, (1, 0), your right is
    ' (0, 1): south, down the map. The classic raycaster this follows has
    ' (dirY, -dirX) - right for a map whose y grows UPWARD - and with ours
    ' that showed the world mirrored: facing east, the north on your right,
    ' and the map's arrow turning the wrong way as you turned. So the plane
    ' is (-dirY, dirX), turning right is a positive angle, and D strafes
    ' along (-dirY, dirX).
    '
    '              plane          The rays for the screen's columns go from
    '      <------------------>   you through points along the plane. Its
    '       \        |       /    length (fovPlane, 0.66 each side of
    '        \       | dir  /     dir) makes the view 66 degrees wide:
    '         \      |     /      a longer plane is a wider, fish-eye view.
    '          \     |    /
    '              you
    '
    ' Turning is rotating both pairs by the same small angle. The rotation
    ' formula for turning a point (x, y) by angle a is:
    '   newX = x * COS(a) - y * SIN(a)
    '   newY = x * SIN(a) + y * COS(a)
    ' (oldDirX keeps dirX's old value, since newY needs it after dirX changed.)
    ' The field of view is a setting (chapter 21): fovPlane is TAN of half
    ' the angle, which is how long the plane must be to see that wide.
    '
    ' The mouse: the pointer is captured (chapter 1), so we add up how far
    ' it moved since the last frame. QB64PE queues every mouse event;
    ' WHILE _MOUSEINPUT reads them all, one at a time, until the queue is
    ' empty. A click that starts and ends between two frames would be
    ' missed by just checking the button, so "clicked" remembers it.
    IF artWant <> artNow THEN ArtReload ' (ART or the renderer changed: chapter 23)
    mouseDX = 0 : mouseDY = 0 : mouseWheel = 0
    WHILE _MOUSEINPUT
        mouseDX = mouseDX + _MOUSEMOVEMENTX : mouseDY = mouseDY + _MOUSEMOVEMENTY
        mouseWheel = mouseWheel + _MOUSEWHEEL
        IF _MOUSEBUTTON(1) THEN clicked = -1
        IF _MOUSEBUTTON(1) AND NOT edQ1 AND editMode AND editView = 1 AND NOT hudEdit THEN edClickL = -1 ' (edClick: the 3D editor's own - a press, not a button held while the mouse moves - kept until it looks: EditFP)
        IF _MOUSEBUTTON(2) AND NOT edQ2 AND editMode AND editView = 1 AND NOT hudEdit THEN edClickR = -1
        edQ1 = _MOUSEBUTTON(1) : edQ2 = _MOUSEBUTTON(2)
    WEND
    IF demoAttract AND (ABS(mouseDX) + ABS(mouseDY) > 3 OR clicked) THEN attractQuit = -1 ' (attract mode: the mouse moved - back to the menu, next frame)
    ' The 3D editor: the mouse is a pointer, free to point at anything (the
    ' face under it is picked - EditPick). Hold the right button to look
    ' round instead: the pointer is captured while you do (chapter 1). The
    ' wheel is the editor's (EditFP), not for changing guns.
    IF editMode AND editView = 1 AND NOT hudEdit THEN
        lookNow = _MOUSEBUTTON(2)
        IF lookNow <> edLooking OR edMouseFix THEN
            IF lookNow THEN _MOUSEHIDE _DISABLE ELSE _MOUSESHOW
            edLooking = lookNow : edMouseFix = 0
        END IF
        IF NOT edLooking THEN mouseDX = 0 : mouseDY = 0
        edWheel = edWheel + mouseWheel : mouseWheel = 0
        edCurX = WideMouseX(_MOUSEX) : edCurY = _MOUSEY
    END IF
    ' Keys go through the key bindings (chapter 21): KeyHeld(BIND_FIRE) asks
    ' "is the key you chose for firing held down?" - left Ctrl, unless you
    ' changed it in the menu.
    IF hudEdit THEN HudEditFrame : mouseDX = 0 : mouseDY = 0 : clicked = 0 ' (the HUD layout editor has the mouse - chapter 21)
    fireDown = _MOUSEBUTTON(1) OR clicked OR KeyHeld(BIND_FIRE)
    IF hudEdit THEN fireDown = 0
    IF conFire > 0 THEN conFire = conFire - 1 : fireDown = -1 ' (the console's fire: holding the trigger)
    clicked = 0
    spaceDown = KeyHeld(BIND_USE) AND NOT editMode ' (in the editor Space flies you up)
    IF conUse THEN conUse = 0 : spaceDown = -1 ' (the console's use: Space, once)

    ' Esc opens the menu (chapter 21), and the game waits while it's open
    escDown = _KEYDOWN(27) AND NOT hudEdit AND NOT edTyping
    IF escDown AND NOT escWas THEN
        menuInGame = -1 : RunMenu : edMouseFix = -1 ' (the menu captured the mouse: the editor's pointer back)
        mouseDX = 0 : mouseDY = 0 : mouseWheel = 0 : clicked = 0 : fireDown = 0 : spaceDown = 0
        fireWait = 15 ' (so the click that closed the menu doesn't fire)
    END IF
    escWas = _KEYDOWN(27) OR edTyping

    ' This frame's keys and buttons, as bits (inBits - DemoInput): yours -
    ' or, with a demo playing, the ones it recorded. Everything below asks
    ' inBits, not the keyboard, so a demo plays exactly as it was played.
    lookAim = (glMode <> 0) AND (setting(SET_LOOK) <> 0) ' (can a shot go high or low? OpenGL's LOOK UP / DOWN - a demo keeps its own)
    DemoInput

    IF dead THEN
        ' Dead: the view stays put; click or Space (after a moment) starts over
        IF deadTicks > 72 AND ((fireDown AND NOT fireWas) OR (spaceDown AND NOT spaceWas)) THEN RestartLevel
        mouseDX = 0 : mouseDY = 0 : mouseWheel = 0
    END IF

    ' Aiming down the sights: hold the right mouse button (_MOUSEBUTTON(2)).
    ' aimAmount slides from 0 (hip) to 1 (aimed) over ADS_FRAMES frames, so
    ' the zoom and the gun ease in and out instead of snapping.
    IF (inBits AND DB_AIM) <> 0 AND NOT dead AND NOT hudEdit AND NOT editMode THEN aimTarget = 1 ELSE aimTarget = 0
    IF swapTimer > 0 THEN aimTarget = 0 ' Changing guns: lower it (no jump in zoom)
    IF aimAmount < aimTarget THEN aimAmount = aimAmount + 1 / ADS_FRAMES : IF aimAmount > 1 THEN aimAmount = 1
    IF aimAmount > aimTarget THEN aimAmount = aimAmount - 1 / ADS_FRAMES : IF aimAmount < 0 THEN aimAmount = 0
    zoom = 1 + (gunZoom(currentGun) - 1) * aimAmount ' (each gun zooms its own amount)

    mouseDX = mouseDX / DisplayScale! ' The same turn speed in a window or full screen
    ' (slower when zoomed, so aiming stays steady - and slower still the
    ' more you're aiming, by AIM SENSITIVITY)
    aimSlow = 1 - aimAmount * (1 - setting(SET_AIMSENS) / 100)
    turn = mouseDX * turnSpeed / zoom * aimSlow ' (the mouse to the right turns you clockwise - as the map shows it: its y grows downward)
    IF botOn AND NOT demoPlay AND NOT editMode THEN turn = botTurn ' (the autopilot turns you)
    IF demoPlay THEN turn = inTU * DEMO_TURN ELSE IF demoRec THEN inTU = CLNG(turn / DEMO_TURN) : turn = inTU * DEMO_TURN ' (a demo's turn: a whole number of steps, played as written)
    oldDirX = dirX : dirX = dirX * DCos(turn) - dirY * DSin(turn) : dirY = oldDirX * DSin(turn) + dirY * DCos(turn)
    oldPlaneX = planeX : planeX = planeX * DCos(turn) - planeY * DSin(turn) : planeY = oldPlaneX * DSin(turn) + planeY * DCos(turn)

    ' Looking up and down - only with OpenGL (chapter 24), which can tilt
    ' its camera; the raycaster's world has no up or down to look at
    ' (LOOK UP / DOWN in SETTINGS > VIDEO). Moving the mouse forward looks
    ' up, as far as 0.6 radians (about 34 degrees) each way. Shots still go
    ' straight ahead: like Doom, whatever's in the middle column is hit,
    ' high or low. Otherwise the view eases back to level.
    IF glMode AND setting(SET_LOOK) AND NOT dead THEN
        pitch = pitch - mouseDY / DisplayScale! * turnSpeed / zoom * aimSlow
        IF botOn AND NOT demoPlay AND NOT editMode THEN pitch = pitch + MaxOf(-0.035, MinOf(0.035, (botPitch - pitch) * 0.25)) ' (the autopilot looks up and down too, eased)
        IF pitch > 0.6 THEN pitch = 0.6
        IF pitch < -0.6 THEN pitch = -0.6
    ELSE
        pitch = pitch * 0.8
    END IF
    IF demoPlay THEN pitch = inPU / 1000 ELSE IF demoRec THEN inPU = CLNG(pitch * 1000) : pitch = inPU / 1000 ' (and its look up or down, in thousandths)
    IF demoRec THEN DemoWriteFrame
    IF demoTrace AND (demoRec OR demoPlay) THEN DemoTraceOut ' (NEON_DEMO_TRACE: the game's state each frame, into the log - two runs' logs side by side show where they part)

    ' Zooming. The camera plane's length sets how wide the view is, so a
    ' shorter plane (fovPlane / zoom) is a narrower view - and a narrower
    ' view stretched across the same screen is a zoom. The plane is always
    ' your direction turned 90 degrees, so we can simply rebuild it from
    ' dirX, dirY at the new length (it's the same direction the rotation
    ' above gave it). Everything must also get taller by the same amount, or
    ' the picture would only stretch sideways: viewH is how many pixels tall
    ' a wall one cell away is drawn, and the floor, walls and sprites
    ' (chapters 14-16) all use it.
    planeX = -dirY * fovPlane / zoom : planeY = dirX * fovPlane / zoom
    viewH = RENDER_H * zoom

    ' Guns: 1 / 2 / 3 / 4, or the mouse wheel through the ones you have.
    ' Swapping takes SWAP_FRAMES: the gun dips out of sight, changes at the
    ' halfway point, and comes back up (the drawing is in chapter 18).
    wantGun = 0
    IF inBits \ DB_GUN THEN wantGun = inBits \ DB_GUN ' (1 to 4, held - by place: Shift + 1 types "!", and you might be running)
    IF mouseWheel <> 0 THEN ' (a notch a gun - from the one coming up, if a swap's still lowering the last)
        wantGun = currentGun : IF swapTimer > SWAP_FRAMES \ 2 THEN wantGun = nextGun
        FOR notch = 1 TO MinOf(ABS(mouseWheel), NUM_GUNS)
            DO
                wantGun = wantGun + SGN(mouseWheel) : IF wantGun > NUM_GUNS THEN wantGun = 1
                IF wantGun < 1 THEN wantGun = NUM_GUNS
            LOOP UNTIL hasGun(wantGun)
        NEXT
    END IF
    IF editMode THEN wantGun = 0 ' (in the editor 1-8 are the lights')
    IF wantGun > 0 AND wantGun <> currentGun AND swapTimer = 0 THEN
        IF hasGun(wantGun) THEN nextGun = wantGun : swapTimer = SWAP_FRAMES
    ELSEIF wantGun > 0 AND swapTimer > SWAP_FRAMES \ 2 THEN
        IF hasGun(wantGun) THEN nextGun = wantGun ' (changed your mind while it's lowering)
    END IF
    IF swapTimer > 0 THEN
        swapTimer = swapTimer - 1
        IF swapTimer = SWAP_FRAMES \ 2 THEN currentGun = nextGun ' (while it's out of sight)
    END IF

    IF numLifts THEN MoveLifts playerX, playerY ' (the lifts move - you ride them: chapter 22)
