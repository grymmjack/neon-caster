''
' NEON-CASTER - WORLD/DOORS.BI
' =============================================================================
' Doors (chapter 2): how open each one is, which way it's going, which
' keycard it wants, and the kinds of door.
'

' Doors: how far open (0 shut .. 1 open), which keycard opens it (0 any,
' 1 red, 2 blue, 3 yellow), and what kind it is (DOOR_ constants below)
DIM SHARED doorOpen(MAP_SIZE, MAP_SIZE) AS SINGLE
' ...which way it's going (1 opening, -1 shutting, 0 still), and how many
' frames more it stays open before shutting itself (chapter 11)
DIM SHARED doorMove(MAP_SIZE, MAP_SIZE) AS INTEGER, doorWait(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorKey(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED doorType(MAP_SIZE, MAP_SIZE) AS INTEGER
' DOOR_ = the kinds of door, the numbers kept in doorType(x, y)
CONST DOOR_SLIDE = 0, DOOR_SHUTTER = 1, DOOR_SPLIT = 2, DOOR_EXIT = 3
CONST DOOR_LIP = 0.15 ' How much of an open door still shows (DoorShown, chapter 11)
' A door is a slab DOOR_THICK thick across the middle of its doorway
' (DoorRay, chapter 15), running in a track in the floor and ceiling
' TRACK_HALF either side of its middle line
CONST DOOR_THICK = 0.12, TRACK_HALF = 0.09
