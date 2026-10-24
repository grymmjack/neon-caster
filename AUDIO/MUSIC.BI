''
' NEON-CASTER - AUDIO/MUSIC.BI
' =============================================================================
' Music: the title menu's, each level's and the network's.
'

' Music: one looping track for the title menu and one per level, and the
' one playing now. (Dark techno, made with soundmon's AI music mode.)
DIM SHARED menuMusic&, levelMusic&(NUM_LEVELS), nowPlaying& ' (your own sectors borrow these: SectorMusic&)
DIM SHARED ownMusic&, ownMusicFile$ ' (a set's or a showcase's own track, opened when it's wanted: SectorMusic&)
CONST INTRO_TAIL = 0.5 ' (seconds of the loop on the end of an intro file: arrange.py's INTRO_TAIL)
DIM SHARED menuIntro&, musIntro& ' (the title menu's intro, music/menu-intro.ogg: played once as the menu starts, then the loop - the intro playing now)
menuMusic& = LoadMusic&("menu.ogg")
menuIntro& = LoadMusic&("menu-intro.ogg")
FOR k = 1 TO NUM_LEVELS : levelMusic&(k) = LoadMusic&("level" + LTRIM$(STR$(k)) + ".ogg") : NEXT
cyberMusic& = LoadMusic&("cyber.ogg") ' (the network's own)
