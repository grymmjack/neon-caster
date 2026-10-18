''
' NEON-CASTER - GAME/TERMINALS.BI
' =============================================================================
' Code terminals ($ on the map): QB64 programs to put back together.
'

CONST PZ_TOP = 70 ' (the puzzle screen's first line)
' Your qb64pe, if you've said where it is (SETTINGS > QB64PE COMPILER, or
' the qb64pe console command) - kept as "qb64pe=" in the settings file; ""
' means look for it (QB64Path$, chapter 19)
DIM SHARED qbChosen$
' --- Code terminals ($ on the map, chapter 19): QB64 programs to put back
' together. Space at one: the doors near it slam and lock (doorLock 3)
' and its puzzle opens (RunPuzzle) - a program from neon-caster/puzzles/,
' its lines shuffled and words blanked out. Put it right and it's compiled
' and run, for real if qb64pe can be found (QB64Path$ - or where you've
' told it, in SETTINGS > QB64PE COMPILER), and its output checked: right,
' and the doors open. No qb64pe: the lines are checked against the answer
' instead. Which puzzle: the level file's
' "puzzles =" list, one a terminal in reading order.
CONST MAX_TERMS = 8, MAX_PZ_LINES = 24, MAX_PZ_BLANKS = 6, MAX_PZ_HINTS = 6
DIM SHARED numTerms AS INTEGER, termX(MAX_TERMS) AS INTEGER, termY(MAX_TERMS) AS INTEGER, termDone(MAX_TERMS) AS INTEGER, lvlPuzzles$
DIM SHARED pzTitle$, pzLesson$, pzExpect$, pzChapter$, pzN AS INTEGER, pzAns$(MAX_PZ_LINES), pzOrder(MAX_PZ_LINES) AS INTEGER
DIM SHARED pzBlanks AS INTEGER, pzBlankLine(MAX_PZ_BLANKS) AS INTEGER, pzBlankWord$(MAX_PZ_BLANKS), pzBlankIn$(MAX_PZ_BLANKS)
DIM SHARED pzHints AS INTEGER, pzHint$(MAX_PZ_HINTS), pzShown AS INTEGER, pzOut$, pzFails AS INTEGER
