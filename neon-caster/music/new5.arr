; NEON-CASTER - new5's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.000   offset -0.0051   bars 24   tail 24
source new5.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-2     intro
clip B  bars 5-12    peak
clip C  bars 13-20   peak
clip D  bars 9-20    peak
clip E  bars 17-20   peak
clip F  bars 9-16    peak
clip G  bars 9-12    peak
clip H  bars 5-16    peak
arrange D C E F D G F C*2 G D H D
seam 2 1 0.08
seam 4 6 0.86
seam 4 7 1.00
seam 4 11 0.82
seam 4 15 0.78
seam 4 19 0.71
seam 4 23 0.62
seam 5 5 0.86
seam 5 7 1.00
seam 5 8 0.88
seam 5 10 0.87
seam 5 11 0.83
seam 5 12 0.91
seam 6 5 1.00
seam 6 6 1.00
seam 6 11 0.99
seam 6 12 0.84
seam 6 15 0.97
seam 6 19 0.93
seam 7 6 0.88
seam 7 10 0.88
seam 7 12 1.00
seam 7 14 0.82
seam 7 16 1.00
seam 7 20 1.00
seam 8 11 1.00
seam 8 13 1.00
seam 8 15 0.94
seam 8 17 0.91
seam 8 19 0.79
seam 8 21 1.00
seam 9 8 0.88
seam 9 11 0.90
seam 9 12 1.00
seam 9 14 1.00
seam 9 18 0.91
seam 9 22 0.99
seam 10 7 0.99
seam 10 9 1.00
seam 10 12 0.92
seam 10 13 0.95
seam 10 15 1.00
seam 10 19 1.00
seam 11 8 1.00
seam 11 10 1.00
seam 11 11 0.92
seam 11 14 0.95
seam 11 16 1.00
seam 11 20 1.00
seam 12 5 0.58
seam 12 7 0.76
seam 12 9 1.00
seam 12 11 0.95
seam 12 15 0.93
seam 12 17 0.95
seam 12 21 1.00
seam 13 8 0.82
seam 13 10 1.00
seam 13 12 0.95
seam 13 16 0.79
seam 13 18 0.95
seam 13 22 0.99
seam 14 7 0.97
seam 14 9 0.94
seam 14 11 1.00
seam 14 13 0.93
seam 14 19 1.00
seam 14 23 0.86
seam 15 6 0.80
seam 15 8 1.00
seam 15 10 0.85
seam 15 12 1.00
seam 15 18 0.81
seam 15 20 0.99
seam 16 5 0.54
seam 16 9 0.91
seam 16 11 0.76
seam 16 13 0.95
seam 16 15 0.72
seam 16 19 0.90
seam 16 21 0.99
seam 17 10 0.91
seam 17 12 0.80
seam 17 14 0.95
seam 17 16 0.81
seam 17 20 0.82
seam 17 22 0.98
seam 18 7 0.93
seam 18 9 0.79
seam 18 11 1.00
seam 18 15 1.00
seam 18 17 0.90
seam 18 21 0.79
seam 19 8 1.00
seam 19 10 0.79
seam 19 12 1.00
seam 19 16 0.99
seam 19 18 0.82
seam 19 22 0.81
seam 20 5 0.54
seam 20 9 1.00
seam 20 11 0.82
seam 20 13 1.00
seam 20 15 0.83
seam 20 17 0.99
seam 20 19 0.79
seam 21 10 0.99
seam 21 11 0.81
seam 21 12 0.80
seam 21 14 0.99
seam 21 18 0.98
seam 21 20 0.81
seam 22 7 0.81
seam 22 8 0.72
seam 22 11 0.83
seam 22 12 0.74
seam 22 15 0.86
seam 22 19 0.73
seam 23 7 0.65
seam 23 8 0.65
seam 23 11 0.68
seam 23 12 0.65
seam 23 15 0.70
seam 23 23 0.82
