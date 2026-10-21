''
' NEON-CASTER - GAME/ALARMS.BI
' =============================================================================
' Alarms: switches on the walls (a thing, alarm) that set off the sector's
' alarm - a siren, the screen's edges flashing red, and every machine
' within ALARM_REACH woken and coming for you, for ALARM_FRAMES. Guards
' (MT_GUARD) run for the nearest switch when they see you; other walkers
' hunting you press one they pass; you can too. Security consoles (a
' thing, alarmpc) switch them on and off - and a hacked computer can.
'
CONST ALARM_FRAMES = 720, ALARM_REACH = 24, ALARM_PRESS = 1.25, GUARD_SEEK = 40
' alarmTimer: frames the alarm's sounding yet (0: quiet); alarmAt: the
' switch that set it off; numArmed: how many switches are on (and whole);
' alarmDist: steps from each open cell to the nearest switch that's on -
' the guards' way there (BuildAlarmWay; 30000: none)
DIM SHARED alarmTimer AS INTEGER, alarmAt AS INTEGER, numArmed AS INTEGER
DIM SHARED alarmDist(MAP_SIZE, MAP_SIZE) AS INTEGER
