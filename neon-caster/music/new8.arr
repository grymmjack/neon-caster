; NEON-CASTER - new8's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.067   offset 0.0260   bars 24   tail 17
source new8.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     peak
clip B  bars 9-16    break
clip C  bars 1-16    peak
clip D  bars 9-12    break
clip E  bars 1-12    peak
clip F  bars 5-8     peak
clip G  bars 1-4     peak
clip H  bars 5-12    peak
arrange C D A E F G C B H G E H G
seam 1 3 0.98
seam 1 4 0.96
seam 1 5 0.96
seam 1 6 1.00
seam 1 7 0.99
seam 1 10 0.90
seam 2 2 0.98
seam 2 4 0.99
seam 2 5 1.00
seam 2 6 0.99
seam 2 7 1.00
seam 2 11 0.92
seam 3 2 0.96
seam 3 3 0.99
seam 3 5 0.98
seam 3 6 1.00
seam 3 7 0.99
seam 3 8 0.94
seam 4 1 1.00
seam 4 2 0.96
seam 4 3 1.00
seam 4 4 0.98
seam 4 6 0.98
seam 4 7 0.98
seam 4 13 0.93
seam 5 2 1.00
seam 5 3 0.99
seam 5 4 1.00
seam 5 5 0.98
seam 5 7 1.00
seam 5 14 0.88
seam 6 2 0.99
seam 6 3 1.00
seam 6 4 0.99
seam 6 5 0.98
seam 6 6 1.00
seam 6 11 0.97
seam 7 3 0.89
seam 7 4 0.94
seam 7 5 0.86
seam 7 6 0.85
seam 7 7 0.89
seam 7 16 0.94
seam 8 1 0.88
seam 8 2 0.77
seam 8 4 0.77
seam 8 5 0.84
seam 8 6 0.77
seam 8 11 0.82
seam 8 13 0.81
seam 9 2 0.90
seam 9 6 0.87
seam 9 11 0.93
seam 9 12 0.98
seam 9 13 0.91
seam 9 14 0.93
seam 10 3 0.92
seam 10 7 0.97
seam 10 10 0.93
seam 10 12 0.92
seam 10 13 1.00
seam 10 15 0.93
seam 11 4 0.93
seam 11 10 0.98
seam 11 11 0.92
seam 11 13 0.87
seam 11 14 0.85
seam 11 16 0.90
seam 12 1 0.92
seam 12 3 0.82
seam 12 5 0.93
seam 12 7 0.83
seam 12 9 0.81
seam 12 10 0.91
seam 12 11 1.00
seam 12 12 0.87
seam 13 2 0.86
seam 13 3 0.82
seam 13 6 0.88
seam 13 7 0.83
seam 13 10 0.93
seam 13 12 0.85
seam 14 2 0.84
seam 14 3 0.84
seam 14 6 0.80
seam 14 7 0.90
seam 14 11 0.93
seam 14 13 0.81
seam 15 4 0.81
seam 15 8 0.94
seam 15 10 0.85
seam 15 11 0.74
seam 15 12 0.90
seam 15 13 0.77
seam 16 1 0.30
seam 16 5 0.74
seam 16 8 0.78
seam 16 9 0.76
seam 16 11 0.73
seam 16 12 0.73
seam 16 13 0.75
seam 16 16 0.79
