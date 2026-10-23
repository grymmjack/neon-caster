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

' The player (on a category's screen, where the title's logo was): what's
' playing, its length (stLen#, seconds) and where it is, a seek bar drawn as
' the whole sound's waveform, and over it a spectrum and a scope worked out
' from the samples under the play position each frame.
' stWave(): the sound's samples mixed to one channel (stFrames of them,
' stRate a second); stOvMin / stOvMax: the waveform squeezed to ST_OVW
' columns for the seek bar. stRe / stIm: the FFT's work (ST_FFT points, a
' Hann window, stRev the bit-reversed order), into ST_BANDS bars (stBand,
' falling slowly; stPeak and stPeakHold, the caps above them).
CONST ST_FFT = 2048, ST_BANDS = 48, ST_OVW = 648
CONST ST_BOX_Y0 = 2, ST_BOX_Y1 = 94, ST_BAR_Y1 = 92, ST_BAR_H = 66 ' (the visualizer's box; the bars stand on ST_BAR_Y1)
CONST ST_SEEK_X0 = 16, ST_SEEK_Y0 = 98, ST_SEEK_Y1 = 118 ' (the seek bar: ST_OVW across from ST_SEEK_X0)
REDIM SHARED stWave(0) AS SINGLE
DIM SHARED stFrames AS LONG, stRate AS DOUBLE, stLen AS DOUBLE, stLoops, stSeekDrag, stSeekX, stFFTReady
DIM SHARED stOvMin(ST_OVW - 1) AS SINGLE, stOvMax(ST_OVW - 1) AS SINGLE
DIM SHARED stRe(ST_FFT - 1) AS SINGLE, stIm(ST_FFT - 1) AS SINGLE, stHann(ST_FFT - 1) AS SINGLE, stRev(ST_FFT - 1) AS LONG
DIM SHARED stCs(ST_FFT \ 2 - 1) AS SINGLE, stSn(ST_FFT \ 2 - 1) AS SINGLE
' A track whose samples can't be read (an Ogg: the engine keeps it in pages) has them worked out
' beforehand, by music/viz.py, in NAME.viz: the seek bar's waveform, and stVizSp$ - stVizFPS a
' second, a byte a bar (stVizOn: it's being used)
DIM SHARED stVizOn, stVizFPS, stVizFrames AS LONG, stVizSp$
DIM SHARED stBand(ST_BANDS - 1) AS SINGLE, stPeak(ST_BANDS - 1) AS SINGLE, stPeakHold(ST_BANDS - 1)
