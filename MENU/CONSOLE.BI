''
' NEON-CASTER - MENU/CONSOLE.BI
' =============================================================================
' The console (`): its log, its history, and the commands waiting.
'

' --- The console (` opens it, like Quake's; chapter 21): what's been
' printed (conLog$, the last CON_LOG lines), the line being typed, the
' lines typed before (conHist$, for Up and Down), and the commands waiting
' to run (conQ$, from the command line or exec - one more each frame until
' a "wait" holds them back for conWait frames). conLogFile$: a file every
' printed line also goes to (logfile). noSaveSettings: settings changed
' from the command line are for this run only.
CONST CON_LOG = 200, CON_QUEUE = 256, CON_HIST = 32
DIM SHARED conLog$(CON_LOG), conLogN AS LONG, conLogFile$, noSaveSettings AS INTEGER
DIM SHARED conHist$(CON_HIST), conHistN AS INTEGER
DIM SHARED conQ$(CON_QUEUE), conQHead AS INTEGER, conQTail AS INTEGER, conWait AS LONG
' (a screenshot: glShotReq 1 asks SUB _GL for one, 2 says it's in glShotMem,
' glShotW x glShotH; shotFile$ is where it goes)
DIM SHARED glShotReq AS INTEGER, glShotMem AS _MEM, glShotW AS LONG, glShotH AS LONG, shotFile$
