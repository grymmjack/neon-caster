''
' NEON-CASTER - GAME/SECURE.BI
' =============================================================================
' Security, and what's left lying about: stronghold doors (kicked down),
' keypad doors and safes (a code - a note can tell it), desks and
' bookshelves to search, broken computers (a repair kit fixes one) and
' computers to hack, security cameras and the monitors that show them,
' notes, and the robot guard dog's bark. Their numbers come from the
' level's [doors], [things] and [notes] (LEVEL/THINGS.BM).
'

' doorLock's two more: a stronghold door (barred - kick it down) and a
' keypad door (its code opens it)
CONST LOCK_STRONG = 5, LOCK_KEYPAD = 6
' A stronghold door: doorHP kicks left of doorHPMax (its [doors] line);
' doorBroke: down for good (it never shuts again). A keypad door's code:
' doorCode (0 none)
DIM SHARED doorHP(MAP_SIZE, MAP_SIZE) AS INTEGER, doorHPMax(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorBroke(MAP_SIZE, MAP_SIZE) AS INTEGER, doorCode(MAP_SIZE, MAP_SIZE) AS LONG
' A decoration's own (its [things] line): a safe's code (decoCode), a
' computer's door or safe to open (decoTX, decoTY: -1 none), a camera's name
DIM SHARED decoCode(MAX_DECO) AS LONG, decoTX(MAX_DECO) AS INTEGER, decoTY(MAX_DECO) AS INTEGER, decoTag$(MAX_DECO)
' The keypad (KeypadRun): what was typed, whether it was right
DIM SHARED padIn$, padOK AS INTEGER, padTitle$
CONST PAD_DIGITS = 8 ' (a code's longest)
' What the word hack is for: a turret panel (0), or computer decoration hackPC
DIM SHARED hackPC AS INTEGER, hackTitle$
' How far a guard dog's bark carries (cells): every machine asleep that
' near wakes
CONST DOG_BARK = 10
' The note on screen (NoteRun): its words, its picture
DIM SHARED noteText$, notePic$
' A view from somewhere else (only what's drawn - where you are and what
' you do go on as ever): a security camera's (VIEW_CAM: camera decoration
' viewCam, from monitor viewMon - Space the next, a step back to you) or
' your rocket's (VIEW_ROCKET: bolt viewBolt - then where it burst, for
' viewHold frames). ViewAway puts the eye there round chapters 14-17;
' ViewBack puts it back (sv*: yours)
CONST VIEW_CAM = 1, VIEW_ROCKET = 2, VIEW_HOLD = 50
DIM SHARED rocketCamHeld AS INTEGER, rocketCamWas AS INTEGER ' (the ROCKET CAM control held this frame, and last: pressed, it fires - held, you ride the rocket)
DIM SHARED viewOn AS INTEGER, viewCam AS INTEGER, viewMon AS INTEGER, viewBolt AS INTEGER, viewHold AS INTEGER, lastBolt AS INTEGER
DIM SHARED viewX AS SINGLE, viewY AS SINGLE, viewZ AS SINGLE, viewA AS SINGLE, viewP AS SINGLE, viewAway AS INTEGER
DIM SHARED svPX AS SINGLE, svPY AS SINGLE, svDX AS SINGLE, svDY AS SINGLE, svPlX AS SINGLE, svPlY AS SINGLE, svEye AS SINGLE, svPitch AS SINGLE, svPZ AS SINGLE
