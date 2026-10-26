''
' NEON-CASTER - LOOP/17-SCREEN.BI
' =============================================================================
' Chapter 17 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 17: ONTO THE SCREEN
    '-------------------------------------------------------------------------
    ' The view is finished in pixels(). _MEMCOPY copies the whole array into
    ' renderImg& in one go (an image's pixels are stored the same way: row
    ' after row of colours), and _PUTIMAGE stretches that 400 x 300 image
    ' over the 800 x 600 window - drawing at half size and scaling up is the
    ' easiest speed-up there is, and it gives the chunky look for free.
    '
    ' Screen shake: firing, getting hurt and explosions add to "shake",
    ' which dies away a little every frame. While it's going, the view is
    ' drawn a few pixels off in a random direction each frame - and a
    ' little bigger than the window, so no gap shows at the edges. (It can
    ' be switched off in the menu's settings - some people find it makes
    ' them feel ill.)
    shakeX = 0 : shakeY = 0 : shakeEdge = 0
    IF shake > 0.3 AND setting(SET_SHAKE) THEN
        shakeEdge = shake : shakeX = (RND - 0.5) * shake : shakeY = (RND - 0.5) * shake
    END IF
    shake = shake * 0.85 : IF shake > 16 THEN shake = 16
    '
    ' Where the gun goes this frame. It's drawn in chapter 18, over the view
    ' - but placed now, so OpenGL's snapshot (below) can take it along.
    '
    ' The gun is lit by where you stand: the light round you (LightAt), in
    ' its colour - plus your muzzle flash, if OpenGL's moving lights took it
    ' out of the cells (chapter 14) - its colour made a little stronger
    ' (GUN_TINT: the level's light is mostly white, which would wash it
    ' out). It follows the light a fifth of the
    ' way each frame, so it eases rather than flickers, and never goes
    ' darker than GUN_DARKEST (it's right in front of your eyes) or brighter
    ' than GUN_BRIGHTEST.
    LightAt playerX, playerY, wantR, wantG, wantB
    IF glMode AND setting(SET_DYNLIGHT) <> 0 AND muzzleFlash > 0 THEN
        wantR = wantR + 70 * muzzleFlash : wantG = wantG + 40 * muzzleFlash : wantB = wantB + 40 * muzzleFlash
    END IF
    IF chargeT > 0 THEN ' (CHARGED SHOTS: the charge lights the gun, in its colour)
        chgF = chargeT / CHARGE_FULL
        IF currentGun = W_RAIL THEN wantR = wantR + 40 * chgF : wantG = wantG + 80 * chgF : wantB = wantB + 100 * chgF ELSE wantR = wantR + 100 * chgF : wantG = wantG + 25 * chgF : wantB = wantB + 60 * chgF
    END IF
    wantR = wantR / 256 : wantG = wantG / 256 : wantB = wantB / 256
    grey = (wantR + wantG + wantB) / 3 ' (its colour pushed further from grey - GUN_TINT - so a coloured light shows)
    wantR = grey + (wantR - grey) * GUN_TINT : wantG = grey + (wantG - grey) * GUN_TINT : wantB = grey + (wantB - grey) * GUN_TINT
    IF wantR < GUN_DARKEST THEN wantR = GUN_DARKEST
    IF wantG < GUN_DARKEST THEN wantG = GUN_DARKEST
    IF wantB < GUN_DARKEST THEN wantB = GUN_DARKEST
    IF wantR > GUN_BRIGHTEST THEN wantR = GUN_BRIGHTEST
    IF wantG > GUN_BRIGHTEST THEN wantG = GUN_BRIGHTEST
    IF wantB > GUN_BRIGHTEST THEN wantB = GUN_BRIGHTEST
    gunLightR = gunLightR + (wantR - gunLightR) * 0.2 : gunLightG = gunLightG + (wantG - gunLightG) * 0.2 : gunLightB = gunLightB + (wantB - gunLightB) * 0.2
    '
    ' The gun sways as you walk (bobPhase, from chapter 9), kicks when it
    ' fires (recoil, which shrinks a quarter every frame), and dips out of
    ' sight to swap.
    IF recoil > 0 THEN recoil = recoil * 0.75 : IF recoil < 0.02 THEN recoil = 0
    gunImage& = gunImg&(currentGun)
    ' Aiming (aimAmount, chapter 8) blends the gun from where it hangs at
    ' your hip up to your eye: bigger, its muzzle risen to ADS_MUZZLE_Y just
    ' under the crosshair, and hardly swaying. Its picture must still reach
    ' past the bottom of the screen, or it would float: a gun whose muzzle
    ' is halfway down its picture has to grow more to get its muzzle up
    ' there, so "grow" is worked out per gun. hipY is where the gun sits
    ' with its bottom 12 pixels below the screen, and it never goes higher.
    gunH = gunSize(currentGun) : gunW = gunH * _WIDTH(gunImage&) / _HEIGHT(gunImage&)
    grow = (GUN_Y + 12 - ADS_MUZZLE_Y) / (1 - gunMuzzleY(currentGun)) / gunH ' Just tall enough
    IF grow < ADS_GUN_GROW THEN grow = ADS_GUN_GROW
    IF grow > ADS_GUN_GROW_MAX THEN grow = ADS_GUN_GROW_MAX
    grow = 1 + (grow - 1) * aimAmount
    gunW = gunW * grow : gunH = gunH * grow
    hipY = GUN_Y - gunH + 12 : eyeY = ADS_MUZZLE_Y - gunH * gunMuzzleY(currentGun)
    IF eyeY < hipY THEN eyeY = hipY ' (its bottom never comes up into view)
    sway = 1 - 0.8 * aimAmount
    IF setting(SET_BOB) = 0 THEN sway = 0 ' Weapon bobbing switched off (chapter 21)
    gunX = 400 - gunW * gunMuzzleX(currentGun) + COS(bobPhase / 2) * 10 * sway + shakeX
    gunY = hipY + (eyeY - hipY) * aimAmount + ABS(SIN(bobPhase / 2)) * 10 * sway + recoil * 36 + shakeY
    IF swapTimer > 0 THEN gunY = gunY + (SWAP_FRAMES / 2 - ABS(swapTimer - SWAP_FRAMES / 2)) * 40
    IF kickTimer > 0 THEN gunY = gunY + SIN((1 - kickTimer / KICK_FRAMES) * 3.14159) * 90 ' (kicking: the gun dips)
    IF dead THEN gunY = gunY + (TIMER - deadAt!) * 400 ' Drops out of view
    '
    ' With OpenGL (chapter 24) there's no picture to copy: instead we finish
    ' the snapshot - the camera, every cell's light, every door - and then
    ' switch glBuf over to it, in one line, so SUB _GL only ever sees a
    ' whole frame. The screen is cleared to see-through (alpha 0), so the
    ' graphics card's view shows from underneath (chapter 1) wherever the
    ' HUD below doesn't draw.
    IF glMode THEN
        glCamX(glWrite) = playerX : glCamY(glWrite) = playerY : glDirX(glWrite) = dirX : glDirY(glWrite) = dirY : glCamZ(glWrite) = eyeZ
        glPlaneLen(glWrite) = fovPlane / zoom : glZoom(glWrite) = zoom : glFullMode(glWrite) = _FULLSCREEN
        glShakeX(glWrite) = shakeX : glShakeY(glWrite) = shakeY : glShakeEdge(glWrite) = shakeEdge
        FOR i = 1 TO NUM_SETTINGS : glSet(i, glWrite) = setting(i) : NEXT
        glNight(glWrite) = nvOn ' (night vision: the post shader's)
        glFl(glWrite) = flNow ' (the flashlight: the world shader's - GLFlashUni)
        IF viewOn THEN glFl(glWrite) = 0 ' (not through a camera or your rocket: the lamp's in your hand)
        glPitch(glWrite) = pitch : glHurt(glWrite) = hurtFlash / 14 : glRail(glWrite) = railBeam / 8
        glGun(glWrite) = 0 : IF gunY < 600 AND NOT editMode AND viewOn = 0 THEN glGun(glWrite) = currentGun ' The gun (0: out of sight - and in the editor), where on our screen
        glGunX0(glWrite) = gunX : glGunY0(glWrite) = gunY : glGunX1(glWrite) = gunX + gunW : glGunY1(glWrite) = gunY + gunH
        glGunR(glWrite) = gunLightR : glGunG(glWrite) = gunLightG : glGunB(glWrite) = gunLightB
        glSideDim(glWrite) = 0 ' (the menu dims the sides of a wide view: GLLiveSettings)
        ' (tilted, or wide, the view sees past the rays' edges)
        wideK = WideView : glWide(glWrite) = wideK
        IF ABS(pitch) > 0.01 OR wideK > 1.01 THEN GLMarkWide playerX, playerY, dirX, dirY, fovPlane / zoom * wideK, zoom
        GLHandOverExtras playerX, playerY, dirX, dirY, muzzleFlash ' Moving lights, particles, explosions (chapter 24)
        FOR y = litY0 TO MinOf(mapN, litY1 + 1) : FOR x = litX0 TO MinOf(mapN, litX1 + 1) ' (the cells lit this frame: UpdateLight)
            glLitR(x, y, glWrite) = litR(x, y) : glLitG(x, y, glWrite) = litG(x, y) : glLitB(x, y, glWrite) = litB(x, y)
            glDoor(x, y, glWrite) = DoorShown(x, y)
            ' Bumps: the middle of the light on this cell (or the cell's own
            ' middle, if it has none), and how much of its light that is
            IF litSumW(x, y) > 0 THEN
                glLitCX(x, y, glWrite) = litSumX(x, y) / litSumW(x, y) : glLitCY(x, y, glWrite) = litSumY(x, y) / litSumW(x, y)
                glLitDir(x, y, glWrite) = litSumW(x, y) / (litR(x, y) + litG(x, y) + litB(x, y) + 1)
            ELSE
                glLitCX(x, y, glWrite) = x + 0.5 : glLitCY(x, y, glWrite) = y + 0.5 : glLitDir(x, y, glWrite) = 0
            END IF
            ' ...and the same into the light tables, for the graphics card
            ' (chapter 24) - only the map's cells: the rest stay 0
            IF x < mapN AND y < mapN THEN
                t& = glWrite * GL_TABLE_SIZE + (y * GL_TABLE + x) * 4
                glLitData(t&) = litR(x, y) : glLitData(t& + 1) = litG(x, y) : glLitData(t& + 2) = litB(x, y)
                v = worldMap(x, y) : glLitData(t& + 3) = (v <= 0 OR v = 2 OR diagCorner(x, y) <> 0) * -1
                glInfoData(t&) = glLitCX(x, y, glWrite) : glInfoData(t& + 1) = glLitCY(x, y, glWrite) : glInfoData(t& + 2) = glLitDir(x, y, glWrite)
                glInfoData(t& + 3) = 0.85 : IF glLitData(t& + 3) THEN glInfoData(t& + 3) = MinOf(ceilH(x, y) - 0.15, floorH(x, y) + 2.5) ' (how high its light is: under its own ceiling - but no more than 2 1/2 walls over its floor: a hall 16 walls high is lit as well)
                FOR k = 1 TO GL_DYN : glDynData(t& + k - 1) = glDynReach(x, y, k, glWrite) : NEXT
            END IF
        NEXT : NEXT
        ' Glows: bolts, explosions, and every lamp and terminal that's lit
        ' (its light's colour, flickering with it)
        n = 0
        FOR i = 1 TO MAX_BOLTS
            IF boltOn(i) THEN
                n = n + 1 : glGlowX(n, glWrite) = boltX(i) : glGlowY(n, glWrite) = boltY(i) : glGlowZ(n, glWrite) = boltZ(i) ' (where the bolt is - it climbs and drops toward you)
                glGlowSize(n, glWrite) = 0.35 : glGlowR(n, glWrite) = 1 : glGlowG(n, glWrite) = 0.25 : glGlowB(n, glWrite) = 0.9
                IF boltKind(i) THEN glGlowSize(n, glWrite) = bkScale(boltKind(i)) * 2.2 : glGlowR(n, glWrite) = bkR(boltKind(i)) / 255 : glGlowG(n, glWrite) = bkG(boltKind(i)) / 255 : glGlowB(n, glWrite) = bkB(boltKind(i)) / 255
                IF boltKind(i) = BK_ROCKET OR boltKind(i) = BK_MISSILE THEN ' (a rocket: its exhaust - a white-hot flare out of its back, and a fading orange plume behind)
                    glGlowX(n, glWrite) = boltX(i) - boltDX(i) * 0.17 : glGlowY(n, glWrite) = boltY(i) - boltDY(i) * 0.17 : glGlowZ(n, glWrite) = boltZ(i) - boltDZ(i) * 0.17
                    glGlowSize(n, glWrite) = 0.09 : glGlowR(n, glWrite) = 1 : glGlowG(n, glWrite) = 0.85 : glGlowB(n, glWrite) = 0.55
                    FOR rkT = 1 TO 3
                        IF n < MAX_GLOWS THEN
                            n = n + 1 : glGlowX(n, glWrite) = boltX(i) - boltDX(i) * (0.17 + rkT * 0.11) : glGlowY(n, glWrite) = boltY(i) - boltDY(i) * (0.17 + rkT * 0.11) : glGlowZ(n, glWrite) = boltZ(i) - boltDZ(i) * (0.17 + rkT * 0.11)
                            glGlowSize(n, glWrite) = 0.09 - rkT * 0.015 + RND * 0.02 : glGlowR(n, glWrite) = 0.7 - rkT * 0.12 : glGlowG(n, glWrite) = 0.38 - rkT * 0.08 : glGlowB(n, glWrite) = 0.08
                        END IF
                    NEXT
                END IF
                IF boltKind(i) >= BK_FLAME THEN glGlowSize(n, glWrite) = 0.3 : glGlowR(n, glWrite) = glGlowR(n, glWrite) * 0.22 : glGlowG(n, glWrite) = glGlowG(n, glWrite) * 0.22 : glGlowB(n, glWrite) = glGlowB(n, glWrite) * 0.22 ' (a spray's puffs: many at once - each faint, or together they'd white out the view)
            END IF
        NEXT
        FOR i = 1 TO MAX_BLASTS
            IF blastTime(i) > 0 THEN
                f = blastTime(i) / BLAST_FRAMES : blastScale = (0.6 + 0.7 * (1 - f)) * blastSize(i)
                n = n + 1 : glGlowX(n, glWrite) = blastX(i) : glGlowY(n, glWrite) = blastY(i)
                glGlowZ(n, glWrite) = FloorAt(blastX(i), blastY(i)) + 0.05 + (1 - blastSize(i)) * 0.35 + blastScale / 2 : glGlowSize(n, glWrite) = blastScale
                IF blastZ(i) <> NO_Z THEN glGlowZ(n, glWrite) = blastZ(i)
                glGlowR(n, glWrite) = f : glGlowG(n, glWrite) = 0.55 * f : glGlowB(n, glWrite) = 0.2 * f
            END IF
        NEXT
        FOR l = 1 TO numLights
            IF lightDeco(l) THEN
                IF decoOn(lightDeco(l)) AND lightNow(l) > 0 THEN
                    i = lightDeco(l) : brightest = lightR(l) : IF lightG(l) > brightest THEN brightest = lightG(l)
                    IF lightB(l) > brightest THEN brightest = lightB(l)
                    n = n + 1 : glGlowX(n, glWrite) = decoX(i) : glGlowY(n, glWrite) = decoY(i)
                    glGlowZ(n, glWrite) = FloorAt(decoX(i), decoY(i)) + DecoScale(decoKind(i)) * 0.8
                    IF decoKind(i) = 2 THEN glGlowSize(n, glWrite) = 0.6 ELSE glGlowSize(n, glWrite) = 0.4 ' (lamps bigger)
                    f = lightNow(l) / (brightest + 1)
                    glGlowR(n, glWrite) = lightR(l) * f : glGlowG(n, glWrite) = lightG(l) * f : glGlowB(n, glWrite) = lightB(l) * f
                END IF
            END IF
        NEXT
        glNumGlow(glWrite) = n
        glFrame(glWrite) = glFrameNo
        glBuf = glWrite : glReady = -1 ' (the switch: from now on, SUB _GL draws this one)
        CLS , _RGBA32(0, 0, 0, 0)
    ELSE
        glReady = 0
        IF nvOn THEN ApplyNight ELSE IF setting(SET_GAMMA) <> 100 THEN ApplyGamma setting(SET_GAMMA) ' (night vision - or BRIGHTNESS)
        _MEMCOPY pixelsMem, pixelsMem.OFFSET, pixelsMem.SIZE TO renderMem, renderMem.OFFSET
        _PUTIMAGE (shakeX - shakeEdge, shakeY - shakeEdge)-(799 + shakeX + shakeEdge, 599 + shakeY + shakeEdge), renderImg&, 0
    END IF
    viewMs = (TIMER(0.001) - viewStart#) * 1000 ' (for SHOW FPS)
