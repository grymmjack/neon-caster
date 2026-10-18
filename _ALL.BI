''
' NEON-CASTER - _ALL.BI
' =============================================================================
' Every declaration - the CONSTs, the DIM SHARED arrays, the tables - and the
' start-up that goes with them, in the order they're needed: a name must be
' declared before anything uses it. neon-caster.bas includes this first.
'

' LIBRARIES ------------------------------------------------------------------
'$INCLUDE:'./lib/glsl/GLSL.BI'
'$INCLUDE:'./lib/steam/STEAM.BI'


' CORE ------------------------------------------------------------------------
'$INCLUDE:'./CORE/WINDOW.BI'
'$INCLUDE:'./CORE/SETTINGS.BI'
'$INCLUDE:'./CORE/KEYS.BI'

' WORLD -----------------------------------------------------------------------
'$INCLUDE:'./WORLD/MAP.BI'
'$INCLUDE:'./WORLD/DOORS.BI'
'$INCLUDE:'./WORLD/GLASS.BI'
'$INCLUDE:'./WORLD/HEIGHTS.BI'
'$INCLUDE:'./WORLD/LIQUIDS.BI'
'$INCLUDE:'./WORLD/LIFTS.BI'

' GAME ------------------------------------------------------------------------
'$INCLUDE:'./GAME/MONSTERS.BI'
'$INCLUDE:'./GAME/PLAYER.BI'
'$INCLUDE:'./GAME/DECOS.BI'
'$INCLUDE:'./GAME/ITEMS.BI'
'$INCLUDE:'./GAME/DROIDS.BI'
'$INCLUDE:'./GAME/EVENTS.BI'
'$INCLUDE:'./GAME/SECRETS.BI'
'$INCLUDE:'./GAME/BLASTS.BI'
'$INCLUDE:'./GAME/GUNS.BI'
'$INCLUDE:'./GAME/TERMINALS.BI'
'$INCLUDE:'./GAME/NETWORK.BI'
'$INCLUDE:'./GAME/NEXUS.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/PICTURES.BI'

' GAME ------------------------------------------------------------------------
'$INCLUDE:'./GAME/MONTYPES.BI'
'$INCLUDE:'./GAME/TRIGGERS.BI'
'$INCLUDE:'./GAME/TELEPORTERS.BI'

' LEVEL -----------------------------------------------------------------------
'$INCLUDE:'./LEVEL/LEVELS.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/LIGHT.BI'

' LEVEL -----------------------------------------------------------------------
'$INCLUDE:'./LEVEL/LEVELFILE.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/HUD.BI'
'$INCLUDE:'./RENDER/SPRITES.BI'
'$INCLUDE:'./RENDER/VIEW.BI'

' GL --------------------------------------------------------------------------
'$INCLUDE:'./GL/OPENGL.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/PARTICLES.BI'

' GL --------------------------------------------------------------------------
'$INCLUDE:'./GL/EXTRAS.BI'

' AUDIO -----------------------------------------------------------------------
'$INCLUDE:'./AUDIO/SOUND.BI'
'$INCLUDE:'./AUDIO/MUSIC.BI'

' MENU ------------------------------------------------------------------------
'$INCLUDE:'./MENU/MENU.BI'
'$INCLUDE:'./MENU/CONSOLE.BI'
'$INCLUDE:'./MENU/SAVES.BI'
'$INCLUDE:'./MENU/SPLASH.BI'

' EDITOR ----------------------------------------------------------------------
'$INCLUDE:'./EDITOR/MONEDIT.BI'
'$INCLUDE:'./EDITOR/EDITOR.BI'

' DEMO ------------------------------------------------------------------------
'$INCLUDE:'./DEMO/DEMO.BI'
'$INCLUDE:'./DEMO/BOT.BI'

' ACH -------------------------------------------------------------------------
'$INCLUDE:'./ACH/ACHIEVEMENTS.BI'
'$INCLUDE:'./ACH/RECORDS.BI'
