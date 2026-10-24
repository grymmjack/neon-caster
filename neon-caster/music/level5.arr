; NEON-CASTER - level5's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 124.957   offset 1.4565   bars 18   tail 19
source level5.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     groove
clip B  bars 9-16    break
clip C  bars 5-8     groove
clip D  bars 5-12    groove
clip E  bars 9-12    break
clip F  bars 1-12    groove
clip G  bars 5-16    groove
clip H  bars 1-4     groove
arrange C A D E D C F E A D G E H A F
seam 1 3 0.86
seam 1 4 0.72
seam 1 6 0.80
seam 1 8 0.66
seam 1 10 0.86
seam 1 14 0.72
seam 2 4 0.94
seam 2 5 0.94
seam 2 6 0.91
seam 2 7 1.00
seam 2 11 0.97
seam 2 15 0.95
seam 3 3 0.94
seam 3 6 0.94
seam 3 7 0.92
seam 3 8 1.00
seam 3 12 1.00
seam 3 16 0.84
seam 4 1 0.63
seam 4 3 0.94
seam 4 4 0.81
seam 4 6 0.86
seam 4 7 0.95
seam 4 9 1.00
seam 4 13 1.00
seam 5 3 0.91
seam 5 4 0.94
seam 5 5 0.86
seam 5 7 0.97
seam 5 10 1.00
seam 5 14 0.93
seam 6 3 1.00
seam 6 4 0.92
seam 6 5 0.95
seam 6 6 0.97
seam 6 11 1.00
seam 6 15 0.93
seam 7 3 0.83
seam 7 4 1.00
seam 7 6 0.80
seam 7 7 0.83
seam 7 12 1.00
seam 7 16 0.97
seam 8 1 0.79
seam 8 3 0.82
seam 8 5 1.00
seam 8 7 0.79
seam 8 10 0.80
seam 8 11 0.80
seam 8 13 1.00
seam 9 2 0.86
seam 9 3 0.85
seam 9 6 1.00
seam 9 11 1.00
seam 9 12 0.87
seam 9 14 0.99
seam 10 3 0.97
seam 10 7 1.00
seam 10 10 1.00
seam 10 12 0.97
seam 10 14 0.82
seam 10 15 0.97
seam 11 4 1.00
seam 11 8 1.00
seam 11 10 0.87
seam 11 11 0.97
seam 11 13 0.81
seam 11 16 0.79
seam 12 1 0.57
seam 12 5 1.00
seam 12 9 1.00
seam 12 10 0.75
seam 12 11 0.75
seam 12 12 0.81
seam 12 14 0.77
seam 13 6 0.93
seam 13 7 0.75
seam 13 10 0.99
seam 13 11 0.82
seam 13 13 0.77
seam 13 15 0.90
seam 14 3 0.95
seam 14 7 0.93
seam 14 10 0.79
seam 14 11 0.97
seam 14 14 0.90
seam 14 16 0.77
seam 15 4 0.84
seam 15 8 0.97
seam 15 10 0.65
seam 15 11 0.62
seam 15 12 0.79
seam 15 15 0.77
seam 16 5 0.42
seam 16 9 0.54
seam 16 10 0.47
seam 16 11 0.44
seam 16 13 0.41
seam 16 16 0.41
