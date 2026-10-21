''
' NEON-CASTER - AUDIO/SOUND.BI
' =============================================================================
' Chapter 6: loading the sounds - every sound effect, as a handle.
'

'-----------------------------------------------------------------------------
' CHAPTER 6: LOADING THE PICTURES AND SOUNDS
'-----------------------------------------------------------------------------
' Every picture is a PNG in the neon-caster/ folder. LoadTex and LoadSprite
' (chapter 23) open one with _LOADIMAGE and copy its colours into the
' texture() or spriteTex() array. The level's own walls, floors and
' ceilings are loaded with the level (chapter 20); these are the ones every
' level shares - all loaded by LoadPictures (at the end of the main
' program), once the settings are read: ART (SETTINGS > VIDEO) picks the
' pixel art in neon-caster/ (CLASSIC) or the paintings in neon-caster/hd/
' (MODERN), and how big they're kept (ArtReload).

' Sounds: WAV files from neon-caster/sfx/ (made with PWMSFXR - see
' make-sfx.sh there). _SNDOPEN loads one and gives back a handle, a number
' we keep in a & (LONG) variable and play with PlaySfx (chapter 23).
sndStep1& = LoadSnd&("step1.wav") : sndStep2& = LoadSnd&("step2.wav")
DIM SHARED sndSplash&, sndWade1&, sndWade2&, sndBubble&, liqHum& ' (liquids: in with a splash, footsteps that slosh, and a bubbling near the harmful ones - liqHum&, its own looping copy: LiquidHum)
DIM SHARED musicDuck!, glFrozen AS INTEGER, glFrozenAt# ' (the pause menu: the music at half - musicDuck! - and OpenGL's animations stopped at glFrozenAt#)
musicDuck! = 1
DIM SHARED sndSwish&, sndSwim1&, sndSwim2&, swishHum&, swishVol! ' (moving through a liquid: the water swishing round you - swishHum&, its own looping copy, as loud as you're quick and deep: SwishSound - and, out of your depth, swimming strokes for footsteps)
sndSplash& = LoadSnd&("splash.wav") : sndWade1& = LoadSnd&("wade1.wav") : sndWade2& = LoadSnd&("wade2.wav") : sndBubble& = LoadSnd&("bubble.wav")
sndSwish& = LoadSnd&("swish.wav") : sndSwim1& = LoadSnd&("swim1.wav") : sndSwim2& = LoadSnd&("swim2.wav")
sndBump& = LoadSnd&("bump.wav") : sndHump& = LoadSnd&("wallhump.wav")
DIM SHARED sndDoor&, sndShutter&, sndSplit& ' (shared: DoorSnd& picks one - chapter 11)
sndDoor& = LoadSnd&("door.wav") : sndShutter& = LoadSnd&("door-shutter.wav") : sndSplit& = LoadSnd&("door-split.wav")
DIM SHARED sndLiftStart&, sndLiftMove&, sndLiftStop& ' (a lift setting off, moving - looped - and stopping)
sndLiftStart& = LoadSnd&("lift-start.wav") : sndLiftMove& = LoadSnd&("lift-move.wav") : sndLiftStop& = LoadSnd&("lift-stop.wav")
sndCrushSlam& = LoadSnd&("crusher-slam.wav") ' (a smasher hitting the floor)
DIM SHARED sndTrapFire&, sndTrapElec& ' (a trap's roar or buzz, looped while it's lit)
sndTrapFire& = LoadSnd&("trap-fire.wav") : sndTrapElec& = LoadSnd&("trap-electric.wav")
sndCard& = LoadSnd&("keycard.wav") : sndLocked& = LoadSnd&("locked.wav")
sndEmpty& = LoadSnd&("empty.wav") : sndWeapon& = LoadSnd&("weapon.wav")
sndHealth& = LoadSnd&("health.wav") : sndAmmo& = LoadSnd&("ammo.wav") : sndShells& = LoadSnd&("shells.wav")
sndBoltWall& = LoadSnd&("bolt-wall.wav")
sndHurt& = LoadSnd&("hurt.wav") : sndDie& = LoadSnd&("die.wav")
DIM SHARED sndHurtZap& : sndHurtZap& = LoadSnd&("hurt-zap.wav") ' (a shock on top of the grunt: hurtElectric)
DIM SHARED sndHurt2&, sndHurt3& ' (more ways to say ouch: HurtPlayer picks one)
DIM SHARED sndHeart&, sndGasp&(3), sndBreath&, sndGroan&
sndHeart& = LoadSnd&("heartbeat.wav") : sndBreath& = LoadSnd&("breath.wav") : sndGroan& = LoadSnd&("groan.wav")
FOR k = 1 TO 3 : sndGasp&(k) = LoadSnd&("gasp" + LTRIM$(STR$(k)) + ".wav") : NEXT
' The sound limiter (PlaySfxPan, chapter 23), and where you're listening
' from, facing (earDX, earDY) - for 3D sound
' How far a sound in the world carries, in cells (SfxAt): most things -
' doors, shots, explosions - and a monster's muttering and growling
CONST SFX_RANGE = 20, SFX_CHATTER = 12
CONST SFX_HEADROOM = 1.6
DIM SHARED sfxLoad!, sfxThis&(32), sfxThisV!(32), sfxThisN AS INTEGER, earDX, earDY, sfxFrameT! ' (sfxFrameT!: when SfxFrame last ran)
earDX = 1 : earDY = 0
sndHurt2& = LoadSnd&("hurt2.wav") : sndHurt3& = LoadSnd&("hurt3.wav")
sndKick& = LoadSnd&("kick.wav") : sndKickSwing& = LoadSnd&("kick-swing.wav")
IF sndKick& = 0 THEN sndKick& = LoadSnd&("bump.wav")
gunSnd&(1) = LoadSnd&("shoot.wav") : gunSnd&(2) = LoadSnd&("scatter.wav") : gunSnd&(3) = LoadSnd&("repeater.wav")
gunSnd&(4) = LoadSnd&("rail.wav") : gunSnd&(5) = LoadSnd&("rocket-fire.wav")
sndBarrel& = LoadSnd&("barrel.wav") : sndArmor& = LoadSnd&("armor.wav") : sndExit& = LoadSnd&("exit.wav")
' A decoration taking a hit, and breaking (by kind: 2 lamp, 3 plant, 4 terminal)
DIM SHARED decoBreakSnd&(DECO_KINDS) ' (shared: BreakLight uses the lamp's)
sndDecoHit& = LoadSnd&("deco-hit.wav")
decoBreakSnd&(2) = LoadSnd&("lamp-break.wav") : decoBreakSnd&(3) = LoadSnd&("plant-break.wav") : decoBreakSnd&(4) = LoadSnd&("terminal-break.wav")
decoBreakSnd&(5) = LoadSnd&("crate-break.wav") : decoBreakSnd&(6) = decoBreakSnd&(4) : decoBreakSnd&(7) = decoBreakSnd&(4)
decoBreakSnd&(9) = decoBreakSnd&(4)
FOR k = 10 TO DECO_KINDS ' (the set pieces: furniture cracks like a crate, the rest like a terminal)
    IF k = 10 OR k = 18 OR k = 19 OR k = DK_CHEST THEN decoBreakSnd&(k) = decoBreakSnd&(5) ELSE decoBreakSnd&(k) = decoBreakSnd&(4)
NEXT
' The event rooms' sounds (chapter 19): the lockdown alarm, a win, a loss,
' the trap's zap, a monster arriving
DIM SHARED sndAlarm&, sndFanfare&, sndFail&, sndZap&, sndSpawn&
DIM SHARED sndDroid&(3), sndDroidBreak& ' (a droid's chirps - two chatty, one startled - and its breaking)
sndAlarm& = LoadSnd&("alarm.wav") : sndFanfare& = LoadSnd&("fanfare.wav") : sndFail& = LoadSnd&("fail.wav")
DIM SHARED sndSizzle& ' (a burning floor - chapter 22's heights)
sndZap& = LoadSnd&("zap.wav") : sndSpawn& = LoadSnd&("spawn.wav") : sndSizzle& = LoadSnd&("sizzle.wav")
DIM SHARED sndLeak&, sndJet&, sndJetFuel& : sndLeak& = LoadSnd&("barrel-leak.wav") : sndJet& = LoadSnd&("jetpack.wav") : sndJetFuel& = LoadSnd&("jetfuel.wav") ' (a barrel leaking; the jetpack's thrust, its fuel)
' Strongholds and keypads, safes, desks, computers, cameras, notes (GAME/SECURE.BM), invulnerability
DIM SHARED sndPadBeep&, sndPadOK&, sndPadBad&, sndDoorKick&, sndDoorBreak&, sndSafe&, sndSearch&, sndRepair&, sndInvuln&, sndInvulnEnd&, sndCamera&, sndNote&
sndPadBeep& = LoadSnd&("keypad-beep.wav") : sndPadOK& = LoadSnd&("keypad-ok.wav") : sndPadBad& = LoadSnd&("keypad-bad.wav")
sndDoorKick& = LoadSnd&("door-kick.wav") : sndDoorBreak& = LoadSnd&("door-break.wav") : sndSafe& = LoadSnd&("safe-open.wav") : sndSearch& = LoadSnd&("search.wav")
DIM SHARED sndSiren&, sndAlarmPress&, sndAlarmOn&, sndAlarmOff&, sndDrain& ' (alarms - GAME/ALARMS.BM; a pool draining)
sndDrain& = LoadSnd&("drain.wav")
sndSiren& = LoadSnd&("alarm.wav") : sndAlarmPress& = LoadSnd&("alarm-press.wav") : sndAlarmOn& = LoadSnd&("alarm-arm.wav") : sndAlarmOff& = LoadSnd&("alarm-disarm.wav")
sndRepair& = LoadSnd&("repair.wav") : sndInvuln& = LoadSnd&("invuln.wav") : sndInvulnEnd& = LoadSnd&("invuln-end.wav") : sndCamera& = LoadSnd&("camera.wav") : sndNote& = LoadSnd&("note.wav")
FOR k = 1 TO 3 : sndDroid&(k) = LoadSnd&("droid-chirp" + LTRIM$(STR$(k)) + ".wav") : NEXT : sndDroidBreak& = LoadSnd&("droid-break.wav")
DIM SHARED sndSteal&, sndHoard&, sndPlate&, sndLaser&, sndCloset&, sndPowerDown&, sndPowerUp&
sndSteal& = LoadSnd&("thief-steal.wav") : sndHoard& = LoadSnd&("hoard-open.wav") : sndPlate& = LoadSnd&("plate-click.wav")
sndLaser& = LoadSnd&("laser-zap.wav") : sndCloset& = LoadSnd&("closet.wav")
sndSecret& = LoadSnd&("secret.wav") : IF sndSecret& = 0 THEN sndSecret& = LoadSnd&("fanfare.wav")
DIM SHARED sndGlassHit&, sndGlassBreak&
sndGlassHit& = LoadSnd&("glass-hit.wav") : sndGlassBreak& = LoadSnd&("glass-break.wav")
sndTeleport& = LoadSnd&("teleport.wav") : IF sndTeleport& = 0 THEN sndTeleport& = LoadSnd&("jack-out.wav")
sndJackIn& = LoadSnd&("jack-in.wav") : sndJackOut& = LoadSnd&("jack-out.wav") : sndCore& = LoadSnd&("core.wav")
sndPowerDown& = LoadSnd&("power-down.wav") : sndPowerUp& = LoadSnd&("power-up.wav")
IF sndSteal& = 0 THEN sndSteal& = LoadSnd&("keycard.wav")
IF sndHoard& = 0 THEN sndHoard& = LoadSnd&("exit.wav")
IF sndPlate& = 0 THEN sndPlate& = LoadSnd&("locked.wav")
IF sndLaser& = 0 THEN sndLaser& = sndZap&
IF sndCloset& = 0 THEN sndCloset& = LoadSnd&("door-shutter.wav")
' (any that aren't there yet borrow a near enough sound)
IF sndAlarm& = 0 THEN sndAlarm& = LoadSnd&("sentry-alert.wav")
IF sndFanfare& = 0 THEN sndFanfare& = LoadSnd&("exit.wav")
IF sndFail& = 0 THEN sndFail& = LoadSnd&("locked.wav")
IF sndZap& = 0 THEN sndZap& = LoadSnd&("bolt-wall.wav")
IF sndSpawn& = 0 THEN sndSpawn& = LoadSnd&("drone-alert.wav")
DIM SHARED sndOvercharge&, sndAmp&, sndAmpEnd&, ampTimer ' (ampTimer: frames left of the damage amp)
sndOvercharge& = LoadSnd&("overcharge.wav") : sndAmp& = LoadSnd&("amp.wav") : sndAmpEnd& = LoadSnd&("amp-end.wav")
' The newer monsters' pictures: each, then itself hurt (MakeHurt: flashed red)
' (and their pictures: LoadPictures)
mtypeAlertSnd&(1) = LoadSnd&("drone-alert.wav") : mtypeAttackSnd&(1) = LoadSnd&("drone-attack.wav")
mtypeHitSnd&(1) = LoadSnd&("drone-hit.wav") : mtypeDieSnd&(1) = LoadSnd&("drone-die.wav")
mtypeAlertSnd&(2) = LoadSnd&("gunner-alert.wav") : mtypeAttackSnd&(2) = LoadSnd&("gunner-shoot.wav")
mtypeHitSnd&(2) = LoadSnd&("gunner-hit.wav") : mtypeDieSnd&(2) = LoadSnd&("gunner-die.wav")
mtypeAlertSnd&(3) = LoadSnd&("heavy-alert.wav") : mtypeAttackSnd&(3) = LoadSnd&("heavy-attack.wav")
mtypeHitSnd&(3) = LoadSnd&("heavy-hit.wav") : mtypeDieSnd&(3) = LoadSnd&("heavy-die.wav")
mtypeAlertSnd&(4) = LoadSnd&("crawler-alert.wav") : mtypeAttackSnd&(4) = LoadSnd&("crawler-attack.wav")
mtypeHitSnd&(4) = LoadSnd&("crawler-hit.wav") : mtypeDieSnd&(4) = LoadSnd&("crawler-die.wav")
mtypeAlertSnd&(5) = LoadSnd&("sentry-alert.wav") : mtypeAttackSnd&(5) = LoadSnd&("sentry-shoot.wav")
mtypeHitSnd&(5) = LoadSnd&("sentry-hit.wav") : mtypeDieSnd&(5) = LoadSnd&("sentry-die.wav")
FOR mtype = 1 TO MON_TYPES ' Every one's idle and hunting sounds: name-idle, name-hunt
    mtypeIdleSnd&(mtype) = LoadSnd&(mtypeName$(mtype) + "-idle.wav") : mtypeHuntSnd&(mtype) = LoadSnd&(mtypeName$(mtype) + "-hunt.wav")
NEXT
FOR mtype = 6 TO MON_TYPES ' (the newer ones: name-alert, -attack or -shoot, -hit, -die)
    nm$ = mtypeName$(mtype) : mtypeAlertSnd&(mtype) = LoadSnd&(nm$ + "-alert.wav")
    IF mtypeRanged(mtype) THEN mtypeAttackSnd&(mtype) = LoadSnd&(nm$ + "-shoot.wav") ELSE mtypeAttackSnd&(mtype) = LoadSnd&(nm$ + "-attack.wav")
    mtypeHitSnd&(mtype) = LoadSnd&(nm$ + "-hit.wav") : mtypeDieSnd&(mtype) = LoadSnd&(nm$ + "-die.wav")
NEXT
FOR mtype = 1 TO MON_TYPES
    mtypePainSnd&(mtype) = LoadSnd&(mtypeName$(mtype) + "-pain.wav") : IF mtypePainSnd&(mtype) = 0 THEN mtypePainSnd&(mtype) = mtypeHitSnd&(mtype)
NEXT
sndHeadshot& = LoadSnd&("headshot.wav")

sndMenuMove& = LoadSnd&("menu-move.wav") : sndMenuSelect& = LoadSnd&("menu-select.wav") : sndMenuBack& = LoadSnd&("menu-back.wav")
' Rockets and the turrets' weapons (GAME/ROCKETS.BM): a rocket's blast, and
' a turret's flame, spray, lightning and missile
DIM SHARED sndRocketBoom&, sndTurFlame&, sndTurSpray&, sndTurZap&, sndTurMissile&
sndRocketBoom& = LoadSnd&("rocket-boom.wav") : sndTurFlame& = LoadSnd&("turret-flame.wav") : sndTurSpray& = LoadSnd&("turret-spray.wav")
sndTurZap& = LoadSnd&("turret-zap.wav") : sndTurMissile& = LoadSnd&("turret-missile.wav")
