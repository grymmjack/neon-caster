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
'$INCLUDE:'./CORE/STATE.BI'
'$INCLUDE:'./CORE/WINDOW.BI'
'$INCLUDE:'./CORE/SETTINGS.BI'
'$INCLUDE:'./AUDIO/SOFTEN.BI'
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
'$INCLUDE:'./GAME/FLASHLIGHT.BI'
'$INCLUDE:'./GAME/SKILL.BI'
'$INCLUDE:'./GAME/DROIDS.BI'
'$INCLUDE:'./GAME/EVENTS.BI'
'$INCLUDE:'./GAME/SECRETS.BI'
'$INCLUDE:'./GAME/BLASTS.BI'
'$INCLUDE:'./GAME/ROCKETS.BI'
'$INCLUDE:'./GAME/BARRELS.BI'
'$INCLUDE:'./GAME/GUNS.BI'
'$INCLUDE:'./GAME/TERMINALS.BI'
'$INCLUDE:'./GAME/HACK.BI'
'$INCLUDE:'./GAME/SECURE.BI'
'$INCLUDE:'./GAME/ALARMS.BI'
'$INCLUDE:'./GAME/JUMPPADS.BI'
'$INCLUDE:'./GAME/NETWORK.BI'
'$INCLUDE:'./GAME/NEXUS.BI'
'$INCLUDE:'./GAME/PHOTO.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/PICTURES.BI'
'$INCLUDE:'./RENDER/MODELS.BI'

' GAME ------------------------------------------------------------------------
'$INCLUDE:'./GAME/MONTYPES.BI'
'$INCLUDE:'./GAME/TUNING.BI'
'$INCLUDE:'./GAME/TRIGGERS.BI'
'$INCLUDE:'./GAME/TELEPORTERS.BI'
'$INCLUDE:'./GAME/ARCADE.BI'

' LEVEL -----------------------------------------------------------------------
'$INCLUDE:'./LEVEL/LEVELS.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/LIGHT.BI'

' LEVEL -----------------------------------------------------------------------
'$INCLUDE:'./LEVEL/LEVELFILE.BI'
'$INCLUDE:'./LEVEL/PIECES.BI'
'$INCLUDE:'./LEVEL/THINGS.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/HUD.BI'
'$INCLUDE:'./RENDER/SPRITES.BI'
'$INCLUDE:'./RENDER/VIEW.BI'

' GL --------------------------------------------------------------------------
'$INCLUDE:'./GL/OPENGL.BI'
'$INCLUDE:'./GL/TEXTART.BI'

' RENDER ----------------------------------------------------------------------
'$INCLUDE:'./RENDER/PARTICLES.BI'

' GL --------------------------------------------------------------------------
'$INCLUDE:'./GL/EXTRAS.BI'

' AUDIO -----------------------------------------------------------------------
'$INCLUDE:'./AUDIO/SOUND.BI'
'$INCLUDE:'./AUDIO/MUSIC.BI'

' MENU ------------------------------------------------------------------------
'$INCLUDE:'./MENU/MENU.BI'
'$INCLUDE:'./MENU/FOLDERS.BI'
'$INCLUDE:'./MENU/CONSOLE.BI'
'$INCLUDE:'./MENU/SAVES.BI'
'$INCLUDE:'./MENU/SPLASH.BI'
'$INCLUDE:'./MENU/SOUNDTEST.BI'
'$INCLUDE:'./EDITOR/ARRANGER.BI'

' EDITOR ----------------------------------------------------------------------
'$INCLUDE:'./EDITOR/MONEDIT.BI'
'$INCLUDE:'./EDITOR/EDITOR.BI'
'$INCLUDE:'./EDITOR/COLOURS.BI'
'$INCLUDE:'./EDITOR/PRESETS.BI'
'$INCLUDE:'./EDITOR/NEWPICS.BI'
'$INCLUDE:'./EDITOR/PAINTER.BI'
'$INCLUDE:'./EDITOR/HUDEDIT.BI'
'$INCLUDE:'./EDITOR/SESSION.BI'

' DEMO ------------------------------------------------------------------------
'$INCLUDE:'./DEMO/DEMO.BI'
'$INCLUDE:'./DEMO/BOT.BI'

' ACH -------------------------------------------------------------------------
'$INCLUDE:'./ACH/ACHIEVEMENTS.BI'
'$INCLUDE:'./ACH/RECORDS.BI'
