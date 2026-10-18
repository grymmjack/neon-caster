''
' NEON-CASTER - MENU/SPLASH.BI
' =============================================================================
' The splash screen's picture.
'

' The splash screen's picture, if there is one (neon-caster/splash.png)
DIM SHARED splashImg&
IF _FILEEXISTS(AssetPath$("splash.png")) THEN splashImg& = _LOADIMAGE(AssetPath$("splash.png"), 32)
