' NEON-CASTER code puzzles - one file each, read by the data terminals ($ on
' a level's map, chapter 19). A puzzle is a little QB64 program: the game
' shuffles its lines and blanks out the words in [blanks]; you put it back
' together, and it's compiled and run for real (if qb64pe is found) - its
' output must be what "expect" says (lines split by |, spaces and case not
' minded). Without qb64pe the lines are checked against [lines] instead,
' so test a new puzzle with it: SETTINGS > QB64PE COMPILER, or the console's
' qb64pe command, says where it is. Lines starting with ' in a section are comments - except in
' [lines], where they're part of the program (hints the player can read).
'
'   title  = what it's called          lesson = the one idea it teaches
'   expect = its output                 chapter = the course chapter it goes with
'   [lines]   the program, in order (the answer)
'   [blanks]  line number, then the word cut out of it (the first one on it)
'   [hints]   shown one at a time, as you ask (H) or get it wrong
