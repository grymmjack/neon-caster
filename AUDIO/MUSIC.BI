''
' NEON-CASTER - AUDIO/MUSIC.BI
' =============================================================================
' Music: the title menu's, each level's and the network's.
'

' Music: one looping track for the title menu and one per level, and the
' one playing now. (Dark techno, made with soundmon's AI music mode.)
DIM SHARED menuMusic&, levelMusic&(NUM_LEVELS), nowPlaying& ' (your own sectors borrow these: SectorMusic&)
DIM SHARED ownMusic&, ownMusicFile$ ' (a set's or a showcase's own track, opened when it's wanted: SectorMusic&)
menuMusic& = LoadMusic&("menu.ogg")
FOR k = 1 TO NUM_LEVELS : levelMusic&(k) = LoadMusic&("level" + LTRIM$(STR$(k)) + ".ogg") : NEXT
cyberMusic& = LoadMusic&("cyber.flac") ' (the network's own)
