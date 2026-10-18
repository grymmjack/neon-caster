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


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED cyberBackDX, cyberBackDY, cyberBackX, cyberBackY, cyberSlot, cyberSlotKind, cyberSlotX, cyberSlotY
