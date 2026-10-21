''
' NEON-CASTER - GAME/NETWORK.BI
' =============================================================================
' Data stations (@) and the network: jacking in.
'

' --- Data stations (@) and the network (chapter 19). A station is a wall
' with a socket; Space at it "jacks you in": the level becomes the
' network - every wall, floor and ceiling a neon grid (MakeCyberTex, the
' real pictures kept in texBak), the light even, the monsters and things
' of the real world left behind - and you have cyberTime frames to grab
' cyberNeed data cores (IT_CORE) while ICE (MT_ICE) hunts you. Get them
' all and the station opens its sealed doors (! on the map: doorLock 2);
' run out of time and you're thrown out, to try again.
CONST MAX_STATIONS = 8, CYBER_SECONDS = 50
DIM SHARED numStations AS INTEGER, stationX(MAX_STATIONS) AS INTEGER, stationY(MAX_STATIONS) AS INTEGER, stationDone(MAX_STATIONS) AS INTEGER
DIM SHARED cyberOn AS INTEGER, cyberStation AS INTEGER, cyberTime AS LONG, cyberNeed AS INTEGER, cyberGot AS INTEGER
DIM SHARED cyberMonStart AS INTEGER, cyberItemStart AS INTEGER, glRetexVersion AS LONG, glRetexDone AS LONG
DIM SHARED sndJackIn&, sndJackOut&, sndCore&, cyberMusic&, sndTeleport&


' The network's other modules (NetSetup - placed by its own dice, NRnd, so
' the ICE there as ever is placed just as before): ICE of four kinds -
' hunters (as ever), sentinels (still - they fire), tracers (quick - while
' one sees you, the TRACE climbs fast), black ICE (slow, tough, and it
' hits hard) - and firewalls, fences of laser across the ways through,
' on and off (a flicker first): through one lit, you're burnt and lose
' time. ICE seeing you raises the TRACE; full, NEXUS sends more hunters.
' How many of each: by the sector's place in its set of ten (d, 1-10)
CONST ICE_HUNTER = 0, ICE_SENTRY = 1, ICE_TRACER = 2, ICE_BLACK = 3
CONST MAX_FENCES = 8, FENCE_CYCLE = 180, FENCE_ON = 80, FENCE_WARN = 24, MAX_NETFAR = 32
DIM SHARED iceKind(MAX_MON) AS INTEGER, netSeed AS DOUBLE, traceAmt AS SINGLE
DIM SHARED numFences AS INTEGER, fenceX0(MAX_FENCES) AS INTEGER, fenceY0(MAX_FENCES) AS INTEGER, fenceX1(MAX_FENCES) AS INTEGER, fenceY1(MAX_FENCES) AS INTEGER, fencePh(MAX_FENCES) AS INTEGER
DIM SHARED numNetFar AS INTEGER, netFarX(MAX_NETFAR) AS INTEGER, netFarY(MAX_NETFAR) AS INTEGER ' (far cells: where traced-in hunters come from)

' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED cyberBackDX, cyberBackDY, cyberBackX, cyberBackY, cyberSlot, cyberSlotKind, cyberSlotX, cyberSlotY
