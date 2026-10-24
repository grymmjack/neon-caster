''
' NEON-CASTER - EDITOR/SESSION.BI
' =============================================================================
' Editing as its own thing: the EDIT menu, an edit session, the sectors
' edited last, and a sector's saved versions.
'

' --- AN EDIT SESSION (the main menu's EDIT): a sector opened straight into
' the editor - no NEXUS greeting, no music, no taunts; play-testing it, the
' exit brings you back to the editor (no tally, no next sector). A game
' started from GAME (or a saved one, or a demo) ends it. menuEditPick: the
' sector lists (SELECT SECTOR, a set's, YOUR SECTORS) were opened from EDIT
' - a sector chosen there opens in the editor.
DIM SHARED editSession AS INTEGER, menuEditPick AS INTEGER

' --- THE SECTORS EDITED LAST (saves/editrecent.txt, newest first): each
' one's code (a set's sector: set * 100 + sector, as the menu's), where you
' were and which way you faced, and the view (0 the map from above, 1 3D).
' RESUME LAST EDIT is the first; EDIT lists the rest.
CONST ER_MAX = 5
DIM SHARED erN AS INTEGER, erCode(ER_MAX) AS INTEGER, erX(ER_MAX) AS SINGLE, erY(ER_MAX) AS SINGLE, erDX(ER_MAX) AS SINGLE, erDY(ER_MAX) AS SINGLE, erView(ER_MAX) AS INTEGER

' --- THE VERSIONS PANE (the editor's VERSIONS button): REVERT TO SAVED,
' SAVE A VERSION, and the versions saved (versions/ beside the sector's
' file - EditSaveCopy$ - newest first, and the save before the last, its
' .bak), VER_ROWS at a time from edVerTop. A click loads one (Ctrl+Z puts
' back what you had).
CONST VER_MAX = 300, VER_ROWS = 12
DIM SHARED edVerPane AS INTEGER, edVerN AS INTEGER, edVerTop AS INTEGER, edVerF$(VER_MAX), edVerLab$(VER_MAX)

' The menu's EDIT screen, and its actions
CONST SCR_EDIT = 62, MA_EDITRESUME = 41, MA_MONKINDS = 42
