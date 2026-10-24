; NEON-CASTER - new10's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 139.980   offset 0.0013   bars 26   tail 25
source new10.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-12    groove
clip C  bars 13-20   peak
clip D  bars 21-24   groove
clip E  bars 1-12    intro
clip F  bars 9-20    groove
clip G  bars 17-24   peak
clip H  bars 17-20   peak
clip I  bars 13-16   peak
clip J  bars 9-16    groove
clip K  bars 5-12    intro
clip L  bars 1-4     intro
clip M  bars 5-16    intro
clip N  bars 13-24   peak
clip O  bars 5-8     intro
arrange A E F G H I J K L A M N G I L B O
seam 1 3 0.97
seam 1 4 1.00
seam 1 5 0.93
seam 1 6 1.00
seam 1 10 1.00
seam 1 16 0.93
seam 2 2 0.97
seam 2 5 0.95
seam 2 7 1.00
seam 2 9 0.94
seam 2 11 1.00
seam 2 17 0.87
seam 3 2 1.00
seam 3 3 0.87
seam 3 6 0.95
seam 3 8 1.00
seam 3 10 0.94
seam 3 12 1.00
seam 4 1 1.00
seam 4 2 0.93
seam 4 3 0.95
seam 4 7 0.96
seam 4 9 1.00
seam 4 11 0.97
seam 4 13 0.98
seam 5 2 1.00
seam 5 4 0.95
seam 5 8 0.96
seam 5 10 1.00
seam 5 12 0.97
seam 5 16 0.98
seam 6 3 1.00
seam 6 5 0.96
seam 6 6 0.93
seam 6 9 0.94
seam 6 11 1.00
seam 6 17 0.89
seam 7 2 0.92
seam 7 4 1.00
seam 7 6 0.96
seam 7 10 0.94
seam 7 11 0.81
seam 7 12 1.00
seam 8 1 1.00
seam 8 3 0.94
seam 8 5 1.00
seam 8 7 0.94
seam 8 11 0.96
seam 8 13 1.00
seam 8 17 0.95
seam 9 2 1.00
seam 9 4 0.94
seam 9 6 1.00
seam 9 8 0.94
seam 9 12 0.96
seam 9 16 1.00
seam 10 3 1.00
seam 10 5 0.97
seam 10 6 0.93
seam 10 7 1.00
seam 10 9 0.96
seam 10 17 0.89
seam 11 2 0.90
seam 11 4 1.00
seam 11 6 0.97
seam 11 8 1.00
seam 11 10 0.96
seam 11 11 0.83
seam 12 1 0.96
seam 12 3 0.87
seam 12 5 0.98
seam 12 9 1.00
seam 12 11 0.86
seam 12 17 0.95
seam 12 21 0.86
seam 13 2 0.78
seam 13 16 0.95
seam 13 17 0.81
seam 13 18 1.00
seam 13 20 0.89
seam 13 22 1.00
seam 14 2 0.79
seam 14 14 0.78
seam 14 16 0.79
seam 14 17 0.95
seam 14 19 1.00
seam 14 23 1.00
seam 15 2 0.93
seam 15 6 0.98
seam 15 10 1.00
seam 15 14 0.95
seam 15 20 1.00
seam 15 24 0.96
seam 16 1 0.91
seam 16 5 0.89
seam 16 7 0.89
seam 16 9 0.95
seam 16 11 0.89
seam 16 13 0.95
seam 16 15 0.95
seam 16 21 1.00
seam 17 14 1.00
seam 17 16 0.92
seam 17 17 0.83
seam 17 20 0.80
seam 17 21 0.76
seam 17 22 1.00
seam 18 2 0.73
seam 18 14 0.75
seam 18 15 1.00
seam 18 16 0.74
seam 18 17 0.87
seam 18 23 0.98
seam 19 9 0.78
seam 19 14 0.89
seam 19 16 1.00
seam 19 17 0.82
seam 19 18 0.80
seam 19 24 0.85
seam 20 9 0.70
seam 20 13 0.86
seam 20 14 0.77
seam 20 15 0.76
seam 20 17 1.00
seam 20 18 0.76
seam 21 14 1.00
seam 21 16 0.63
seam 21 18 1.00
seam 21 20 0.57
seam 21 21 0.68
seam 21 24 0.69
seam 22 2 0.58
seam 22 3 0.53
seam 22 15 1.00
seam 22 17 0.62
seam 22 19 0.98
seam 22 21 0.58
seam 23 2 0.72
seam 23 3 0.74
seam 23 4 0.71
seam 23 14 0.72
seam 23 16 0.96
seam 23 20 0.85
seam 24 5 0.64
seam 24 12 0.64
seam 24 13 0.68
seam 24 17 0.91
seam 24 21 0.66
seam 24 22 0.64
seam 24 23 0.70
seam 24 24 0.83
