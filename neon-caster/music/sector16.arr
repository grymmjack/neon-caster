; NEON-CASTER - sector16's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.000   offset 0.0290   bars 23   tail 24
source sector16.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-12    peak
clip C  bars 13-20   peak
clip D  bars 9-20    peak
clip E  bars 17-20   peak
clip F  bars 9-16    peak
clip G  bars 13-16   peak
clip H  bars 9-12    peak
clip I  bars 5-20    peak
arrange D E F C G H D*2 I G D*2
seam 1 4 0.40
seam 3 2 0.40
seam 4 9 0.57
seam 4 13 0.52
seam 4 17 0.48
seam 4 18 0.45
seam 4 21 0.57
seam 4 23 0.46
seam 5 8 0.76
seam 5 10 0.97
seam 5 14 1.00
seam 5 18 1.00
seam 5 20 0.83
seam 5 22 1.00
seam 6 11 0.92
seam 6 15 0.97
seam 6 17 0.77
seam 6 19 1.00
seam 6 21 0.83
seam 6 23 1.00
seam 7 6 0.76
seam 7 12 0.86
seam 7 16 0.94
seam 7 18 0.75
seam 7 20 1.00
seam 7 22 0.74
seam 8 7 0.69
seam 8 11 0.66
seam 8 13 0.94
seam 8 17 0.97
seam 8 19 0.67
seam 8 21 0.97
seam 9 6 0.97
seam 9 12 0.89
seam 9 14 1.00
seam 9 16 0.78
seam 9 18 1.00
seam 9 22 0.97
seam 10 7 0.92
seam 10 12 0.85
seam 10 13 0.91
seam 10 15 1.00
seam 10 19 0.97
seam 10 23 0.96
seam 11 8 0.86
seam 11 10 0.89
seam 11 11 0.85
seam 11 14 0.86
seam 11 16 1.00
seam 11 20 0.95
seam 12 9 0.94
seam 12 11 0.91
seam 12 12 0.80
seam 12 15 0.79
seam 12 17 1.00
seam 12 21 0.95
seam 13 6 1.00
seam 13 10 1.00
seam 13 12 0.86
seam 13 16 0.82
seam 13 18 1.00
seam 13 22 0.97
seam 14 7 0.97
seam 14 11 1.00
seam 14 13 0.79
seam 14 16 0.79
seam 14 19 1.00
seam 14 23 0.96
seam 15 8 0.94
seam 15 11 0.81
seam 15 12 1.00
seam 15 14 0.82
seam 15 15 0.79
seam 15 20 1.00
seam 16 7 0.77
seam 16 9 0.97
seam 16 11 0.79
seam 16 13 1.00
seam 16 19 0.78
seam 16 21 1.00
seam 17 6 1.00
seam 17 8 0.75
seam 17 10 1.00
seam 17 14 1.00
seam 17 20 0.80
seam 17 22 1.00
seam 18 7 1.00
seam 18 11 0.97
seam 18 15 1.00
seam 18 17 0.78
seam 18 21 0.81
seam 18 23 1.00
seam 19 6 0.83
seam 19 8 1.00
seam 19 12 0.95
seam 19 16 1.00
seam 19 18 0.80
seam 19 22 0.76
seam 20 7 0.83
seam 20 9 0.97
seam 20 13 0.95
seam 20 17 1.00
seam 20 19 0.81
seam 20 23 0.81
seam 21 6 1.00
seam 21 8 0.74
seam 21 10 0.97
seam 21 14 0.97
seam 21 18 1.00
seam 21 20 0.76
seam 22 7 1.00
seam 22 11 0.96
seam 22 15 0.96
seam 22 17 0.75
seam 22 19 1.00
seam 22 21 0.81
seam 23 7 0.76
seam 23 11 0.73
seam 23 15 0.76
seam 23 16 0.78
seam 23 19 0.77
seam 23 23 0.82
