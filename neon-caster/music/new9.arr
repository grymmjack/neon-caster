; NEON-CASTER - new9's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.017   offset 0.0036   bars 24   tail 24
source new9.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    peak
clip C  bars 17-23   peak
clip D  bars 1-4     intro
clip E  bars 1-20    intro
clip F  bars 9-20    peak
clip G  bars 13-20   peak
clip H  bars 1-12    intro
clip I  bars 13-16   peak
arrange D E F G F D H F I B G D
seam 1 3 0.88
seam 1 4 0.93
seam 1 5 0.88
seam 1 6 0.92
seam 1 7 0.67
seam 1 23 0.66
seam 2 2 0.88
seam 2 4 1.00
seam 2 5 1.00
seam 2 6 0.98
seam 2 7 0.88
seam 2 8 0.71
seam 3 2 0.93
seam 3 3 1.00
seam 3 5 1.00
seam 3 6 0.86
seam 3 7 0.90
seam 3 8 0.75
seam 4 2 0.88
seam 4 3 1.00
seam 4 4 1.00
seam 4 6 0.99
seam 4 7 0.79
seam 4 8 0.70
seam 5 2 0.92
seam 5 3 0.98
seam 5 4 0.86
seam 5 5 0.99
seam 5 7 0.91
seam 5 8 0.58
seam 6 2 0.67
seam 6 3 0.88
seam 6 4 0.90
seam 6 5 0.79
seam 6 6 0.91
seam 6 8 0.71
seam 7 3 0.71
seam 7 4 0.75
seam 7 5 0.70
seam 7 7 0.71
seam 7 16 0.81
seam 7 23 0.75
seam 8 10 0.73
seam 8 13 0.95
seam 8 17 0.89
seam 8 21 0.96
seam 8 22 0.70
seam 8 23 0.74
seam 9 11 0.91
seam 9 12 0.74
seam 9 14 1.00
seam 9 15 0.88
seam 9 18 0.92
seam 9 22 0.83
seam 10 10 0.91
seam 10 12 1.00
seam 10 15 0.93
seam 10 16 0.91
seam 10 19 1.00
seam 10 20 0.87
seam 11 11 1.00
seam 11 15 0.97
seam 11 16 0.93
seam 11 18 0.77
seam 11 19 1.00
seam 11 20 0.99
seam 12 9 0.95
seam 12 11 0.71
seam 12 12 0.73
seam 12 15 0.74
seam 12 17 1.00
seam 12 21 0.99
seam 13 10 1.00
seam 13 11 0.82
seam 13 12 0.71
seam 13 15 0.93
seam 13 18 1.00
seam 13 22 0.88
seam 14 10 0.88
seam 14 11 0.93
seam 14 12 0.97
seam 14 14 0.93
seam 14 16 0.97
seam 14 23 0.88
seam 15 8 0.81
seam 15 11 0.91
seam 15 12 0.93
seam 15 15 0.97
seam 15 19 0.85
seam 15 23 0.82
seam 16 9 0.89
seam 16 12 0.74
seam 16 13 1.00
seam 16 16 0.79
seam 16 19 0.81
seam 16 21 0.87
seam 17 10 0.92
seam 17 11 0.79
seam 17 12 0.77
seam 17 14 1.00
seam 17 17 0.73
seam 17 19 0.89
seam 18 11 1.00
seam 18 12 1.00
seam 18 15 0.87
seam 18 16 0.85
seam 18 18 0.89
seam 18 20 0.84
seam 19 11 0.87
seam 19 12 0.99
seam 19 15 0.73
seam 19 16 0.80
seam 19 19 0.84
seam 19 23 0.66
seam 20 9 0.96
seam 20 12 0.69
seam 20 13 0.99
seam 20 17 0.87
seam 20 22 0.69
seam 20 23 0.77
seam 21 9 0.70
seam 21 10 0.83
seam 21 14 0.88
seam 21 15 0.82
seam 21 18 0.70
seam 21 23 0.93
seam 22 8 0.75
seam 22 9 0.74
seam 22 15 0.88
seam 22 16 0.82
seam 22 21 0.77
seam 22 22 0.93
seam 23 8 0.85
seam 23 9 0.74
seam 23 15 0.85
seam 23 16 0.90
seam 23 22 0.84
seam 23 23 0.99
