''
' NEON-CASTER - LOOP/12-SHOOTING.BI
' =============================================================================
' Chapter 12 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 12: SHOOTING
    '-------------------------------------------------------------------------
    ' Shots are "hitscan": they hit instantly, nothing flies. A shot goes
    ' straight out through one column of the screen - the middle one, or a
    ' little to the side for a scatter gun's pellets (aim, from -1 at the
    ' left edge to 1 at the right). What does it hit?
    '
    ' For each monster we work out where it is on screen, exactly as
    ' chapter 16 does to draw it: transformY is how far in front of you it
    ' is, and transformX / transformY says how far across the screen. If
    ' the shot's column passes through the monster's sprite, it's in the
    ' line of fire. The nearest one wins - unless the wall in that column is
    ' nearer still. zBuffer() still holds each column's wall distance from
    ' drawing the last frame (chapter 15), so that's a free answer to "is
    ' there a wall in the way?"
    '
    ' Decorations can be hit the same way: a barrel blows up (chapter 13),
    ' anything else takes damage and breaks (HitDeco, chapter 19). The
    ' railgun's shot doesn't stop at the first thing: it hits everything in
    ' its line that's nearer than the wall.
    '
    ' Hold the button to keep firing: fireWait counts down the frames until
    ' the gun can fire again.
    IF fireWait > 0 THEN fireWait = fireWait - 1
    IF editMode THEN fireDown = 0 ' (in the editor the button builds, not shoots: EditFP)
    IF fireDown AND NOT dead AND fireWait = 0 AND swapTimer = 0 THEN
        ammoType = gunAmmoType(currentGun)
        IF ammoCount(ammoType) >= gunAmmoPerShot(currentGun) THEN
            ammoCount(ammoType) = ammoCount(ammoType) - gunAmmoPerShot(currentGun) : fireWait = gunDelay(currentGun) : recoil = gunKick(currentGun) : muzzleFlash = 4
            PlaySfx gunSnd&(currentGun), 0.7
            FOR j = 1 TO numMonsters ' (heard: a monster that hears this far wakes - [monsters])
                IF monsterState(j) = 0 AND monHear(j) > 0 AND monWake(j) <> WAKE_HIT AND (cyberOn = 0 OR monsterType(j) = MT_ICE) THEN
                    IF (monsterX(j) - playerX) ^ 2 + (monsterY(j) - playerY) ^ 2 < monHear(j) * monHear(j) THEN monsterState(j) = 1 : monsterTimer(j) = 30 : SfxAt mtypeAlertSnd&(monsterType(j)), monsterX(j), monsterY(j), playerX, playerY
                END IF
            NEXT
            StirDust playerX, playerY, dirX, dirY, 5, 0.02 * gunKick(currentGun) ' (the shot's wind blows the dust along - chapter 24)
            hitDamage = gunDamage(currentGun) : IF gunPierce(currentGun) THEN railBeam = 8
            IF currentGun <> W_BLASTER THEN achOtherGun = -1
            IF ampTimer > 0 THEN hitDamage = hitDamage * 2 ' (the damage amp: double)
            shake = shake + gunKick(currentGun) * 1.5 ' (a big gun shakes the screen - chapter 17)
            IF setting(SET_XFEEDBACK) THEN crossScale = 0.6 ' The crosshair tightens as you fire
            invDet = 1 /(planeX * dirY - dirX * planeY)
            pellets = gunPellets(currentGun)
            IF currentGun = W_ROCKET THEN FireRocket : pellets = 0 ' (a rocket: it flies - GAME/ROCKETS.BM - and there's no shot along the line)
            FOR pellet = 1 TO pellets
                aim = (GRnd * 2 - 1) * gunSpread(currentGun) ' Across the view: -1 left edge .. 1 right
                IF gunPellets(currentGun) > 1 THEN aim = ((pellet - 1) /(gunPellets(currentGun) -1) * 2 - 1) * gunSpread(currentGun) + (GRnd - 0.5) * 0.02
                screenCol = INT(RENDER_W / 2 * (1 + aim)) : IF screenCol < 0 THEN screenCol = 0
                IF screenCol > RENDER_W - 1 THEN screenCol = RENDER_W-1
                ' (a piercing shot hits everything in its line that's nearer than
                ' the wall; any other shot just the nearest monster or decoration)
                bestMonster = 0 : bestDeco = 0 : bestDist = zBuffer(screenCol)
                ' Glass nearer than the wall stops the shot (but the rail goes
                ' straight through it, and shatters it)
                glassShot = 0
                IF glassT(screenCol) > 0 AND glassT(screenCol) < bestDist THEN
                    glassHitX = glassCX(screenCol) : glassHitY = glassCY(screenCol)
                    glassAtX = playerX + (dirX + planeX * aim) * glassT(screenCol) : glassAtY = playerY + (dirY + planeY * aim) * glassT(screenCol)
                    IF gunPierce(currentGun) THEN glassDmg = 99 : HitGlass ELSE bestDist = glassT(screenCol) : glassShot = -1
                END IF
                ' Where it lands on a monster counts too: in its weak spot (a head,
                ' an eye - WeakSpotHit), double the damage. How far across its
                ' picture: the shot's column against its middle; how high: your
                ' eye, rising TAN(pitch) a cell as the shot goes (LOOK UP / DOWN -
                ' level, without it, as the software renderer's shots fly)
                rayLen = SQR((dirX + planeX * aim) ^ 2 + (dirY + planeY * aim) ^ 2) : bestHead = 0
                FOR i = 1 TO numMonsters
                    IF monsterState(i) < 2 AND (cyberOn = 0 OR monsterType(i) = MT_ICE) THEN
                        relX = monsterX(i) - playerX : relY = monsterY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < viewH / transformY * mtypeScale(monsterType(i)) * 0.3 AND NOT ShotPasses(i, eyeZ + DTan(pitch) * rayLen * transformY) THEN
                                shotU = 0.5 + RENDER_W / 2 * (aim - transformX / transformY) / (viewH / transformY * mtypeScale(monsterType(i)))
                                head = WeakSpotHit(i, shotU, eyeZ + DTan(pitch) * rayLen * transformY)
                                IF gunPierce(currentGun) THEN
                                    target = i : headZ = eyeZ + DTan(pitch) * rayLen * transformY : HitMonsterAimed : crossFlash = 6
                                ELSE
                                    bestMonster = i : bestDist = transformY : bestHead = head : bestHeadZ = eyeZ + DTan(pitch) * rayLen * transformY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                FOR i = 1 TO numDecos
                    IF decoOn(i) AND (NOT DecoFlat(decoKind(i)) OR decoKind(i) = DK_CAMERA) AND cyberOn = 0 THEN
                        relX = decoX(i) - playerX : relY = decoY(i) -playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < viewH / transformY * DecoScale(decoKind(i)) * 0.35 AND DecoAtHeight(i, eyeZ + DTan(pitch) * rayLen * transformY) THEN
                                IF gunPierce(currentGun) THEN
                                    targetDeco = i : HitDeco
                                ELSE
                                    bestDeco = i : bestMonster = 0 : bestDist = transformY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                bestDroid = 0 ' (a droid, nearer than all of those)
                FOR i = 1 TO numDroids
                    IF droidHP(i) > 0 AND cyberOn = 0 THEN
                        relX = droidX(i) - playerX : relY = droidY(i) - playerY
                        transformX = invDet * (dirY * relX - dirX * relY) : transformY = invDet * (-planeY * relX + planeX * relY)
                        IF transformY > 0.2 AND transformY < bestDist THEN
                            IF ABS(RENDER_W / 2 * (transformX / transformY - aim)) < viewH / transformY * DroidScale(droidKind(i)) * 0.35 THEN
                                IF gunPierce(currentGun) THEN
                                    HitDroid i, hitDamage, playerX, playerY
                                ELSE
                                    bestDroid = i : bestDeco = 0 : bestMonster = 0 : bestDist = transformY
                                END IF
                            END IF
                        END IF
                    END IF
                NEXT
                IF bestDroid THEN HitDroid bestDroid, hitDamage, playerX, playerY : crossFlash = 6
                IF bestMonster THEN target = bestMonster : head = bestHead : headZ = bestHeadZ : HitMonsterAimed : crossFlash = 6 ' (the crosshair flashes: a hit)
                IF bestDeco THEN targetDeco = bestDeco : HitDeco
                ' Sparks where it landed (chapter 24's particles): on the
                ' monster, or on the wall - the shot's ray (dir + plane * aim),
                ' as far as the wall in that column
                IF bestMonster THEN
                    SpawnSparks monsterX(bestMonster), monsterY(bestMonster), MonFoot(bestMonster) - FloorAt(monsterX(bestMonster), monsterY(bestMonster)) + mtypeScale(monsterType(bestMonster)) * 0.5, 8, 255, 150, 60 ' (on it, as high as it is)
                ELSEIF bestDroid THEN ' (HitDroid made its sparks)
                ELSEIF bestDeco = 0 AND glassShot THEN
                    glassDmg = hitDamage : HitGlass
                ELSEIF bestDeco = 0 THEN
                    ' The wall in that column - or, looking up or down (OpenGL),
                    ' the ceiling or floor, if the shot reaches it first: it rises
                    ' TAN(pitch) for each cell it goes (the ray's length, rayLen,
                    ' as its steps are a little longer than a cell off-centre)
                    rayX = dirX + planeX * aim : rayY = dirY + planeY * aim : rayLen = SQR(rayX * rayX + rayY * rayY)
                    hitDist = zBuffer(screenCol) : surface = 0 : rise = DTan(pitch) * rayLen
                    IF levelFlat THEN
                        IF rise > 0.01 THEN IF 0.5 / rise < hitDist THEN hitDist = 0.5 / rise : surface = 1 ' (the ceiling)
                        IF rise < -0.01 THEN IF 0.5 / -rise < hitDist THEN hitDist = 0.5 / -rise : surface = 2 ' (the floor)
                    ELSE ' Heights: along the shot until it meets a floor, a ceiling, or the face of a step or a lintel
                        pfz = FloorAt(playerX, playerY) : pcz = CeilAt(playerX, playerY)
                        FOR st = 1 TO INT(hitDist / 0.05)
                            t = st * 0.05 : sx = playerX + rayX * t : sy = playerY + rayY * t : sz = eyeZ + rise * t
                            sfz = FloorAt(sx, sy) : scz = CeilAt(sx, sy)
                            IF sz <= sfz THEN
                                IF sfz > pfz + 0.01 AND eyeZ + rise * (t - 0.05) > pfz THEN surface = 3 : hitDist = t - 0.025 ELSE surface = 2 : IF ABS(rise) > 0.0001 THEN hitDist = (sfz - eyeZ) / rise ELSE hitDist = t
                                EXIT FOR
                            END IF
                            IF sz >= scz THEN
                                IF scz < pcz - 0.01 AND eyeZ + rise * (t - 0.05) < pcz THEN surface = 3 : hitDist = t - 0.025 ELSE surface = 1 : IF ABS(rise) > 0.0001 THEN hitDist = (scz - eyeZ) / rise ELSE hitDist = t
                                EXIT FOR
                            END IF
                            pfz = sfz : pcz = scz
                        NEXT
                        IF surface = 3 THEN surface = 0 ' (a step's face, or a lintel's: marked as a wall is)
                    END IF
                    hitX = playerX + rayX * hitDist : hitY = playerY + rayY * hitDist : hitZ = eyeZ + rise * hitDist ' (how high: from your eye)
                    hfz = FloorAt(hitX - rayX * 0.02, hitY - rayY * 0.02) : hcz = CeilAt(hitX - rayX * 0.02, hitY - rayY * 0.02)
                    IF surface = 0 THEN
                        IF hitZ < hfz + 0.03 THEN hitZ = hfz + 0.03
                        IF hitZ > hcz - 0.03 THEN hitZ = hcz - 0.03
                    END IF
                    SELECT CASE currentGun
                        CASE W_BLASTER : sparkN = 6 : sparkR = 255 : sparkG = 70 : sparkB = 120
                        CASE W_SCATTER : sparkN = 3 : sparkR = 255 : sparkG = 180 : sparkB = 70
                        CASE W_REPEATER : sparkN = 4 : sparkR = 80 : sparkG = 220 : sparkB = 255
                        CASE ELSE : sparkN = 14 : sparkR = 170 : sparkG = 240 : sparkB = 255
                    END SELECT
                    SpawnSparks hitX - rayX / rayLen * 0.03, hitY - rayY / rayLen * 0.03, hitZ - FloorAt(hitX - rayX / rayLen * 0.03, hitY - rayY / rayLen * 0.03), sparkN, sparkR, sparkG, sparkB ' (sparks measure from the floor)
                    ShotMark hitX, hitY, hitZ, rayX / rayLen, rayY / rayLen, surface, 0.1 + 0.06 * (currentGun = W_RAIL) * -1
                    IF surface = 0 THEN ShotAt INT(hitX + rayX / rayLen * 0.05), INT(hitY + rayY / rayLen * 0.05) ' (a "shoot" trigger on that wall?)
                END IF
            NEXT
        ELSEIF NOT fireWas THEN
            PlaySfx sndEmpty&, 0.7
            IF ammoCount(ammoType) > 0 THEN
                ShowMsg "The " + gunName$(currentGun) + " needs" + STR$(gunAmmoPerShot(currentGun)) + " " + AmmoName$(ammoType) + " a shot - another gun, or kick! (F)"
            ELSEIF ammoType = AM_SHELLS THEN
                ShowMsg "Out of shells - kick! (F)"
            ELSEIF ammoType = AM_ROCKETS THEN
                ShowMsg "Out of rockets - kick! (F)"
            ELSEIF ammoType = AM_ROUNDS THEN
                ShowMsg "Out of repeater rounds - kick! (F)"
            ELSEIF ammoType = AM_SLUGS THEN
                ShowMsg "Out of railgun slugs - kick! (F)"
            ELSE
                ShowMsg "Out of energy cells - kick! (F)"
            END IF
            fireWait = 20 : IF kickTimer = 0 THEN kickTimer = KICK_FRAMES : PlaySfx sndKickSwing&, 0.7
        END IF
    END IF
    ' THE KICK: F (or Fire with no ammo, above). The boot swings up, lands
    ' KICK_HIT frames in - on the nearest monster in front, within KICK_REACH
    ' (and roughly where you're looking), shoving it back - or else a
    ' decoration - then drops back down
    kickDown = (inBits AND DB_KICK) <> 0 AND NOT editMode ' (in the editor F is the floor's picture, not a kick)
    IF kickDown AND NOT kickWas AND kickTimer = 0 AND NOT dead THEN kickTimer = KICK_FRAMES : PlaySfx sndKickSwing&, 0.7
    kickWas = kickDown
    IF kickTimer > 0 THEN
        kickTimer = kickTimer - 1
        IF kickTimer = KICK_FRAMES - KICK_HIT THEN
            best = 0 : bestD = KICK_REACH
            FOR i = 1 TO numMonsters
                IF monsterState(i) < 2 AND (cyberOn = 0 OR monsterType(i) = MT_ICE) THEN
                    ox = monsterX(i) - playerX : oy = monsterY(i) - playerY : d = SQR(ox * ox + oy * oy)
                    IF d < bestD AND d > 0.01 AND ABS(MonFoot(i) - playerZ) < 0.7 THEN IF (ox * dirX + oy * dirY) / d > 0.7 AND NOT GlassBetween(playerX, playerY, monsterX(i), monsterY(i)) THEN best = i : bestD = d ' (and at your height: no kicking up a ledge)
                END IF
            NEXT
            IF best THEN
                target = best : hitDamage = KICK_DAMAGE : IF ampTimer > 0 THEN hitDamage = hitDamage * 2
                HitMonster
                IF monsterState(best) >= 2 AND NOT cyberOn THEN Achieve "NC_KICK_KILL", 0
                walkZ = FloorAt(monsterX(best), monsterY(best)) ' (shoved along the floor it's on: off an edge, yes - up a ledge, no)
                IF monsterType(best) <> 5 AND monsterType(best) <> MT_TURRET THEN FOR kp = 1 TO 3 : MoveBody monsterX(best), monsterY(best), dirX * KICK_PUSH / 3, dirY * KICK_PUSH / 3 : NEXT ' (sentries and turrets are bolted down; in three steps, so it can't jump through glass)
                walkZ = -999
                SpawnSparks monsterX(best), monsterY(best), 0.35, 8, 255, 200, 140
                PlaySfx sndKick&, 0.9 : shake = shake + 4 : crossFlash = 6
            ELSE
                kicked = 0
                FOR i = 1 TO numDecos
                    IF decoOn(i) AND (NOT DecoFlat(decoKind(i)) OR decoKind(i) = DK_CAMERA) AND cyberOn = 0 THEN
                        ox = decoX(i) - playerX : oy = decoY(i) - playerY : d = SQR(ox * ox + oy * oy)
                        IF d < KICK_REACH AND d > 0.01 THEN
                            IF (ox * dirX + oy * dirY) / d > 0.7 THEN targetDeco = i : hitDamage = KICK_DAMAGE : hitKick = -1 : HitDeco : hitKick = 0 : PlaySfx sndKick&, 0.8 : shake = shake + 2 : kicked = -1 : EXIT FOR
                        END IF
                    END IF
                NEXT
                IF NOT kicked THEN kicked = KickDoor ' A door in front? A stronghold door takes the boot (GAME/SECURE.BM)
                IF NOT kicked THEN ' Glass in front? The boot cracks it
                    FOR kd = 3 TO 7
                        glassAtX = playerX + dirX * kd / 10 : glassAtY = playerY + dirY * kd / 10
                        IF InGlass(glassAtX, glassAtY) THEN glassHitX = INT(glassAtX) : glassHitY = INT(glassAtY) : glassDmg = 1 : HitGlass : PlaySfx sndKick&, 0.8 : shake = shake + 2 : EXIT FOR
                    NEXT
                END IF
            END IF
        END IF
    END IF
    fireWas = fireDown : spaceWas = spaceDown

    IF cyberOn THEN ' In the network (chapter 19): the clock, and the way out
        IF NOT dead THEN ' (dead in it: the clock stops - the sector starts over, network and all)
            cyberTime = cyberTime - 1
            NetFrame ' (the firewalls, the TRACE - GAME/NETWORK.BM)
            IF cyberGot >= cyberNeed THEN
                cyberWon = -1 : JackOut
            ELSEIF cyberTime <= 0 THEN
                cyberWon = 0 : JackOut
            END IF
        END IF
    ELSEIF NOT editMode THEN
        RunEvents ' The level's event rooms (chapter 19)
        RunTriggers ' ...its triggers, and its teleporters
        UpdateDroids playerX, playerY ' ...and its droids
    END IF
