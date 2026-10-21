''
' NEON-CASTER - LOOP/18-HUD.BI
' =============================================================================
' Chapter 18 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 18: THE GUN AND THE HUD
    '-------------------------------------------------------------------------
    ' Everything from here is drawn straight onto the window, at full size,
    ' with ordinary QB64PE graphics: _PUTIMAGE for pictures, LINE for boxes,
    ' _PRINTSTRING for text. Colours made with _RGBA32 have an alpha (0
    ' clear .. 255 solid), so a LINE ... BF over the whole screen with a low
    ' alpha tints everything: red when you're hurt, yellow for a pickup.
    '
    ' The map comes last: the minimap in the corner once you've found the
    ' map pickup, and the full-screen map when Tab is on.
    '
    ' The gun was placed in chapter 17 (gunX, gunY, gunW, gunH): drawn here
    ' - or with OpenGL, by the graphics card, at the window's own size
    ' (chapter 24), under all of this
    IF gunY < 600 AND NOT glMode AND NOT editMode AND viewOn = 0 THEN _PUTIMAGE (gunX, gunY)-(gunX + gunW - 1, gunY + gunH - 1), TintedGun&(currentGun) ' (in its light - not in the editor: nothing to shoot, and it's in the way)
    ' The kick: the boot comes up from the bottom of the screen (a little
    ' left of the middle), at its highest when it lands, then drops away -
    ' lit like the gun, by where you stand
    IF kickTimer > 0 AND kickImg& < -1 THEN
        kf = 1 - kickTimer / KICK_FRAMES ' (0 .. 1 through the kick)
        IF kf < KICK_HIT / KICK_FRAMES THEN up = kf / (KICK_HIT / KICK_FRAMES) ELSE up = 1 - (kf - KICK_HIT / KICK_FRAMES) / (1 - KICK_HIT / KICK_FRAMES)
        up = SIN(up * 1.5708)
        kh = 360 : kw = kh * _WIDTH(kickImg&) / _HEIGHT(kickImg&)
        kx = 330 - kw / 2 + shakeX : ky = 600 - kh * up * 0.95 + shakeY
        _PUTIMAGE (kx, ky)-(kx + kw - 1, ky + kh - 1), kickImg&
    END IF
    IF muzzleFlash > 0 THEN ' Muzzle flash, and a flicker of light on everything
        muzzleFlash = muzzleFlash - 1
        LINE (0, 0)-(799, 599), _RGBA32(255, 120, 120, 18), BF
        flashX = gunX + gunW * gunMuzzleX(currentGun) : flashY = gunY + gunH * gunMuzzleY(currentGun)
        FillCircle flashX, flashY, 30 + muzzleFlash * 4, _RGBA32(255, 40, 40, 90)
        FillCircle flashX, flashY, 18 + muzzleFlash * 3, _RGBA32(255, 150, 150, 170)
        FillCircle flashX, flashY, 8, _RGBA32(255, 255, 255, 230)
    END IF
    IF railBeam > 0 THEN ' The railgun's beam, from the muzzle to the crosshair
        flashX = gunX + gunW * gunMuzzleX(currentGun) : flashY = gunY + gunH * gunMuzzleY(currentGun)
        FOR k = -3 TO 3
            LINE (flashX + k, flashY)-(400 + k / 3, 300), _RGBA32(255, 60 + 30 * (3 - ABS(k)), 60 + 30 * (3 - ABS(k)), railBeam * 28)
        NEXT
    END IF

    ' The crosshair - its style, colour, size and opacity are settings, and
    ' with CROSSHAIR FEEDBACK it tightens as you fire, jolts wide when
    ' you're hit and flashes white when your shot hits something, easing
    ' back each frame - and the damage indicators: a red arc around it for
    ' each recent hit, pointing where it came from. Each one remembers
    ' where the hit came from, not which way it pointed, so the arc turns
    ' as you do - turn until it's at the top, and you're facing it.
    IF NOT dead AND viewOn = 0 THEN DrawCrosshair 400, 300
    ViewOverlay ' (a security camera's feed, your rocket's - GAME/SECURE.BM)
    AlarmOverlay ' (the alarm sounding: red at the edges)
    crossScale = 1 + (crossScale - 1) * 0.85
    IF crossFlash > 0 THEN crossFlash = crossFlash - 1
    IF hurtFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(MaxOf(painR, 120), painG, painB, hurtFlash * 5), BF ' (in what hurt you - and fainter now the edges show it)
    IF pickFlash > 0 THEN LINE (0, 0)-(799, 599), _RGBA32(255, 255, 160, pickFlash * 4), BF
    IF invTimer > 0 AND NOT (invTimer < 60 AND (invTimer \ 6) MOD 2 = 1) THEN ' Invulnerable: a golden glow round the edges (a hit that couldn't hurt: brighter) - blinking out its last second
        invAl = 9 + invFlash * 3 + 3 * DSin(lvFrame * 0.2)
        FOR invE = 0 TO 15 : LINE (invE, invE)-(799 - invE, 599 - invE), _RGBA32(255, 205, 70, MaxOf(0, (16 - invE) * invAl)), B : NEXT
        MenuText 400, 70, "INVULNERABLE " + LTRIM$(STR$((invTimer + 59) \ 60)), 1.5, _RGB32(255, 215, 90), 1
    END IF
    ' A ripper's slash: three claw marks torn across the view - drawn out
    ' fast over the first frames (the swipe), then fading
    IF clawFx > 0 THEN
        clawF! = (CLAW_FX - clawFx) / 4 : IF clawF! > 1 THEN clawF! = 1
        clawAl = 255 * MinOf(1, clawFx / (CLAW_FX * 0.6))
        FOR clawN = -1 TO 1
            clawSX = clawX + clawN * 34 - 110 * clawA : clawSY = clawY - 120
            clawEX = clawSX + (220 * clawA) * clawF! : clawEY = clawSY + 240 * clawF!
            FOR clawW = -3 TO 3
                IF ABS(clawW) = 3 THEN clawC~& = _RGBA32(90, 0, 10, clawAl * 0.6) ELSE clawC~& = _RGBA32(255, 40 + ABS(clawW) * 25, 70, clawAl)
                LINE (clawSX + clawW, clawSY)-(clawEX + clawW * (1 - clawF! * 0.7), clawEY), clawC~& ' (thinner at the end, as a claw drags out)
            NEXT
        NEXT
        clawFx = clawFx - 1
    END IF
    IF setting(SET_HURTDIR) THEN DrawHurtDirs playerX, playerY, dirX, dirY ' (over the red flash, so they stand out)
    IF godMode AND hudShow(HE_GOD) THEN HudText hudX(HE_GOD), hudY(HE_GOD), hudLabel$(HE_GOD), HudColor~&(HE_GOD, _RGB32(255, 215, 30))
    IF editMode THEN EditOverlay playerX, playerY, dirX, dirY ' (the editor: what you're aiming at, what you'll place)
    IF editMode AND editView = 1 THEN EditDrawFaces ' (the face under the pointer, and the ones selected, outlined)
    IF editMode AND editView = 1 AND NOT hudEdit THEN ' The toolbar (and the help, when it's up)
        IF edPickOpen THEN
            IF edLooking THEN EditDrawPicker -1, -1 ELSE EditDrawPicker edCurX, edCurY
        ELSEIF edPickOn THEN ' (tucked away: a strip saying what the brush is)
            LINE (0, PK_TUCK)-(799, 599), _RGBA32(6, 2, 18, 200), BF : LINE (0, PK_TUCK)-(799, PK_TUCK), _RGBA32(255, 60, 200, 160)
            IF edTool = ET_PAINT THEN t$ = EditPaintName$ ELSE IF edTool = ET_LIGHT THEN t$ = "light: " + LCASE$(EditFxName$(edLFx)) ELSE t$ = GlyphName$(editGlyph$)
            HudText 8, PK_TUCK + 2, LEFT$("^ PICKER  (point here to open it)   brush: " + t$, 98), _RGB32(190, 180, 230)
        END IF
        IF edLooking THEN EditDrawPane -1, -1 ELSE EditDrawPane edCurX, edCurY
        IF edLooking THEN EditDrawTB 1, -1, -1 ELSE EditDrawTB 1, edCurX, edCurY
        IF edHelp THEN EditDrawHelp 1
    END IF

    ' The map (DrawMap, chapter 23). The minimap in the corner only appears
    ' once you've found this level's map pickup. Tab opens the full-screen
    ' map: without the pickup it shows only the cells you've seen - you draw
    ' it as you explore - and with it, the whole level.
    killsY = hudY(HE_KILLS)
    IF hasMap AND NOT mapOpen AND hudShow(HE_MINIMAP) THEN
        DrawMap hudX(HE_MINIMAP), hudY(HE_MINIMAP), hudW(HE_MINIMAP), -1, playerX, playerY, dirX, dirY
        ' (the kill count, if it's where the map is, goes under it)
        IF hudX(HE_KILLS) = hudX(HE_MINIMAP) AND hudY(HE_KILLS) = hudY(HE_MINIMAP) THEN killsY = hudY(HE_MINIMAP) + MinOf(mapN, 48) * hudW(HE_MINIMAP) + 6
    END IF
    IF mapOpen THEN
        LINE (0, 0)-(799, 599), _RGBA32(0, 4, 14, 225), BF
        MenuText 400, 14, levelName$, 2, _RGB32(255, 100, 215), 1
        fmC = MinOf(10, 480 \ mapN) : mmFull = -1 ' (the whole sector, as big as fits)
        DrawMap 400 - mapN * fmC \ 2, 60, fmC, hasMap, playerX, playerY, dirX, dirY : mmFull = 0
        IF hasMap THEN mapNote$ = "THIS SECTOR'S MAP - BRIGHTER WHERE YOU'VE BEEN.   TAB  CLOSE" ELSE mapNote$ = "NO MAP YET - ONLY WHERE YOU'VE BEEN.   TAB  CLOSE"
        MenuText 400, 552, mapNote$, 1, _RGB32(170, 170, 200), 1
    END IF
    IF NOT mapOpen AND hudShow(HE_KILLS) AND NOT (editMode AND NOT hudEdit) THEN HudText hudX(HE_KILLS), killsY, hudLabel$(HE_KILLS) + STR$(kills) + " /" + STR$(numMonsters), HudColor~&(HE_KILLS, _RGB32(255, 90, 90))
    ' F3: where you are, in numbers (DrawInfo) - under the kills, when they're top left
    IF infoOn AND NOT mapOpen AND NOT cyberOn THEN
        infoTop = 8 : IF hudShow(HE_KILLS) AND hudX(HE_KILLS) < 300 AND killsY < 300 THEN infoTop = killsY + 22
        DrawInfo infoTop
    END IF

    ' Keycards you hold, top right
    cardX = hudX(HE_CARDS)
    FOR k = 3 TO 1 STEP - 1
        IF hasCard(k) AND hudShow(HE_CARDS) AND NOT (editMode AND NOT hudEdit) THEN cardX = cardX - hudW(HE_CARDS) - 4 : _PUTIMAGE (cardX, hudY(HE_CARDS))-STEP(hudW(HE_CARDS) - 1, hudW(HE_CARDS) - 1), cardImg&(k)
    NEXT

    ' Armour and health (bottom left)
    IF (armor > 0 OR hudEdit) AND hudShow(HE_ARMOR) AND NOT (editMode AND NOT hudEdit) THEN
        ac~& = HudColor~&(HE_ARMOR, _RGB32(90, 160, 255)) : ax = hudX(HE_ARMOR) : ay = hudY(HE_ARMOR)
        HudText ax, ay, hudLabel$(HE_ARMOR) + STR$(armor), ac~&
        IF hudW(HE_ARMOR) > 0 THEN
            LINE (ax, ay + 18)-STEP(hudW(HE_ARMOR) + 1, hudH(HE_ARMOR) + 1), _RGBA32(0, 0, 0, 170), BF
            IF armor > 0 THEN LINE (ax + 1, ay + 19)-STEP(MaxOf(1, armor * hudW(HE_ARMOR) \ MAX_ARMOR) - 1, hudH(HE_ARMOR) - 1), ac~&, BF
        END IF
    END IF
    IF health > 60 THEN healthColor~& = _RGB32(60, 230, 90) ELSE IF health > 25 THEN healthColor~& = _RGB32(255, 200, 40) ELSE healthColor~& = _RGB32(255, 50, 50)
    healthColor~& = HudColor~&(HE_HEALTH, healthColor~&)
    IF hudShow(HE_HEALTH) AND NOT (editMode AND NOT hudEdit) THEN
        hx = hudX(HE_HEALTH) : hy = hudY(HE_HEALTH) : bw = hudW(HE_HEALTH) : bh = hudH(HE_HEALTH)
        HudText hx, hy, hudLabel$(HE_HEALTH) + STR$(health), healthColor~&
        IF poisonLeft > 0 AND (lvFrame \ 20) MOD 3 THEN HudText hx + 8 * (LEN(hudLabel$(HE_HEALTH) + STR$(health)) + 2), hy, "POISONED", _RGB32(90, 255, 80) ' (poisoned: it goes on hurting - a health pack cures it)
        IF bw > 0 THEN
            LINE (hx, hy + 18)-STEP(bw + 1, bh + 1), _RGBA32(0, 0, 0, 170), BF
            IF health > 0 THEN LINE (hx + 1, hy + 19)-STEP(MaxOf(1, MinOf(health, MAX_HP) * bw \ MAX_HP) - 1, bh - 1), healthColor~&, BF
            IF health > MAX_HP THEN LINE (hx + 1, hy + 19)-STEP(MaxOf(1, (health - MAX_HP) * bw \ MAX_HP) - 1, bh - 1), _RGB32(90, 200, 255), BF ' (overcharged: the extra, in blue, over it)
        END IF
    END IF
    IF ampTimer > 0 AND hudShow(HE_AMP) THEN HudText hudX(HE_AMP), hudY(HE_AMP), hudLabel$(HE_AMP) + STR$(ampTimer \ 60 + 1), HudColor~&(HE_AMP, _RGB32(255, 90, 90))
    IF nvHave AND hudShow(HE_AMP) THEN ' (night vision, beside the amp: bright while it's on)
        IF nvOn THEN c~& = _RGB32(110, 255, 120) ELSE c~& = _RGB32(60, 130, 70)
        HudText hudX(HE_AMP) + 136, hudY(HE_AMP), "NIGHT VISION", c~&
    END IF
    IF suitLeft > 0 AND hudShow(HE_AMP) THEN ' (the hazmat suit, under them: what's left of it, going orange then red as it wears)
        IF suitLeft > 50 THEN c~& = _RGB32(255, 220, 40) ELSE IF suitLeft > 20 THEN c~& = _RGB32(255, 140, 30) ELSE c~& = _RGB32(255, 50, 50)
        HudText hudX(HE_AMP) + 136, hudY(HE_AMP) + 18, "HAZMAT" + STR$(INT(suitLeft + 0.99)) + "%", c~&
    END IF
    IF jetHave AND hudShow(HE_AMP) THEN ' (the jetpack's fuel: cyan, lit while it burns, red when it's low)
        IF jetFuel < 20 THEN c~& = _RGB32(255, 60, 60) ELSE IF jetOn THEN c~& = _RGB32(255, 190, 60) ELSE c~& = _RGB32(90, 220, 255)
        HudText hudX(HE_AMP) + 136, hudY(HE_AMP) + 36, "JET" + STR$(INT(jetFuel + 0.99)) + "%", c~&
    END IF
    ' The VIGNETTES (with HIT FX on): a lockdown strobing red; low health
    ' thumping red with your heart; poison's green; the colour of the last
    ' thing that hurt you, fading
    IF setting(SET_HITFX) AND NOT editMode THEN
        FOR ev = 1 TO numEvents
            IF evState(ev) = 1 AND (evType(ev) = EV_AMBUSH OR evType(ev) = EV_SURVIVE) THEN DrawVignette 230, 0, 0, 0.12 + 0.6 * MaxOf(0, SIN(TIMER * 9)) ^ 6 : EXIT FOR
        NEXT
        IF beatAt > 0 THEN ' (a beat's two thumps: lub, then dub a quarter second on)
            bt = TIMER(0.001) - beatAt : IF bt < 0 THEN bt = 9
            thump = EXP(-bt * 9) : IF bt > 0.25 THEN thump = MaxOf(thump, 0.7 * EXP(-(bt - 0.25) * 9))
            DrawVignette 120, 0, 0, 0.25 + 0.3 * (1 - health / LOW_HP) + 0.45 * thump
        END IF
        IF poisonTint > 0 THEN DrawVignette 40, 190, 60, poisonTint / 40
        IF painVig > 0 THEN DrawVignette painR, painG, painB, painVig
    END IF
    evLine = 0 ' (two going at once - a nest and a lockdown: one line each, not one over the other)
    FOR ev = 1 TO numEvents ' An event room going on: what's left to do, and a pulsing red frame
        IF evState(ev) = 1 THEN
            SELECT CASE evType(ev)
                CASE EV_AMBUSH
                    left = evA(ev) - evCount(ev)
                    FOR j = 1 TO numMonsters
                        IF monsterEv(j) = ev AND monsterState(j) < 2 THEN left = left + 1
                    NEXT
                    evText$ = "LOCKDOWN - HOSTILES LEFT:" + STR$(left)
                CASE EV_SURVIVE : evText$ = "LOCKDOWN - SURVIVE" + STR$(evTimer(ev) \ 60 + 1)
                CASE EV_GALLERY : evText$ = "SMASH EVERYTHING:" + STR$(evCount(ev)) + " LEFT," + STR$(evTimer(ev) \ 60 + 1) + "s"
                CASE EV_NEST : evText$ = "DESTROY THE SPAWNERS"
                CASE EV_BLACKOUT : evText$ = "POWER FAILURE -" + STR$(blackoutTimer \ 60 + 1)
                CASE ELSE : evText$ = "" ' (a plate, a laser...: you can see what it is - nothing to say, and no frame)
            END SELECT
            IF evText$ <> "" AND hudShow(HE_EVENT) THEN HudText hudX(HE_EVENT) - LEN(evText$) * 4, hudY(HE_EVENT) + evLine * 16, evText$, HudColor~&(HE_EVENT, _RGB32(255, 120, 90)) : evLine = evLine + 1
            IF evText$ <> "" AND evType(ev) <> EV_NEST AND evType(ev) <> EV_GALLERY THEN
                pulse = 60 + 50 * SIN(TIMER * 6)
                FOR k = 0 TO 3 : LINE (k, k)-(799 - k, 599 - k), _RGBA32(255, 30, 30, pulse), B : NEXT
            END IF
        END IF
    NEXT
    AchDrawToast 0 ' (an achievement just unlocked: its pop-up, bottom right)

    ' Gun and its ammo (bottom right), and which guns you have
    ammoType = gunAmmoType(currentGun)
    IF ammoCount(ammoType) = 0 THEN
        ammoColor~& = _RGB32(255, 50, 50)
    ELSEIF ammoType = AM_SHELLS THEN
        ammoColor~& = _RGB32(255, 150, 40)
    ELSEIF ammoType = AM_ROCKETS THEN
        ammoColor~& = _RGB32(255, 90, 140)
    ELSEIF ammoType = AM_ROUNDS THEN
        ammoColor~& = _RGB32(190, 255, 60)
    ELSEIF ammoType = AM_SLUGS THEN
        ammoColor~& = _RGB32(90, 150, 255)
    ELSE
        ammoColor~& = _RGB32(60, 220, 255)
    END IF
    ammoColor~& = HudColor~&(HE_AMMO, ammoColor~&)
    ammoText$ = gunName$(currentGun) + "  " + LTRIM$(STR$(ammoCount(ammoType)))
    IF hudShow(HE_AMMO) AND NOT (editMode AND NOT hudEdit) THEN ' (its right edge at hudX)
        rx = hudX(HE_AMMO) : ry = hudY(HE_AMMO) : bw = hudW(HE_AMMO) : bh = hudH(HE_AMMO)
        HudText rx - 8 * LEN(ammoText$), ry, ammoText$, ammoColor~&
        IF bw > 0 THEN
            LINE (rx - bw - 2, ry + 18)-STEP(bw + 1, bh + 1), _RGBA32(0, 0, 0, 170), BF
            IF ammoCount(ammoType) > 0 THEN LINE (rx - 1 - ammoCount(ammoType) * bw \ ammoMax(ammoType), ry + 19)-(rx - 1, ry + 18 + bh), ammoColor~&, BF
        END IF
    END IF
    IF hudShow(HE_GUNS) AND NOT (editMode AND NOT hudEdit) THEN
        FOR gun = 1 TO NUM_GUNS
            gunNumColor~& = _RGB32(60, 60, 70)
            IF hasGun(gun) THEN gunNumColor~& = _RGB32(150, 150, 160)
            IF gun = currentGun THEN gunNumColor~& = HudColor~&(HE_GUNS, _RGB32(255, 255, 255))
            HudText hudX(HE_GUNS) + (gun - 1) * 20, hudY(HE_GUNS), LTRIM$(STR$(gun)), gunNumColor~&
        NEXT
    END IF

    ' In the network: what's left to grab, and the time left
    IF cyberOn AND hudShow(HE_NETWORK) THEN
        c$ = "NETWORK   DATA " + LTRIM$(STR$(cyberGot)) + " / " + LTRIM$(STR$(cyberNeed)) + "   TIME " + LTRIM$(STR$(cyberTime \ 60))
        nx = hudX(HE_NETWORK) : ny = hudY(HE_NETWORK)
        LINE (nx - LEN(c$) * 4 - 10, ny)-(nx + LEN(c$) * 4 + 10, ny + 20), _RGBA32(0, 20, 40, 190), BF
        LINE (nx - LEN(c$) * 4 - 10, ny)-(nx + LEN(c$) * 4 + 10, ny + 20), _RGB32(60, 240, 255), B
        cc~& = HudColor~&(HE_NETWORK, _RGB32(150, 250, 255)) : IF cyberTime < 600 AND (cyberTime \ 15) MOD 2 = 0 THEN cc~& = _RGB32(255, 80, 120)
        HudText nx - LEN(c$) * 4, ny + 5, c$, cc~&
    END IF
    ' What NEXUS is saying: a red-framed subtitle at the top
    IF speechUntil! > TIMER AND LEN(speechText$) AND hudShow(HE_SUBTITLE) THEN
        w = LEN(speechText$) * 8 + 24 : IF w > 780 THEN w = 780
        sx = hudX(HE_SUBTITLE) : sy = hudY(HE_SUBTITLE)
        LINE (sx - w \ 2, sy)-(sx + w \ 2, sy + 24), _RGBA32(30, 0, 8, 190), BF
        LINE (sx - w \ 2, sy)-(sx + w \ 2, sy + 24), _RGB32(255, 60, 90), B
        HudText sx - LEN(speechText$) * 4, sy + 5, speechText$, HudColor~&(HE_SUBTITLE, _RGB32(255, 200, 210))
    END IF
    ' Message line
    IF TIMER < messageUntil! AND LEN(message$) AND NOT mapOpen AND hudShow(HE_MESSAGE) THEN
        HudText hudX(HE_MESSAGE) - LEN(message$) * 4, hudY(HE_MESSAGE), message$, HudColor~&(HE_MESSAGE, _RGB32(255, 255, 255))
    END IF
    IF hudEdit THEN HudEditDraw ' (the HUD layout editor: boxes round it all)

    IF dead THEN
        LINE (0, 0)-(799, 599), _RGBA32(90, 0, 0, 110), BF
        BigText "YOU DIED", 230, 6, _RGB32(255, 60, 60)
        IF TIMER - deadAt! > 1.2 THEN HudText 400 - 15 * 8, 330, "Click or press Space to try again", _RGB32(255, 255, 255)
    END IF

    ' SHOW FPS (SETTINGS > VIDEO): frames a second, counted over each
    ' second, and how long the 3D view takes to draw, smoothed a little -
    ' for OpenGL, our part of it plus SUB _GL's (glMs, chapter 24). Try
    ' both renderers and compare. (_LIMIT 60 keeps the frames at 60 at
    ' most, so the milliseconds tell you more: 16.7 is all of a frame.)
    fpsFrames = fpsFrames + 1
    IF TIMER - fpsStart! >= 1 OR TIMER < fpsStart! THEN fpsShown = fpsFrames : fpsFrames = 0 : fpsStart! = TIMER
    IF glMode THEN viewMs = viewMs + glMs
    viewAvg = viewAvg * 0.9 + viewMs * 0.1
    tenths = INT(viewAvg * 10 + 0.5) : IF tenths > 9999 THEN tenths = 9999
    msText$ = LTRIM$(STR$(tenths \ 10)) + "." + LTRIM$(STR$(tenths MOD 10))
    infoFps$ = "FPS" + STR$(fpsShown) + "   3D VIEW " + msText$ + " MS   " + MID$("SOFTWAREOPENGL", 1 - 8 * glMode, 8 + 2 * glMode) ' (for the F3 panel, next frame)
    IF setting(SET_FPS) THEN
        ' Every part padded to the same width (RIGHT$ of spaces and the number),
        ' so the line doesn't shift about as the numbers grow and shrink
        IF glMode THEN fpsText$ = "  OPENGL" ELSE fpsText$ = "SOFTWARE"
        fpsText$ = fpsText$ + "   FPS" + RIGHT$("   " + STR$(fpsShown), 4) + "   3D VIEW" + RIGHT$("     " + msText$, 6) + " MS"
        IF hudShow(HE_FPS) THEN HudText hudX(HE_FPS) - LEN(fpsText$) * 4, hudY(HE_FPS), fpsText$, HudColor~&(HE_FPS, _RGB32(255, 255, 120))
    END IF
    ' The sector timer (SECTOR TIMER): how long you've been in it, the
    ' clock green while you're inside your best and red once past it
    ' (the keycards you hold sit top right too: the demo's lines go under them)
    ddy = 0 : IF hudShow(HE_CARDS) AND hudX(HE_CARDS) > 560 AND hudY(HE_CARDS) < 110 AND (hasCard(1) OR hasCard(2) OR hasCard(3)) THEN ddy = MaxOf(0, hudY(HE_CARDS) + hudW(HE_CARDS) + 6 - 38)
    IF demoPlay THEN ' Playing one: a green play arrow and PLAYING over the clock - and, small, which demo, how long, what
        dpw = 8 * 8 + 16 : dpx = 784 - dpw : dpc~& = _RGB32(90, 255, 130)
        FOR dpy = 0 TO 10 : LINE (dpx, 42 + ddy + dpy)-(dpx + (5 - ABS(dpy - 5)) * 1.6, 42 + ddy + dpy), dpc~& : NEXT ' (the arrow: a little triangle)
        HudText dpx + 14, 40 + ddy, "PLAYING", dpc~&
        dp$ = UCASE$(demoName$) + "  " + TimeText$(demoTotal / 60)
        HudText 784 - LEN(dp$) * 8, 76 + ddy, dp$, _RGB32(160, 220, 255)
        IF LEN(demoInfoNow$) THEN HudText 784 - LEN(demoInfoNow$) * 8, 92 + ddy, demoInfoNow$, _RGB32(120, 150, 190)
    END IF
    IF demoRec OR demoPlay THEN ' A demo going: REC (red) or DEMO (cyan), and how long, at the top right
        IF demoRec THEN dh$ = "REC " ELSE dh$ = "DEMO " : IF demoAttract THEN dh$ = "ANY KEY: MENU   DEMO "
        dh$ = dh$ + TimeText$(demoFrame / 60) : IF demoPlay AND demoBad THEN dh$ = dh$ + "  OUT OF STEP"
        IF demoRec THEN dhc~& = _RGB32(255, 70, 80) ELSE dhc~& = _RGB32(90, 230, 255)
        IF demoRec AND (demoFrame \ 30) MOD 2 = 0 THEN FillCircle 784 - LEN(dh$) * 8 - 10, 66 + ddy, 4, dhc~& ' (the red light, blinking)
        HudText 784 - LEN(dh$) * 8, 58 + ddy, dh$, dhc~&
    END IF
    IF setting(SET_TIMER) AND hudShow(HE_TIMER) AND NOT editMode AND NOT cyberOn THEN
        lt! = TIMER - levelStart! : IF lt! < 0 THEN lt! = lt! + 86400
        rk = level : IF level <= NUM_LEVELS THEN rk = sectorSet * 100 + level
        best! = RecordBest!(rk) : tc~& = _RGB32(240, 240, 255)
        IF best! > 0 THEN IF lt! <= best! THEN tc~& = _RGB32(90, 255, 140) ELSE tc~& = _RGB32(255, 90, 90)
        IF achCheat AND NOT achTest THEN tc~& = _RGB32(150, 140, 170) ' (cheats on: it can't make a record)
        tmr$ = TimeText$(INT(lt!)) + "." + LTRIM$(STR$(INT((lt! - INT(lt!)) * 10)))
        tdy = 0 ' (a demo's lines in the same corner: the clock goes down under them)
        IF (demoRec OR demoPlay) AND hudX(HE_TIMER) > 560 AND hudY(HE_TIMER) < 140 THEN
            dbot = 74 + ddy : IF demoPlay THEN dbot = 92 + ddy + 16
            tdy = MaxOf(0, dbot + 8 - hudY(HE_TIMER))
        END IF
        MenuText hudX(HE_TIMER), hudY(HE_TIMER) + tdy, tmr$, 2, HudColor~&(HE_TIMER, tc~&), 2
        IF best! > 0 THEN tmr$ = "BEST " + TimeText$(INT(best!)) : HudText hudX(HE_TIMER) - LEN(tmr$) * 8, hudY(HE_TIMER) + tdy + 34, tmr$, _RGB32(255, 220, 80)
    END IF

    ' With OpenGL, the HUD goes to the graphics card as a picture, to be
    ' laid over the 3D view there (chapter 24): GLSL_filter_capture copies
    ' the screen for SUB _GL, and our own screen layer is switched off
    IF glMode THEN GLSL_filter_capture
    GLScreenLayer glMode
    DisplayFollow ' (Alt + Enter changes the DISPLAY setting - chapter 21)
    ShowFrame ' Show the finished frame (chapter 7)
    ' A screenshot asked for (the console's screenshot): the software
    ' renderer's frame is our screen; OpenGL's, SUB _GL reads back for us
    ' (glShotReq 2 - chapter 24)
    IF shotFile$ <> "" AND NOT glMode THEN _SAVEIMAGE shotFile$, 0 : ConPrint "saved " + shotFile$ : shotFile$ = ""
    IF glShotReq = 2 THEN SaveGLShot
