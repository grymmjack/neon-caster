''
' NEON-CASTER - LOOP/16-SPRITES.BI
' =============================================================================
' Chapter 16 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 16: DRAWING SPRITES
    '-------------------------------------------------------------------------
    ' Monsters, pickups, decorations, bolts and explosions are "billboards":
    ' flat pictures that always face you, like cardboard cut-outs that turn
    ' to follow you around.
    '
    ' First every visible thing goes into one list (drawX, drawY, which
    ' picture, how big, how high off the floor), and the list is sorted
    ' far to near: drawing the far ones first lets near ones cover them
    ' (the "painter's algorithm"). A simple swap sort is fine for a few
    ' dozen sprites.
    '
    ' Then, for each one, where is it on screen? (relX, relY) is the sprite
    ' relative to you. We turn that into "camera space" - how far in front
    ' of you (transformY) and how far to the side (transformX), measured
    ' along your direction and the camera plane. That's solving
    '   rel = plane * transformX + dir * transformY
    ' for the two unknowns, which is what invDet and the two lines below do
    ' (it's the inverse of the 2 x 2 matrix [plane dir]). Then:
    '   - behind you (transformY <= 0): skip it
    '   - across the screen: RENDER_W / 2 * (1 + transformX / transformY)
    '     (things further away crowd towards the middle - perspective)
    '   - size: viewH / transformY, like a wall slice, times its scale
    '
    ' Each column of the sprite is drawn only if it's nearer than the wall
    ' in that column (transformY < zBuffer(x)) - that's how sprites hide
    ' behind walls and doorframes. Transparent pixels (alpha 128 or less)
    ' are skipped, so you see the shape, not its square.
    numDraw = 0
    FOR k = 1 TO MAX_DRAW : drawFace(k) = 0 : drawMdl(k) = 0 : drawPic(k) = 0 : drawRed(k) = 0 : drawTint(k) = 0 : drawCap(k) = 0 : drawFlip(k) = 0 : drawMirror(k) = 0 : drawUpX(k) = 0 : drawUpY(k) = 0 : drawUpZ(k) = 1 : drawOX(k) = 0 : drawPitch(k) = 0 : drawHead(k) = 0 : drawMZ(k) = 1 : drawLk(k) = 0 : NEXT ' (all of it: an entry a turret had last frame is something else's now)
    FOR i = 1 TO numItems
        IF itemOn(i) AND (itemKind(i) = IT_CORE) = cyberOn THEN ' (in the network, just its data cores)
            numDraw = numDraw + 1 : drawX(numDraw) = itemX(i) : drawY(numDraw) = itemY(i)
            IF i <= lkItemN THEN drawLk(numDraw) = itemLk(i) ' (its look: [looks])
            drawSprite(numDraw) = ItemSprite(itemKind(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 96 ' They glow: less fog
            SELECT CASE itemKind(i)
                CASE 1 TO 3 : drawScale(numDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL, IT_LAUNCHER : drawScale(numDraw) = GUN_ITEM_SCALE
                CASE IT_CORE : drawScale(numDraw) = 0.42 : drawMinShade(numDraw) = 256
                CASE ELSE : drawScale(numDraw) = ITEM_SCALE
            END SELECT
            drawLift(numDraw) = 0.12 + 0.04 * SIN(glClock# * 3 + i) ' Hovering, bobbing (glClock#: TIMER - held still by the pause menu and PHOTO MODE)
            IF itemToss(i) > 0 THEN f = itemToss(i) / LOOT_TOSS : drawLift(numDraw) = drawLift(numDraw) + 1.4 * f * (1 - f) ' (tossed: up and over, and down - TossItem)
            IF itemMdl(itemKind(i)) THEN ' A 3D pickup, turning slowly as it hovers (RENDER/MODELS.BM)
                drawMdl(numDraw) = itemMdl(itemKind(i)) : drawAng(numDraw) = glClock# * 1.6 + i * 1.3
                drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), itemX(i), itemY(i))
            END IF
        END IF
    NEXT
    FOR i = 1 TO numMonsters
        mtype = monsterType(i)
        IF cyberOn AND mtype <> MT_ICE THEN _CONTINUE ' (in the network: only ICE)
        IF monsterState(i) = 4 THEN _CONTINUE ' (a thief that got home: gone)
        IF mtype = MT_TURRET AND glMode AND turPlateMdl AND numDraw < MAX_DRAW - 1 THEN TurretPlate i ' (its mounting plate - blown open, once it's destroyed: GAME/TURRETS.BM)
        IF mtype = MT_TURRET AND NOT editMode THEN IF monDeploy(i) < 0 OR (monDeploy(i) = 0 AND monsterState(i) < 2) THEN _CONTINUE ' (a turret hidden, or switched off: nothing to see - but in the editor, it's shown out)
        numDraw = numDraw + 1 : drawX(numDraw) = monsterX(i) : drawY(numDraw) = monsterY(i)
        IF i <= lkMonN THEN drawLk(numDraw) = monLk(i) ' (its look: [looks])
        drawScale(numDraw) = mtypeScale(mtype) : drawMinShade(numDraw) = 40 : IF mtype = MT_ICE THEN drawMinShade(numDraw) = 230
        IF mtype = MT_ICE THEN ' (the network's other ICE, each its own colour: sentinels orange, tracers yellow, black ICE dark - and bigger)
            SELECT CASE iceKind(i)
                CASE ICE_SENTRY : drawTint(numDraw) = _RGB32(255, 150, 50)
                CASE ICE_TRACER : drawTint(numDraw) = _RGB32(255, 240, 60)
                CASE ICE_BLACK : drawTint(numDraw) = _RGB32(30, 10, 70) : drawScale(numDraw) = drawScale(numDraw) * 1.35 : drawMinShade(numDraw) = 30
            END SELECT
        END IF
        IF mtype = MT_TURRET THEN drawTint(numDraw) = TurretRGB~&(monWeap(i)) ' (a turret: tinted the colour of what it fires - its wreck too)
        ' Its frame: hurt, attacking, or how far through its animation
        IF monsterHurt(i) > 0 THEN
            drawSprite(numDraw) = mtypeSprite(mtype) + 1
        ELSEIF monsterAtk(i) > 0 THEN
            drawSprite(numDraw) = MonFrame(mtype, ANIM_FRAMES)
        ELSE
            drawSprite(numDraw) = MonFrame(mtype, INT(monsterAnim(i)) MOD ANIM_FRAMES)
        END IF
        fallen = monsterState(i) = 3 OR (monsterState(i) = 2 AND monsterTimer(i) <= MON_DYING \ 2)
        turretFall = (mtype = MT_TURRET AND monFrom(i) = 0 AND monsterState(i) = 2) ' (a turret from the ceiling, destroyed: falling)
        IF turretFall THEN fallen = 0
        IF turretFall THEN ' Falling out of the ceiling: faster and faster, tumbling round - the model, flushed red (or its red picture) - to land as a wreck
            f = 1 - monsterTimer(i) / MON_DYING
            drawSquash(numDraw) = 1 : drawSprite(numDraw) = mtypeSprite(mtype) + 1
            drawLift(numDraw) = (ceilH(INT(monsterX(i)), INT(monsterY(i))) - FloorAt(monsterX(i), monsterY(i)) - mtypeScale(mtype)) * (1 - f * f)
            IF mtypeMdl(mtype) AND glMode THEN drawMdl(numDraw) = mtypeMdl(mtype) : drawAng(numDraw) = monsterTimer(i) * 0.45 + i : drawRed(numDraw) = -1
        ELSEIF fallen THEN ' Dead (or half way through falling): its body, lying on the floor
            drawSprite(numDraw) = S_CORPSE + mtype : drawScale(numDraw) = corpseScale(mtype)
            drawSquash(numDraw) = corpseSquash(mtype) : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw) : drawMinShade(numDraw) = 0
        ELSEIF monsterState(i) = 2 THEN ' Falling: it sinks to the floor and crumples, hurt
            f = (monsterTimer(i) - MON_DYING / 2) / (MON_DYING / 2) ' (1 just hit .. 0 down)
            drawSquash(numDraw) = 0.55 + 0.45 * f : drawLift(numDraw) = (mtypeLift(mtype) + monFly(i)) * f : drawSprite(numDraw) = mtypeSprite(mtype) + 1 ' (a flyer: down from where it flew)
        ELSE
            drawSquash(numDraw) = 1 : drawLift(numDraw) = mtypeLift(mtype) + monFly(i) + mtypeBob(mtype) * SIN(lvFrame / 24 + i * 1.7) ' (bobbing by the frame clock, as WeakSpotHit has it: the same bob in a demo)
            IF mtype = MT_EYEBOT AND monsterHurt(i) = 0 THEN ' (its eye says what it's doing: plain, idle - yellow, hunting you - red, rushing you, flaring as it beeps)
                IF monRush(i) = 1 THEN
                    drawSprite(numDraw) = S_EYE + 1 : IF (monBurst(i) \ 3) MOD 2 THEN drawMinShade(numDraw) = 255
                ELSEIF monsterState(i) = 1 THEN
                    drawSprite(numDraw) = S_EYE : drawMinShade(numDraw) = 150
                END IF
            END IF
            IF mtype = MT_ROBODOG THEN DogPose i, numDraw ' (painted side on: head on as it runs at you, else facing the way it runs - GAME/SECURE.BM)
            IF mtype = MT_TURRET THEN ' A turret coming out: from the floor, it grows up out of it; from the ceiling, it comes down out of that; from a wall, it slides out
                f = MinOf(1, monDeploy(i) / TURRET_UP) : IF editMode THEN f = 1
                drawSquash(numDraw) = MaxOf(0.05, f)
                IF monFrom(i) = TURRET_CEIL THEN drawLift(numDraw) = ceilH(INT(monsterX(i)), INT(monsterY(i))) - FloorAt(monsterX(i), monsterY(i)) - mtypeScale(mtype) * f : drawFlip(numDraw) = -1 ' (hanging upside down)
                IF glMode AND mtypeMdl(mtype) THEN ' (OpenGL, its model: it slides out whole - the ceiling, or the floor, hides what's still in it)
                    drawSquash(numDraw) = 1 : IF monFrom(i) = TURRET_FLOOR THEN drawLift(numDraw) = -mtypeScale(mtype) * (1 - f)
                END IF
                IF monFrom(i) = TURRET_WALL THEN ' (out of its wall: whole, chest high - the wall hides what's still in it)
                    drawSquash(numDraw) = 1 : drawLift(numDraw) = MonFoot(i) - FloorAt(monsterX(i), monsterY(i))
                    drawX(numDraw) = monsterX(i) - monWallX(i) * 0.5 * (1 - f) : drawY(numDraw) = monsterY(i) - monWallY(i) * 0.5 * (1 - f)
                    IF monsterHurt(i) = 0 THEN drawSprite(numDraw) = S_TURTOP ' (its picture: from the room - its head at you)
                END IF
            END IF
            IF mtype = MT_MIMIC AND monsterState(i) = 0 THEN ' A mimic asleep: a chest, to look at (but its lock) - its model too, turned to you as a chest's is
                drawSprite(numDraw) = S_MIMICNAP : drawScale(numDraw) = DecoScale(DK_CHEST) : drawLift(numDraw) = 0 : drawSquash(numDraw) = 1
                IF mimicNapMdl THEN drawMdl(numDraw) = mimicNapMdl : drawAng(numDraw) = DAtan2(playerY - monsterY(i), playerX - monsterX(i)) : drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), monsterX(i), monsterY(i))
            END IF
            IF mtypeMdl(mtype) THEN ' A monster with a model (the turret): turned to you - its barrels at you; hit, flushed red (the software renderer: its red picture)
                drawMdl(numDraw) = mtypeMdl(mtype) : drawAng(numDraw) = DAtan2(playerY - monsterY(i), playerX - monsterX(i))
                IF mtype = MT_TURRET THEN TurretDrawAt i, numDraw ' (its aim, its weapon's colour, and which way up: GAME/TURRETS.BM)
                IF monsterHurt(i) > 0 THEN
                    drawRed(numDraw) = -1
                ELSEIF NOT (mtype = MT_TURRET AND monFrom(i) = TURRET_WALL) THEN
                    drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), monsterX(i), monsterY(i))
                END IF
            END IF
        END IF
    NEXT
    ' The beams: a line of glowing dots - a laser aiming, faint red; firing,
    ' white-hot and thicker (MonLaser)
    IF glMode THEN glNumSight(glWrite) = 0
    FOR i = 1 TO MAX_BEAMS
        IF beamT(i) > 0 AND beamKind(i) >= BEAM_SIGHT AND glMode THEN ' (a turret's laser sight, in OpenGL: a glowing line - GLSight)
            n = glNumSight(glWrite) + 1 : glNumSight(glWrite) = n
            glSightX0(n, glWrite) = beamX0(i) : glSightY0(n, glWrite) = beamY0(i) : glSightZ0(n, glWrite) = beamZ0(i)
            glSightX1(n, glWrite) = beamX1(i) : glSightY1(n, glWrite) = beamY1(i) : glSightZ1(n, glWrite) = beamZ1(i) : glSightC(n, glWrite) = TurretRGB~&(beamKind(i) - BEAM_SIGHT)
            _CONTINUE
        END IF
        IF beamT(i) > 0 THEN
            bl = SQR((beamX1(i) - beamX0(i)) ^ 2 + (beamY1(i) - beamY0(i)) ^ 2) : bn = MinOf(90, INT(bl / 0.2) + 1)
            IF beamKind(i) >= BEAM_SIGHT THEN bn = MinOf(140, INT(bl / 0.12) + 1) ' (a sight: finer dots, closer together)
            FOR k = 1 TO bn
                f = k / bn : bx = beamX0(i) + (beamX1(i) - beamX0(i)) * f : by = beamY0(i) + (beamY1(i) - beamY0(i)) * f
                IF (bx - playerX) ^ 2 + (by - playerY) ^ 2 < 1.44 THEN _CONTINUE ' (none right at you: a dot by your eye would fill the screen)
                IF numDraw < MAX_DRAW THEN
                    numDraw = numDraw + 1
                    drawX(numDraw) = bx : drawY(numDraw) = by
                    drawLift(numDraw) = beamZ0(i) + (beamZ1(i) - beamZ0(i)) * f - FloorAt(drawX(numDraw), drawY(numDraw))
                    drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256 : drawFace(numDraw) = 0
                    IF beamKind(i) = BEAM_SHOT THEN drawSprite(numDraw) = S_BEAM : drawScale(numDraw) = 0.1 ELSE drawSprite(numDraw) = S_BEAM_AIM : drawScale(numDraw) = 0.05
                    IF beamKind(i) >= BEAM_SIGHT THEN drawSprite(numDraw) = S_SIGHT + beamKind(i) - BEAM_SIGHT : drawScale(numDraw) = 0.035 ' (a turret's laser sight, in its weapon's colour)
                END IF
            NEXT
        END IF
    NEXT
    FOR i = 1 TO numDecos
        IF cyberOn = 0 AND NOT (decoOn(i) = 0 AND decoZ(i) > 0.05) AND NOT (viewOn = VIEW_CAM AND i = viewCam) THEN ' (not the camera you're looking through; every one - broken ones leave their wreck - one up a stack: blown away; none in the network)
            numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) : drawY(numDraw) = decoY(i)
            drawLk(numDraw) = decoLk(i) ' (its look: [looks])
            drawSprite(numDraw) = DecoSlot(decoKind(i)) : drawScale(numDraw) = DecoScale(decoKind(i)) : drawLift(numDraw) = decoZ(i)
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40 : drawFace(numDraw) = decoFace(i)
            IF decoKind(i) = DK_JUMPPAD THEN drawSquash(numDraw) = 0.16 : drawFace(numDraw) = 0 : drawMinShade(numDraw) = 200 + 56 * SIN(lvFrame * 0.08 + i) ' (a jump pad: flat on the floor, glowing - as a teleporter's)
            IF decoOpen(i) = -1 THEN ' An open chest (safe, switched-off alarm): its open picture (its "wreck"), its open model - not a searched desk or bookshelf (1): that's just as it was
                drawSprite(numDraw) = S_WRECK + decoKind(i) : drawScale(numDraw) = wreckScale(decoKind(i)) : drawSquash(numDraw) = wreckSquash(decoKind(i))
                IF wreckMdl(decoKind(i)) THEN drawMdl(numDraw) = wreckMdl(decoKind(i)) : drawAng(numDraw) = ModelFacing(i) : drawFace(numDraw) = 0 : drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), decoX(i), decoY(i))
            ELSEIF NOT decoOn(i) AND (wreckMdl(decoKind(i)) OR BarrelLiquid(decoKind(i))) THEN ' Broken, with a wreck of its own: its picture, its model (OpenGL), standing where it stood
                drawSprite(numDraw) = S_WRECK + decoKind(i) : drawScale(numDraw) = wreckScale(decoKind(i)) : drawSquash(numDraw) = wreckSquash(decoKind(i)) : drawMinShade(numDraw) = 0
                IF wreckMdl(decoKind(i)) THEN drawMdl(numDraw) = wreckMdl(decoKind(i)) : drawAng(numDraw) = ModelFacing(i) : drawFace(numDraw) = 0 : drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), decoX(i), decoY(i))
            ELSEIF NOT decoOn(i) THEN ' Broken: what's left of it (MakeWreck)
                drawSprite(numDraw) = S_WRECK + decoKind(i) : drawScale(numDraw) = wreckScale(decoKind(i))
                drawSquash(numDraw) = wreckSquash(decoKind(i)) : drawMinShade(numDraw) = 0 : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw)
                IF decoMdl(decoKind(i)) AND glMode THEN ' (a 3D prop - OpenGL, near: its own model, broken - crumpled to half its height, knocked askew, charred; far off, its wreck's picture)
                    drawMdl(numDraw) = decoMdl(decoKind(i)) : drawAng(numDraw) = ModelFacing(i) + (i MOD 5 - 2) * 0.35 : drawMZ(numDraw) = 0.45 + (i MOD 3) * 0.06
                    wa = (i * 2.399) : drawUpX(numDraw) = DCos(wa) * 0.34 : drawUpY(numDraw) = DSin(wa) * 0.34 : drawUpZ(numDraw) = 0.94 ' (leaning, a different way each)
                    drawOX(numDraw) = decoX(i) : drawOY(numDraw) = decoY(i) : drawOZ(numDraw) = FloorAt(decoX(i), decoY(i)) - 0.02
                    drawTint(numDraw) = _RGB32(46, 40, 36) : drawMinShade(numDraw) = 0
                END IF
            ELSEIF decoMdl(decoKind(i)) THEN ' A 3D prop: OpenGL draws its model; we draw its picture from nearest where you are (RENDER/MODELS.BM)
                drawMdl(numDraw) = decoMdl(decoKind(i)) : drawAng(numDraw) = ModelFacing(i) : drawFace(numDraw) = 0
                drawPic(numDraw) = ModelPic(drawMdl(numDraw), drawAng(numDraw), decoX(i), decoY(i))
            END IF
            IF decoKind(i) = DK_ALARM AND alarmTimer > 0 AND vendState(i) = 0 THEN drawMinShade(numDraw) = 120 + 120 * ((lvFrame \ 15) MOD 2) ' (sounding: its switch flashing)
            IF drawMdl(numDraw) AND decoKind(i) = DK_CAMERA AND decoOn(i) THEN CamTrack i, numDraw ' (a camera: turning and tilting to follow you, as a turret does - GAME/SECURE.BM)
            IF drawMdl(numDraw) AND (decoKind(i) = DK_CAMERA OR decoKind(i) = DK_ALARM) AND decoFace(i) >= 1 AND decoFace(i) <= 4 THEN ' (a 3D camera or alarm switch: on its wall, not out in the middle of its cell)
                wa = (decoFace(i) - 1) * 1.5708 : IF decoKind(i) = DK_CAMERA THEN wo = 0.34 ELSE wo = 0.47
                drawX(numDraw) = decoX(i) - COS(wa) * wo : drawY(numDraw) = decoY(i) - SIN(wa) * wo
            END IF
            IF decoKind(i) = 2 OR decoKind(i) = 7 OR decoKind(i) = 12 OR decoKind(i) = 13 OR decoKind(i) = 17 THEN drawMinShade(numDraw) = 200 ' Lamps (vending machines, monitors, tanks, holograms) glow
            IF BarrelLiquid(decoKind(i)) = LQ_LAVA THEN drawMinShade(numDraw) = 150 ' (a lava barrel's cracks)
            IF decoKind(i) = 9 AND decoOn(i) AND (decoCharge(i) > 0 OR decoBurst(i) > 0) THEN ' A spawner charging: an orb of light in it, growing - and sending one out, the orb falls in on itself, then bursts
                c = decoCharge(i) : drawMinShade(numDraw) = 40 + 200 * c
                d = SQR((playerX - decoX(i)) ^ 2 + (playerY - decoY(i)) ^ 2) + 0.001
                numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) + (playerX - decoX(i)) / d * 0.08 : drawY(numDraw) = decoY(i) + (playerY - decoY(i)) / d * 0.08
                drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256 : drawFace(numDraw) = 0 : drawSprite(numDraw) = S_BOLT
                drawScale(numDraw) = 0.05 + 0.3 * c * c * (0.9 + 0.1 * SIN(lvFrame * (0.2 + 0.6 * c)))
                IF decoBurst(i) > 0 THEN
                    ph = 1 - decoBurst(i) / 20
                    IF ph < 0.25 THEN
                        drawScale(numDraw) = 0.36 * (1 - ph / 0.25) + 0.01
                    ELSE
                        drawSprite(numDraw) = S_BOOM + 1 + MinOf(BOOM_FRAMES - 1, INT((ph - 0.25) / 0.75 * BOOM_FRAMES)) : drawScale(numDraw) = 0.7
                    END IF
                END IF
                drawLift(numDraw) = 0.45 - drawScale(numDraw) / 2
            END IF
        END IF
    NEXT
    FOR i = 1 TO numDroids ' The droids: rocking a little as they roll; broken, a sooty heap
        IF cyberOn = 0 THEN
            numDraw = numDraw + 1 : drawX(numDraw) = droidX(i) : drawY(numDraw) = droidY(i) : drawFace(numDraw) = 0
            drawSprite(numDraw) = S_DROID + droidKind(i) - 1 : drawScale(numDraw) = DroidScale(droidKind(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40
            drawLift(numDraw) = 0
            IF droidState(i) = 1 OR droidState(i) = 3 THEN drawLift(numDraw) = 0.012 * ABS(SIN(lvFrame * 0.5 + i))
            IF droidState(i) = 2 THEN drawSquash(numDraw) = 1 + 0.03 * SIN(lvFrame * 0.7 + i) ' (at work: bobbing as it scrubs)
            IF droidHP(i) <= 0 THEN drawSprite(numDraw) = S_DROID + 1 + droidKind(i) : drawSquash(numDraw) = 0.62 : drawMinShade(numDraw) = 0
        END IF
    NEXT
    ' Traps: pressure plates (flat on the floor, glowing while they count
    ' down) and laser beams (a wall-high bar per cell of the beam)
    FOR k = 1 TO numPads ' Teleporters' pads: flat and glowing
        IF numDraw < MAX_DRAW THEN
            numDraw = numDraw + 1 : drawX(numDraw) = padX(k) + 0.5 : drawY(numDraw) = padY(k) + 0.5 : drawSprite(numDraw) = S_PAD
            drawScale(numDraw) = 0.85 : drawSquash(numDraw) = 0.16 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 200 + 56 * SIN(glClock# * 4 + k)
        END IF
    NEXT
    FOR ev = 1 TO numEvents
        IF cyberOn THEN EXIT FOR ' (no traps in the network)
        SELECT CASE evType(ev)
            CASE EV_PLATE
                FOR py = evY0(ev) TO evY1(ev) : FOR px = evX0(ev) TO evX1(ev)
                    IF numDraw < MAX_DRAW THEN
                        numDraw = numDraw + 1 : drawX(numDraw) = px + 0.5 : drawY(numDraw) = py + 0.5 : drawSprite(numDraw) = S_PLATE
                        drawScale(numDraw) = 0.9 : drawSquash(numDraw) = 0.08 : drawLift(numDraw) = 0
                        drawMinShade(numDraw) = 0 : IF evState(ev) = 1 AND (evTimer(ev) \ 4) MOD 2 = 0 THEN drawMinShade(numDraw) = 200
                        IF glMode AND plateMdl THEN ' (OpenGL: a steel plate lying across the cell, square to the map - its slit of a light dim red, flashing as it counts down)
                            drawSprite(numDraw) = 0 : drawScale(numDraw) = 1 : drawSquash(numDraw) = 1 : drawMdl(numDraw) = plateMdl : drawAng(numDraw) = 0
                            IF evState(ev) = 0 THEN drawCap(numDraw) = _RGB32(70, 10, 12) ' (armed: a faint glow, there if you look)
                            IF evState(ev) = 1 AND (evTimer(ev) \ 4) MOD 2 = 0 THEN drawCap(numDraw) = _RGB32(255, 46, 40)
                        END IF
                    END IF
                NEXT : NEXT
            CASE EV_LASER
                IF LaserOn(ev) OR (LaserSoon(ev) AND (evTimer(ev) \ 3) MOD 2 = 0) THEN
                    FOR py = evY0(ev) TO evY1(ev) : FOR px = evX0(ev) TO evX1(ev)
                        IF numDraw < MAX_DRAW THEN
                            numDraw = numDraw + 1 : drawX(numDraw) = px + 0.5 : drawY(numDraw) = py + 0.5 : drawSprite(numDraw) = S_LASER
                            drawScale(numDraw) = 1 : drawSquash(numDraw) = 1 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 256
                        END IF
                    NEXT : NEXT
                END IF
            CASE EV_CUTTER
                CutterAt ev, cutX, cutY, cutAlongX
                IF cutAlongX THEN n0 = evY0(ev) : n1 = evY1(ev) ELSE n0 = evX0(ev) : n1 = evX1(ev)
                FOR k = n0 TO n1
                    IF numDraw < MAX_DRAW THEN
                        numDraw = numDraw + 1 : drawSprite(numDraw) = S_LASER
                        IF cutAlongX THEN drawX(numDraw) = cutX : drawY(numDraw) = k + 0.5 ELSE drawX(numDraw) = k + 0.5 : drawY(numDraw) = cutY
                        drawScale(numDraw) = 1 : drawSquash(numDraw) = 1 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 256
                    END IF
                NEXT
        END SELECT
    NEXT
    ' Decals, for the software renderer: little flat scorch marks facing
    ' you, just off the wall (so the wall doesn't hide them) - or squashed
    ' flat on the floor or ceiling. (OpenGL lays them on the surface itself:
    ' GLDecals, chapter 24.)
    IF NOT glMode THEN
        FOR i = 1 TO MAX_DECALS
            IF decalOn(i) THEN
                numDraw = numDraw + 1 : drawSprite(numDraw) = S_DECAL : drawScale(numDraw) = decalSize(i) : drawMinShade(numDraw) = 0
                IF decalKind(i) = 1 THEN drawSprite(numDraw) = S_ACID + 1 : drawMinShade(numDraw) = 90 ' (an acid stain)
                IF decalKind(i) >= DK_SMEAR THEN drawSprite(numDraw) = S_SMEAR + decalKind(i) - DK_SMEAR : drawMinShade(numDraw) = 30 ' (blood, oil)
                drawX(numDraw) = decalX(i) + decalNX(i) * 0.03 : drawY(numDraw) = decalY(i) + decalNY(i) * 0.03
                IF ABS(decalNZ(i)) > 0.5 THEN
                    drawSquash(numDraw) = 0.35
                    IF decalNZ(i) > 0 THEN drawLift(numDraw) = 0.004 ELSE drawLift(numDraw) = CeilAt(decalX(i), decalY(i)) - FloorAt(decalX(i), decalY(i)) - 0.004 - decalSize(i) * 0.35
                ELSE ' (decalZ is a real height; a sprite's lift is over the floor it stands on)
                    drawSquash(numDraw) = 1 : drawLift(numDraw) = decalZ(i) - decalSize(i) / 2 - FloorAt(drawX(numDraw), drawY(numDraw))
                END IF
            END IF
        NEXT
    END IF
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN ' Explosions swell as they fade
            numDraw = numDraw + 1 : drawX(numDraw) = blastX(i) : drawY(numDraw) = blastY(i)
            ' Its frame: how far through it is, from the white-hot flash to
            ' the last of the smoke (MakeBoomFrames)
            boomF = INT((1 - blastTime(i) / BLAST_FRAMES) * BOOM_FRAMES) + 1 : IF boomF > BOOM_FRAMES THEN boomF = BOOM_FRAMES
            drawSprite(numDraw) = S_BOOM + boomF : drawScale(numDraw) = (0.6 + 0.7 * (1 - blastTime(i) / BLAST_FRAMES)) * blastSize(i)
            drawLift(numDraw) = 0.05 + (1 - blastSize(i)) * 0.35 ' (a small puff of sparks floats at the broken thing's middle)
            IF blastZ(i) <> NO_Z THEN drawLift(numDraw) = blastZ(i) - FloorAt(blastX(i), blastY(i)) - drawScale(numDraw) / 2 ' (in the air: a rocket's, where it hit)
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) AND NOT (viewOn = VIEW_ROCKET AND i = viewBolt) THEN ' (not the rocket you're riding)
            numDraw = numDraw + 1 : drawX(numDraw) = boltX(i) : drawY(numDraw) = boltY(i)
            drawSprite(numDraw) = S_BOLT : drawScale(numDraw) = 0.22 : drawLift(numDraw) = boltZ(i) - 0.11 - floorH(INT(boltX(i)), INT(boltY(i)))
            IF boltKind(i) THEN ' (a rocket, a missile, a spray's puff: its own picture - a puff swelling as it goes)
                drawSprite(numDraw) = S_PUFF + boltKind(i) : drawScale(numDraw) = bkScale(boltKind(i))
                IF boltKind(i) >= BK_FLAME THEN drawScale(numDraw) = bkScale(boltKind(i)) * (0.5 + 0.9 * (1 - boltLife(i) / PUFF_LIFE))
                drawLift(numDraw) = boltZ(i) - drawScale(numDraw) / 2 - floorH(INT(boltX(i)), INT(boltY(i)))
                IF boltKind(i) <= BK_MISSILE AND rocketMdl THEN ' (a rocket: its model, nose first - pitched up or down as it flies; its picture far off)
                    rkA = DAtan2(boltDY(i), boltDX(i)) : rkP = ATN(boltDZ(i))
                    drawMdl(numDraw) = rocketMdl : drawAng(numDraw) = rkA : drawMinShade(numDraw) = 120
                    drawPitch(numDraw) = rkP
                    drawOX(numDraw) = boltX(i) : drawOY(numDraw) = boltY(i) : drawOZ(numDraw) = boltZ(i)
                    drawPic(numDraw) = ModelPic(rocketMdl, rkA, boltX(i), boltY(i)) : drawScale(numDraw) = mdlFrame(rocketMdl)
                    drawLift(numDraw) = boltZ(i) - mdlFrame(rocketMdl) / 2 - floorH(INT(boltX(i)), INT(boltY(i)))
                END IF
            END IF
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256 ' Glowing: no fog at all
        END IF
    NEXT
    FOR i = 1 TO MAX_GIBS ' (what a rocket blew apart: its pieces)
        IF gibLife(i) > 0 AND numDraw < MAX_DRAW THEN
            numDraw = numDraw + 1 : drawX(numDraw) = gibX(i) : drawY(numDraw) = gibY(i) : drawSprite(numDraw) = gibSlot(i)
            drawScale(numDraw) = gibSize(i) : drawLift(numDraw) = gibZ(i) - FloorAt(gibX(i), gibY(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 30
            IF gibVZ(i) <> 0 THEN drawFlip(numDraw) = (gibLife(i) \ 6) MOD 2 ' (spinning as it flies)
        END IF
    NEXT
    FOR i = 1 TO numDraw
        drawOrder(i) = i : drawDistSq(i) = (drawX(i) - playerX) ^ 2 + (drawY(i) -playerY) ^ 2
    NEXT
    FOR a = 1 TO numDraw - 1 : FOR b = a + 1 TO numDraw
        IF drawDistSq(drawOrder(b)) > drawDistSq(drawOrder(a)) THEN SWAP drawOrder(a), drawOrder(b)
    NEXT : NEXT
    invDet = 1 /(planeX * dirY - dirX * planeY)
    ' (with GLASS REFLECTIONS, what's behind you goes to OpenGL too, within
    ' GLASS_BEHIND cells: a pane in front of you shows it - GL/OPENGL.BM's GLMirrors)
    glassBehind = glMode AND setting(SET_GLASSREF) <> 0 AND glassRefAny
    FOR drawIdx = 1 TO numDraw
        i = drawOrder(drawIdx)
        lkS = 1 : IF drawLk(i) THEN lkS = lkSize(drawLk(i)) : IF lkS <> 1 THEN drawScale(i) = drawScale(i) * lkS ' (sized by its look: [looks])
        relX = drawX(i) - playerX : relY = drawY(i) -playerY
        transformX = invDet * (dirY * relX - dirX * relY) ' Sideways from the view
        transformY = invDet * ( - planeY * relX + planeX * relY) ' Depth
        IF drawFace(i) THEN
            DrawFlat ' (standing flat, facing one way: RENDER/VIEW.BM)
        ELSEIF transformY > 0.1 OR (glassBehind AND transformY > -GLASS_BEHIND AND transformY < -0.3) THEN
            behindNow = transformY < 0 : IF behindNow THEN transformY = -transformY ' (behind you - well behind, so all of it is: as far, for its fog - it's only ever seen in glass)
            sc = drawScale(i) : IF drawPic(i) AND NOT glMode THEN sc = mdlFrame(drawMdl(i)) * lkS ' (a 3D prop's picture: wider than its sprite, to fit it from any way round)
            spriteW = INT(viewH / transformY * sc) : spriteH = INT(spriteW * drawSquash(i))
            IF spriteH < 1 THEN spriteH = 1
            spriteTop = INT(RENDER_H / 2 + (eyeZ - FloorAt(drawX(i), drawY(i)) - drawLift(i)) * viewH / transformY) -spriteH ' Bottom edge on its floor, lifted off it - below your eye
            spriteLeft = INT(RENDER_W / 2 * (1 + transformX / transformY)) - spriteW \ 2
            ' Lit by the cell it's in, dimmed by fog - but never darker than
            ' its drawMinShade (things that glow)
            fog& = 256 - transformY * 10 : IF fog& < 0 THEN fog& = 0
            litX = INT(drawX(i)) : litY = INT(drawY(i))
            lightR& = litR(litX, litY) * fog& \ 256 : lightG& = litG(litX, litY) * fog& \ 256 : lightB& = litB(litX, litY) * fog& \ 256
            IF lightR& < drawMinShade(i) THEN lightR& = drawMinShade(i)
            IF lightG& < drawMinShade(i) THEN lightG& = drawMinShade(i)
            IF lightB& < drawMinShade(i) THEN lightB& = drawMinShade(i)
            IF drawTint(i) THEN lightR& = lightR& * (0.25 + _RED32(drawTint(i)) / 300) : lightG& = lightG& * (0.25 + _GREEN32(drawTint(i)) / 300) : lightB& = lightB& * (0.25 + _BLUE32(drawTint(i)) / 300) ' (a turret: its weapon's colour, strongly)
            spriteSz = spriteSize(drawSprite(i)) : spriteSlot = drawSprite(i)
            IF drawPic(i) THEN spriteSz = MDL_PIC ' (a 3D prop's picture from where you are: mdlPic)
            IF glMode THEN
                ' OpenGL draws it (chapter 24): just note where it stands, how
                ' big it is, its picture and its light (256 here is 1 there:
                ' full). It's drawScale cells tall. The loop below draws it as
                ' wide on the screen as it is tall, and on the screen a cell
                ' across isn't quite as many pixels as a cell up - so in cells,
                ' that's fovPlane * RENDER_H / RENDER_W * drawScale either side
                ' of its middle.
                ' (A 3D prop: its model when it's near and in view - out to the
                ' side, nothing; further than MODEL_NEAR, its sprite, as ever:
                ' a model costs hundreds of triangles, and that far off it's a
                ' few pixels tall.)
                mdlNow = drawMdl(i) : sc = drawScale(i)
                IF mdlNow AND behindNow THEN ' (behind you: its picture, or nothing)
                    IF drawPic(i) = 0 AND drawSprite(i) = 0 THEN _CONTINUE
                    mdlNow = 0 : IF drawPic(i) THEN spriteSlot = SPR_SLOTS + drawPic(i) : sc = mdlFrame(drawMdl(i)) * lkS
                ELSEIF mdlNow THEN
                    IF ABS(transformX) > transformY * 2 + mdlFrame(mdlNow) THEN _CONTINUE
                    lx = INT(drawX(i)) : ly = INT(drawY(i)) ' (not seen this frame - in another room, behind a wall: nothing to draw)
                    IF glSeen(lx, ly, glWrite) <> glFrameNo AND glSeen(lx + 1, ly, glWrite) <> glFrameNo AND glSeen(lx, ly + 1, glWrite) <> glFrameNo AND glSeen(MaxOf(0, lx - 1), ly, glWrite) <> glFrameNo AND glSeen(lx, MaxOf(0, ly - 1), glWrite) <> glFrameNo THEN _CONTINUE
                    IF transformY > MODEL_NEAR OR (transformY > MODEL_NEAR_SMALL AND mdlFrame(mdlNow) < 0.75 AND drawHead(i) = 0) OR (transformY > MODEL_NEAR_MID AND mdlFrame(mdlNow) < 1 AND drawHead(i) = 0) THEN mdlNow = 0 ' (a small one - a barrel, a pickup - its picture sooner: a stockpile's stacks were tens of thousands of corners a frame; not a turret, whose head turns)
                    IF mdlNow = 0 AND drawPic(i) = 0 AND drawSprite(i) = 0 THEN _CONTINUE ' (a model with no picture - a turret's plate: only near)
                    IF drawPic(i) THEN spriteSlot = SPR_SLOTS + drawPic(i) : sc = mdlFrame(drawMdl(i)) * lkS ' (further off, and in reflections: its picture from where you are - the model, as it stands)
                END IF
                n = glNumSpr(glWrite) + 1 : glNumSpr(glWrite) = n
                glSprX(n, glWrite) = drawX(i) : glSprY(n, glWrite) = drawY(i) : glSprLift(n, glWrite) = drawLift(i) + FloorAt(drawX(i), drawY(i))
                glSprHalfW(n, glWrite) = sc * fovPlane * RENDER_H / RENDER_W
                glSprH(n, glWrite) = sc * drawSquash(i) : glSprSlot(n, glWrite) = spriteSlot
                glSprR(n, glWrite) = lightR& / 256 : glSprG(n, glWrite) = lightG& / 256 : glSprB(n, glWrite) = lightB& / 256 : glSprFace(n, glWrite) = 0
                IF drawRed(i) THEN glSprR(n, glWrite) = MaxOf(1.2, glSprR(n, glWrite) * 1.8) : glSprG(n, glWrite) = glSprG(n, glWrite) * 0.35 : glSprB(n, glWrite) = glSprB(n, glWrite) * 0.35 ' (hit: flushed red)
                glSprMdl(n, glWrite) = mdlNow : glSprAng(n, glWrite) = drawAng(i) ' (a 3D prop: GLDrawModel)
                glSprLk(n, glWrite) = drawLk(i) : glSprSz(n, glWrite) = lkS ' (its look: tinted, and a model sized - GLSpritesAndExtras)
                glSprMZ(n, glWrite) = drawMZ(i) : glSprPitch(n, glWrite) = drawPitch(i) : glSprHead(n, glWrite) = drawHead(i) : glSprHAng(n, glWrite) = drawHAng(i) : glSprHPitch(n, glWrite) = drawHPitch(i)
                glSprCap(n, glWrite) = drawCap(i) : glSprFlip(n, glWrite) = drawFlip(i) : glSprMirror(n, glWrite) = drawMirror(i) : glSprUpX(n, glWrite) = drawUpX(i) : glSprUpY(n, glWrite) = drawUpY(i) : glSprUpZ(n, glWrite) = drawUpZ(i)
                IF mdlNow AND (drawUpZ(i) < 0.99 OR drawOX(i) <> 0) THEN glSprX(n, glWrite) = drawOX(i) : glSprY(n, glWrite) = drawOY(i) : glSprLift(n, glWrite) = drawOZ(i) ' (on its side, or upside down: its model from its mount)
            ELSE
                FOR screenX = spriteLeft TO spriteLeft + spriteW - 1
                    IF screenX >= 0 AND screenX < RENDER_W THEN
                        IF transformY < zBuffer(screenX) THEN
                            ' (glass in this column nearer than the wall but behind
                            ' this sprite: on now, over what's behind it - all of
                            ' that is drawn, far to near - and under this)
                            IF glassT(screenX) > 0 AND glassDone(screenX) = 0 THEN IF transformY < glassT(screenX) THEN gx = screenX : GlassColumn
                            spriteU = (screenX - spriteLeft) * spriteSz \ spriteW : IF drawMirror(i) THEN spriteU = spriteSz - 1 - spriteU ' (left for right)
                            ' (heights: hidden above and below by the ledges and
                            ' lintels nearer than it - HeightColumn's clips)
                            spTop = 0 : spBot = RENDER_H - 1
                            FOR k = 1 TO clipN(screenX)
                                IF clipD(screenX, k) < transformY THEN spTop = clipT(screenX, k) : spBot = clipB(screenX, k)
                            NEXT
                            FOR screenY = spriteTop TO spriteTop + spriteH - 1
                                IF screenY >= spTop AND screenY <= spBot THEN
                                    spriteV = (screenY - spriteTop) * spriteSz \ spriteH : IF drawFlip(i) THEN spriteV = spriteSz - 1 - spriteV ' (upside down)
                                    IF drawPic(i) THEN texel~& = mdlPic(spriteU, spriteV, drawPic(i)) ELSE texel~& = spriteTex(spriteU, spriteV, spriteSlot)
                                    IF drawLk(i) THEN IF lkMode(drawLk(i)) THEN texel~& = LookPx~&(texel~&, drawLk(i)) ' (its look: tinted as a face's piece is)
                                    IF _ALPHA32(texel~&) > 128 THEN pixels(screenY * RENDER_W + screenX) = ShadeRGB~&(texel~&, lightR&, lightG&, lightB&)
                                END IF
                            NEXT
                        END IF
                    END IF
                NEXT
            END IF
        END IF
    NEXT
    ' ...and the glass in every column that had no sprite in front of it
    IF NOT glMode THEN
        FOR gx = 0 TO RENDER_W - 1
            IF glassT(gx) > 0 AND glassDone(gx) = 0 THEN GlassColumn
        NEXT
    END IF
