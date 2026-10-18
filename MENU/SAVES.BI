''
' NEON-CASTER - MENU/SAVES.BI
' =============================================================================
' Saved games: the slots, and the file's first bytes.
'

' Saved games: the slots, and the file's first bytes, so a file from
' something else (or an older version) is never read as a save
CONST NUM_SLOTS = 3, SAVE_TAG = "NCSAVE04", SAVE_INFO_LEN = 48
DIM savedCount AS INTEGER ' A count read back from a save (the same type as numItems, so GET reads 2 bytes)
