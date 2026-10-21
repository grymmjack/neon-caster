''
' NEON-CASTER - GAME/BARRELS.BI
' =============================================================================
' Barrels of a liquid - water, poison, slime, lava, acid (one map character,
' :, its liquid in [barrels]) - and treasure chests ([). A liquid barrel hit
' springs a leak and hisses (its fuse), then bursts: a blast, a pool of
' what was in it, and its own harm - poison gas, fire, acid, slime; water
' puts fires out. Fire near one cooks it off. A chest opens on Space.
'

' LEAK_FRAMES: how long a shot barrel leaks before it bursts; COOK_FRAMES:
' one set burning, before it goes; SPILL_R: how far its pool reaches (cells)
CONST LEAK_FRAMES = 40, COOK_FRAMES = 90, SPILL_R = 1.4, SPILL_DEPTH = 0.5 ' (in eighths: a film on the floor)
