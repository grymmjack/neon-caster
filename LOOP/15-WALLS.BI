''
' NEON-CASTER - LOOP/15-WALLS.BI
' =============================================================================
' Chapter 15 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    '-------------------------------------------------------------------------
    ' CHAPTER 15: DRAWING THE WALLS - THE RAYCASTER
    '-------------------------------------------------------------------------
    ' The heart of the game. For each of the 400 columns of the view:
    '
    ' 1. THE RAY. cameraX goes from -1 at the left column to +1 at the
    '    right. The ray's direction is your direction plus that much of the
    '    camera plane (chapter 8): rayDir = dir + plane * cameraX.
    '
    ' 2. WALKING THE GRID (the "DDA"). We want the first wall cell the ray
    '    enters. Rather than inch along it, we hop from one cell edge to the
    '    next. The ray crosses a vertical grid line (an "x-side") every
    '    deltaDistX of travel, and a horizontal one (a "y-side") every
    '    deltaDistY - for a ray that's (rayDirX, rayDirY), that's
    '    ABS(1 / rayDirX) and ABS(1 / rayDirY). sideDistX and sideDistY are
    '    how far along the ray the NEXT x-side and y-side are. Each step,
    '    whichever is nearer is the edge we cross: move into that cell
    '    (stepX or stepY is +1 or -1, the way the ray points), push that
    '    side's distance one deltaDist further, and look at the new cell.
    '    "side" remembers which kind of edge we came through: 0 = x-side
    '    (a wall facing east or west), 1 = y-side (north or south).
    '
    '                    +-----+-----+-----+
    '                    |     |     |#####|   The ray crosses edges in
    '                    |     |    /|#####|   order of distance: x-side,
    '                    +-----+---/-+-----+   y-side, x-side... and stops
    '                    |     |  /  |     |   in the first wall cell (#).
    '                    |     | /   |     |
    '                    +-----+/----+-----+
    '                    | you /     |     |
    '
    ' 3. HOW FAR? perpWallDist is the distance to the wall measured straight
    '    ahead (at right angles to the camera plane), NOT along the ray. If
    '    we used the true ray length, walls at the screen's edges would come
    '    out too far away and the view would bulge like a fish-eye lens.
    '    Measured straight ahead, a flat wall stays flat. The DDA hands it
    '    to us: it's the sideDist of the edge we crossed last (sideDist minus
    '    one deltaDist, as sideDist has already moved on) - worked out below
    '    from the cell we stopped in.
    '
    ' 4. HOW TALL? A wall one cell high, perpWallDist away, is
    '    viewH / perpWallDist pixels tall, centred on the horizon (viewH
    '    is RENDER_H, times the zoom while you aim - chapter 8).
    '
    ' 5. WHICH TEXTURE COLUMN? wallX is where along the wall's face the ray
    '    hit (0 to 1); times 64 that's the column of the texture to draw.
    '    Some faces flip it, so textures aren't mirrored when you see them
    '    from the other side. Down the screen we step through the texture
    '    by texStep = 64 / lineHeight texels per pixel.
    '
    ' 6. LIGHT. Fog by distance as on the floor, and y-sides a bit darker
    '    than x-sides. It's fake lighting, but it makes corners readable.
    '
    ' 7. zBuffer(x) = perpWallDist, for the sprites (chapter 16) and for
    '    shooting (chapter 12).
    '
    ' Some cells aren't simply solid:
    '   DOORS are slabs DOOR_THICK thick across the middle of their cell
    '   (DoorRay works out where a ray meets one). The ray stops at the slab
    '   only where the door still is: a sliding door has slid doorOpen of
    '   the way across, so a ray crossing where it slid away from carries on
    '   into the room beyond - unless it meets the door's edge on the way.
    '   A rising shutter is drawn in a second pass, over whatever is behind
    '   it ("shutterSeen" remembers it) - and its underside, once it's above
    '   your eyes. (The exit door, which never opens, stays on its cell's
    '   face, like a wall.)
    '   DIAGONAL WALLS: entering one, we check where the ray crosses the
    '   cell's diagonal (DiagonalHit, chapter 23). If it does before leaving
    '   the cell, that's the hit, at that distance; otherwise the ray is in
    '   the open half and carries on.
    '   BLOCKS stand in open cells: a box anywhere inside the cell (boxOn,
    '   boxX0...). Crossing such a cell, we ask where the ray goes into the
    '   box (BoxRay, chapter 23); if that's before it leaves the cell, the
    '   box's side is the hit - its side 0 or 1 like any wall's - and
    '   otherwise the ray is on open floor and carries on. Its sides are
    '   faces of their own (FACE_BOX + 1 to 4), so they take pictures too.
    FOR x = 0 TO RENDER_W - 1
        cameraX = 2 * x / RENDER_W - 1
        rayDirX = dirX + planeX * cameraX : rayDirY = dirY + planeY * cameraX
        mapX = INT(playerX) : mapY = INT(playerY)
        cellSeen(mapX, mapY) = -1 : glSeen(mapX, mapY, glWrite) = glFrameNo
        deltaDistX = ABS(1 / rayDirX) : deltaDistY = ABS(1 / rayDirY)

        IF rayDirX < 0 THEN stepX = -1 : sideDistX = (playerX - mapX) * deltaDistX ELSE stepX = 1 : sideDistX = (mapX + 1 - playerX) * deltaDistX
        IF rayDirY < 0 THEN stepY = -1 : sideDistY = (playerY - mapY) * deltaDistY ELSE stepY = 1 : sideDistY = (mapY + 1 - playerY) * deltaDistY

        hit = 0 : side = 0 : shutterSeen = 0 : diagHit = 0 : doorHit = 0 : boxHit = 0
        glassT(x) = 0 : glassDone(x) = 0 ' (glass: GlassRay notes the nearest pane the ray goes through)
        IF glassHP(mapX, mapY) > 0 THEN IF GlassRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, gT, gU) THEN glassT(x) = gT : glassU(x) = gU : glassCX(x) = mapX : glassCY(x) = mapY
        IF diagCorner(mapX, mapY) THEN ' Standing in a diagonal wall's open half
            exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
            diagDist = DiagonalHit(diagCorner(mapX, mapY), mapX, mapY, playerX, playerY, rayDirX, rayDirY, 0, exitDist)
            IF diagDist >= 0 THEN hit = worldMap(mapX, mapY) : diagHit = diagCorner(mapX, mapY) : perpWallDist = diagDist
        END IF
        IF boxOn(mapX, mapY) THEN ' Standing beside a box, in its cell
            exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
            boxDist = BoxRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, 0, exitDist, bSide)
            IF boxDist >= 0 THEN hit = boxOn(mapX, mapY) : boxHit = -1 : side = bSide : perpWallDist = boxDist
        END IF
        WHILE hit = 0
            IF sideDistX < sideDistY THEN sideDistX = sideDistX + deltaDistX : mapX = mapX + stepX : side = 0 ELSE sideDistY = sideDistY + deltaDistY : mapY = mapY + stepY : side = 1
            IF sideDistX - deltaDistX > RAY_FAR AND sideDistY - deltaDistY > RAY_FAR THEN hit = 1 : EXIT WHILE ' (this far the fog's long since black: as good as a wall - in a sector 256 across, the ray needn't go all the way)
            cellValue = worldMap(mapX, mapY)
            cellSeen(mapX, mapY) = -1 ' (for the map: you've seen this cell)
            glSeen(mapX, mapY, glWrite) = glFrameNo ' (and for OpenGL: a cell to draw - chapter 24)
            IF glassHP(mapX, mapY) > 0 AND glassT(x) = 0 THEN ' Glass: note it, and carry on through
                IF GlassRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, gT, gU) THEN glassT(x) = gT : glassU(x) = gU : glassCX(x) = mapX : glassCY(x) = mapY
            END IF
            IF diagCorner(mapX, mapY) THEN
                ' Diagonal wall: came in through its solid half, that's a plain
                ' wall face; else it hits the diagonal if it crosses it in here
                IF side = 0 THEN enterDist = sideDistX - deltaDistX ELSE enterDist = sideDistY - deltaDistY
                exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
                IF InDiagonalWall(diagCorner(mapX, mapY), playerX + (enterDist + 0.001) * rayDirX - mapX, playerY + (enterDist + 0.001) * rayDirY - mapY) THEN
                    hit = cellValue
                ELSE
                    diagDist = DiagonalHit(diagCorner(mapX, mapY), mapX, mapY, playerX, playerY, rayDirX, rayDirY, enterDist, exitDist)
                    IF diagDist >= 0 THEN hit = cellValue : diagHit = diagCorner(mapX, mapY) : perpWallDist = diagDist
                END IF
            ELSEIF boxOn(mapX, mapY) THEN
                ' A box: the ray hits it if it goes into it before leaving the
                ' cell (BoxRay); else it's open floor, and the ray carries on
                IF side = 0 THEN enterDist = sideDistX - deltaDistX ELSE enterDist = sideDistY - deltaDistY
                exitDist = sideDistX : IF sideDistY < exitDist THEN exitDist = sideDistY
                boxDist = BoxRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, enterDist, exitDist, bSide)
                IF boxDist >= 0 THEN hit = boxOn(mapX, mapY) : boxHit = -1 : side = bSide : perpWallDist = boxDist
            ELSEIF cellValue = 2 THEN
                IF doorType(mapX, mapY) = DOOR_EXIT THEN ' Never opens: a wall, on its cell's face
                    hit = 2
                ELSE ' A slab across the doorway's middle (DoorRay)
                    doorHit = DoorRay(mapX, mapY, playerX, playerY, rayDirX, rayDirY, doorDist, doorU, doorSide, doorLitX, doorLitY, doorBack)
                    IF doorHit = 3 THEN ' A rising shutter: drawn afterwards, over what's behind
                        IF shutterSeen = 0 THEN
                            shutterSeen = -1 : shutterDist = doorDist : shutterBack = doorBack : shutterU = doorU : shutterOpen = DoorShown(mapX, mapY)
                            shutterSide = doorSide : shutterLitX = doorLitX : shutterLitY = doorLitY
                        END IF
                        doorHit = 0
                    ELSEIF doorHit THEN
                        hit = 2 : side = doorSide : perpWallDist = doorDist
                    END IF
                END IF
            ELSEIF cellValue > 0 THEN
                hit = cellValue
            END IF
        WEND

        IF diagHit = 0 AND doorHit = 0 AND boxHit = 0 THEN
            IF side = 0 THEN perpWallDist = (mapX - playerX + (1 - stepX) / 2) / rayDirX ELSE perpWallDist = (mapY - playerY + (1 - stepY) / 2) / rayDirY
        END IF
        IF perpWallDist < 0.001 THEN perpWallDist = 0.001
        zBuffer(x) = perpWallDist

        ' Texture column and slot (a door's texture slides along with it)
        texSlot2 = 0 : wallVO = 0 : wallVK = 1 : wallPc = 0 ' (a face divided top | bottom in the editor: the bottom half's; wallVO, wallVK: its picture slid up, stretched)
        IF side = 0 THEN wallX = playerY + perpWallDist * rayDirY ELSE wallX = playerX + perpWallDist * rayDirX
        wallCell = INT(wallX) : wallX = wallX - wallCell ' (wallCell: which cell along the wall - a stretched picture's measured from the map's grid)
        IF diagHit THEN ' Along the diagonal, left to right as you see it
            wallX = playerX + perpWallDist * rayDirX - mapX
            IF diagHit > 2 THEN wallX = 1 - wallX
            texX = INT(wallX * texSize) : texSlot = wallTexSlot(hit)
        ELSEIF doorHit = 2 THEN ' A door's edge: a thin slice of its picture
            texX = INT(doorU * DOOR_THICK * texSize)
            SELECT CASE doorType(mapX, mapY)
                CASE DOOR_SLIDE : texSlot = DoorSlot(mapX, mapY)
                CASE DOOR_SPLIT : texSlot = T_SPLIT
                CASE ELSE : texSlot = T_SHUTTER
            END SELECT
        ELSEIF hit = 2 THEN
            IF doorHit THEN wallX = doorU ' (where along the slab)
            doorOpenAmt = DoorShown(mapX, mapY)
            SELECT CASE doorType(mapX, mapY)
                CASE DOOR_SLIDE
                    texX = INT((wallX - doorOpenAmt) * texSize)
                    texSlot = DoorSlot(mapX, mapY)
                CASE DOOR_SPLIT
                    IF wallX < 0.5 THEN texX = INT((wallX + doorOpenAmt / 2) * texSize) ELSE texX = INT((wallX - doorOpenAmt / 2) * texSize)
                    texSlot = T_SPLIT
                CASE DOOR_EXIT ' (turned like a wall, so its sign reads the right way)
                    texX = INT(wallX * texSize) : texSlot = T_EXIT
                    IF side = 0 AND rayDirX < 0 THEN texX = texSize - 1 - texX
                    IF side = 1 AND rayDirY > 0 THEN texX = texSize - 1 - texX
                    IF faceAny THEN ' (painted, or divided, in the editor: as a wall's side)
                        IF side = 0 THEN IF rayDirX > 0 THEN sd = 3 ELSE sd = 1
                        IF side = 1 THEN IF rayDirY > 0 THEN sd = 4 ELSE sd = 2
                        IF faceDiv(mapX, mapY, sd) = 3 THEN ' (in pieces: each its own picture, slide, stretch - LEVEL/PIECES.BM)
                            wallPc = faceTex(mapX, mapY, sd) : wallPcD = texSlot : wallPcX = texX : wallPcC = 0 : wallPcG = MinOf(15, INT(texX / texSize * 16))
                        END IF
                        IF faceTex(mapX, mapY, sd) OR faceTex2(mapX, mapY, sd) THEN texSlot2 = FaceSlot(mapX, mapY, sd, texX / texSize, 1, texSlot) : texSlot = FaceSlot(mapX, mapY, sd, texX / texSize, 0, texSlot)
                    END IF
                CASE ELSE
                    texX = INT(wallX * texSize) : texSlot = T_SHUTTER
            END SELECT
        ELSE
            texX = INT(wallX * texSize) : texSlot = wallTexSlot(hit)
            ' (a picture reads left to right as you face it: wallX grows with y
            ' or x, which runs right to left on a wall you see going west, or
            ' south - so there it's turned round)
            IF side = 0 AND rayDirX < 0 THEN texX = texSize - 1 - texX
            IF side = 1 AND rayDirY > 0 THEN texX = texSize - 1 - texX
            IF faceAny THEN ' (a side with a picture of its own - the editor's PAINT, or a light's tint)
                IF side = 0 THEN IF rayDirX > 0 THEN sd = 3 ELSE sd = 1
                IF side = 1 THEN IF rayDirY > 0 THEN sd = 4 ELSE sd = 2
                fu = texX / texSize
                IF boxHit THEN fu = BoxFaceU(mapX, mapY, sd, fu) : sd = sd + FACE_BOX ' (a block's sides are faces of their own)
                IF faceDiv(mapX, mapY, sd) = 3 THEN ' (in pieces: each its own picture, slide, stretch - LEVEL/PIECES.BM)
                    wallPc = faceTex(mapX, mapY, sd) : wallPcD = texSlot : wallPcX = texX : wallPcG = MaxOf(0, MinOf(15, INT(fu * 16)))
                    wallPcC = wallCell : IF (side = 0 AND rayDirX < 0) OR (side = 1 AND rayDirY > 0) THEN wallPcC = -wallCell
                END IF
                IF faceTex(mapX, mapY, sd) OR faceTex2(mapX, mapY, sd) THEN texSlot2 = FaceSlot(mapX, mapY, sd, fu, 1, texSlot) : texSlot = FaceSlot(mapX, mapY, sd, fu, 0, texSlot)
                IF faceOffAny THEN ' (its picture slid along and up, and stretched: [faces])
                    IF faceKU(mapX, mapY, sd) THEN ' (u as the map's grid has it, the way the picture runs - then stretched)
                        IF (side = 0 AND rayDirX < 0) OR (side = 1 AND rayDirY > 0) THEN wallCell = -wallCell
                        texX = INT((texX / texSize + wallCell) * 100 / faceKU(mapX, mapY, sd) * texSize)
                    END IF
                    texX = texX + faceOU(mapX, mapY, sd) * texSize \ 64 : wallVO = faceOV(mapX, mapY, sd) * texSize \ 64
                    IF faceKV(mapX, mapY, sd) THEN wallVK = 100 / faceKV(mapX, mapY, sd)
                END IF
            END IF
        END IF
        texX = texX AND (texSize - 1)

        lineHeight = viewH / perpWallDist
        drawStart = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2)
        texStep = texSize / lineHeight : texPos = (drawStart - RENDER_H / 2 + lineHeight / 2) * texStep
        IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
        IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1

        ' Light: the light of the cell in front of the face we hit (for a
        ' diagonal, its own cell), dimmed by distance fog, y-sides darker and
        ' diagonals in between
        fog& = 256 - perpWallDist * 16
        IF fog& < 0 THEN fog& = 0
        IF diagHit THEN fog& = fog& * 0.85 ELSE IF side = 1 THEN fog& = fog& * 0.7
        IF doorHit THEN
            litX = doorLitX : litY = doorLitY
        ELSEIF diagHit OR boxHit THEN
            litX = mapX : litY = mapY
        ELSEIF side = 0 THEN
            litX = mapX - stepX : litY = mapY
        ELSE
            litX = mapX : litY = mapY - stepY
        END IF
        lightR& = litR(litX, litY) * fog& \ 256 : lightG& = litG(litX, litY) * fog& \ 256 : lightB& = litB(litX, litY) * fog& \ 256
        IF lightR& > 256 THEN lightR& = 256
        IF lightG& > 256 THEN lightG& = 256
        IF lightB& > 256 THEN lightB& = 256

        clipN(x) = 0
        IF NOT glMode AND NOT levelFlat THEN HeightColumn ' (heights: the column, Doom's way - RENDER/VIEW.BM)
        IF NOT glMode AND levelFlat THEN ' (OpenGL draws the walls itself)
            IF texSlot2 = 0 THEN texSlot2 = texSlot
            wSl = texSlot : texMid = texSize / 2
            IF wallPc THEN ' A face in pieces: down the column, each piece as it comes - its picture, slide and stretch
                pcL = -1 : pcTX = texX
                FOR y = drawStart TO drawEnd
                    pcV = INT(texPos * 16 / texSize) : IF pcV < 0 THEN pcV = 0 ELSE IF pcV > 15 THEN pcV = 15
                    IF pcGrid(wallPc, wallPcG + 16 * pcV) <> pcL THEN
                        pcL = pcGrid(wallPc, wallPcG + 16 * pcV) : wSl = pcSl(wallPc, pcL) : IF wSl = 0 THEN wSl = wallPcD
                        pcTX = wallPcX : IF pcKU(wallPc, pcL) THEN pcTX = INT((wallPcX / texSize + wallPcC) * 100 / pcKU(wallPc, pcL) * texSize)
                        pcTX = (pcTX + pcOU(wallPc, pcL) * texSize \ 64) AND (texSize - 1)
                        wallVO = pcOV(wallPc, pcL) * texSize \ 64 : wallVK = 1 : IF pcKV(wallPc, pcL) THEN wallVK = 100 / pcKV(wallPc, pcL)
                    END IF
                    texel~& = texture(pcTX, (INT(texPos * wallVK) + wallVO) AND (texSize - 1), wSl)
                    pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                    IF gridOn THEN IF texX < gridW OR (INT(texPos) AND (texSize - 1)) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
                    texPos = texPos + texStep
                NEXT
            ELSE
                FOR y = drawStart TO drawEnd ' (ShadeRGB~&, written out - see the floor)
                    IF texPos >= texMid THEN wSl = texSlot2
                    texel~& = texture(texX, (INT(texPos * wallVK) + wallVO) AND (texSize - 1), wSl)
                    pixels(y * RENDER_W + x) = &HFF000000~& OR (((texel~& AND &HFF0000) \ 65536) * lightR& \ 256) * 65536 OR (((texel~& AND &HFF00&) \ 256) * lightG& \ 256) * 256 OR ((texel~& AND 255) * lightB& \ 256)
                    IF gridOn THEN IF texX < gridW OR (INT(texPos) AND (texSize - 1)) < gridW THEN pixels(y * RENDER_W + x) = GridMix~&(pixels(y * RENDER_W + x))
                    texPos = texPos + texStep
                NEXT
            END IF
        END IF

        ' A rising shutter in front: its lower edge has lifted shutterOpen of
        ' the way up, so draw only the part still hanging down
        IF shutterSeen THEN
            lineHeight = viewH / shutterDist
            shutterTop = INT(RENDER_H / 2 - lineHeight / 2) : drawEnd = INT(RENDER_H / 2 + lineHeight / 2 - shutterOpen * lineHeight)
            texStep = texSize / lineHeight : texPos = shutterOpen * texSize
            drawStart = shutterTop
            IF drawStart < 0 THEN texPos = texPos - drawStart * texStep : drawStart = 0
            IF drawEnd > RENDER_H - 1 THEN drawEnd = RENDER_H-1
            fog& = 256 - shutterDist * 16
            IF fog& < 0 THEN fog& = 0
            IF shutterSide = 1 THEN fog& = fog& * 0.7
            lightR& = litR(shutterLitX, shutterLitY) * fog& \ 256 : lightG& = litG(shutterLitX, shutterLitY) * fog& \ 256 : lightB& = litB(shutterLitX, shutterLitY) * fog& \ 256
            texX = INT(shutterU * texSize) AND (texSize - 1)
            IF NOT glMode AND levelFlat THEN
                FOR y = drawStart TO drawEnd
                    pixels(y * RENDER_W + x) = ShadeRGB~&(texture(texX, INT(texPos) AND (texSize - 1), T_SHUTTER), lightR&, lightG&, lightB&)
                    texPos = texPos + texStep
                NEXT
                ' Lifted above your eyes, you see its underside: from its front
                ' edge down to its back edge (further away, so nearer the
                ' middle of the view), darker
                IF shutterOpen > 0.5 AND shutterBack > shutterDist THEN
                    underEnd = INT(RENDER_H / 2 + viewH / shutterBack * (0.5 - shutterOpen))
                    IF underEnd > RENDER_H - 1 THEN underEnd = RENDER_H - 1
                    FOR y = drawEnd + 1 TO underEnd
                        IF y >= 0 THEN pixels(y * RENDER_W + x) = ShadeRGB~&(texture(texX, texSize - 2, T_SHUTTER), lightR& \ 2, lightG& \ 2, lightB& \ 2)
                    NEXT
                END IF
            END IF
            IF shutterOpen < 0.5 THEN zBuffer(x) = shutterDist ' Mostly down: things behind it stay hidden
        END IF
    NEXT x
