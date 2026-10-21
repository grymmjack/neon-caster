''
' NEON-CASTER - LOOP/11-DOORS.BI
' =============================================================================
' Chapter 11 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 11: DOORS
    '-------------------------------------------------------------------------
    ' Space opens the door in front of you - or shuts it, if it's open. To
    ' find it, we take small steps (0.05 cells) out from you along (dirX,
    ' dirY), up to 2 cells, and look at the cell each step lands in: the
    ' first door is the one (not one you're standing in), and a wall first
    ' means there's nothing to open. The exit door is a door that never
    ' opens - Space on it ends the level (chapter 20).
    '
    ' A door's doorOpen() goes from 0 (shut) to 1 (open), and doorMove()
    ' says which way it's going: Space sets it going, and the loop below
    ' moves it a little every frame. The wall drawing (chapter 15) uses the
    ' number to slide the door aside, raise the shutter, or part the split
    ' door's halves. An open door waits a while (doorWait, DoorHold frames:
    ' each kind its own), then shuts itself - but never on anyone: with you
    ' or a monster in the doorway (DoorBlocked), it waits, or if it was
    ' already shutting, opens again, like an automatic door.
    usedTrig = 0
    IF viewOn = VIEW_CAM AND spaceDown AND NOT spaceWas THEN CameraNext : spaceWas = -1 ' (watching a security camera: USE, the next one - GAME/SECURE.BM)
    IF spaceDown AND NOT spaceWas AND NOT dead AND NOT editMode AND NOT cyberOn THEN ' A "use" trigger at the cell in front? (chapter 19 - not from the network)
        FOR k = 1 TO numTrigs
            IF trigWhen$(k) = "use" AND NOT trigDone(k) THEN
                FOR reach = 0.3 TO 1.6 STEP 0.1
                    IF INT(playerX + dirX * reach) = trigX0(k) AND INT(playerY + dirY * reach) = trigY0(k) THEN trigRun$ = trigCmd$(k) : trigDone(k) = NOT trigRepeat(k) : PlaySfx sndCore&, 0.6 : usedTrig = -1 : TriggerRun : EXIT FOR
                NEXT
            END IF
        NEXT
    END IF
    IF spaceDown AND NOT spaceWas AND NOT dead AND NOT cyberOn AND NOT editMode THEN ' (a "chest" in front of you, asleep: it's a mimic - and it's awake now)
        FOR k = 1 TO numMonsters
            IF monsterType(k) = MT_MIMIC AND monsterState(k) = 0 THEN
                d = SQR((monsterX(k) - playerX) ^ 2 + (monsterY(k) - playerY) ^ 2)
                IF d < 1.8 AND d > 0.01 THEN IF ((monsterX(k) - playerX) * dirX + (monsterY(k) - playerY) * dirY) / d > 0.7 THEN MimicWake k : spaceWas = -1
            END IF
        NEXT
    END IF
    IF spaceDown AND NOT spaceWas AND NOT dead THEN ' (once per press)
        FOR reach = 0.05 TO 2 STEP 0.05
            cellX = INT(playerX + dirX * reach) : cellY = INT(playerY + dirY * reach)
            IF cellX = INT(playerX) AND cellY = INT(playerY) THEN _CONTINUE ' (the doorway you're in)
            IF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) = 0 AND doorLock(cellX, cellY) THEN
                IF SecureDoorUse(cellX, cellY) THEN EXIT FOR ' (a stronghold door - kick it; a keypad door - its code: GAME/SECURE.BM)
                PlaySfx sndLocked&, 0.8
                IF doorLock(cellX, cellY) = 2 THEN ShowMsg "SEALED - hack its data station to open it" ELSE IF doorLock(cellX, cellY) = 3 THEN ShowMsg "LOCKED DOWN - repair the terminal's program" ELSE IF doorLock(cellX, cellY) = 4 THEN ShowMsg "LOCKED" ELSE ShowMsg SealedMsg$(cellX, cellY)
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 AND doorOpen(cellX, cellY) = 0 THEN
                keyNeeded = doorKey(cellX, cellY)
                IF doorType(cellX, cellY) = DOOR_EXIT THEN
                    IF cyberOn THEN ShowMsg "The exit's in the real world - jack out first" ELSE LevelDone
                ELSEIF keyNeeded = 0 OR hasCard(keyNeeded) THEN
                    doorOpen(cellX, cellY) = 0.01 : doorMove(cellX, cellY) = 1
                    PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                ELSE
                    PlaySfx sndLocked&, 0.8
                    ShowMsg "Locked - you need the " + CardName$(keyNeeded) + " keycard"
                END IF
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 AND doorLock(cellX, cellY) THEN
                PlaySfx sndLocked&, 0.8 : ShowMsg SealedMsg$(cellX, cellY)
                EXIT FOR
            ELSEIF worldMap(cellX, cellY) = 2 THEN ' Open (or on the move): shut it - or open it again
                IF doorBroke(cellX, cellY) THEN
                    ' (kicked down: there's nothing left to shut)
                ELSEIF doorMove(cellX, cellY) = -1 THEN
                    doorMove(cellX, cellY) = 1 : PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                ELSEIF NOT DoorBlocked(cellX, cellY, playerX, playerY) THEN
                    doorMove(cellX, cellY) = -1 : PlaySfx DoorSnd&(doorType(cellX, cellY)), 0.9
                END IF
                EXIT FOR
            END IF
            IF worldMap(cellX, cellY) = 9 THEN ' A code terminal: its puzzle
                tm = TermAt(cellX, cellY)
                IF termDone(tm) THEN
                    ShowMsg "TERMINAL: program running - ACCESS GRANTED"
                ELSE
                    TerminalUse
                END IF
                EXIT FOR
            END IF
            IF worldMap(cellX, cellY) = 10 THEN HackUse TCtrlAt(cellX, cellY) : EXIT FOR ' A turret control panel: the hack
            IF worldMap(cellX, cellY) = 8 THEN ' A data station: jack in
                st = StationAt(cellX, cellY)
                IF stationDone(st) THEN
                    ShowMsg "This station's hacked - its doors are open"
                ELSEIF NOT cyberOn THEN
                    JackIn
                END IF
                EXIT FOR
            END IF
            IF decoCell(cellX, cellY) AND reach <= 1.5 AND NOT cyberOn AND NOT usedTrig THEN ' A decoration you can use: a vending machine (VendStep)
                dv = decoCell(cellX, cellY)
                IF DecoUse(dv) THEN EXIT FOR ' (a safe, a desk or bookshelf, a computer, a security monitor, a note - GAME/SECURE.BM)
                IF decoOn(dv) AND decoKind(dv) = DK_CHEST THEN ' (a treasure chest: open it - GAME/BARRELS.BM)
                    IF decoOpen(dv) THEN ShowMsg "Empty - you've had what was in it" ELSE ChestOpen dv
                    EXIT FOR
                END IF
                IF decoOn(dv) AND decoKind(dv) = DK_VENDING THEN
                    IF vendState(dv) = 0 THEN
                        SlotUse dv ' (a slot machine: a pull - SlotUse)
                    ELSEIF vendState(dv) = 3 THEN
                        ShowMsg "SOLD OUT"
                    END IF
                    EXIT FOR
                END IF
                IF decoOn(dv) AND (decoKind(dv) = DK_TERMINAL OR decoKind(dv) = DK_CONSOLE OR decoKind(dv) = DK_SCREENS) AND NOT editMode THEN ' A computer: a game on it
                    IF vendState(dv) = 3 THEN ShowMsg "HIGH SCORE: YOU - this one's paid out" ELSE arcDeco = dv : ArcadeRun
                    EXIT FOR
                END IF
            END IF
            IF secretCell(cellX, cellY) > 0 AND worldMap(cellX, cellY) > 0 AND reach <= 1.2 AND NOT cyberOn AND NOT usedTrig THEN ' A secret wall (chapter 22): found - unless a switch opens it, or its closet still has monsters in
                secS = secretCell(cellX, cellY)
                IF NOT secretShot(secS) AND SecretReady(secS) THEN OpenSecret secS, -1 : EXIT FOR
            END IF
            IF SolidAt(playerX + dirX * reach, playerY + dirY * reach) THEN
                IF reach <= 1.2 AND NOT usedTrig THEN PlaySfx sndHump&, 0.8 : AchAdd "Searches", 1 ' Trying to open a plain wall (not a switch you just used)
                EXIT FOR
            END IF
        NEXT
    END IF
    FOR doorK& = 1 TO numDoorCells ' (the doors: ListDoors)
        doorX = doorCellX(doorK&) : doorY = doorCellY(doorK&)
        IF doorBroke(doorX, doorY) THEN doorOpen(doorX, doorY) = 1 : doorMove(doorX, doorY) = 0 : _CONTINUE ' (kicked down: open for good)
        ' (a locked door that's open shuts - as soon as nobody's in the way)
        IF doorLock(doorX, doorY) AND doorOpen(doorX, doorY) > 0 AND doorMove(doorX, doorY) <> -1 THEN
            IF NOT DoorBlocked(doorX, doorY, playerX, playerY) THEN doorMove(doorX, doorY) = -1 : doorWait(doorX, doorY) = 0
        END IF
        IF worldMap(doorX, doorY) = 2 AND doorOpen(doorX, doorY) > 0 THEN
            ' (a door part-open with nowhere to go - from an old saved game - opens)
            IF doorMove(doorX, doorY) = 0 AND doorOpen(doorX, doorY) < 1 THEN doorMove(doorX, doorY) = 1
            SELECT CASE doorMove(doorX, doorY)
                CASE 1 ' Opening
                    doorOpen(doorX, doorY) = doorOpen(doorX, doorY) + DoorSpeed(doorType(doorX, doorY))
                    IF doorOpen(doorX, doorY) >= 1 THEN
                        doorOpen(doorX, doorY) = 1 : doorMove(doorX, doorY) = 0 : doorWait(doorX, doorY) = DoorHold(doorType(doorX, doorY))
                    END IF
                CASE -1 ' Shutting - unless someone's in the way: then it opens again
                    IF DoorBlocked(doorX, doorY, playerX, playerY) THEN
                        doorMove(doorX, doorY) = 1
                    ELSE
                        doorOpen(doorX, doorY) = doorOpen(doorX, doorY) - DoorSpeed(doorType(doorX, doorY))
                        IF doorOpen(doorX, doorY) <= 0 THEN doorOpen(doorX, doorY) = 0 : doorMove(doorX, doorY) = 0
                    END IF
                CASE ELSE ' Open, waiting - then shutting itself, when the doorway's clear
                    IF doorWait(doorX, doorY) > 0 THEN
                        doorWait(doorX, doorY) = doorWait(doorX, doorY) - 1
                    ELSEIF NOT DoorBlocked(doorX, doorY, playerX, playerY) THEN
                        doorMove(doorX, doorY) = -1
                        far = SQR((doorX + 0.5 - playerX) ^ 2 + (doorY + 0.5 - playerY) ^ 2) ' (quieter further off)
                        IF far < 14 THEN PlaySfx DoorSnd&(doorType(doorX, doorY)), 0.9 * (1 - far / 14)
                    ELSE
                        doorWait(doorX, doorY) = 30 ' (someone's in it: look again in half a second)
                    END IF
            END SELECT
        END IF
    NEXT
