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

' THE PLAYLIST (SETTINGS > AUDIO > MUSIC, AUDIO/MUSIC.BM): in a sector its
' own track plays once, then the game's other tracks follow - IN ORDER, or
' SHUFFLE (at random, none of the last MUS_RECENT again); SECTOR'S OWN loops
' the one track, as the game always did. The pool is every music/*.ogg but
' the menu's, the network's and intros (MusicPoolMake). Music only: RND.
CONST MUS_OWN = 0, MUS_ORDER = 1, MUS_SHUFFLE = 2, MUS_POOL_MAX = 160, MUS_RECENT = 8
DIM SHARED musPool$(MUS_POOL_MAX), musPoolN, musPoolMade
DIM SHARED musList, musSector, musAt ' (the sector's music is on: MusicFrame moves on when a track ends - which sector it's for - the pool's track playing, 0 none)
DIM SHARED musTrack&, musFile$, musStartT# ' (the playlist's track playing - its file - when it started)
DIM SHARED mixMusic&, mixMusicFile$, musRecent$ ' (the playlist's track playing, held whole in memory; the last few played, |name|name|)
DIM SHARED musPre&, musPreFile$ ' (the next, loaded whole ahead at a quiet moment: MusicPreload)
menuMusic& = LoadMusic&("menu.ogg")
menuIntro& = LoadMusic&("menu-intro.ogg")
FOR k = 1 TO NUM_LEVELS : levelMusic&(k) = LoadMusic&("level" + LTRIM$(STR$(k)) + ".ogg") : NEXT
cyberMusic& = LoadMusic&("cyber.ogg") ' (the network's own)
