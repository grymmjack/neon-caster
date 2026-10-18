''
' NEON-CASTER - DEMO/BOT.BI
' =============================================================================
' The autopilot (bot): what it knows and how a person presses keys.
'

' The autopilot (bot, the console's - BotThink): it plays, and a demo records it
CONST BOT_FAR = 32000
CONST BOT_MODES = "nowhere to go,to the exit,a keycard,a medkit,exploring,ammo,a data station,data cores,picking things up,after a monster"
DIM SHARED botOn AS INTEGER, botDist(MAP_SIZE, MAP_SIZE) AS INTEGER, botBlock(MAP_SIZE, MAP_SIZE) AS LONG, botSeen(MAP_SIZE, MAP_SIZE) AS INTEGER
DIM SHARED botQ(MAP_SIZE * MAP_SIZE) AS LONG, botQT AS LONG, botTurn AS SINGLE, botMode AS INTEGER, botNX AS INTEGER, botNY AS INTEGER
DIM SHARED botDeaths AS INTEGER, botWasDead AS INTEGER, botLastX AS SINGLE, botLastY AS SINGLE, botCheckAt AS LONG, botStuck AS INTEGER
DIM SHARED botPathX(16) AS INTEGER, botPathY(16) AS INTEGER, botPathN AS INTEGER ' (the way ahead, up to 12 cells: it heads straight for the furthest it can walk to in a line)
DIM SHARED botHuman AS INTEGER, botSafe AS INTEGER, buddhaMode AS INTEGER, botTurnMax AS SINGLE, botTurnK AS SINGLE ' (bot human 0-100: how human it plays; bot safe: buddha - hurt, but never below 1 health)
DIM SHARED botKeyOn(5) AS INTEGER, botKeyOff(5) AS INTEGER, botDriftDir AS INTEGER, botDriftUntil AS LONG, botRunOn AS INTEGER, botRunAt AS LONG ' (how a person plays: measured from a real one)
DIM SHARED botKeyState(5) AS INTEGER, botKeyAt(5) AS LONG, botTurnPrev AS SINGLE, botTargetSeen AS LONG, botBackOn AS INTEGER, botStrafeOK AS INTEGER ' (the human filter: each key's state and since when; the turn last frame)
DIM SHARED botAimErr AS SINGLE, botReactAt AS LONG, botLastTarget AS INTEGER, botBurstOn AS INTEGER, botBurstAt AS LONG, botStrafeDir AS INTEGER, botStrafeAt AS LONG, botPauseUntil AS LONG
DIM SHARED botLookAt AS LONG, botLookDir AS INTEGER, botLookAmp AS SINGLE, botTurnLeft AS INTEGER, botTurnSgn AS INTEGER ' (a look round the room: when, which way first, how far; a turn carried through: frames left, which way)
botHuman = 60 : botSafe = 0 : botTurnMax = 0.12 : botTurnK = 0.5 : botStrafeDir = 1 ' (the autopilot: fairly human, and it doesn't die)
' How a person presses the keys - measured from five minutes of Rick
' playing sector 1 (a demo): the shortest a key's held (and let go) - the
' quickest tenth of his - in frames, for forward, back, the strafes, run,
' fire. A strafe's a quick dodge; fire's tapped (held 8, let go 5).
FOR bk = 0 TO 5 : botKeyOn(bk) = VAL(MID$("14 14 10 10 22 06", bk * 3 + 1, 2)) : botKeyOff(bk) = VAL(MID$("11 14 15 15 22 03", bk * 3 + 1, 2)) : NEXT
DIM SHARED botPitch AS SINGLE, botAimV0 AS SINGLE ' (with LOOK UP / DOWN: where it wants to look up or down; a new target's first look lands this far high or low)
DIM SHARED botAimE0 AS SINGLE, botTrig AS SINGLE ' (a new target: how far off the first flick lands - it overshoots and settles; how sure it wants to be before it shoots, this burst)
botTrig = 1.5
DIM SHARED botSawAt(MAX_MON) AS LONG ' (the frame the autopilot last saw each monster - a room's cleared of what it's seen)
DIM SHARED botIgnore(MAX_MON) AS LONG, botStallX AS SINGLE, botStallY AS SINGLE, botStallAt AS LONG, botStallN AS INTEGER, botAmmoAt AS LONG ' (the autopilot's: monsters it's leaving alone a while, and its watch on whether it's moving)


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED bcx, bcy, bmx, bmy, botBest, botBestAt, botEX, botEY, bpass
