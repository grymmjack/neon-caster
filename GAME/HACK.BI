''
' NEON-CASTER - GAME/HACK.BI
' =============================================================================
' Turret control panels (; on the map) and the word hack that switches
' the turrets near one off.
'

' --- A turret control panel: a wall with a screen (; - worldMap 10). Space
' on it starts the hack (HackRun): a screen of junk with words hidden in
' it, one of them the password. Pick a word and it says how many of its
' letters are the password's, in the same places; HACK_TRIES wrong and the
' panel locks for good - and every turret near it comes for you. Get it,
' and every turret within HACK_REACH cells of the panel goes off for good.
' tcState: 0 ready, 1 switched its turrets off (OFFLINE), 2 locked out.
CONST MAX_TCTRL = 16, HACK_TRIES = 4, HACK_REACH = 12
DIM SHARED numTCtrl AS INTEGER, tcX(MAX_TCTRL) AS INTEGER, tcY(MAX_TCTRL) AS INTEGER, tcState(MAX_TCTRL) AS INTEGER
' The hack's screen: HACK_ROWS rows of HACK_COLS characters in each of two
' columns - hackG$, all of them in reading order (down the left column,
' then the right) - with HACK_WORDS words in it (where each starts, and
' whether it's been ruled out: a dud gone), the password one of them
CONST HACK_ROWS = 16, HACK_COLS = 12, HACK_WORDS = 12, HACK_LEN = 6
DIM SHARED hackG$, hackWordAt(HACK_WORDS) AS INTEGER, hackWordGone(HACK_WORDS) AS INTEGER, hackPass AS INTEGER
DIM SHARED hackTries AS INTEGER, hackLog$(10), hackWon AS INTEGER, hackLeft AS INTEGER, hackTc AS INTEGER
DIM SHARED hackUsed$ ' (the bracket pairs already used: each one's start, as "|n|")
