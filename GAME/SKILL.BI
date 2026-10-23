''
' NEON-CASTER - GAME/SKILL.BI
' =============================================================================
' DIFFICULTY (SETTINGS > GAMEPLAY, or GAME): EASY is the game as it always
' was; NORMAL, HARD and NIGHTMARE make the machines tougher and the
' pickups fewer - and NIGHTMARE starts you with every gun, full, in a
' sector with more machines, short of ammo, where everything hurts more.
' GAME/SKILL.BM does it; a sector takes it as it loads.
'
CONST SKILL_EASY = 0, SKILL_NORMAL = 1, SKILL_HARD = 2, SKILL_NIGHTMARE = 3
DIM SHARED demoSkill AS INTEGER ' (the difficulty a demo plays at: its own, recorded - a demo with none was made on EASY)
