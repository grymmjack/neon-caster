' NEON INVADERS - a program a computer in NEON-CASTER runs.
'
' A level starts it with a trigger: use X Y : program invaders - Space at
' that computer, and the game builds this file with qb64pe (the first time
' only: neon-caster/saves/programs/ keeps it), runs it, and waits. How it
' ends is the answer: SYSTEM 1 - you won, and the computer pays out;
' SYSTEM 0 (or Esc) - you didn't. Copy it, change it, make your own: any
' QB64PE program in this folder is a program a computer can run.
'
' Left / Right (or A / D) move, Space or Up fires, Esc gives up. Shoot all
' 24 invaders before they land - three hits and you're out.

_TITLE "NEON INVADERS"
SCREEN _NEWIMAGE(800, 600, 32)
_SCREENMOVE _MIDDLE
RANDOMIZE TIMER

CONST COLS = 8, ROWS = 3
DIM alive(COLS, ROWS) AS INTEGER
DIM shotX(3) AS SINGLE, shotY(3) AS SINGLE, shotOn(3) AS INTEGER ' (yours: up to three at once)
DIM bombX(5) AS SINGLE, bombY(5) AS SINGLE, bombOn(5) AS INTEGER ' (theirs)
FOR c = 1 TO COLS : FOR r = 1 TO ROWS : alive(c, r) = -1 : NEXT : NEXT
swarmX = 120 : top = 90 : dir = 1 : speed = 0.6 : shipX = 400 : lives = 3 : hurt = 0 : remaining = COLS * ROWS
fireWait = 0 : result = 0 : frame = 0

DO
    _LIMIT 60
    frame = frame + 1
    k$ = INKEY$ : IF k$ = CHR$(27) THEN result = 0 : EXIT DO
    IF _KEYDOWN(19200) OR _KEYDOWN(97) OR _KEYDOWN(65) THEN shipX = shipX - 6
    IF _KEYDOWN(19712) OR _KEYDOWN(100) OR _KEYDOWN(68) THEN shipX = shipX + 6
    IF shipX < 40 THEN shipX = 40
    IF shipX > 760 THEN shipX = 760
    IF fireWait > 0 THEN fireWait = fireWait - 1
    IF (_KEYDOWN(32) OR _KEYDOWN(18432)) AND fireWait = 0 THEN
        FOR i = 1 TO 3
            IF NOT shotOn(i) THEN shotOn(i) = -1 : shotX(i) = shipX : shotY(i) = 540 : fireWait = 14 : EXIT FOR
        NEXT
    END IF

    ' The invaders: across, and down a step at each edge - faster as fewer are left
    minX = 9999 : maxX = -1 : maxY = -1
    FOR c = 1 TO COLS : FOR r = 1 TO ROWS
        IF alive(c, r) THEN
            x = swarmX + (c - 1) * 64 : y = top + (r - 1) * 50
            IF x < minX THEN minX = x
            IF x > maxX THEN maxX = x
            IF y > maxY THEN maxY = y
        END IF
    NEXT : NEXT
    speed = 0.6 + (COLS * ROWS - remaining) * 0.09
    swarmX = swarmX + dir * speed
    IF (dir > 0 AND maxX > 740) OR (dir < 0 AND minX < 40) THEN dir = -dir : top = top + 18
    IF maxY > 500 THEN result = 0 : EXIT DO ' (they've landed)

    ' Their bombs: now and then, from one of them
    IF RND < 0.025 + (COLS * ROWS - remaining) * 0.002 THEN
        c = INT(RND * COLS) + 1
        FOR r = ROWS TO 1 STEP -1
            IF alive(c, r) THEN
                FOR i = 1 TO 5
                    IF NOT bombOn(i) THEN bombOn(i) = -1 : bombX(i) = swarmX + (c - 1) * 64 : bombY(i) = top + (r - 1) * 50 + 16 : EXIT FOR
                NEXT
                EXIT FOR
            END IF
        NEXT
    END IF

    ' Your shots, up: into an invader?
    FOR i = 1 TO 3
        IF shotOn(i) THEN
            shotY(i) = shotY(i) - 10
            IF shotY(i) < 40 THEN shotOn(i) = 0
            FOR c = 1 TO COLS : FOR r = 1 TO ROWS
                IF alive(c, r) AND shotOn(i) THEN
                    x = swarmX + (c - 1) * 64 : y = top + (r - 1) * 50
                    IF ABS(shotX(i) - x) < 20 AND ABS(shotY(i) - y) < 16 THEN alive(c, r) = 0 : shotOn(i) = 0 : remaining = remaining - 1
                END IF
            NEXT : NEXT
        END IF
    NEXT
    IF remaining = 0 THEN result = 1 : EXIT DO

    ' Their bombs, down: into you?
    FOR i = 1 TO 5
        IF bombOn(i) THEN
            bombY(i) = bombY(i) + 5
            IF bombY(i) > 590 THEN bombOn(i) = 0
            IF ABS(bombX(i) - shipX) < 22 AND bombY(i) > 530 AND bombY(i) < 560 THEN
                bombOn(i) = 0 : lives = lives - 1 : hurt = 20
                IF lives = 0 THEN result = 0 : EXIT DO
            END IF
        END IF
    NEXT
    IF lives = 0 THEN EXIT DO
    IF hurt > 0 THEN hurt = hurt - 1

    ' Draw it: a dark screen with scanlines, the invaders in neon
    CLS , _RGB32(6, 2, 16)
    FOR y = 0 TO 599 STEP 3 : LINE (0, y)-(799, y), _RGB32(0, 0, 0) : NEXT
    LINE (0, 572)-(799, 574), _RGB32(255, 60, 200), BF
    FOR c = 1 TO COLS : FOR r = 1 TO ROWS
        IF alive(c, r) THEN
            x = swarmX + (c - 1) * 64 : y = top + (r - 1) * 50
            SELECT CASE r
                CASE 1 : col~& = _RGB32(255, 80, 200)
                CASE 2 : col~& = _RGB32(80, 230, 255)
                CASE ELSE : col~& = _RGB32(140, 255, 120)
            END SELECT
            legs = (frame \ 20) MOD 2 ' (two frames: legs in, legs out)
            LINE (x - 16, y - 8)-(x + 16, y + 6), col~&, BF
            LINE (x - 10, y - 14)-(x + 10, y - 8), col~&, BF
            LINE (x - 8, y - 4)-(x - 3, y), _RGB32(6, 2, 16), BF : LINE (x + 3, y - 4)-(x + 8, y), _RGB32(6, 2, 16), BF
            IF legs THEN
                LINE (x - 16, y + 6)-(x - 10, y + 14), col~&, BF : LINE (x + 10, y + 6)-(x + 16, y + 14), col~&, BF
            ELSE
                LINE (x - 10, y + 6)-(x - 4, y + 14), col~&, BF : LINE (x + 4, y + 6)-(x + 10, y + 14), col~&, BF
            END IF
        END IF
    NEXT : NEXT
    FOR i = 1 TO 3
        IF shotOn(i) THEN LINE (shotX(i) - 2, shotY(i) - 10)-(shotX(i) + 2, shotY(i)), _RGB32(255, 255, 160), BF
    NEXT
    FOR i = 1 TO 5
        IF bombOn(i) THEN LINE (bombX(i) - 3, bombY(i) - 8)-(bombX(i) + 3, bombY(i)), _RGB32(255, 70, 70), BF
    NEXT
    IF hurt = 0 OR (hurt \ 3) MOD 2 = 0 THEN
        LINE (shipX - 24, 548)-(shipX + 24, 562), _RGB32(80, 255, 140), BF
        LINE (shipX - 6, 536)-(shipX + 6, 548), _RGB32(80, 255, 140), BF
    END IF
    COLOR _RGB32(200, 190, 240), _RGB32(6, 2, 16)
    _PRINTSTRING (16, 12), "NEON INVADERS   LEFT" + STR$(remaining) + "   LIVES" + STR$(lives) + "   ARROWS MOVE - SPACE FIRES - ESC GIVES UP"
    _DISPLAY
LOOP

' The end: a moment to see it, then the answer for the computer
IF result = 1 THEN t$ = "YOU WIN!" ELSE t$ = "GAME OVER"
COLOR _RGB32(255, 240, 120), _RGB32(6, 2, 16)
_PRINTSTRING (400 - LEN(t$) * 4, 292), t$
_DISPLAY
_DELAY 1.5
SYSTEM result
