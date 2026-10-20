''
' NEON-CASTER - MENU/CONSOLE.BI
' =============================================================================
' The console (`): its log, its history, and the commands waiting.
'

' --- The console (` opens it, like Quake's; chapter 21): what's been
' printed (conLog$, the last CON_LOG lines - conBack of them scrolled back,
' PgUp and the wheel; conTall: F11 has it fill the screen), the line being typed, the
' lines typed before (conHist$, for Up and Down), and the commands waiting
' to run (conQ$, from the command line or exec - one more each frame until
' a "wait" holds them back for conWait frames). conLogFile$: a file every
' printed line also goes to (logfile). noSaveSettings: settings changed
' from the command line are for this run only.
CONST CON_LOG = 1000, CON_QUEUE = 256, CON_HIST = 32
DIM SHARED conLog$(CON_LOG), conLogN AS LONG, conBack AS LONG, conTall AS INTEGER, conLogFile$, noSaveSettings AS INTEGER
DIM SHARED conHist$(CON_HIST), conHistN AS INTEGER
DIM SHARED conQ$(CON_QUEUE), conQHead AS INTEGER, conQTail AS INTEGER, conWait AS LONG
' Aliases (alias NAME "commands; ..."): a name for a line of commands -
' $1 to $9 the words after it, $* all of them - and how deep in one
' another we are (an alias that runs itself stops at ALIAS_DEPTH)
CONST MAX_ALIAS = 64, ALIAS_DEPTH = 8
DIM SHARED aliasName$(MAX_ALIAS), aliasCmd$(MAX_ALIAS), numAlias AS INTEGER, aliasDepth AS INTEGER
' (a screenshot: glShotReq 1 asks SUB _GL for one, 2 says it's in glShotMem,
' glShotW x glShotH; shotFile$ is where it goes)
DIM SHARED glShotReq AS INTEGER, glShotMem AS _MEM, glShotW AS LONG, glShotH AS LONG, shotFile$


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED am, conB$, conC$, conLevelChanged
