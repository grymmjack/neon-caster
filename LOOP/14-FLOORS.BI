''
' NEON-CASTER - LOOP/14-FLOORS.BI
' =============================================================================
' Chapter 14 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 14: LIGHT, AND DRAWING THE FLOOR AND CEILING
    '-------------------------------------------------------------------------
    ' Now we draw the frame into pixels() - floor and ceiling first, then the
    ' walls on top of them (chapter 15), then the sprites (chapter 16).
    '
    ' But first, light. Like Doom, the light is kept per cell: litR(),
    ' litG() and litB() say how much red, green and blue light each cell
    ' has this frame. Everything in a cell - its floor and ceiling, the
    ' faces of the walls around it, the monsters in it - is lit by it.
    ' UpdateLight starts every cell at the level's ambient light, then adds
    ' each of the level's lights (a light is brightest where it is and
    ' fades to nothing at its radius, and it doesn't shine through walls),
    ' made to flicker, pulse or strobe by its effect. Then muzzle flashes,
    ' explosions and bolts add their glow. A per-cell light is blocky, like
    ' Doom's, but it's cheap: 48 x 48 cells, not 120,000 pixels.
    '
    ' The horizon is the middle row of the screen. Your eye is half a wall up
    ' from the floor, so every row below the horizon shows the floor at one
    ' fixed distance: the further down the screen, the closer the floor. By
    ' similar triangles, row y sees the floor at
    '
    '     rowDist = (viewH / 2) / (y - RENDER_H / 2)
    '
    ' (viewH is RENDER_H, times the zoom while you aim - chapter 8)
    '
    ' (the + 0.5 below aims at the middle of the row, and keeps us from ever
    ' dividing by 0). Along that row, the floor point slides in a straight
    ' line from where the left-most ray (rayDirX0, rayDirY0) meets the floor
    ' to where the right-most ray (rayDirX1, rayDirY1) does - so we work out
    ' the step from one pixel to the next once (floorStepX, floorStepY) and
    ' just add it 400 times. The fraction part of the floor point picks the
    ' texture pixel: INT(floorX * 64) AND 63 is the same as
    ' (floorX * 64) MOD 64 for a 64-pixel texture, only faster - which is why
    ' textures are a power of 2 wide.
    '
    ' The ceiling is the same picture upside down: row y's mirror image above
    ' the horizon shows the ceiling at the same distance, straight above the
    ' same floor point. So one pass draws both.
    '
    ' The light: each pixel takes its cell's light (litR, litG, litB), dimmed
    ' by the fog - fog& goes from 256 close up down to 0 (black) 16 cells
    ' away. ShadeRGB~& (chapter 23) multiplies the texture's red, green and
    ' blue by the light's.
    '
    ' Which renderer draws this frame (RENDERER in the menu: chapter 21)?
    ' This code, or the graphics card (OPENGL, chapter 24). With OpenGL the
    ' light is still worked out here, and the raycaster still runs - for
    ' the zBuffer, the map, and to find the cells you can see - but the
    ' loops that colour in pixels one at a time are skipped. glWrite is the
    ' half of OpenGL's snapshot (chapter 5) this frame fills in.
    glMode = (setting(SET_RENDERER) = 2)
    glWrite = 1 - glBuf : glFrameNo = glFrameNo + 1 : glNumSpr(glWrite) = 0
    viewStart# = TIMER(0.001) ' (for SHOW FPS: how long the 3D view takes)
    ' This frame's light: the level's own (UpdateLight, chapter 23), then
    ' the flashes - your muzzle, explosions, bolts - each a glow that fades
    ' out over a few cells (AddGlow, chapter 23)
    ' (With OpenGL's MOVING LIGHTS, the flashes are real lights of their own,
    ' lighting every pixel - chapter 24 - so they're left out of the cells.)
    UpdateLight
    IF NOT (glMode AND setting(SET_DYNLIGHT) <> 0) THEN
        IF muzzleFlash > 0 THEN AddGlow playerX, playerY, 5, 70 * muzzleFlash, 40 * muzzleFlash, 40 * muzzleFlash
        FOR i = 1 TO MAX_BLASTS
            IF blastTime(i) > 0 THEN
                f = blastTime(i) / BLAST_FRAMES * blastSize(i)
                AddGlow blastX(i), blastY(i), 2 + 5 * blastSize(i), 400 * f, 220 * f, 90 * f
            END IF
        NEXT
        FOR i = 1 TO MAX_BOLTS
            IF boltOn(i) THEN
                IF boltKind(i) = BK_PLASMA THEN
                    AddGlow boltX(i), boltY(i), 2.5, 160, 40, 170
                ELSEIF boltKind(i) <= BK_MISSILE THEN
                    AddGlow boltX(i), boltY(i), 2.5, bkR(boltKind(i)) * 0.7, bkG(boltKind(i)) * 0.7, bkB(boltKind(i)) * 0.7
                ELSEIF boltKind(i) = BK_FLAME THEN
                    AddGlow boltX(i), boltY(i), 1.5, 50, 22, 4 ' (a flame's puffs light a little - poison and acid not at all)
                END IF
            END IF
        NEXT
        FOR i = 1 TO numMonsters ' (a body burning: orange, flickering)
            IF monBurn(i) > 0 THEN fl = (0.6 + 0.4 * RND) * MinOf(1, monBurn(i) / 60) : AddGlow monsterX(i), monsterY(i), 3, 220 * fl, 110 * fl, 30 * fl
        NEXT
        FOR i = 1 TO numDecos
            IF decoBurn(i) > 0 THEN fl = (0.6 + 0.4 * RND) * MinOf(1, decoBurn(i) / 60) : AddGlow decoX(i), decoY(i), 3, 220 * fl, 110 * fl, 30 * fl
        NEXT
        FOR i = 1 TO numMonsters ' (a destroyed turret's mount: its torn wires flicker blue-white)
            IF monBlown(i) = 2 THEN IF RND < 0.45 THEN fl = RND : AddGlow monsterX(i), monsterY(i), 2.2, 60 * fl, 110 * fl, 200 * fl
        NEXT
    END IF
    FOR i = 1 TO numDecos ' (the spawners, glowing as they charge)
        IF decoOn(i) AND decoKind(i) = 9 THEN
            c = decoCharge(i) : f = decoBurst(i) / 20
            pulse = 0.65 + 0.35 * SIN(lvFrame * (0.08 + 0.4 * c) + i)
            AddGlow decoX(i), decoY(i), 1.3 + 2.2 * c + 3 * f, (40 + 230 * c) * pulse + 500 * f, (10 + 50 * c) * pulse + 220 * f, (50 + 220 * c) * pulse + 480 * f
        END IF
    NEXT
    IF NOT glMode THEN ' The sky's column for each screen column (by its ray's angle) and row for each screen row (by how far above the horizon)
        FOR x = 0 TO RENDER_W - 1
            cameraX = 2 * x / RENDER_W - 1 : a = _ATAN2(dirY + planeY * cameraX, dirX + planeX * cameraX) / 6.2831853 * SKY_REPEAT
            skyU(x) = INT((a - INT(a)) * texSize) AND (texSize - 1)
        NEXT
        FOR y = 0 TO RENDER_H - 1
            el = ATN((RENDER_H / 2 - y - 0.5) / viewH) / SKY_EL : IF el < 0 THEN el = 0
            IF el > 1 THEN el = 1
            skyV(y) = INT((1 - el) * (texSize - 1))
        NEXT
    END IF
    IF NOT glMode AND liqAny AND NOT cyberOn THEN LiquidAnimate ' (the liquids' pictures, rippling - OpenGL's shader does its own)
    IF NOT glMode AND levelFlat THEN ' (OpenGL draws the floor and ceiling itself; with heights, HeightColumn does - chapter 15)
        rayDirX0 = dirX - planeX : rayDirY0 = dirY - planeY
        rayDirX1 = dirX + planeX : rayDirY1 = dirY + planeY
        FOR y = RENDER_H \ 2 TO RENDER_H - 1
            rowDist = (viewH / 2) /(y - RENDER_H / 2 + 0.5)
            floorStepX = rowDist * (rayDirX1 - rayDirX0) / RENDER_W : floorStepY = rowDist * (rayDirY1 - rayDirY0) / RENDER_W
            floorX = playerX + rowDist * rayDirX0 : floorY = playerY + rowDist * rayDirY0
            fog& = 256 - rowDist * 16
            IF fog& < 0 THEN fog& = 0
            floorRow = y * RENDER_W : ceilRow = (RENDER_H - 1 - y) * RENDER_W
            lastCellX = -1 : lastCellY = -1
            FOR x = 0 TO RENDER_W - 1
                cellX = INT(floorX) : cellY = INT(floorY)
                ' Neighbouring pixels are nearly always in the same cell, so a
                ' cell's textures and light are only looked up when we cross
                ' into a new one
                IF cellX <> lastCellX OR cellY <> lastCellY THEN
                    lastCellX = cellX : lastCellY = cellY : splitCell = 0
                    IF cellX >= 0 AND cellX < mapN AND cellY >= 0 AND cellY < mapN THEN
                        cellFloor = floorTex(cellX, cellY) : cellCeil = ceilTex(cellX, cellY)
                        cFU = 0 : cFV = 0 : cCU = 0 : cCV = 0 ' (the floor's and ceiling's pictures slid: [faces])
                        cFSU = texSize : cFSV = texSize : cCSU = texSize : cCSV = texSize ' (texels a cell across: texSize, or stretched)
                        IF faceOffAny THEN
                            cFU = faceOU(cellX, cellY, 9) * texSize \ 64 : cFV = faceOV(cellX, cellY, 9) * texSize \ 64 : cCU = faceOU(cellX, cellY, 10) * texSize \ 64 : cCV = faceOV(cellX, cellY, 10) * texSize \ 64
                            IF faceKU(cellX, cellY, 9) THEN cFSU = texSize * 100 / faceKU(cellX, cellY, 9)
                            IF faceKV(cellX, cellY, 9) THEN cFSV = texSize * 100 / faceKV(cellX, cellY, 9)
                            IF faceKU(cellX, cellY, 10) THEN cCSU = texSize * 100 / faceKU(cellX, cellY, 10)
                            IF faceKV(cellX, cellY, 10) THEN cCSV = texSize * 100 / faceKV(cellX, cellY, 10)
                        END IF
                        splitCell = floorSplit(cellX, cellY) OR ceilSplit(cellX, cellY)
                        cellTrack = 0 ' A door's track: 1 running along x, 2 along y (DoorAcross + 1)
                        IF worldMap(cellX, cellY) = 2 THEN IF doorType(cellX, cellY) <> DOOR_EXIT THEN cellTrack = DoorAcross(cellX, cellY) + 1
                        lightR& = litR(cellX, cellY) * fog& \ 256 : lightG& = litG(cellX, cellY) * fog& \ 256 : lightB& = litB(cellX, cellY) * fog& \ 256
                    ELSE
                        cellFloor = T_FLOOR + 1 : cellCeil = T_CEIL + 1 : cellTrack = 0 : cFU = 0 : cFV = 0 : cCU = 0 : cCV = 0 : cFSU = texSize : cFSV = texSize : cCSU = texSize : cCSV = texSize
                        lightR& = ambientR * fog& \ 256 : lightG& = ambientG * fog& \ 256 : lightB& = ambientB * fog& \ 256
                    END IF
                    IF lightR& > 256 THEN lightR& = 256 ' (full brightness at most: then the sums below can't overflow)
                    IF lightG& > 256 THEN lightG& = 256
                    IF lightB& > 256 THEN lightB& = 256
                END IF
                floorSlot = cellFloor : ceilSlot = cellCeil
                IF splitCell THEN ' A cell split on the diagonal: which half is this pixel in?
                    IF floorSplit(cellX, cellY) THEN IF InDiagonalWall(floorSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN floorSlot = floorTex2(cellX, cellY)
                    IF ceilSplit(cellX, cellY) THEN IF InDiagonalWall(ceilSplit(cellX, cellY), floorX - cellX, floorY - cellY) THEN ceilSlot = ceilTex2(cellX, cellY)
                END IF
                texU = INT(floorX * texSize) AND (texSize - 1) : texV = INT(floorY * texSize) AND (texSize - 1)
                ' The same sum as ShadeRGB~& (chapter 23), written out here: this
                ' runs 120,000 times a frame, and calling a FUNCTION each time
                ' would cost more than the sum itself
                texel~& = texture((INT(floorX * cFSU) + cFU) AND (texSize - 1), (INT(floorY * cFSV) + cFV) AND (texSize - 1), floorSlot)
                pixels(floorRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                IF texSky(ceilSlot) THEN ' (a sky: by the way you look, full bright)
                    pixels(ceilRow + x) = texture(skyU(x), skyV(RENDER_H - 1 - y), ceilSlot) OR &HFF000000~&
                ELSE
                    texel~& = texture((INT(floorX * cCSU) + cCU) AND (texSize - 1), (INT(floorY * cCSV) + cCV) AND (texSize - 1), ceilSlot)
                    pixels(ceilRow + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                END IF
                IF gridOn THEN IF texU < gridW OR texV < gridW THEN pixels(floorRow + x) = GridMix~&(pixels(floorRow + x)) : pixels(ceilRow + x) = GridMix~&(pixels(ceilRow + x)) ' (the editor's grid: chapter 21)
                IF cellTrack THEN ' In a doorway: its door's track, a dark groove (a quarter as bright)
                    IF cellTrack = 1 THEN trackD = ABS(floorY - cellY - 0.5) ELSE trackD = ABS(floorX - cellX - 0.5)
                    IF trackD < TRACK_HALF THEN
                        pixels(floorRow + x) = ((pixels(floorRow + x) AND &HFCFCFC) \ 4) OR &HFF000000~&
                        pixels(ceilRow + x) = ((pixels(ceilRow + x) AND &HFCFCFC) \ 4) OR &HFF000000~&
                    END IF
                END IF
                floorX = floorX + floorStepX : floorY = floorY + floorStepY
            NEXT
        NEXT
    END IF

    ' (HeightColumn's floors and ceilings: each row's distance-per-height,
    ' worked out once a frame instead of once a pixel - see HeightColumn)
    IF NOT glMode AND NOT levelFlat THEN
        FOR y = 0 TO RENDER_H - 1
            rowF(y) = viewH / (y - RENDER_H / 2 + 0.5) : rowC(y) = viewH / (RENDER_H / 2 - y - 0.5)
        NEXT
    END IF
