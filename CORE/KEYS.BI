''
' NEON-CASTER - CORE/KEYS.BI
' =============================================================================
' Key bindings (BIND_) and the keyboard's scancodes (chapter 21).
'

' Each letter's scancode (where it is on the keyboard), a to z, as
' characters 32 on (CHR$(scancode + 32)), for KeyAt% (chapter 21)
CONST LETTER_SCANS = ">PN@2ABC7DEFRQ8903?46O1M5L"
DIM SHARED keyDevice AS INTEGER, keyTrusted AS INTEGER, keyScanAdd AS INTEGER
' BIND_ = a key binding's number: what each one does, its name in the
' settings file, its menu label, and its key to start with (a _KEYDOWN
' code: letters as lower case, 32 Space, 100306 left Ctrl, 16128 F5,
' 17152 F9, 9 Tab, 100304 left Shift)
CONST NUM_BINDS = 15
CONST BIND_FORWARD = 1, BIND_BACK = 2, BIND_LEFT = 3, BIND_RIGHT = 4
CONST BIND_USE = 5, BIND_FIRE = 6, BIND_QUICKSAVE = 7, BIND_QUICKLOAD = 8, BIND_MAP = 9, BIND_RUN = 10, BIND_KICK = 11, BIND_NIGHT = 12
CONST BIND_UP = 13, BIND_DOWN = 14 ' (flying - fly mode, the jetpack - up and down)
CONST BIND_ROCKETCAM = 15 ' (held: the rocket launcher fires, and you ride the rocket - let go, back to you)
CONST KEY_MOUSE = 300000 ' (a binding to a mouse button: KEY_MOUSE + 1 left, 2 right, 3 middle)
DIM SHARED keyBind&(NUM_BINDS), bindDefault&(NUM_BINDS), bindKey$(NUM_BINDS), bindLabel$(NUM_BINDS)
'          binding         file name        menu label      key
DefineBind BIND_FORWARD,   "key_forward",   "MOVE FORWARD", 119
DefineBind BIND_BACK,      "key_back",      "MOVE BACK",    115
DefineBind BIND_LEFT,      "key_left",      "STRAFE LEFT",  97
DefineBind BIND_RIGHT,     "key_right",     "STRAFE RIGHT", 100
DefineBind BIND_USE,       "key_use",       "OPEN / USE",   32
DefineBind BIND_FIRE,      "key_fire",      "FIRE",         100306
DefineBind BIND_QUICKSAVE, "key_quicksave", "QUICK SAVE",   16128
DefineBind BIND_QUICKLOAD, "key_quickload", "QUICK LOAD",   17152
DefineBind BIND_MAP, "key_map", "MAP", 9
DefineBind BIND_RUN,       "key_run",       "RUN (HOLD)",   100304
DefineBind BIND_KICK,      "key_kick",      "KICK",         102
DefineBind BIND_NIGHT,     "key_night",     "NIGHT VISION", 110
DefineBind BIND_UP,        "key_flyup",     "FLY / JET UP", 101
DefineBind BIND_DOWN,      "key_flydown",   "FLY / JET DOWN", 99
DefineBind BIND_ROCKETCAM, "key_rocketcam", "ROCKET CAM (HOLD)", KEY_MOUSE + 3
