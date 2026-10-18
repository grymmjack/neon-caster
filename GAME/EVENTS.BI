''
' NEON-CASTER - GAME/EVENTS.BI
' =============================================================================
' Event rooms (chapter 3): ambushes, survival rounds, traps, galleries,
' nests, closets, hoards, plates, lasers, cutters, blackouts, death pits.
'

' --- Event rooms: a part of the map (x0, y0) to (x1, y1) where something
' happens when you walk in - each a line of the level's file (chapter 22).
' EV_ = the kinds:
'   EV_AMBUSH   the doors slam shut and lock; evA monsters teleport in (of
'               type evB, or a mix if 0), a few at a time. Kill them all
'               and the doors open - and there's a reward (evReward, a
'               pickup kind, appears in the middle)
'   EV_SURVIVE  locked in for evA seconds, monsters arriving every evB
'               frames; hold out and the doors open, and the reward
'   EV_TRAP     the floor is electrified: on for evA frames, off for evB
'               (cross on the off beat). No reward - it's just there.
'   EV_GALLERY  a mini game: break every decoration in the room within evA
'               seconds for the reward
'   EV_NEST     spawners (decoration S) in the room send out a monster of
'               type evA every evB frames while you're near; break them
'               all for the reward
' evState: 0 waiting for you, 1 going on, 2 won, 3 lost. evTimer counts
' down its frames; evCount is how many monsters it's sent; evNext the
' frames to the next. monsterEv(i) is the event that sent monster i (0
' if it was always there). A locked door (doorLock) stays shut - Space
' won't open it, nor will monsters.
CONST MAX_EVENTS = 16
CONST EV_AMBUSH = 1, EV_SURVIVE = 2, EV_TRAP = 3, EV_GALLERY = 4, EV_NEST = 5
' ...and more (see chapter 22's Part 4 for what a and b are for each):
'   EV_CLOSET   walk in and the secret walls (%) round the room slide away,
'               and what's been waiting behind them comes out
'   EV_HOARD    a treasure room, sealed; the thief bots (T) run to its door
'               with what they steal, and when the last thief dies it opens -
'               but a thief that gets home with your things slips inside,
'               and it's locked for good (evState 3)
'   EV_PLATE    a pressure plate: step on it (or a monster does) - click,
'               beep, and a moment later an explosion lands on it
'   EV_LASER    a laser beam across a corridor, on for a frames, off for b
'   EV_CUTTER   a laser sweeping back and forth across the room
'   EV_BLACKOUT a power failure: the lights die for a seconds, and b
'               monsters come out of the dark
CONST EV_CLOSET = 6, EV_HOARD = 7, EV_PLATE = 8, EV_LASER = 9, EV_CUTTER = 10, EV_BLACKOUT = 11
'   EV_FIRETRAP the same as EV_TRAP, but a burner grate: flames, not sparks
CONST EV_FIRETRAP = 12
'   EV_DEATHPIT a floor that kills: land on its lowest floor (from any height)
'               and you die - a pit with a bottom you can see, an alley under
'               the rooftops. Higher floors in its room are safe.
CONST EV_DEATHPIT = 13, EV_KINDS = 13
' A trap gives itself away: its floor is its own picture (MakeTrapTex), it
' smokes or crackles for TRAP_WARN frames before it goes live, and while
' live it blazes or arcs, lights the room and roars or buzzes (TrapFx)
CONST TRAP_WARN = 30
DIM SHARED doorLockEv(MAP_SIZE, MAP_SIZE) AS INTEGER, evMiss(MAX_EVENTS) AS INTEGER ' (evMiss: an ambush's spawns that found no room, in a row) ' (which event room sealed a door, doorLock -1: only it lets it go)
DIM SHARED evGlow(MAX_EVENTS) AS SINGLE, evHum&(MAX_EVENTS) ' (how lit a trap is now, 0 to 1; its own looping copy of its sound)
DIM SHARED closetCell(MAP_SIZE, MAP_SIZE) AS INTEGER ' (a closet's secret wall: which closet event it belongs to)
DIM SHARED thiefDist(MAP_SIZE, MAP_SIZE) AS INTEGER ' (how many steps from a hoard's door: the thieves' way home - BuildThiefWay)
DIM SHARED blackoutTimer AS LONG, glMeshVersion AS LONG, glMeshDone AS LONG
DIM SHARED numEvents AS INTEGER, evType(MAX_EVENTS) AS INTEGER
' A lockdown you've got out of (a teleporter, a glitch): evAway counts the
' frames you've been out of its room; a second, and it lifts - evPaused, so
' walking back in carries on where it was (its monsters, its count, its
' clock) rather than starting again
DIM SHARED evAway(MAX_EVENTS) AS INTEGER, evPaused(MAX_EVENTS) AS INTEGER
DIM SHARED evX0(MAX_EVENTS) AS INTEGER, evY0(MAX_EVENTS) AS INTEGER, evX1(MAX_EVENTS) AS INTEGER, evY1(MAX_EVENTS) AS INTEGER
DIM SHARED evA(MAX_EVENTS) AS INTEGER, evB(MAX_EVENTS) AS INTEGER, evReward(MAX_EVENTS) AS INTEGER
DIM SHARED evState(MAX_EVENTS) AS INTEGER, evTimer(MAX_EVENTS) AS LONG, evCount(MAX_EVENTS) AS INTEGER, evNext(MAX_EVENTS) AS INTEGER
DIM SHARED doorLock(MAP_SIZE, MAP_SIZE) AS INTEGER
