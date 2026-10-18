''
' NEON-CASTER - DEMO/DEMO.BI
' =============================================================================
' Demos: every frame's keys, kept or played back.
'

' Demos (record, playdemo - the console's; DemoInput): each frame's keys,
' written down as they're played - or read back in their place
DIM SHARED demoRec AS INTEGER, demoPlay AS INTEGER, demoFH AS INTEGER, demoFrame AS LONG, demoName$, demoQuit AS INTEGER
DIM SHARED demoPend$, demoPendN AS LONG, demoLeft AS LONG, demoBack$, demoFovQ AS LONG, demoLook AS INTEGER
DIM SHARED conSession AS INTEGER, conReplay AS INTEGER, conTick AS LONG, conRTick AS LONG, conRKey AS LONG, conRType AS INTEGER, conRLine$ ' (the console in a demo: its keys, typed again at their ticks)
DIM SHARED demoRecQuit AS INTEGER, demoTrace AS INTEGER, demoDebug AS INTEGER, demoBad AS LONG, demoBadAt AS LONG, demoInject AS INTEGER, demoKind$, demoRes AS LONG
DIM SHARED inBits AS LONG, inTU AS LONG, inPU AS LONG, inWheel AS INTEGER, lookAim AS INTEGER, lvFrame AS LONG, deadTicks AS LONG
CONST DB_FWD = 1, DB_BACK = 2, DB_LEFT = 4, DB_RIGHT = 8, DB_RUN = 16, DB_FIRE = 32, DB_USE = 64, DB_AIM = 128, DB_KICK = 256
CONST DB_NIGHT = 512, DB_MAP = 1024, DB_UP = 2048, DB_DOWN = 4096, DB_CHEATK = 8192, DB_CHEATG = 16384, DB_GUN = 32768 ' (DB_GUN: times 1-4, the gun key held)
CONST DEMO_KEYS = "WSADRFUZKNMECkg" ' (in a demo file each bit is its letter: W forward, S back, A and D strafe, R run, F fire, U use, Z aim, K kick, N night vision, M map, E and C fly up and down, k and g the cheat keys)
CONST DEMO_TURN = 6.283185307179586# / 65536 ' (a demo's turns are in 65536ths of a circle, as DOOM's: whole numbers, so playing one back turns exactly as it was played)
demoDebug = LEN(ENVIRON$("NEON_DEMO_DEBUG")) > 0 : demoTrace = LEN(ENVIRON$("NEON_DEMO_TRACE")) > 0
CONST MAX_DEMOLIST = 200
DIM SHARED demoListN AS INTEGER, demoList$(MAX_DEMOLIST), demoListFile$(MAX_DEMOLIST), demoListInfo$(MAX_DEMOLIST), demoListPage AS INTEGER
DIM SHARED demoFromMenu AS INTEGER, demoMenuWant AS INTEGER, demoStarting AS INTEGER, demoTotal AS LONG, demoInfoNow$
DIM SHARED demoAttract AS INTEGER, demoAttractMenu AS INTEGER, attractPlayed$, attractQuit AS INTEGER, menuIdle AS LONG ' (attract mode: the title menu left alone ATTRACT_SECONDS - a demo plays, then the menu again; attractPlayed$: the ones that have, |name| each)
CONST ATTRACT_SECONDS = 15 ' (a demo started from DEMO REPLAYS: when it's over, back to that list)
