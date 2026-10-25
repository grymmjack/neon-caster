''
' NEON-CASTER - CORE/SETTINGS.BI
' =============================================================================
' The settings table (chapter 21): SET_ numbers, and each setting's
' DefineSetting line - its name in settings.ini, its label in the menu, its
' kind of control, its range and where it starts.
'

' --- Settings, key bindings, the menu and music (all in chapter 21) ---
' SET_ = a setting's number. The settings live in one table, setting(), so
' the menu, the settings file and the game can all treat them the same way.
' Each is defined by one DefineSetting line below: the name it has in the
' settings file, its label in the menu, what kind of control it gets (a
' slider, an on/off toggle, or a "< choice >"), its lowest and highest
' value, how much one press changes it, and its value to start with.
CONST NUM_SETTINGS = 48
CONST RES_NATIVE = 1, RES_RETRO = 7
CONST SET_SFX = 1, SET_MUSIC = 2, SET_SPEECH = 3, SET_FOV = 4, SET_XSTYLE = 5
CONST SET_XCOLOR = 6, SET_XSIZE = 7, SET_BOB = 8, SET_SHAKE = 9, SET_MOUSE = 10
CONST SET_XALPHA = 11, SET_XFEEDBACK = 12, SET_HURTDIR = 13, SET_RENDERER = 14, SET_FPS = 15
CONST SET_BUMP = 16, SET_GLOW = 17, SET_NEON = 18, SET_SMOOTH = 19, SET_DYNLIGHT = 20, SET_SHADOWS = 21
CONST SET_PARTICLES = 22, SET_REFLECT = 23, SET_BLOOM = 24, SET_SCREENFX = 25, SET_HITFX = 26, SET_RES = 27, SET_LOOK = 28
CONST SET_SCANLINES = 29, SET_PHOSPHOR = 30, SET_SHAFTS = 31
CONST SET_SCANGAP = 32, SET_SCANTHICK = 33, SET_DISPLAY = 34, SET_AIMSENS = 35
CONST SET_SPATIAL = 36, SET_LIMITER = 37, SET_CUTSCENES = 38, SET_TAUNTS = 39, SET_ART = 40
CONST SET_MODE = 41, SET_TIMER = 42, SET_GAMMA = 43, SET_POISON = 44, SET_SOFTEN = 45, SET_SKILL = 46, SET_CHARGE = 47, SET_WINSIZE = 48
' MODE: a whole look at once (ModeWants) - or CUSTOM, when the settings
' don't all match one
CONST MODE_CUSTOM = 0, MODE_OLDSCHOOL = 1, MODE_90S = 2, MODE_NEWSCHOOL = 3
DIM SHARED setting(NUM_SETTINGS), setDefault(NUM_SETTINGS), setMin(NUM_SETTINGS), setMax(NUM_SETTINGS)
DIM SHARED glSet(NUM_SETTINGS, 1) ' (OpenGL's copy of them, each frame: chapter 24)
DIM SHARED glNight(1) AS INTEGER ' (...and of night vision being on)
DIM SHARED setStep(NUM_SETTINGS), setKind(NUM_SETTINGS), setKey$(NUM_SETTINGS), setLabel$(NUM_SETTINGS)
' MI_ = Menu Item kinds (what a line of a menu is and does)
CONST MI_ACTION = 1, MI_SUBMENU = 2, MI_SLIDER = 3, MI_TOGGLE = 4, MI_CHOICE = 5
CONST MI_KEY = 6, MI_BACK = 7, MI_TEXT = 8
'             setting        file name             menu label            control    min max  step start
DefineSetting SET_SFX,       "sfx",                "SFX VOLUME",         MI_SLIDER, 0,  100, 5,   100
DefineSetting SET_MUSIC,     "music",              "MUSIC VOLUME",       MI_SLIDER, 0,  100, 5,   50
DefineSetting SET_SPEECH,    "speech",             "SPEECH VOLUME",      MI_SLIDER, 0,  100, 5,   100
DefineSetting SET_FOV,       "fov",                "FIELD OF VIEW",      MI_SLIDER, 50, 110, 2,   80
DefineSetting SET_XSTYLE,    "crosshair_style",    "CROSSHAIR STYLE",    MI_CHOICE, 1,  6,   1,   4
DefineSetting SET_XCOLOR,    "crosshair_color",    "CROSSHAIR COLOR",    MI_CHOICE, 1,  6,   1,   1
DefineSetting SET_XSIZE,     "crosshair_size",     "CROSSHAIR SIZE",     MI_SLIDER, 1,  5,   1,   5
DefineSetting SET_BOB,       "weapon_bob",         "WEAPON BOBBING",     MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHAKE,     "screen_shake",       "SCREEN SHAKE",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_MOUSE,     "mouse_speed",        "MOUSE LOOK SPEED",   MI_SLIDER, 1,  10,  1,   2
DefineSetting SET_XALPHA,    "crosshair_opacity",  "CROSSHAIR OPACITY",  MI_SLIDER, 10, 100, 10,  100
DefineSetting SET_XFEEDBACK, "crosshair_feedback", "CROSSHAIR FEEDBACK", MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_HURTDIR,   "damage_indicators",  "DAMAGE INDICATORS",  MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RENDERER,  "renderer",           "RENDERER",           MI_CHOICE, 1,  2,   1,   2 ' 1 software, 2 OpenGL (chapter 24)
DefineSetting SET_FPS,       "show_fps",           "SHOW FPS",           MI_TOGGLE, 0,  1,   1,   0
DefineSetting SET_TIMER,     "sector_timer",       "SECTOR TIMER",       MI_TOGGLE, 0,  1,   1,   0 ' (the sector's clock, and your best: HE_TIMER)
DefineSetting SET_POISON,    "poison_damage",      "POISON DAMAGE",      MI_SLIDER, 0,  10,  1,   3 ' (poisoned - by a poison turret, its fog, a poison pool: this much health a second, till a health pack cures it - GAME/ROCKETS.BM)
DefineSetting SET_GAMMA,     "brightness",         "BRIGHTNESS",         MI_SLIDER, 50, 200, 10,  100 ' (a gamma curve on the 3D view: above 100% the dark parts come up, the brightest stay - ApplyGamma, and the OpenGL post shader's "gamma")
DefineSetting SET_BUMP,      "bump_mapping",       "BUMP MAPPING",       MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
DefineSetting SET_GLOW,      "glows",              "GLOWS",              MI_TOGGLE, 0,  1,   1,   1 ' (OpenGL only)
' ART: 1 CLASSIC (the pixel art), 2 MODERN (neon-caster/hd/'s paintings)
DefineSetting SET_ART,       "art",                "ART",                MI_CHOICE, 1,  2,   1,   1
' The OpenGL effects (chapter 24; SETTINGS > EFFECTS) and the two OpenGL
' view settings (SETTINGS > VIDEO). SCREEN FX: 1 off, 2 scanlines, 3 CRT.
' RESOLUTION: what size OpenGL draws the 3D view, 1 (RES_NATIVE: the
' window's own pixels) to 7 (RES_RETRO: the software renderer's 400 x 300) -
' ResSize, chapter 24, has the sizes in between (2160P 4K down to 480P).
DefineSetting SET_NEON,      "neon",               "NEON",               MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SMOOTH,    "smooth_light",       "SMOOTH LIGHT",       MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_DYNLIGHT,  "moving_lights",      "MOVING LIGHTS",      MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SHADOWS,   "shadows",            "SHADOWS",            MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_PARTICLES, "particles",          "PARTICLES",          MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_REFLECT,   "reflections",        "WET FLOORS",         MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_BLOOM,     "bloom",              "BLOOM",              MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_SCREENFX,  "screen_fx",          "SCREEN FX",          MI_CHOICE, 1,  3,   1,   2
DefineSetting SET_HITFX,     "hit_fx",             "HIT FX",             MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_RES,       "resolution",         "RESOLUTION",         MI_CHOICE, 1,  7,   1,   2
DefineSetting SET_LOOK,      "look_up_down",       "LOOK UP / DOWN",     MI_TOGGLE, 0,  1,   1,   1
' How dark the scanlines are (with SCREEN FX on), and how much light bleeds
' round bright things, as on a real tube's glass (both 0..100%)
DefineSetting SET_SCANLINES, "scanlines",          "SCANLINE DARKNESS",  MI_SLIDER, 0,  100, 5,   50
' ...and how far apart they are (in the window's own pixels) and how thick
' (how much of that gap is dark)
DefineSetting SET_SCANGAP,   "scanline_spacing",   "SCANLINE SPACING",   MI_SLIDER, 2,  16,  1,   3
DefineSetting SET_SCANTHICK, "scanline_thickness", "SCANLINE THICKNESS", MI_SLIDER, 10, 90,  5,   35
' DISPLAY: 1 in a window; full screen 2 WIDE (with OpenGL, the 3D view
' fills a widescreen and sees more to the sides; the HUD stays 4:3 in the
' middle), 3 4:3 (our shape, black bars at the sides), 4 STRETCH (all of
' it stretched to fill the screen) - ApplyDisplay, chapter 21
DefineSetting SET_DISPLAY,   "display",            "DISPLAY",            MI_CHOICE, 1,  4,   1,   1
' WINDOW SIZE: the window's size, windowed - one of NUM_WINSIZES (CORE/WINDOW.BI:
' 800 x 600 to 2880 x 2160); dragging the window's edge sets it too (WindowFrame)
DefineSetting SET_WINSIZE,   "window_size",        "WINDOW SIZE",        MI_CHOICE, 1,  10,  1,   1
DefineSetting SET_PHOSPHOR,  "phosphor_glow",      "PHOSPHOR GLOW",      MI_SLIDER, 0,  100, 5,   50
' Beams of light under the ceiling lights, with the dust hanging in them
' How fast the mouse turns you while you aim down the sights, as well as
' the zoom slowing it (chapter 8)
' Sound: placed round you (3D SOUND: panned by where it is, fainter with
' distance, muffled behind walls), and kept from getting too loud when a
' lot happens at once (LIMITER - PlaySfx, chapter 23). NEXUS's voice: the
' transmissions as you arrive in a sector (CUTSCENES), and what it says to
' you now and then while you play (TAUNTS).
DefineSetting SET_SPATIAL,   "spatial_sound",      "3D SOUND",           MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_LIMITER,   "sound_limiter",      "LIMITER",            MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_CUTSCENES, "cutscenes",          "CUTSCENES",          MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_TAUNTS,    "taunts",             "NEXUS TAUNTS",       MI_TOGGLE, 0,  1,   1,   1
' SOFTEN HIGHS: a low-pass over every sound effect and voice (AUDIO/SOFTEN.BM) - OFF, LIGHT (10 kHz) or STRONG (7 kHz, steeper)
DefineSetting SET_SOFTEN,    "soften_highs",       "SOFTEN HIGHS",       MI_CHOICE, 0,  2,   1,   0
' DIFFICULTY: EASY (the game as made), NORMAL, HARD, NIGHTMARE - GAME/SKILL.BM; a sector takes it as it loads
DefineSetting SET_SKILL,     "difficulty",         "DIFFICULTY",         MI_CHOICE, 0,  3,   1,   0
' CHARGED SHOTS: hold fire on the blaster or the railgun to charge a shot - let go full for twice the damage, at twice the ammo (GAME/GUNS.BM's ChargeStep)
DefineSetting SET_CHARGE,    "charged_shots",      "CHARGED SHOTS",      MI_TOGGLE, 0,  1,   1,   1
DefineSetting SET_AIMSENS,   "aim_sensitivity",    "AIM SENSITIVITY",    MI_SLIDER, 10, 100, 5,   50
DefineSetting SET_SHAFTS,    "light_shafts",       "LIGHT SHAFTS",       MI_TOGGLE, 0,  1,   1,   1
' MODE: OLDSCHOOL, 90S or NEWSCHOOL - every video and effects setting at
' once (ModeWants, chapter 21). It isn't kept as itself: what it shows is
' worked out from the others (ModeNow), so it says CUSTOM after you change
' one by hand.
DefineSetting SET_MODE,      "mode",               "MODE",               MI_CHOICE, 0,  3,   1,   0
DIM SHARED modeWas ' (the MODE last put into effect: ApplySettings)
' Things the settings change, worked out by ApplySettings: the camera
' plane's length (from the field of view) and the mouse turn speed
DIM SHARED fovPlane, turnSpeed, displayAsked, displayModeNow
