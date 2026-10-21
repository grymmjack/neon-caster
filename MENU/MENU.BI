''
' NEON-CASTER - MENU/MENU.BI
' =============================================================================
' The menu (chapter 21): its screens, items and actions.
'

' SCR_ = the menu's screens; MA_ = Menu Actions (what choosing a button does)
CONST SCR_MAIN = 1, SCR_GAME = 2, SCR_SAVE = 3, SCR_LOAD = 4, SCR_SETTINGS = 5
CONST SCR_AUDIO = 6, SCR_GAMEPLAY = 7, SCR_CONTROLS = 8, SCR_CREDITS = 9, SCR_QUIT = 10, SCR_VIDEO = 11, SCR_EFFECTS = 12
CONST MA_RESUME = 1, MA_NEW = 2, MA_SAVE = 3, MA_LOAD = 4, MA_QUIT = 5, MA_KEYS_DEFAULT = 6, MA_SECTOR = 7
CONST SCR_SECTOR = 13, SCR_QB64 = 14, SCR_CUSTOM = 15, SCR_CUSTOM2 = 16, SCR_SET1 = 17 ' (SCR_SET1 + s - 1: set s's sectors)
CONST SCR_DEMOS = 30, MA_DEMO = 14, MA_DEMOPAGE = 15, MA_STOPDEMO = 16, MA_DEMOFOLDER = 17 ' (DEMO REPLAYS: the demos on disk - DemoListLoad - ten a page; Enter plays one; OPEN FOLDER, or F, shows your own)
CONST MA_QB64_TYPE = 8, MA_QB64_BROWSE = 9, MA_QB64_AUTO = 10, MA_NEWSECTOR = 11, MA_ACHIEVE = 12, MA_LINK = 13 ' (MA_LINK: its info$ is "NAME|address" - the name underlined, the address opened in the web browser)
' The items on the menu screen showing now: label, kind (MI_), what it
' refers to (a screen, a setting, a binding or a save slot), its action
' (MA_), whether it can be chosen, and a line of small print beside it
CONST MAX_MI = 22
DIM SHARED miLabel$(MAX_MI), miKind(MAX_MI), miRef(MAX_MI), miAct(MAX_MI), miOn(MAX_MI), miInfo$(MAX_MI)
DIM SHARED numMI, menuTitle$, menuSel, menuCapture, menuWide, menuScreen, menuInGame
DIM SHARED menuTyping, menuTyped$, menuTypeBad ' (typing qb64pe's path: MenuTypeKey)
DIM SHARED menuStack(10), menuStackSel(10) ' The screens you came through (for BACK)
' MENU_ = where the menu is drawn: the first row, the gap between rows,
' where labels start, and where sliders and other controls go
CONST MENU_FIT = 14 ' (rows a menu shows at once: a longer one - CONTROLS - scrolls, menuScroll rows down)
DIM SHARED menuScroll AS INTEGER
CONST MENU_TOP = 176, MENU_ROW = 32, MENU_LABEL_X = 140, MENU_WIDGET_X = 444, MENU_WIDGET_W = 160 ' (an 18-letter name, then the widget and its value: all inside the panel, 96 to 704)
CONST SPLASH_SECONDS = 3.5 ' How long the splash screen stays up (any key skips it)


' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED menuAdjust, menuDepth, menuDone, menuMove, menuT, mouseWasDown, qbF$, qbSel
