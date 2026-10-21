''
' NEON-CASTER - GAME/JUMPPADS.BI
' =============================================================================
' Jump pads (a thing, jumppad): step on one and you're SHOT through the air -
' along its DIR (degrees, 0 east, 90 south - as tp's), up at its ANGLE
' (degrees over the floor), at its POWER (hundredths of a cell a frame) -
' then the sector's gravity has you, a cannonball's arc: you can look and
' shoot, not walk, till you land - and a long drop hurts as any fall does (water, a jetpack fired on the way down soften it). Monsters too. How far it throws you,
' on the level: POWER^2 x sin(2 x ANGLE) / (100 x gravity) cells, gravity
' the sector's percent (FALL_G is 0.01 a frame) - POWER 30, ANGLE 45, at
' 100%: 9 cells. A jump-pad console (a thing, padpc) sets its pad's three
' (JumpPadRun) - from a note's numbers, worked out.
'
DIM SHARED jpDir(MAX_DECO) AS SINGLE, jpAng(MAX_DECO) AS SINGLE, jpPow(MAX_DECO) AS SINGLE ' (a pad's: degrees, degrees, hundredths)
DIM SHARED monPadAir(MAX_MON) AS INTEGER, monPadLast(MAX_MON) AS INTEGER, monPadZ(MAX_MON) AS SINGLE, monPadVZ(MAX_MON) AS SINGLE, monPadVX(MAX_MON) AS SINGLE, monPadVY(MAX_MON) AS SINGLE ' (a monster shot from a pad: in the air, its height and speeds - drawn and shooting from up there: monFly)
DIM SHARED padAir AS INTEGER, jpLast AS INTEGER ' (shot from a pad, in the air now; the pad you're standing on - not again till you've stepped off it)
DIM SHARED jpField AS INTEGER, jpVal(3) AS SINGLE, jpOK AS INTEGER ' (the console's screen: which of DIR, ANGLE, POWER; their values; set or not)
