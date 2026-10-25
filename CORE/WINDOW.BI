''
' NEON-CASTER - CORE/WINDOW.BI
' =============================================================================
' Chapter 1: the window, the version, the error trap, and the dice.
'

'-----------------------------------------------------------------------------
' CHAPTER 1: A WINDOW
'-----------------------------------------------------------------------------
' An 800 x 600 window with 32-bit colour: every pixel holds a full RGB
' colour (an _UNSIGNED LONG, &HAARRGGBB), which we need for textures and
' for fading things into the dark.
'
' _MOUSEHIDE _DISABLE hides the pointer and captures it in the window. Moving
' the mouse then gives raw movement (_MOUSEMOVEMENTX, chapter 8) instead of
' a pointer that gets stuck at the edge of the screen - just what mouse look
' needs. _PRINTMODE _KEEPBACKGROUND prints text without a box behind it.
'
' _DISPLAYORDER says what goes on the window, bottom layer first: whatever
' OpenGL draws (_GLRENDER), then our screen (_SOFTWARE) on top of it. The
' game normally covers the whole screen, so the OpenGL layer is hidden. The
' OpenGL renderer (chapter 24) switches our screen off (GLScreenLayer) and
' draws it itself, over the 3D view.
'
' The OpenGL renderer's shaders (chapter 24) come from the GLSL library in
' QB64_GJ_LIB (github.com/grymmjack/QB64_GJ_LIB), a copy of it in lib/glsl:
' its .BI first in _ALL.BI, its .BM last in _ALL.BM.
' Steam achievements and stats (chapter 23) come from QB64_GJ_LIB's STEAM
' library, a copy of it in lib/steam (included next to GLSL) - with a stand-in (the "mock") that
' keeps them in a file when there's no Steam, so they work anywhere.
' Which release this is (the create-release skill bumps it: major.minor.patch)
CONST GAME_VERSION$ = "0.8.0"
_TITLE "NEON-CASTER " + GAME_VERSION$
ON ERROR GOTO GameError ' (a runtime error: logged, and the game carries on - chapter 21)
DIM SHARED mouseSettle AS INTEGER ' (frames the mouse can't turn you: just captured again after a screen of its own - the pointer's snap back isn't a turn)
DIM SHARED grSeed AS DOUBLE ' (the game's own dice: GRnd - where they've got to)
RANDOMIZE TIMER ' (RND's dice start somewhere new each time: without this, every game rolls the same numbers - the same loot, the same vending machines)
grSeed = 1 + INT(RND * 2147483645) ' (and the game's own, GRnd's, with them)
SCREEN _NEWIMAGE(800, 600, 32)
_MOUSEHIDE _DISABLE
_PRINTMODE _KEEPBACKGROUND
_DISPLAYORDER _GLRENDER , _SOFTWARE
