''
' NEON-CASTER - ACH/RECORDS.BI
' =============================================================================
' Records: each sector's best.
'

' RECORDS (chapter 23: RecordsLoad, RecordFor): each sector's best - its
' quickest finish, most kills and items - in every set, kept in
' saves/records.txt. recKey: set * 100 + the sector (your own sectors,
' 11-30, by their number alone). recNew: the sector just finished beat
' its best time (the tally says so); recBest!: the best before it.
CONST MAX_RECORDS = (NUM_SETS + 1) * NUM_LEVELS + MAX_CUSTOM ' (every set's ten and all of yours: it was 64, fewer than the four sets and 30 of yours)
DIM SHARED recNm$(NUM_LEVELS + MAX_CUSTOM), recNmSet AS INTEGER ' (the RECORDS page's names, for set recNmSet)
DIM SHARED recN AS INTEGER, recKey(MAX_RECORDS) AS INTEGER, recTime!(MAX_RECORDS), recKills(MAX_RECORDS) AS INTEGER, recKillsOf(MAX_RECORDS) AS INTEGER
DIM SHARED recItems(MAX_RECORDS) AS INTEGER, recItemsOf(MAX_RECORDS) AS INTEGER, recClears(MAX_RECORDS) AS INTEGER, recNew AS INTEGER, recBest!
