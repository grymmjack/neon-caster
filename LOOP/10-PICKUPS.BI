''
' NEON-CASTER - LOOP/10-PICKUPS.BI
' =============================================================================
' Chapter 10 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 10: PICKUPS AND CHEAT KEYS
    '-------------------------------------------------------------------------
    ' A pickup is taken when you're within 0.45 cells of it. Comparing the
    ' squared distance with 0.45 squared gives the same answer as comparing
    ' distances, and skips a slow SQR - a trick used all through the game.
    ' Things you can't use yet (health when you're full) stay where they are,
' and loot still flying out of something broken (itemToss) can't be
' caught in the air.
    FOR i = 1 TO numItems
        IF itemOn(i) AND itemToss(i) = 0 AND NOT dead AND NOT editMode AND (itemKind(i) = IT_CORE) = cyberOn AND (itemX(i) - playerX) ^ 2 + (itemY(i) -playerY) ^ 2 < 0.45 * 0.45 THEN
            SELECT CASE itemKind(i)
                CASE IT_CORE ' A data core (the network)
                    itemOn(i) = 0 : cyberGot = cyberGot + 1 : PlaySfx sndCore&, 1 : pickFlash = 12
                    IF cyberGot < cyberNeed THEN ShowMsg "DATA CORE " + LTRIM$(STR$(cyberGot)) + " / " + LTRIM$(STR$(cyberNeed))
                CASE 1 TO 3
                    itemOn(i) = 0 : hasCard(itemKind(i)) = -1
                    PlaySfx sndCard&, 0.8
                    ShowMsg "Picked up the " + CardName$(itemKind(i)) + " keycard"
                CASE IT_HEALTH
                    IF health < MAX_HP THEN
                        itemOn(i) = 0 : health = health + 25 : IF health > MAX_HP THEN health = MAX_HP
                        PlaySfx sndHealth&, 0.8 : ShowMsg "Health pack (+25)" : pickFlash = 10
                    END IF
                CASE IT_MAP
                    itemOn(i) = 0 : hasMap = -1
                    PlaySfx sndCard&, 0.8 : ShowMsg "You found the map!  (TAB for the full map)" : pickFlash = 10
                CASE IT_BIGMED
                    IF health < MAX_HP THEN
                        itemOn(i) = 0 : health = health + 50 : IF health > MAX_HP THEN health = MAX_HP
                        PlaySfx sndHealth&, 0.9 : ShowMsg "Big medkit (+50)" : pickFlash = 14
                    END IF
                CASE IT_OVERCHARGE ' Health past full, up to MAX_OVER
                    IF health < MAX_OVER THEN
                        itemOn(i) = 0 : health = health + 100 : IF health > MAX_OVER THEN health = MAX_OVER
                        PlaySfx sndOvercharge&, 0.9 : ShowMsg "OVERCHARGE! (+100)" : pickFlash = 18
                    END IF
                CASE IT_GOGGLES ' A night-vision headset: its battery added to yours, and on
                    IF nvCharge < NV_MAX THEN
                        itemOn(i) = 0 : nvCharge = MinOf(NV_MAX, nvCharge + NV_FRAMES)
                        IF NOT nvOn THEN nvOn = -1 : PlaySfx sndPowerUp&, 0.8
                        ShowMsg "NIGHT VISION HEADSET - " + KeyName$(keyBind&(BIND_NIGHT)) + " switches it on and off" : pickFlash = 12
                    END IF
                CASE IT_AMP ' Double damage for a while
                    itemOn(i) = 0 : ampTimer = AMP_FRAMES : achAmpKills = 0
                    PlaySfx sndAmp&, 0.9 : ShowMsg "DAMAGE AMP! Double damage for 30 seconds" : pickFlash = 18
                CASE IT_ARMOR
                    IF armor < MAX_ARMOR THEN
                        itemOn(i) = 0 : armor = armor + 50 : IF armor > MAX_ARMOR THEN armor = MAX_ARMOR
                        PlaySfx sndArmor&, 0.8 : ShowMsg "Armour (+50)" : pickFlash = 10
                    END IF
                CASE IT_CELLS
                    IF GiveAmmo%(AM_CELLS, 15) THEN itemOn(i) = 0 : PlaySfx sndAmmo&, 0.8 : ShowMsg "Energy cells (+15)" : pickFlash = 10
                CASE IT_SHELLS
                    IF GiveAmmo%(AM_SHELLS, 8) THEN itemOn(i) = 0 : PlaySfx sndShells&, 0.8 : ShowMsg "Shells (+8)" : pickFlash = 10
                CASE IT_SCATTER, IT_REPEATER, IT_RAIL
                    IF itemKind(i) = IT_RAIL THEN gun = W_RAIL ELSE gun = itemKind(i) - IT_SCATTER + W_SCATTER
                    IF gun = W_SCATTER THEN taken = GiveAmmo%(AM_SHELLS, 8) ELSE taken = GiveAmmo%(AM_CELLS, 30)
                    IF NOT hasGun(gun) OR taken THEN
                        itemOn(i) = 0 : PlaySfx sndWeapon&, 0.9 : pickFlash = 10
                        IF NOT hasGun(gun) THEN
                            hasGun(gun) = -1 : nextGun = gun : swapTimer = SWAP_FRAMES
                            IF hasGun(1) AND hasGun(2) AND hasGun(3) AND hasGun(4) THEN Achieve "NC_ARSENAL", 0
                            ShowMsg "You got the " + gunName$(gun) + "!  (" + LTRIM$(STR$(gun)) + " or mouse wheel to switch)"
                        ELSE
                            ShowMsg gunName$(gun) + " ammo"
                        END IF
                    END IF
            END SELECT
        END IF
    NEXT

    ' The cheat keys act once per press, not every frame the key is held.
    ' That's "edge detection": remember last frame's state (kKeyWas) and act
    ' only when the key is down now and wasn't then. Space and the fire
    ' button use the same trick.
    ' K: every keycard (testing)
    kKeyDown = (inBits AND DB_CHEATK) <> 0
    IF CHEAT_KEYS AND kKeyDown AND NOT kKeyWas AND NOT dead AND NOT editMode THEN
        FOR k = 1 TO 3 : hasCard(k) = -1 : NEXT
        hasMap = -1 : achCheat = -1 ' (a cheat: achievements wait for a new game)
        PlaySfx sndCard&, 0.8 : ShowMsg "All keycards, and the map"
    END IF
    kKeyWas = kKeyDown
    ' G: god mode on / off - no damage, through walls, flying, and the
    ' monsters leave you be (for looking round a sector)
    gKeyDown = (inBits AND DB_CHEATG) <> 0
    IF CHEAT_KEYS AND gKeyDown AND NOT gKeyWas AND NOT dead AND NOT editMode THEN
        godMode = NOT godMode : flyMode = godMode : noTarget = godMode : achCheat = -1
        IF godMode THEN ShowMsg "God mode ON - no damage, no walls, fly (E up, C down), monsters ignore you" ELSE ShowMsg "God mode OFF"
        PlaySfx sndCard&, 0.8
    END IF
    gKeyWas = gKeyDown
    ' Quick save and quick load (F5 and F9 unless you rebind them -
    ' chapter 21): the same saving and loading as the menu, in the
    ' "quick" slot
    qsDown = KeyHeld(BIND_QUICKSAVE) AND NOT edTyping
    IF qsDown AND NOT qsWas AND NOT dead THEN saveSlot = 0 : GOSUB SaveGame
    qsWas = qsDown
    qlDown = KeyHeld(BIND_QUICKLOAD) AND NOT edTyping
    IF qlDown AND NOT qlWas THEN
        IF editMode THEN EditNote "No quick load in the editor (it would lose your changes) - F2 out first" ELSE saveSlot = 0 : GOSUB LoadGame
    END IF
    qlWas = qlDown
    ' Tab: the full-screen map on or off (drawn in chapter 18). In the
    ' editor Tab is its own (the map from above / walking round), and the
    ' editor reads it first - so it mustn't open this map as well.
    mapKeyDown = (inBits AND DB_MAP) <> 0
    IF mapKeyDown AND NOT mapKeyWas AND NOT editMode THEN mapOpen = NOT mapOpen
    mapKeyWas = mapKeyDown
