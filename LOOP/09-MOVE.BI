''
' NEON-CASTER - LOOP/09-MOVE.BI
' =============================================================================
' Chapter 9 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 9: MOVING, AND BUMPING INTO THINGS
    '-------------------------------------------------------------------------
    ' W and S move you along (dirX, dirY); A and D move you sideways, along
    ' (-dirY, dirX) - your direction turned 90 degrees, to your right (chapter
    ' 8: the map's y grows downward). Pressing W and D
    ' together adds the two, which would be about 1.4 times as fast, so the
    ' sum is "normalized": divided by its own length (moveLen) to make it one
    ' cell long, then scaled to your speed - walking, or running while you
    ' hold Shift. Now every direction is the same speed, and opposite keys
    ' simply cancel out.
    forward = 0 : strafe = 0
    IF NOT dead AND NOT edTyping THEN ' (typing a name in the editor: the keys aren't for walking)
        IF inBits AND DB_FWD THEN forward = forward + 1 ' W, unless rebound
        IF inBits AND DB_BACK THEN forward = forward - 1 ' S
        IF inBits AND DB_LEFT THEN strafe = strafe - 1 ' A (strafe left)
        IF inBits AND DB_RIGHT THEN strafe = strafe + 1 ' D (strafe right)
    END IF
    moveX = dirX * forward - dirY * strafe : moveY = dirY * forward + dirX * strafe ' (your right: (-dirY, dirX))
    moveLen = SQR(moveX * moveX + moveY * moveY)
    moveSpeed = WALK_SPEED : IF inBits AND DB_RUN THEN moveSpeed = RUN_SPEED ' (Shift: run)
    IF FloorHazard(INT(playerX), INT(playerY)) = HAZ_WADE THEN IF playerZ - floorH(INT(playerX), INT(playerY)) < 0.05 THEN moveSpeed = moveSpeed * SLOW_WADE ' (wading)
    IF health <= LOW_HP AND NOT godMode AND NOT editMode THEN moveSpeed = moveSpeed * LOW_SLOW ' (badly hurt: you drag yourself along)
    IF liqWas THEN moveSpeed = moveSpeed * LiquidSlow(liqWas, liqZ(INT(playerX), INT(playerY)) - playerZ) ' (wading in a liquid: slower the deeper - LQ_FULL deep, as slow as it gets)
    IF moveLen > 0 THEN
        moveX = moveX / moveLen * moveSpeed : moveY = moveY / moveLen * moveSpeed
    END IF

    ' Collision. You're a square, PLAYER_RADIUS from your middle to each
    ' side, so the camera can never get right up against a wall (it would
    ' fill the screen with one blurry texel). MoveBody (chapter 23) tries the
    ' X part of the move and the Y part separately: walk into a wall at an
    ' angle and the blocked part stops, while the other part carries on -
    ' so you slide along the wall instead of sticking to it. Monsters move
    ' with MoveBody too.
    prevX = playerX : prevY = playerY
    IF godMode OR editMode THEN ' No clipping (god mode, or the editor): straight through anything, but stay inside the border
        playerX = playerX + moveX : playerY = playerY + moveY
        IF playerX < 1.01 THEN playerX = 1.01
        IF playerX > MAP_SIZE - 1.01 THEN playerX = MAP_SIZE - 1.01
        IF playerY < 1.01 THEN playerY = 1.01
        IF playerY > MAP_SIZE - 1.01 THEN playerY = MAP_SIZE - 1.01
    ELSE
        walkZ = playerZ : MoveBody playerX, playerY, moveX, moveY : walkZ = -999
    END IF
    ' Up and down (chapter 22's heights): step up onto anything low enough
    ' (MoveBody wouldn't have let you onto anything higher), fall off
    ' anything higher - faster and faster - and land, hard if it was far;
    ' fall into a pit and that's the end. Your eye eases up a step.
    IF editMode OR (flyMode AND NOT dead) THEN ' The editor, or fly (god mode): you fly - Space (the editor) or E (fly) up, C down (Shift faster), or on the way you look - no falling
        flySpeed = 0.04 : IF inBits AND DB_RUN THEN flySpeed = 0.1
        IF editMode THEN flyUp = _KEYDOWN(32) : flyDown = _KEYDOWN(99) OR _KEYDOWN(67) ELSE flyUp = (inBits AND DB_UP) <> 0 : flyDown = (inBits AND DB_DOWN) <> 0 ' (in play Space opens things)
        IF flyUp AND NOT edTyping THEN playerZ = playerZ + flySpeed
        IF flyDown AND NOT edTyping THEN playerZ = playerZ - flySpeed
        IF forward <> 0 THEN playerZ = playerZ + forward * moveSpeed * DSin(pitch) * 1.5 ' (and the way you look: look up and walk on, and you climb - OpenGL's look up and down)
        IF playerZ < -1.4 THEN playerZ = -1.4
        IF playerZ > 4.5 THEN playerZ = 4.5
        IF NOT editMode THEN ' (in play: your eye stays under the ceiling - above it the room isn't drawn - and the floor still holds you up)
            IF playerZ > ceilH(INT(playerX), INT(playerY)) - EYE_H - 0.05 THEN playerZ = ceilH(INT(playerX), INT(playerY)) - EYE_H - 0.05
            IF playerZ < floorH(INT(playerX), INT(playerY)) THEN playerZ = floorH(INT(playerX), INT(playerY))
        END IF
        playerVZ = 0
    ELSEIF NOT levelFlat THEN
        ' Just dropped off something higher, and still hanging over its edge?
        ' Slide off it - else its rim, more than a step up, blocks every move
        ' along its foot but straight away (only your middle's cell holds you)
        IF NOT godMode THEN
            ecx = INT(playerX) : ecy = INT(playerY) : er = PLAYER_RADIUS
            IF INT(playerX + er) > ecx THEN IF worldMap(ecx + 1, ecy) <= 0 AND floorH(ecx + 1, ecy) > playerZ + STEP_UP THEN IF Walkable(playerX - 0.04, playerY) THEN playerX = playerX - MinOf(0.04, playerX + er - ecx - 1 + 0.001)
            IF INT(playerX - er) < ecx THEN IF worldMap(ecx - 1, ecy) <= 0 AND floorH(ecx - 1, ecy) > playerZ + STEP_UP THEN IF Walkable(playerX + 0.04, playerY) THEN playerX = playerX + MinOf(0.04, ecx - (playerX - er) + 0.001)
            IF INT(playerY + er) > ecy THEN IF worldMap(ecx, ecy + 1) <= 0 AND floorH(ecx, ecy + 1) > playerZ + STEP_UP THEN IF Walkable(playerX, playerY - 0.04) THEN playerY = playerY - MinOf(0.04, playerY + er - ecy - 1 + 0.001)
            IF INT(playerY - er) < ecy THEN IF worldMap(ecx, ecy - 1) <= 0 AND floorH(ecx, ecy - 1) > playerZ + STEP_UP THEN IF Walkable(playerX, playerY + 0.04) THEN playerY = playerY + MinOf(0.04, ecy - (playerY - er) + 0.001)
        END IF
        fz = floorH(INT(playerX), INT(playerY))
        IF liqKind(INT(playerX), INT(playerY)) AND NOT cyberOn THEN fz = MaxOf(fz, liqZ(INT(playerX), INT(playerY)) - LQ_FULL) ' (in deep liquid you float, your head above it)
        IF playerZ < fz THEN playerZ = fz : playerVZ = 0
        IF liftCell(INT(playerX), INT(playerY)) THEN IF playerZ - fz < MaxOf(0.06, liftSpeed(liftCell(INT(playerX), INT(playerY))) + 0.02) AND playerVZ < 0.03 THEN playerZ = fz : playerVZ = 0 ' (riding a lift down - however fast it goes)
        IF playerZ > fz THEN
            playerVZ = playerVZ + FALL_G : playerZ = playerZ - playerVZ
            IF playerZ <= fz THEN
                IF liqKind(INT(playerX), INT(playerY)) THEN playerVZ = playerVZ * 0.5 ' (into a liquid: it breaks the fall)
                IF playerVZ > 0.13 AND NOT dead AND NOT godMode THEN ' (a fall that hurts - about a wall's drop or more: the thud, the jolt; anything less is just a step down, and the footsteps carry on)
                    damage = INT((playerVZ - 0.13) * 260) + 2 : hurtFromX = -1 : hurtFromY = -1 : GOSUB HurtPlayer
                    PlaySfx sndStep1&, 1 : shake = shake + 8
                END IF
                playerZ = fz : playerVZ = 0
            END IF
        END IF
        IF fz <= PIT_DEPTH AND playerZ < -0.6 AND NOT dead AND NOT godMode THEN damage = 999 : hurtFromX = -1 : hurtFromY = -1 : GOSUB HurtPlayer : ShowMsg "You fell into the dark"
    END IF
    ' A burning floor (molten metal, lava): it hurts while you stand in it
    IF burnWait > 0 THEN burnWait = burnWait - 1
    IF FloorHazard(INT(playerX), INT(playerY)) = HAZ_BURN AND playerZ - floorH(INT(playerX), INT(playerY)) < 0.05 AND NOT dead THEN
        IF burnWait = 0 THEN
            burnWait = BURN_EVERY : PlaySfx sndSizzle&, 0.9
            SpawnSparks playerX + dirX * 0.3, playerY + dirY * 0.3, 0.05, 12, 255, 120, 30
            IF NOT godMode THEN damage = BURN_DAMAGE : hurtFromX = -1 : hurtFromY = -1 : hurtR = 255 : hurtG = 110 : hurtB = 20 : GOSUB HurtPlayer
        END IF
    END IF
    ' A liquid (chapter 3's LQ_): are your feet in one? In you go with a
    ' splash (a hiss, into lava); it slows you (above), and the harmful
    ' ones hurt, every lqEvery frames - more the deeper you are. Acid eats
    ' your armor first (twice as fast as it would you), and poison turns
    ' everything green for a moment.
    lk = 0
    IF NOT levelFlat AND NOT cyberOn AND NOT editMode THEN
        lk = liqKind(INT(playerX), INT(playerY)) : IF lk THEN IF playerZ >= liqZ(INT(playerX), INT(playerY)) - 0.01 THEN lk = 0
    END IF
    IF lk AND lk <> liqWas THEN
        IF lk = LQ_LAVA OR lk = LQ_ACID THEN PlaySfx sndSizzle&, 0.9 ELSE PlaySfx sndSplash&, 0.8
        SpawnSparks playerX + dirX * 0.25, playerY + dirY * 0.25, liqZ(INT(playerX), INT(playerY)) - FloorAt(playerX + dirX * 0.25, playerY + dirY * 0.25), 14, lqR(lk), lqG(lk), lqB(lk)
        liqWait = lqEvery(lk) \ 2 ' (a moment before it starts to hurt)
    END IF
    IF lk = LQ_LAVA THEN achInLava = -1 ELSE IF achInLava AND NOT dead THEN achInLava = 0 : Achieve "NC_HOT_FOOT", 0
    liqWas = lk
    IF liqWait > 0 THEN liqWait = liqWait - 1
    IF lk AND NOT dead THEN
        IF lqHurt(lk) > 0 AND liqWait = 0 THEN
            liqWait = lqEvery(lk)
            deep = MinOf(1, (liqZ(INT(playerX), INT(playerY)) - playerZ) / LQ_FULL)
            dmg = INT(lqHurt(lk) * (0.5 + 0.5 * deep) + 0.5) : IF dmg < 1 THEN dmg = 1
            SpawnSparks playerX + dirX * 0.3, playerY + dirY * 0.3, liqZ(INT(playerX), INT(playerY)) - FloorAt(playerX + dirX * 0.3, playerY + dirY * 0.3), 8, lqR(lk), lqG(lk), lqB(lk)
            IF lk = LQ_POISON THEN poisonTint = 40
            IF NOT godMode THEN
                IF lqAcid(lk) AND armor > 0 THEN ' Acid: the armor first
                    armor = MaxOf(0, armor - dmg * 2) : hurtFlash = 6 : PlaySfx sndSizzle&, 0.7 : Achieve "NC_CORRODED", 0
                    painR = lqR(lk) : painG = lqG(lk) : painB = lqB(lk) : painVig = MaxOf(painVig, 0.5)
                ELSE
                    IF lk = LQ_LAVA OR lk = LQ_ACID THEN PlaySfx sndSizzle&, 0.9
                    damage = dmg : hurtFromX = -1 : hurtFromY = -1 : hurtR = lqR(lk) : hurtG = lqG(lk) : hurtB = lqB(lk) : GOSUB HurtPlayer
                END IF
            END IF
        END IF
    END IF
    IF poisonTint > 0 THEN poisonTint = poisonTint - 1
    liqTick = liqTick + 1 ' (the monsters' clock, in harmful liquids)
    IF liqAny AND NOT editMode THEN LiquidHum playerX, playerY ' (the harmful ones bubble: louder as you near them - not in the editor, where the world's sounds are off)
    IF levelFlat AND NOT editMode AND NOT flyMode THEN playerZ = 0 : playerVZ = 0
    IF editMode OR flyMode OR playerVZ > 0 OR ABS(eyeZ - (playerZ + EYE_H)) < 0.01 THEN eyeZ = playerZ + EYE_H ELSE eyeZ = eyeZ + (playerZ + EYE_H - eyeZ) * 0.3
    ' ...and you can't walk through a monster: if a step takes you inside one
    ' (closer than touchDist) and closer than you were, take it back
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 2 AND NOT godMode AND NOT editMode AND (cyberOn = 0 OR monsterType(i) = MT_ICE) THEN ' (in the network the real world's machines aren't there)
            touchDist = 0.3 + mtypeScale(monsterType(i)) * 0.35
            newDistSq = (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2
            IF newDistSq < touchDist * touchDist AND newDistSq <(monsterX(i) - prevX) ^ 2 + (monsterY(i) -prevY) ^ 2 THEN playerX = prevX : playerY = prevY
        END IF
    NEXT

    ' Footsteps and the gun's bob keep one clock, bobPhase. It moves on by
    ' 2 pi for each stride actually walked (so walking into a wall makes
    ' no footsteps), the gun dips once each 2 pi (chapter 18), and a foot
    ' lands, alternately, at the bottom of each dip - when bobPhase passes
    ' an odd multiple of pi. A stride is STEP_WALK cells walking and up to
    ' STEP_RUN running: you run with longer strides, not just quicker ones.
    moved = SQR((playerX - prevX) ^ 2 + (playerY - prevY) ^ 2)
    IF editMode THEN moved = 0 ' (flying round the editor: no footsteps)
    IF flyMode THEN IF playerZ > floorH(INT(playerX), INT(playerY)) + 0.05 THEN moved = 0 ' (or in the air, flying)
    SwishSound moved, liqWas, dead ' (through a liquid: the water swishing round you)
    IF numSecrets THEN SecretHints ' (a closet cleared: its stash clicks)
    IF NOT levelFlat THEN IF playerZ - floorH(INT(playerX), INT(playerY)) > 0.05 AND liqWas = 0 THEN moved = 0 ' (in the air: none either)
    IF moved > 0 THEN
        stride = STEP_WALK + (STEP_RUN - STEP_WALK) * MaxOf(0, MinOf(1, (moveSpeed - WALK_SPEED) / (RUN_SPEED - WALK_SPEED)))
        beatWas = INT((bobPhase - 3.14159265) / 6.2831853)
        bobPhase = bobPhase + 6.2831853 * moved / stride
        IF INT((bobPhase - 3.14159265) / 6.2831853) <> beatWas THEN
            stepFoot = 1 - stepFoot
            IF liqWas <> 0 AND playerZ - floorH(INT(playerX), INT(playerY)) > 0.05 AND sndSwim1& > 0 THEN ' (out of your depth, floating: a swimming stroke)
                IF stepFoot THEN PlaySfx sndSwim1&, 0.55 ELSE PlaySfx sndSwim2&, 0.55
            ELSEIF liqWas <> 0 AND sndWade1& > 0 THEN ' (in a liquid: they slosh - "<> 0" and "> 0": AND of two numbers is bitwise, and water's kind 1 AND an even handle is 0)
                IF stepFoot THEN PlaySfx sndWade1&, 0.5 ELSE PlaySfx sndWade2&, 0.5
            ELSEIF stepFoot THEN
                PlaySfx sndStep1&, 0.35
            ELSE
                PlaySfx sndStep2&, 0.35
            END IF
        END IF
    END IF

    ' (Walking into a wall makes no sound - it got old fast. Pressing Space
    ' on one does: a dull hump, as you search it for secrets - chapter 11.)
