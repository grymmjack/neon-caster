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
    FOR k = 1 TO MAX_DRAW : drawFace(k) = 0 : NEXT
    FOR i = 1 TO numItems
        IF itemOn(i) AND (itemKind(i) = IT_CORE) = cyberOn THEN ' (in the network, just its data cores)
            numDraw = numDraw + 1 : drawX(numDraw) = itemX(i) : drawY(numDraw) = itemY(i)
            drawSprite(numDraw) = ItemSprite(itemKind(i)) : drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 96 ' They glow: less fog
            SELECT CASE itemKind(i)
                CASE 1 TO 3 : drawScale(numDraw) = CARD_SCALE
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL : drawScale(numDraw) = GUN_ITEM_SCALE
                CASE IT_CORE : drawScale(numDraw) = 0.42 : drawMinShade(numDraw) = 256
                CASE ELSE : drawScale(numDraw) = ITEM_SCALE
            END SELECT
            drawLift(numDraw) = 0.12 + 0.04 * SIN(TIMER * 3 + i) ' Hovering, bobbing
            IF itemToss(i) > 0 THEN f = itemToss(i) / LOOT_TOSS : drawLift(numDraw) = drawLift(numDraw) + 1.4 * f * (1 - f) ' (tossed: up and over, and down - TossItem)
        END IF
    NEXT
    FOR i = 1 TO numMonsters
        mtype = monsterType(i)
        IF cyberOn AND mtype <> MT_ICE THEN _CONTINUE ' (in the network: only ICE)
        IF monsterState(i) = 4 THEN _CONTINUE ' (a thief that got home: gone)
        numDraw = numDraw + 1 : drawX(numDraw) = monsterX(i) : drawY(numDraw) = monsterY(i)
        drawScale(numDraw) = mtypeScale(mtype) : drawMinShade(numDraw) = 40 : IF mtype = MT_ICE THEN drawMinShade(numDraw) = 230
        ' Its frame: hurt, attacking, or how far through its animation
        IF monsterHurt(i) > 0 THEN
            drawSprite(numDraw) = mtypeSprite(mtype) + 1
        ELSEIF monsterAtk(i) > 0 THEN
            drawSprite(numDraw) = MonFrame(mtype, ANIM_FRAMES)
        ELSE
            drawSprite(numDraw) = MonFrame(mtype, INT(monsterAnim(i)) MOD ANIM_FRAMES)
        END IF
        fallen = monsterState(i) = 3 OR (monsterState(i) = 2 AND monsterTimer(i) <= MON_DYING \ 2)
        IF fallen THEN ' Dead (or half way through falling): its body, lying on the floor
            drawSprite(numDraw) = S_CORPSE + mtype : drawScale(numDraw) = corpseScale(mtype)
            drawSquash(numDraw) = corpseSquash(mtype) : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw) : drawMinShade(numDraw) = 0
        ELSEIF monsterState(i) = 2 THEN ' Falling: it sinks to the floor and crumples, hurt
            f = (monsterTimer(i) - MON_DYING / 2) / (MON_DYING / 2) ' (1 just hit .. 0 down)
            drawSquash(numDraw) = 0.55 + 0.45 * f : drawLift(numDraw) = mtypeLift(mtype) * f : drawSprite(numDraw) = mtypeSprite(mtype) + 1
        ELSE
            drawSquash(numDraw) = 1 : drawLift(numDraw) = mtypeLift(mtype) + mtypeBob(mtype) * SIN(lvFrame / 24 + i * 1.7) ' (bobbing by the frame clock, as WeakSpotHit has it: the same bob in a demo)
        END IF
    NEXT
    FOR i = 1 TO numDecos
        IF cyberOn = 0 THEN ' (every one - broken ones leave their wreck; none in the network)
            numDraw = numDraw + 1 : drawX(numDraw) = decoX(i) : drawY(numDraw) = decoY(i)
            drawSprite(numDraw) = DecoSlot(decoKind(i)) : drawScale(numDraw) = DecoScale(decoKind(i)) : drawLift(numDraw) = 0
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 40 : drawFace(numDraw) = decoFace(i)
            IF NOT decoOn(i) THEN ' Broken: what's left of it (MakeWreck)
                drawSprite(numDraw) = S_WRECK + decoKind(i) : drawScale(numDraw) = wreckScale(decoKind(i))
                drawSquash(numDraw) = wreckSquash(decoKind(i)) : drawMinShade(numDraw) = 0 : drawLift(numDraw) = -CORPSE_SINK * drawScale(numDraw) * drawSquash(numDraw)
            END IF
            IF decoKind(i) = 2 OR decoKind(i) = 7 OR decoKind(i) = 12 OR decoKind(i) = 13 OR decoKind(i) = 17 THEN drawMinShade(numDraw) = 200 ' Lamps (vending machines, monitors, tanks, holograms) glow
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
            drawScale(numDraw) = 0.85 : drawSquash(numDraw) = 0.16 : drawLift(numDraw) = 0 : drawMinShade(numDraw) = 200 + 56 * SIN(TIMER * 4 + k)
        END IF
    NEXT
    FOR ev = 1 TO numEvents
        IF cyberOn THEN EXIT FOR ' (no traps in the network)
        SELECT CASE evType(ev)
            CASE EV_PLATE
                FOR py = evY0(ev) TO evY1(ev) : FOR px = evX0(ev) TO evX1(ev)
                    IF numDraw < MAX_DRAW THEN
                        numDraw = numDraw + 1 : drawX(numDraw) = px + 0.5 : drawY(numDraw) = py + 0.5 : drawSprite(numDraw) = S_PLATE
                        drawScale(numDraw) = 0.7 : drawSquash(numDraw) = 0.18 : drawLift(numDraw) = 0
                        drawMinShade(numDraw) = 60 : IF evState(ev) = 1 AND (evTimer(ev) \ 4) MOD 2 = 0 THEN drawMinShade(numDraw) = 256
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
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256
        END IF
    NEXT
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) THEN
            numDraw = numDraw + 1 : drawX(numDraw) = boltX(i) : drawY(numDraw) = boltY(i)
            drawSprite(numDraw) = S_BOLT : drawScale(numDraw) = 0.22 : drawLift(numDraw) = boltZ(i) - 0.11 - floorH(INT(boltX(i)), INT(boltY(i)))
            drawSquash(numDraw) = 1 : drawMinShade(numDraw) = 256 ' Glowing: no fog at all
        END IF
    NEXT
    FOR i = 1 TO numDraw
        drawOrder(i) = i : drawDistSq(i) = (drawX(i) - playerX) ^ 2 + (drawY(i) -playerY) ^ 2
    NEXT
    FOR a = 1 TO numDraw - 1 : FOR b = a + 1 TO numDraw
        IF drawDistSq(drawOrder(b)) > drawDistSq(drawOrder(a)) THEN SWAP drawOrder(a), drawOrder(b)
    NEXT : NEXT
    invDet = 1 /(planeX * dirY - dirX * planeY)
    FOR drawIdx = 1 TO numDraw
        i = drawOrder(drawIdx)
        relX = drawX(i) - playerX : relY = drawY(i) -playerY
        transformX = invDet * (dirY * relX - dirX * relY) ' Sideways from the view
        transformY = invDet * ( - planeY * relX + planeX * relY) ' Depth
        IF drawFace(i) THEN
            GOSUB DrawFlat ' (standing flat, facing one way: RENDER/VIEW.BM)
        ELSEIF transformY > 0.1 THEN
            spriteW = INT(viewH / transformY * drawScale(i)) : spriteH = INT(spriteW * drawSquash(i))
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
            spriteSz = spriteSize(drawSprite(i)) : spriteSlot = drawSprite(i)
            IF glMode THEN
                ' OpenGL draws it (chapter 24): just note where it stands, how
                ' big it is, its picture and its light (256 here is 1 there:
                ' full). It's drawScale cells tall. The loop below draws it as
                ' wide on the screen as it is tall, and on the screen a cell
                ' across isn't quite as many pixels as a cell up - so in cells,
                ' that's fovPlane * RENDER_H / RENDER_W * drawScale either side
                ' of its middle.
                n = glNumSpr(glWrite) + 1 : glNumSpr(glWrite) = n
                glSprX(n, glWrite) = drawX(i) : glSprY(n, glWrite) = drawY(i) : glSprLift(n, glWrite) = drawLift(i) + FloorAt(drawX(i), drawY(i))
                glSprHalfW(n, glWrite) = drawScale(i) * fovPlane * RENDER_H / RENDER_W
                glSprH(n, glWrite) = drawScale(i) * drawSquash(i) : glSprSlot(n, glWrite) = spriteSlot
                glSprR(n, glWrite) = lightR& / 256 : glSprG(n, glWrite) = lightG& / 256 : glSprB(n, glWrite) = lightB& / 256 : glSprFace(n, glWrite) = 0
            ELSE
                FOR screenX = spriteLeft TO spriteLeft + spriteW - 1
                    IF screenX >= 0 AND screenX < RENDER_W THEN
                        IF transformY < zBuffer(screenX) THEN
                            ' (glass in this column nearer than the wall but behind
                            ' this sprite: on now, over what's behind it - all of
                            ' that is drawn, far to near - and under this)
                            IF glassT(screenX) > 0 AND glassDone(screenX) = 0 THEN IF transformY < glassT(screenX) THEN gx = screenX : GOSUB GlassColumn
                            spriteU = (screenX - spriteLeft) * spriteSz \ spriteW
                            ' (heights: hidden above and below by the ledges and
                            ' lintels nearer than it - HeightColumn's clips)
                            spTop = 0 : spBot = RENDER_H - 1
                            FOR k = 1 TO clipN(screenX)
                                IF clipD(screenX, k) < transformY THEN spTop = clipT(screenX, k) : spBot = clipB(screenX, k)
                            NEXT
                            FOR screenY = spriteTop TO spriteTop + spriteH - 1
                                IF screenY >= spTop AND screenY <= spBot THEN
                                    texel~& = spriteTex(spriteU,(screenY - spriteTop) * spriteSz \ spriteH, spriteSlot)
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
            IF glassT(gx) > 0 AND glassDone(gx) = 0 THEN GOSUB GlassColumn
        NEXT
    END IF
