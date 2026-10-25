' ============================================================================
' THE COLOUR HELPER - beside any colour being typed in the editor (a tint,
' a thing's look, a light's colour, a cell's light, a made colour): a
' palette's colours to click (GIMP .gpl files - neon-caster/palettes/, or
' any loaded), and PICK, a colour taken from the screen (Shift: the
' picture's own colour, unlit, under the pointer). EDITOR/COLOURS.BM.
' ============================================================================
CONST CP_MAX = 256 ' (the most colours a palette keeps)
CONST CP_W = 200, CP_COLS = 10, CP_SQ = 20, CP_ROWS = 8 ' (the panel: as wide as the pane, ten swatches a row, eight rows shown)
CONST CP_BUILT = 120 ' (the most palettes in neon-caster/palettes/)
DIM SHARED cpN AS INTEGER, cpCol(CP_MAX) AS _UNSIGNED LONG, cpName$(CP_MAX), cpTitle$ ' (the palette: its colours, their names, its own)
DIM SHARED cpFile$ ' (palette= in settings: the palette last chosen, a path - "" the usual one)
DIM SHARED cpBuiltN AS INTEGER, cpBuilt$(CP_BUILT), cpBuiltAt AS INTEGER ' (the palettes that come with the game; which is up - 0 one loaded from elsewhere)
DIM SHARED cpTop AS INTEGER, cpX0 AS INTEGER, cpY0 AS INTEGER, cpBot AS INTEGER ' (the first row shown; where the panel is)
DIM SHARED cpPick AS INTEGER, cpUsed AS INTEGER ' (-1: the next click takes a colour from the screen; a colour's been used while typing)
DIM SHARED cpGLReq AS INTEGER, cpGLX AS SINGLE, cpGLY AS SINGLE, cpGLCol AS _UNSIGNED LONG ' (1: SUB _GL is asked for the pixel at cpGLX, cpGLY - 2: it's in cpGLCol)
