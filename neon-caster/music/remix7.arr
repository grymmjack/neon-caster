; NEON-CASTER - remix7's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.000   offset 0.0206   bars 23   tail 24
source remix7.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     peak
clip B  bars 9-16    build
clip C  bars 17-23   break
clip D  bars 1-20    peak
clip E  bars 13-20   build
clip F  bars 5-12    peak
clip G  bars 1-4     peak
clip H  bars 9-20    build
clip I  bars 5-20    peak
clip J  bars 13-16   build
arrange D E F G*2 D H A I J G
seam 1 3 0.71
seam 1 4 0.78
seam 1 5 0.84
seam 1 6 1.00
seam 1 7 0.80
seam 1 8 0.88
seam 2 2 0.71
seam 2 4 0.72
seam 2 5 0.86
seam 2 6 0.75
seam 2 7 0.98
seam 2 8 0.81
seam 3 2 0.78
seam 3 3 0.72
seam 3 5 0.93
seam 3 6 0.92
seam 3 7 0.77
seam 3 8 0.98
seam 4 2 0.84
seam 4 3 0.86
seam 4 4 0.93
seam 4 6 0.94
seam 4 7 0.91
seam 4 8 0.92
seam 5 2 1.00
seam 5 4 0.92
seam 5 5 0.94
seam 5 7 0.84
seam 5 8 0.89
seam 5 9 0.80
seam 6 2 0.80
seam 6 3 0.98
seam 6 4 0.77
seam 6 5 0.91
seam 6 6 0.84
seam 6 8 0.81
seam 7 2 0.88
seam 7 3 0.81
seam 7 4 0.98
seam 7 5 0.92
seam 7 6 0.89
seam 7 7 0.81
seam 8 5 0.82
seam 8 6 0.80
seam 8 10 0.70
seam 8 13 0.81
seam 8 14 0.71
seam 8 16 0.72
seam 9 11 1.00
seam 9 12 0.90
seam 9 13 0.84
seam 9 14 1.00
seam 9 15 0.92
seam 9 16 0.95
seam 10 10 1.00
seam 10 12 0.91
seam 10 13 0.90
seam 10 14 0.99
seam 10 15 1.00
seam 10 16 0.97
seam 11 10 0.90
seam 11 11 0.91
seam 11 14 0.82
seam 11 15 0.97
seam 11 16 1.00
seam 11 20 0.85
seam 12 10 0.84
seam 12 11 0.90
seam 12 14 0.86
seam 12 15 0.82
seam 12 16 0.98
seam 12 17 0.85
seam 13 10 1.00
seam 13 11 0.99
seam 13 12 0.82
seam 13 13 0.86
seam 13 15 0.87
seam 13 16 0.90
seam 14 10 0.92
seam 14 11 1.00
seam 14 12 0.97
seam 14 14 0.87
seam 14 16 0.91
seam 14 19 0.83
seam 15 10 0.95
seam 15 11 0.97
seam 15 12 1.00
seam 15 13 0.98
seam 15 14 0.90
seam 15 15 0.91
seam 16 11 0.78
seam 16 12 0.72
seam 16 13 0.85
seam 16 14 0.72
seam 16 15 0.76
seam 16 21 0.78
seam 17 10 0.73
seam 17 14 0.75
seam 17 19 0.65
seam 17 20 0.81
seam 17 22 1.00
seam 17 23 0.59
seam 18 11 0.83
seam 18 15 0.83
seam 18 17 0.67
seam 18 20 0.80
seam 18 21 0.81
seam 18 23 1.00
seam 19 12 0.85
seam 19 16 0.73
seam 19 18 0.81
seam 19 19 0.80
seam 19 22 0.71
seam 19 23 0.70
seam 20 9 0.63
seam 20 13 0.81
seam 20 17 0.78
seam 20 19 0.81
seam 20 20 0.68
seam 20 23 0.71
seam 21 10 0.69
seam 21 14 0.75
seam 21 18 1.00
seam 21 19 0.63
seam 21 20 0.71
seam 21 23 0.60
seam 22 11 0.74
seam 22 15 0.75
seam 22 19 1.00
seam 22 20 0.70
seam 22 21 0.71
seam 22 22 0.60
seam 23 18 0.87
seam 23 19 0.87
seam 23 20 0.89
seam 23 21 0.89
seam 23 22 0.79
seam 23 23 0.79
