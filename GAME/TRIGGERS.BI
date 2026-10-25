''
' NEON-CASTER - GAME/TRIGGERS.BI
' =============================================================================
' Triggers ([triggers] in the level file): WHEN something happens, DO
' something.
'

' --- Triggers ([triggers] in the level file, chapter 19): WHEN, then a colon,
' then what happens - console commands (chapter 21), split by ;. WHEN is
'   enter X0 Y0 X1 Y1   you walk into that rectangle (a line: one cell wide)
'   use X Y             you press Space at that cell
'   shoot X Y           you shoot (or kick) the wall or the thing in that cell
'   clear X0 Y0 X1 Y1   every monster that started in it is dead
'   time SECONDS        that long into the level
'   hack X Y            the computer there hacked (GAME/SECURE.BM)
'   alarm [X Y]         that alarm switch - or any - sets the alarm off
'   calm                the alarm stops (AlarmCalm, GAME/ALARMS.BM)
' and "repeat" after it to go off every time (else just once).
' trig...: each one taken apart (TakeTrigger); trigWas: you were in it
' last frame (an enter goes off as you step in, not while you stand there).
CONST MAX_TRIGS = 96
DIM SHARED lvlNumTrigs AS INTEGER, lvlTrig$(MAX_TRIGS)
DIM SHARED numTrigs AS INTEGER, trigWhen$(MAX_TRIGS), trigX0(MAX_TRIGS) AS INTEGER, trigY0(MAX_TRIGS) AS INTEGER, trigX1(MAX_TRIGS) AS INTEGER, trigY1(MAX_TRIGS) AS INTEGER
DIM SHARED trigRepeat(MAX_TRIGS) AS INTEGER, trigDone(MAX_TRIGS) AS INTEGER, trigWas(MAX_TRIGS) AS INTEGER, trigCmd$(MAX_TRIGS)
DIM SHARED trigHit(MAX_TRIGS) AS INTEGER ' (a "shoot" trigger's cell was shot: it goes off the next time the triggers run - ShotAt)
DIM SHARED trigLoadN AS LONG ' (sectors loaded so far: a trigger that changes the sector stops the rest - they were the old one's)
