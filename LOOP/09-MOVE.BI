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
    IF knockX <> 0 OR knockY <> 0 THEN ' (a blast's knock - GAME/ROCKETS.BM: easing off; in the air, it carries you)
        moveX = moveX + knockX : moveY = moveY + knockY
        IF playerVZ < 0 OR playerZ > floorH(INT(playerX), INT(playerY)) + 0.02 THEN knockX = knockX * 0.96 : knockY = knockY * 0.96 ELSE knockX = knockX * 0.75 : knockY = knockY * 0.75
        IF ABS(knockX) < 0.002 AND ABS(knockY) < 0.002 THEN knockX = 0 : knockY = 0
    END IF
    IF godMode OR editMode THEN ' No clipping (god mode, or the editor): straight through anything, but stay inside the border
        playerX = playerX + moveX : playerY = playerY + moveY
        IF playerX < 1.01 THEN playerX = 1.01
        IF playerX > mapN - 1.01 THEN playerX = mapN - 1.01
        IF playerY < 1.01 THEN playerY = 1.01
        IF playerY > mapN - 1.01 THEN playerY = mapN - 1.01
    ELSE
        walkZ = playerZ : MoveBody playerX, playerY, moveX, moveY : walkZ = -999
    END IF
    ' Up and down (chapter 22's heights): step up onto anything low enough
    ' (MoveBody wouldn't have let you onto anything higher), fall off
    ' anything higher - faster and faster - and land, hard if it was far;
    ' fall into a pit and that's the end. Your eye eases up a step.
    ' A jetpack: FLY UP (E) lights it while there's fuel - or, looking up
    ' (LOOK UP / DOWN), walking forward does: up the way you look, not
    ' straight up. Then you fly as fly mode does - look down and walk, and
    ' down you go - burning fuel all the while you're up (more climbing);
    ' out of fuel you fall, and back on the ground it's off till it's lit again
    IF jetHave AND NOT dead AND NOT editMode AND NOT flyMode AND NOT cyberOn THEN
        jetClimb = (inBits AND DB_UP) <> 0 OR (lookAim AND forward > 0 AND pitch > JET_LOOK)
        IF NOT jetOn AND jetClimb AND jetFuel > 0 THEN jetOn = -1 : rocketAir = 0 : PlaySfx sndJet&, 0.7
        IF jetOn THEN
            IF NOT jetInf THEN jetFuel = jetFuel - JET_BURN : IF jetClimb THEN jetFuel = jetFuel - JET_CLIMB
            IF lvFrame MOD 40 = 0 THEN PlaySfx sndJet&, 0.55
            IF RND < 0.7 THEN SpawnPart PART_FLAME, playerX - dirX * 0.15, playerY - dirY * 0.15, playerZ + 0.15, (RND - 0.5) * 0.01, (RND - 0.5) * 0.01, -0.03, 10 + INT(RND * 8), 1, 0.6, 0.25, 0.04 ' (its exhaust, under you)
            IF jetFuel <= 0 THEN jetFuel = 0 : jetOn = 0 : playerVZ = 0 : PlaySfx sndPowerDown&, 0.8 : ShowMsg "Jetpack: out of fuel"
            IF jetOn AND NOT jetClimb AND playerZ <= floorH(INT(playerX), INT(playerY)) + 0.01 THEN jetOn = 0 ' (landed)
        END IF
    END IF
    IF editMode OR ((flyMode OR jetOn) AND NOT dead) THEN ' The editor, fly (god mode) or a jetpack lit: you fly - Space (the editor) or E (fly) up, C down (Shift faster), or on the way you look - no falling
        flySpeed = 0.04 : IF inBits AND DB_RUN THEN flySpeed = 0.1 : IF editMode THEN flySpeed = 0.25 ' (the editor, with Shift: a hall 30 walls high in two seconds)
        IF editMode THEN flyUp = _KEYDOWN(32) : flyDown = KeyHeld(BIND_DOWN) ELSE flyUp = (inBits AND DB_UP) <> 0 : flyDown = (inBits AND DB_DOWN) <> 0 ' (in play Space opens things)
        IF flyUp AND NOT edTyping THEN playerZ = playerZ + flySpeed
        IF flyDown AND NOT edTyping THEN playerZ = playerZ - flySpeed
        IF forward <> 0 THEN playerZ = playerZ + forward * moveSpeed * DSin(pitch) * 1.5 ' (and the way you look: look up and walk on, and you climb - OpenGL's look up and down)
        IF playerZ < -1.4 THEN playerZ = -1.4
        IF playerZ > H_MAX * H_STEP + 0.5 THEN playerZ = H_MAX * H_STEP + 0.5 ' (as high as a sector goes: 30 walls, and a little over)
        IF NOT editMode THEN ' (in play: your eye stays under the ceiling - above it the room isn't drawn - and the floor still holds you up)
            IF playerZ > ceilH(INT(playerX), INT(playerY)) - BODY_H - 0.01 THEN playerZ = ceilH(INT(playerX), INT(playerY)) - BODY_H - 0.01 ' (room to move on: Walkable wants BODY_H)
            IF playerZ < floorH(INT(playerX), INT(playerY)) THEN playerZ = floorH(INT(playerX), INT(playerY))
        END IF
        playerVZ = 0 : rocketAir = 0
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
        IF liftCell(INT(playerX), INT(playerY)) THEN IF playerZ - fz < MaxOf(0.06, liftSpeed(liftCell(INT(playerX), INT(playerY))) + 0.02) AND playerVZ < 0.03 AND playerVZ >= 0 THEN playerZ = fz : playerVZ = 0 ' (riding a lift down - however fast it goes)
        IF playerZ > fz THEN
            IF rocketAir THEN playerVZ = playerVZ + FALL_G * ROCKET_FALL ELSE playerVZ = playerVZ + FALL_G ' (a rocket jump: floatier)
            playerZ = playerZ - playerVZ
            IF playerVZ < 0 AND playerZ > ceilH(INT(playerX), INT(playerY)) - BODY_H - 0.01 THEN playerZ = ceilH(INT(playerX), INT(playerY)) - BODY_H - 0.01 : playerVZ = 0 ' (thrown up: your head on the ceiling)
            IF playerZ <= fz THEN
                IF liqKind(INT(playerX), INT(playerY)) THEN playerVZ = playerVZ * 0.5 ' (into a liquid: it breaks the fall)
                IF playerVZ > 0.13 AND NOT dead AND NOT godMode AND NOT rocketAir THEN ' (a fall that hurts - not a rocket jump's, you meant that - - about a wall's drop or more: the thud, the jolt; anything less is just a step down, and the footsteps carry on)
                    damage = INT((playerVZ - 0.13) * 260) + 2 : hurtFromX = -1 : hurtFromY = -1 : HurtPlayer
                    PlaySfx sndStep1&, 1 : shake = shake + 8
                END IF
                playerZ = fz : playerVZ = 0 : rocketAir = 0
            END IF
        ELSE
            rocketAir = 0 ' (on the ground: a rocket jump's over)
        END IF
        IF fz <= PIT_DEPTH AND playerZ < -0.6 AND NOT dead AND NOT godMode AND liftCell(INT(playerX), INT(playerY)) = 0 THEN damage = 999 : hurtFromX = -1 : hurtFromY = -1 : HurtPlayer : ShowMsg "You fell into the dark"
    END IF
    ' A burning floor (molten metal, lava): it hurts while you stand in it
    IF burnWait > 0 THEN burnWait = burnWait - 1
    IF FloorHazard(INT(playerX), INT(playerY)) = HAZ_BURN AND playerZ - floorH(INT(playerX), INT(playerY)) < 0.05 AND NOT dead THEN
        IF burnWait = 0 THEN
            burnWait = BURN_EVERY : PlaySfx sndSizzle&, 0.9
            SpawnSparks playerX + dirX * 0.3, playerY + dirY * 0.3, 0.05, 12, 255, 120, 30
            IF NOT godMode THEN damage = BURN_DAMAGE : hurtFromX = -1 : hurtFromY = -1 : hurtR = 255 : hurtG = 110 : hurtB = 20 : HurtPlayer
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
            IF suitLeft > 0 AND lk <> LQ_LAVA THEN ' The hazmat suit takes it, and wears: nothing gets through till it's worn out (lava burns through it)
                suitLeft = MaxOf(0, suitLeft - dmg * SUIT_WEAR) : PlaySfx sndSizzle&, 0.35
                IF suitLeft = 0 THEN PlaySfx sndPowerDown&, 0.8 : ShowMsg "Hazmat suit: worn through"
            ELSEIF NOT godMode THEN
                IF lk = LQ_POISON THEN poisonTint = 40 : Poisoned dmg
                IF lqAcid(lk) AND armor > 0 THEN ' Acid: the armor first
                    armor = MaxOf(0, armor - dmg * 2) : hurtFlash = 6 : PlaySfx sndSizzle&, 0.7 : Achieve "NC_CORRODED", 0
                    painR = lqR(lk) : painG = lqG(lk) : painB = lqB(lk) : painVig = MaxOf(painVig, 0.5)
                ELSE
                    IF lk = LQ_LAVA OR lk = LQ_ACID THEN PlaySfx sndSizzle&, 0.9
                    damage = dmg : hurtFromX = -1 : hurtFromY = -1 : hurtR = lqR(lk) : hurtG = lqG(lk) : hurtB = lqB(lk) : HurtPlayer
                END IF
            END IF
        END IF
    END IF
    PoisonFrame ' (poisoned: it goes on hurting - GAME/ROCKETS.BM)
    IF poisonTint > 0 THEN poisonTint = poisonTint - 1
    liqTick = liqTick + 1 ' (the monsters' clock, in harmful liquids)
    IF liqAny AND NOT editMode THEN LiquidHum playerX, playerY ' (the harmful ones bubble: louder as you near them - not in the editor, where the world's sounds are off)
    IF levelFlat AND NOT editMode AND NOT flyMode AND NOT jetOn THEN playerZ = 0 : playerVZ = 0
    IF editMode OR flyMode OR playerVZ > 0 OR ABS(eyeZ - (playerZ + EYE_H)) < 0.01 THEN eyeZ = playerZ + EYE_H ELSE eyeZ = eyeZ + (playerZ + EYE_H - eyeZ) * 0.3
    IF NOT levelFlat THEN IF eyeZ > ceilH(INT(playerX), INT(playerY)) - 0.06 THEN eyeZ = MaxOf(playerZ + 0.04, ceilH(INT(playerX), INT(playerY)) - 0.06) ' (a crusher coming down on you: you see from under it)
    ' ...and you can't walk through a monster: if a step takes you inside one
    ' (closer than touchDist) and closer than you were, take it back
    FOR i = 1 TO numMonsters
        IF monsterState(i) < 2 AND NOT godMode AND NOT editMode AND (cyberOn = 0 OR monsterType(i) = MT_ICE) AND monsterType(i) <> MT_TURRET THEN ' (in the network the real world's machines aren't there; a turret's in the ceiling, or a low thing you step round)
            touchDist = 0.3 + mtypeScale(monsterType(i)) * 0.35
            IF monFly(i) > 0 THEN IF MonFoot(i) > playerZ + BODY_H THEN touchDist = 0 ' (a drone flown up over your head: you walk under it)
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
