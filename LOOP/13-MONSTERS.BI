''
' NEON-CASTER - LOOP/13-MONSTERS.BI
' =============================================================================
' Chapter 13 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 13: MONSTERS, BOLTS AND BARRELS
    '-------------------------------------------------------------------------
    ' Each monster is a little "state machine": what it does depends on
    ' which state it's in, and things that happen move it to another state.
    '
    '   0 idle     waits until it can see you (CanSee walks a line from it
    '              to you, checking for walls and shut doors - chapter 23)
    '   1 hunting  forever after: walks at you and attacks when close
    '              enough - or, if it shoots (mtypeRanged), keeps its
    '              distance and fires bolts whenever it has a clear line
    '   2 dying    falls for MON_DYING frames: sinks to the floor, then
    '              lies there (its body: MakeCorpse, chapter 23)
    '   3 dead     a body on the floor; skipped by everything else
    '
    ' Shooting an idle monster wakes it too (HitMonster, chapter 19).
    ' Monsters steer the dumbest way possible - straight at you - and slide
    ' along walls with MoveBody like you do. They also push gently apart, so
    ' a pack doesn't merge into one sprite.
    ' (chatterWait: frames before any monster may mutter or growl again, so
    ' a crowd doesn't drown everything)
    IF chatterWait > 0 THEN chatterWait = chatterWait - 1
    FOR i = 1 TO MAX_BEAMS ' (the beams a frame on: a laser's aim is drawn the frame it's made, and gone the next unless it's made again)
        IF beamT(i) > 0 THEN beamT(i) = beamT(i) - 1
    NEXT
    FOR i = 1 TO numMonsters
        IF cyberOn AND monsterType(i) <> MT_ICE THEN _CONTINUE ' (in the real world: they wait)
        IF editMode OR hudEdit THEN _CONTINUE ' (in the editors: everything waits)
        IF monsterType(i) = MT_MIMIC AND monsterState(i) = 0 AND NOT noTarget AND NOT dead THEN IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < 1 THEN MimicWake i ' (a "chest" you've come right up to)
        IF monBlown(i) = 2 THEN TurretStump i ' (a destroyed turret's mount: sparks, arcs, smoke - GAME/TURRETS.BM)
        IF noTarget AND monsterState(i) = 1 THEN monsterState(i) = 0 : IF monsterType(i) = MT_TURRET AND monDeploy(i) > 0 AND monDeploy(i) < TURRET_UP THEN monDeploy(i) = 0 ' (notarget: whatever woke it, it forgets you - before it can chase or shoot; a turret half out, back in its housing)
        IF monsterHurt(i) > 0 THEN monsterHurt(i) = monsterHurt(i) -1
        IF monsterAtk(i) > 0 THEN monsterAtk(i) = monsterAtk(i) - 1
        ' Kicked over the edge of a pit with no bottom (it never walks off
        ' one): gone into the dark
        IF monsterState(i) < 2 AND NOT levelFlat THEN
            IF floorH(INT(monsterX(i)), INT(monsterY(i))) <= PIT_DEPTH AND mtypeLift(monsterType(i)) = 0 AND monFly(i) = 0 AND liftCell(INT(monsterX(i)), INT(monsterY(i))) = 0 THEN target = i : hitDamage = 9999 : HitMonster : ShowMsg "Over the edge!" : Achieve "NC_OVER_EDGE", 0
        END IF
        ' Knocked into a harmful liquid (it never walks into one): it hurts
        ' as it does you - but not what hovers over it
        IF monsterState(i) < 2 AND liqAny THEN
            mlk = liqKind(INT(monsterX(i)), INT(monsterY(i)))
            IF mlk THEN
                IF lqHurt(mlk) > 0 AND lqEvery(mlk) > 0 AND mtypeLift(monsterType(i)) = 0 THEN ' (QB64 works out every part of an AND: the MOD only once lqEvery is known not to be 0)
                    IF (liqTick + i) MOD lqEvery(mlk) = 0 THEN
                        target = i : hitDamage = MaxOf(1, lqHurt(mlk) \ 3) : HitMonster
                        SpawnSparks monsterX(i), monsterY(i), liqZ(INT(monsterX(i)), INT(monsterY(i))) - FloorAt(monsterX(i), monsterY(i)), 8, lqR(mlk), lqG(mlk), lqB(mlk)
                    END IF
                END IF
            END IF
        END IF
        mtype = monsterType(i)
        ' Its animation moves on: walkers and the crawler as far as they
        ' walked (a frame every MON_STRIDE of a cell), the drone and the
        ' sentry all the time (hovering, scanning) - a little slower idle
        animX = monsterX(i) : animY = monsterY(i)
        IF mtype = 1 OR mtype = 5 OR mtype = 8 THEN IF monsterState(i) < 2 THEN monsterAnim(i) = monsterAnim(i) + 0.12 - 0.06 * (monsterState(i) = 0) ' (hovering, scanning: slower asleep)
        SELECT CASE monsterState(i)
            CASE 0 ' Idle: wake when it can see you - and mutter now and then
                ' (a sound about every 8 seconds, if you're near enough to hear:
                ' SFX_CHATTER cells)
                IF RND < 0.002 AND chatterWait = 0 THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < SFX_CHATTER * SFX_CHATTER THEN SfxAtRange mtypeIdleSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY, SFX_CHATTER : chatterWait = 30
                END IF
                IF NOT dead AND NOT noTarget AND monWake(i) <> WAKE_HIT THEN ' (asleep till it's hit: nothing else wakes it)
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) -playerY) ^ 2 < monSight(i) * monSight(i) THEN
                        IF monWake(i) = WAKE_NEAR OR CanSee(monsterX(i), monsterY(i), playerX, playerY) THEN ' (an ambush: you near enough, seen or not)
                            monsterState(i) = 1 : monsterTimer(i) = 30
                            SfxAt mtypeAlertSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                            IF mtype = 8 THEN Say "boss", 0 ' (the overseer: NEXUS speaks through it)
                            IF mtype = MT_ROBODOG THEN DogBark i ' (a guard dog: its bark wakes every machine that hears it)
                            IF (mtype = 2 OR mtype = 6 OR mtype = 7) AND RND < 0.35 THEN SayAt "bark" + LTRIM$(STR$(INT(RND * 6) + 1)), monsterX(i), monsterY(i) ' (a minion reports in - from where it is)
                        END IF
                    END IF
                END IF
            CASE 1 ' Hunting - growling or whirring as it comes (about every 4 seconds)
                IF monsterTimer(i) > 0 THEN monsterTimer(i) = monsterTimer(i) -1
                IF RND < 0.004 AND chatterWait = 0 THEN
                    IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < SFX_CHATTER * SFX_CHATTER THEN SfxAtRange mtypeHuntSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY, SFX_CHATTER : chatterWait = 30
                END IF
                ' Who it's after: you - or the monster it's turned on (monFoe:
                ' it hurt it - GAME/MONSTERS.BM's MonHurtBy), while that's alive
                monVs = monFoe(i) : IF monVs THEN IF monsterState(monVs) >= 2 OR cyberOn OR monVs = i THEN monFoe(i) = 0 : monVs = 0
                IF monVs THEN monTX = monsterX(monVs) : monTY = monsterY(monVs) : monTZ = MonFoot(monVs) ELSE monTX = playerX : monTY = playerY : monTZ = playerZ
                toPlayerX = monTX - monsterX(i) : toPlayerY = monTY - monsterY(i) : distance = SQR(toPlayerX * toPlayerX + toPlayerY * toPlayerY)
                boltFromMon = i ' (its shots are its own: what they hit, it hit)
                IF mtypeLift(mtype) > 0 AND NOT cyberOn THEN MonFlyTurn i ' (a flyer: up or down to who it's after)
                IF (NOT dead OR monVs) AND distance > 0.01 THEN
                    goX = 0 : goY = 0
                    gRun = 0 : IF mtype = MT_GUARD AND monVs = 0 THEN gRun = GuardRun(i) ' (a guard: for the alarm switch first - GAME/ALARMS.BM)
                    IF numArmed > 0 AND monVs = 0 THEN AlarmMobPress i ' (passing a switch that's on: now and then, slapped)
                    IF mtype = MT_THIEF THEN
                        ThiefStep
                    ELSEIF gRun THEN
                        ' (running for the alarm: GuardRun set goX, goY)
                    ELSEIF mtypeStyle(mtype) THEN ' (the newer kinds: how each fights - MonStyleTurn)
                        MonStyleTurn i
                    ELSEIF mtypeRanged(mtype) THEN
                        ' Gunner: keep its distance, shoot when it has a clear line
                        ' (a sentry can't move, so it just shoots)
                        seen = CanSee(monsterX(i), monsterY(i), monTX, monTY)
                        IF distance > GUNNER_FAR OR NOT seen THEN goX = toPlayerX / distance : goY = toPlayerY / distance
                        IF distance < GUNNER_NEAR THEN goX = - toPlayerX / distance : goY = -toPlayerY / distance
                        IF seen AND monsterTimer(i) = 0 AND distance < 11 THEN
                            FireBolt monsterX(i), monsterY(i), toPlayerX / distance, toPlayerY / distance, mtypeDamage(mtype) + INT(GRnd * mtypeDamageRnd(mtype))
                            IF mtype = 8 THEN ' The overseer: a fan of three (two more, turned a little either way)
                                FOR spread = -1 TO 1 STEP 2
                                    spreadA = spread * 0.22 : ux = toPlayerX / distance : uy = toPlayerY / distance
                                    FireBolt monsterX(i), monsterY(i), ux * DCos(spreadA) - uy * DSin(spreadA), ux * DSin(spreadA) + uy * DCos(spreadA), mtypeDamage(mtype)
                                NEXT
                            END IF
                            monsterAtk(i) = ATTACK_FRAMES
                            SfxAt mtypeAttackSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                            monsterTimer(i) = mtypeCooldown(mtype) + INT(GRnd * 30)
                        END IF
                    ELSEIF distance > mtypeReach(mtype) THEN
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' The rest: close in...
                    ELSEIF GlassBetween(monsterX(i), monsterY(i), monTX, monTY) THEN
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' (glass between: it just presses against it)
                    ELSEIF ABS(MonFoot(i) - monTZ) > 0.7 THEN ' (you up a ledge, or down one - a flyer still flying up or down to you: claws don't reach)
                        goX = toPlayerX / distance : goY = toPlayerY / distance ' (you're up a ledge, or down one: claws don't reach)
                    ELSEIF monsterTimer(i) = 0 THEN ' ...and hit
                        dmg = mtypeDamage(mtype) + INT(GRnd * mtypeDamageRnd(mtype)) : monsterTimer(i) = mtypeCooldown(mtype)
                        SfxAt mtypeAttackSnd&(mtype), monsterX(i), monsterY(i), playerX, playerY
                        MonStrike i, dmg ' (you - or the monster it's turned on)
                        monsterAtk(i) = ATTACK_FRAMES
                    END IF
                    IF (goX <> 0 OR goY <> 0) AND mtypeSpeed(mtype) > 0 THEN ' A door in the way? Open it (MonsterDoor, chapter 11)
                        MonsterDoor INT(monsterX(i) + goX * 0.7), INT(monsterY(i)), playerX, playerY
                        MonsterDoor INT(monsterX(i)), INT(monsterY(i) + goY * 0.7), playerX, playerY
                    END IF
                    walkZ = floorH(INT(monsterX(i)), INT(monsterY(i))) ' (it steps up, and falls off, as you do - but only so high)
                    IF monFly(i) > 0 THEN walkZ = walkZ + monFly(i) ' (a flyer: over anything below it)
                    walkFromHaz = FloorHazard(INT(monsterX(i)), INT(monsterY(i))) + 10 ' (and keeps out of fire, unless it's in it already)
                    mlk = liqKind(INT(monsterX(i)), INT(monsterY(i))) : msl = 1 ' (...and out of harmful liquids - and wades slower in any)
                    IF mlk AND mtypeLift(mtype) = 0 AND NOT cyberOn THEN
                        msl = LiquidSlow(mlk, liqZ(INT(monsterX(i)), INT(monsterY(i))) - floorH(INT(monsterX(i)), INT(monsterY(i))))
                        IF lqHurt(mlk) > 0 THEN walkFromHaz = walkFromHaz + 100 ' (in one already: it may walk on through)
                    END IF
                    IF mtypeLift(mtype) > 0 THEN walkFromHaz = walkFromHaz + 100 ' (it hovers: liquids are nothing to it)
                    mfz = floorH(INT(monsterX(i)), INT(monsterY(i))) ' (the floor it left: a flyer keeps its height, not its height off the floor)
                    IF goX <> 0 OR goY <> 0 THEN MoveBody monsterX(i), monsterY(i), goX * mtypeSpeed(mtype) * monSpd(i) * msl, goY * mtypeSpeed(mtype) * monSpd(i) * msl
                    IF monFly(i) > 0 THEN monFly(i) = MaxOf(0, monFly(i) - (floorH(INT(monsterX(i)), INT(monsterY(i))) - mfz))
                    walkZ = -999 : walkFromHaz = 0
                END IF
                boltFromMon = 0 : monVs = 0
                monsterAnim(i) = monsterAnim(i) + SQR((monsterX(i) - animX) ^ 2 + (monsterY(i) - animY) ^ 2) / MON_STRIDE
                ' Keep a little apart from each other - by the rules it walks by: no
                ' shove up a ledge, off an edge, into fire or a harmful pool
                walkZ = floorH(INT(monsterX(i)), INT(monsterY(i))) : walkFromHaz = FloorHazard(INT(monsterX(i)), INT(monsterY(i))) + 10
                IF mtypeLift(mtype) > 0 THEN walkFromHaz = walkFromHaz + 100
                IF liqKind(INT(monsterX(i)), INT(monsterY(i))) THEN IF lqHurt(liqKind(INT(monsterX(i)), INT(monsterY(i)))) > 0 THEN walkFromHaz = walkFromHaz + 100
                FOR j = 1 TO numMonsters
                    IF j <> i AND monsterState(j) < 2 AND mtypeSpeed(mtype) > 0 THEN
                        relX = monsterX(i) - monsterX(j) : relY = monsterY(i) -monsterY(j) : distSq = relX * relX + relY * relY
                        IF distSq < 0.36 AND distSq > 0.0001 THEN
                            newX = monsterX(i) + relX * 0.05 : newY = monsterY(i) + relY * 0.05
                            IF BoxFree(newX, newY) THEN monsterX(i) = newX : monsterY(i) = newY
                        END IF
                    END IF
                NEXT
                walkZ = -999 : walkFromHaz = 0
            CASE 2 ' Dying: collapse
                IF monFly(i) > 0 THEN monFly(i) = MaxOf(0, monFly(i) - 0.06) ' (a flyer: falling out of the air)
                IF monBlown(i) = 1 THEN TurretBlown i ' (a turret, destroyed: it blows up - GAME/TURRETS.BM)
                monsterTimer(i) = monsterTimer(i) -1
                IF monsterTimer(i) <= 0 THEN
                    monsterState(i) = 3
                    IF monsterType(i) = MT_TURRET AND monFrom(i) = 0 THEN ' (a turret from the ceiling: it's hit the floor - a crash, sparks, the floor shakes)
                        SpawnSparks monsterX(i), monsterY(i), 0.05, 20, 255, 190, 80 : SfxAt mtypeDieSnd&(MT_TURRET), monsterX(i), monsterY(i), playerX, playerY
                        IF (monsterX(i) - playerX) ^ 2 + (monsterY(i) - playerY) ^ 2 < 25 THEN shake = shake + 4
                    END IF
                END IF
        END SELECT
    NEXT

    ' Bolts fly in a straight line, a little each frame, and burst on walls
    ' or on you. Since they move only 0.14 cells a frame, checking the one
    ' point where each bolt is can't miss a wall.
    FOR i = 1 TO MAX_BOLTS
        IF boltOn(i) AND boltKind(i) <> BK_PLASMA THEN BoltFly i : _CONTINUE ' (a rocket, a missile, a spray's puff: GAME/ROCKETS.BM)
        IF boltOn(i) THEN
            boltX(i) = boltX(i) + boltDX(i) * BOLT_SPEED : boltY(i) = boltY(i) + boltDY(i) * BOLT_SPEED : boltZ(i) = boltZ(i) + boltDZ(i) * BOLT_SPEED
            IF NOT levelFlat THEN ' (heights: into a step, a floor or a ceiling, it bursts)
                IF boltZ(i) < floorH(INT(boltX(i)), INT(boltY(i))) + 0.02 OR boltZ(i) > ceilH(INT(boltX(i)), INT(boltY(i))) - 0.02 THEN boltX(i) = boltX(i) - boltDX(i) * 0.05 : boltY(i) = boltY(i) - boltDY(i) * 0.05 : boltOn(i) = 0 : SpawnSparks boltX(i), boltY(i), boltZ(i) - floorH(INT(boltX(i)), INT(boltY(i))), 7, 255, 60, 230 : SfxAt sndBoltWall&, boltX(i), boltY(i), playerX, playerY
            END IF
            IF boltOn(i) = 0 THEN
            ELSEIF InGlass(boltX(i), boltY(i)) THEN ' Glass: it bursts on it, and cracks it
                boltOn(i) = 0 : SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, 0.49, 7, 255, 60, 230
                glassHitX = INT(boltX(i)) : glassHitY = INT(boltY(i)) : glassAtX = boltX(i) : glassAtY = boltY(i) : glassDmg = 1 : HitGlass
            ELSEIF BoltDeco(boltX(i), boltY(i), boltZ(i)) THEN ' A decoration in its way: the bolt bursts on it - and hurts it as your shots do (a crate breaks, loot and all; a barrel blows)
                targetDeco = BoltDeco(boltX(i), boltY(i), boltZ(i)) : boltOn(i) = 0
                SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, boltZ(i) - FloorAt(boltX(i), boltY(i)), 7, 255, 60, 230
                hitDamage = boltDamage(i) : hitKick = 0 : decoByMon = -1 : HitDeco : decoByMon = 0
            ELSEIF BoltMon(boltX(i), boltY(i), boltZ(i), boltOwner(i)) THEN ' Another monster in its way: hit (and it may turn on the one that shot it - INFIGHTING)
                j = BoltMon(boltX(i), boltY(i), boltZ(i), boltOwner(i)) : boltOn(i) = 0
                SpawnSparks boltX(i), boltY(i), boltZ(i) - FloorAt(boltX(i), boltY(i)), 7, 255, 60, 230
                MonHurtBy j, boltOwner(i), boltDamage(i)
            ELSEIF NOT Walkable(boltX(i), boltY(i)) THEN
                boltOn(i) = 0 : SfxAt sndBoltWall&, boltX(i), boltY(i), playerX, playerY
                SpawnSparks boltX(i) - boltDX(i) * 0.15, boltY(i) - boltDY(i) * 0.15, 0.49, 7, 255, 60, 230
                IF IsWall(INT(boltX(i)), INT(boltY(i))) THEN ShotMark boltX(i) - boltDX(i) * BOLT_SPEED, boltY(i) - boltDY(i) * BOLT_SPEED, boltZ(i), boltDX(i), boltDY(i), 0, 0.12
            ELSEIF NOT dead AND (boltX(i) - playerX) ^ 2 + (boltY(i) -playerY) ^ 2 < 0.35 * 0.35 AND ABS(boltZ(i) - playerZ - 0.45) < 0.5 THEN
                boltOn(i) = 0 : damage = boltDamage(i)
                hurtFromX = boltX(i) - boltDX(i) * 2 : hurtFromY = boltY(i) - boltDY(i) * 2 ' (back along its path)
                HurtPlayer
            END IF
        END IF
    NEXT
    GibsAndFires ' (a rocket's pieces flying, and what it set burning: GAME/ROCKETS.BM)
    ' Barrels: a shot lights a fuse (decoFuse), which counts down frames and
    ' then the barrel blows up (Explode, chapter 19). A blast lights the
    ' fuses of barrels near it, so they go off in a quick chain - and breaks
    ' the lamps, plants and terminals near it. Explosions on show fade out
    ' over BLAST_FRAMES.
    StacksSettle ' (barrels on barrels: one with less under it falls - GAME/BARRELS.BM)
    FOR i = 1 TO numDecos
        IF decoFuse(i) > 0 THEN
            IF decoLeak(i) > 0 THEN BarrelLeak i ' (a liquid barrel: spurting, hissing)
            decoFuse(i) = decoFuse(i) - 1
            IF decoFuse(i) = 0 THEN barrel = i : Explode
        END IF
        IF vendState(i) = 1 OR vendState(i) = 2 THEN VendStep ' (a vending machine you pressed Space on)
        IF decoTimer(i) > 0 THEN decoTimer(i) = decoTimer(i) - 1 ' A broken one collapsing
    NEXT
    FOR i = 1 TO numItems ' Loot thrown out of something broken, flying to where it lands (TossItem)
        IF itemToss(i) > 0 THEN itemToss(i) = itemToss(i) - 1 : itemX(i) = itemX(i) + itemVX(i) : itemY(i) = itemY(i) + itemVY(i)
    NEXT
    FOR i = 1 TO MAX_BLASTS
        IF blastTime(i) > 0 THEN blastTime(i) = blastTime(i) - 1
    NEXT
    IF railBeam > 0 THEN railBeam = railBeam - 1
    ' Particles (sparks, embers and dust, drawn by OpenGL - chapter 24) move
    ' on; dust drifts in around you with the PARTICLES effect on, and swirls
    ' out of your way as you walk through it (playerX - prevX: this frame's
    ' step, from chapter 9)
    UpdateParticles playerX, playerY, playerX - prevX, playerY - prevY
    IF glMode AND setting(SET_PARTICLES) THEN SpawnDust playerX, playerY

    IF hurtFlash > 0 THEN hurtFlash = hurtFlash - 1
    IF painVig > 0 THEN painVig = MaxOf(0, painVig - 0.025) ' (the hurt edges fade, over 40 frames or so)
    ' LOW ON HEALTH: your heart pounds - a beat every 1.2 seconds at LOW_HP,
    ' every 0.6 near death, louder the lower you are - and now and then a
    ' gasp, a breath, a groan, quietly (DrawVignette thumps red with the beat)
    IF health <= LOW_HP AND health > 0 AND NOT dead AND NOT editMode AND NOT godMode AND NOT cyberOn THEN
        lowness = 1 - health / LOW_HP
        IF TIMER(0.001) >= beatNext OR beatNext - TIMER(0.001) > 5 THEN ' (or TIMER went past midnight)
            beatAt = TIMER(0.001) : beatNext = beatAt + 1.2 - 0.6 * lowness
            IF sndHeart& THEN PlaySfx sndHeart&, 0.35 + 0.5 * lowness
        END IF
        IF TIMER(0.001) >= gaspNext OR gaspNext - TIMER(0.001) > 30 THEN
            IF gaspNext > 0 THEN
                SELECT CASE INT(RND * 5)
                    CASE 0 : IF sndBreath& THEN PlaySfx sndBreath&, 0.3
                    CASE 1 : IF sndGroan& THEN PlaySfx sndGroan&, 0.15
                    CASE ELSE : k = INT(RND * 3) + 1 : IF sndGasp&(k) THEN PlaySfx sndGasp&(k), 0.075
                END SELECT
            END IF
            gaspNext = TIMER(0.001) + 4 + RND * 6
        END IF
    ELSE
        beatNext = 0 : gaspNext = 0 : beatAt = 0
    END IF
    ' Night vision: N (BIND_NIGHT) on and off, once you have a headset (it's
    ' yours till you die, as a gun is)
    nvKey = (inBits AND DB_NIGHT) <> 0
    IF nvKey AND NOT nvKeyWas AND NOT editMode AND NOT dead THEN
        IF nvHave THEN
            nvOn = NOT nvOn : IF nvOn THEN PlaySfx sndPowerUp&, 0.7 ELSE PlaySfx sndPowerDown&, 0.6
        ELSE
            ShowMsg "No night vision - find a headset"
        END IF
    END IF
    nvKeyWas = nvKey
    IF invTimer > 0 THEN ' Invulnerability wears off
        invTimer = invTimer - 1 : IF invTimer = 0 THEN PlaySfx sndInvulnEnd&, 0.8 : ShowMsg "Invulnerability wore off"
    END IF
    IF invFlash > 0 THEN invFlash = invFlash - 1
    AlarmStep ' (the alarm's siren going round - GAME/ALARMS.BM)
    DrainStep ' (pools draining away - WORLD/LIQUIDS.BM)
    IF ampTimer > 0 THEN ' The damage amp wears off
        ampTimer = ampTimer - 1 : IF ampTimer = 0 THEN PlaySfx sndAmpEnd&, 0.8 : ShowMsg "Damage amp wore off"
    END IF
    IF pickFlash > 0 THEN pickFlash = pickFlash - 1
