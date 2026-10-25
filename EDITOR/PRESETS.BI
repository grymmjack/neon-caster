''
' NEON-CASTER - EDITOR/PRESETS.BI
' =============================================================================
' PAINT's PRESETS: a face's whole look kept, to put on other faces again -
' its pieces, and each piece's picture, turn, slide, stretch, tint and
' start (as a [faces] line's division 3 has them: the tree's shape and its
' pieces joined by |). Kept under the picture they're of (the face's first
' piece's, or its usual one), in neon-caster/presets.txt - one a line:
'   picture <tab> shape <tab> pieces
' so every sector has them. The PICTURE pane shows the shelf for the
' selected face's picture: click one to put it on everything selected, SAVE
' keeps the selected face's look, REPLACE puts it over the one chosen,
' DELETE throws that away (EDITOR/PRESETS.BM).
'
CONST PR_MAX = 1024, PR_THUMB = 58
DIM SHARED prN AS INTEGER, prPic$(PR_MAX), prShape$(PR_MAX), prLeaves$(PR_MAX), prImg&(PR_MAX), prLoaded AS INTEGER
DIM SHARED edPrKey$, edPrScroll AS INTEGER, edPrSel AS INTEGER ' (the shelf showing: whose picture, how many rows down, the one chosen - an index, 0 none)
