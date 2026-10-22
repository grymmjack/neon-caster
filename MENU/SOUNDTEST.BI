''
' NEON-CASTER - MENU/SOUNDTEST.BI
' =============================================================================
' SOUND TEST (SETTINGS > AUDIO): every sound, voice and track, by category,
' to hear one at a time - and flag, for later (saves/soundflags.txt).
'

' The list (neon-caster/sfx/soundtest.txt, written by sfx/soundtest.py):
' its categories, and each sound's file (under neon-caster/), name and
' category. SCR_ST1 + c - 1 is category c's screen; ST_PAGE to a page.
CONST ST_MAX = 600, ST_CATS = 16, ST_PAGE = 12
CONST SCR_SOUNDTEST = 31, SCR_ST1 = 32, MA_STPLAY = 18, MA_STPAGE = 19
DIM SHARED stCat$(ST_CATS), stCats, stFile$(ST_MAX), stName$(ST_MAX), stOf(ST_MAX), stFlagged(ST_MAX), stN, stLoaded
DIM SHARED menuOpenSound ' (the soundtest command: open the menu there)
' Your review of each sound (saves/soundreview.txt): 1 OK, 2 a note (stNote$); stTyping = the sound
' whose note is being typed (stTyped$ so far)
DIM SHARED stReview(ST_MAX), stNote$(ST_MAX), stTyping, stTyped$
DIM SHARED stPage, stSnd&, stNow, stMusicWas& ' (the page showing, the sound playing and which, the music it stopped)
