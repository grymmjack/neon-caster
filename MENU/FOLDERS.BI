''
' NEON-CASTER - MENU/FOLDERS.BI
' =============================================================================
' GAME / EDIT > SECTORS: every sector in folders of your own making.
'

' The folders are only the menu's: a tree of folders (up to FD_DEEP inside
' one another) holding sectors - a set's (set * 100 + n, the original ten
' just n) or yours (custom N is 10 + N) - and more folders. Sectors are
' still played, saved and recorded by those numbers: nothing else changes.
' The game's tree is neon-caster/levels/folders.txt; once you change it in
' the menu, yours is saves/folders.txt (delete it to go back).
CONST SCR_FOLDERS = 63 ' (one screen: whichever folder you're in - fdAt)
CONST MA_FDOPEN = 46, MA_FDUP = 47, MA_FDNEW = 48, MA_FDHERE = 49
CONST FD_MAX = 512 ' (folders and sectors in the tree, at most)
CONST FD_DEEP = 10 ' (folders inside folders, at most)
CONST FD_NAME_MAX = 24 ' (a folder's name: letters at most)
' Node 0 is the top (SECTORS); each other one a folder (fdKind 1) or a
' sector (2), its folder fdUp, its place among its folder's fdOrd
DIM SHARED fdN, fdKind(FD_MAX), fdName$(FD_MAX), fdCode(FD_MAX), fdUp(FD_MAX), fdOrd(FD_MAX) AS LONG
DIM SHARED fdOrdNext AS LONG
DIM SHARED fdRest ' (the folder your new sectors go in - a "rest" line - 0: the top)
DIM SHARED fdAt ' (the folder showing)
DIM SHARED fdFwd(FD_DEEP), fdFwdN ' (where you came back from: Right goes there again, as a browser's forward)
DIM SHARED fdMove ' (a folder or sector picked up to move (X): V puts it in the folder showing)
DIM SHARED fdTypeNode, fdTypeNew ' (a folder being named: R, or a NEW FOLDER - Esc takes a new one away again)
DIM SHARED fdRow(MAX_MI) ' (each menu row's node: 0 none)
DIM SHARED fdNote$ ' (a word on the last thing done, under the list)
