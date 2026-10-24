; NEON-CASTER - new1's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 140.000   offset 0.8744   bars 26   tail 27
source new1.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     peak
clip C  bars 9-12    groove
clip D  bars 13-20   build
clip E  bars 21-26   peak
clip F  bars 1-20    intro
clip G  bars 5-24    peak
clip H  bars 21-24   peak
clip I  bars 1-16    intro
clip J  bars 1-24    intro
clip K  bars 5-16    peak
arrange F G H*2 I J G K
seam 1 3 0.98
seam 1 4 1.00
seam 1 17 0.85
seam 1 18 1.00
seam 1 19 1.00
seam 1 20 0.94
seam 2 2 0.98
seam 2 4 0.96
seam 2 5 0.80
seam 2 17 0.88
seam 2 19 0.94
seam 2 20 0.81
seam 3 2 1.00
seam 3 3 0.96
seam 3 5 0.81
seam 3 18 0.81
seam 3 19 0.72
seam 3 20 0.92
seam 4 3 0.80
seam 4 4 0.81
seam 4 6 0.84
seam 4 21 0.98
seam 4 22 0.85
seam 4 26 0.83
seam 5 7 0.99
seam 5 21 0.87
seam 5 22 1.00
seam 5 23 1.00
seam 5 25 0.90
seam 5 26 1.00
seam 6 6 0.99
seam 6 8 0.97
seam 6 22 0.97
seam 6 23 1.00
seam 6 24 0.99
seam 6 26 1.00
seam 7 7 0.97
seam 7 9 0.97
seam 7 22 0.83
seam 7 23 0.95
seam 7 24 1.00
seam 7 25 0.86
seam 8 7 0.78
seam 8 8 0.97
seam 8 10 0.97
seam 8 16 0.81
seam 8 24 0.84
seam 8 25 0.80
seam 9 9 0.97
seam 9 11 0.86
seam 9 16 0.79
seam 9 20 0.72
seam 9 21 0.69
seam 9 25 0.68
seam 10 6 0.68
seam 10 10 0.86
seam 10 12 0.79
seam 10 21 0.70
seam 10 22 0.69
seam 10 26 0.70
seam 11 5 0.64
seam 11 6 0.67
seam 11 11 0.79
seam 11 13 0.67
seam 11 22 0.71
seam 11 26 0.67
seam 12 5 0.52
seam 12 6 0.53
seam 12 12 0.67
seam 12 21 0.46
seam 12 22 0.53
seam 12 26 0.51
seam 13 6 0.38
seam 13 15 0.40
seam 13 26 0.35
seam 14 9 0.49
seam 14 10 0.43
seam 14 16 0.71
seam 14 18 0.44
seam 14 19 0.44
seam 14 20 0.46
seam 15 9 0.81
seam 15 10 0.79
seam 15 15 0.71
seam 15 18 0.71
seam 15 19 0.76
seam 15 20 0.74
seam 16 2 0.85
seam 16 3 0.88
seam 16 16 0.67
seam 16 18 0.82
seam 16 19 0.99
seam 16 20 0.88
seam 17 2 1.00
seam 17 3 0.79
seam 17 4 0.81
seam 17 17 0.82
seam 17 19 1.00
seam 17 20 0.98
seam 18 2 1.00
seam 18 3 0.94
seam 18 17 0.99
seam 18 18 1.00
seam 18 20 1.00
seam 18 21 0.81
seam 19 2 0.94
seam 19 4 0.92
seam 19 17 0.88
seam 19 18 0.98
seam 19 19 1.00
seam 19 21 0.87
seam 20 5 0.98
seam 20 6 0.87
seam 20 20 0.87
seam 20 22 0.87
seam 20 25 0.97
seam 20 26 0.85
seam 21 6 1.00
seam 21 7 0.97
seam 21 21 0.87
seam 21 23 1.00
seam 21 25 0.91
seam 21 26 1.00
seam 22 6 1.00
seam 22 7 1.00
seam 22 8 0.95
seam 22 22 1.00
seam 22 24 0.99
seam 22 26 1.00
seam 23 7 0.99
seam 23 8 1.00
seam 23 22 0.87
seam 23 23 0.99
seam 23 25 0.89
seam 23 26 0.85
seam 24 6 0.90
seam 24 8 0.86
seam 24 21 0.97
seam 24 22 0.91
seam 24 24 0.89
seam 24 26 0.89
seam 25 6 1.00
seam 25 7 1.00
seam 25 21 0.85
seam 25 22 1.00
seam 25 23 1.00
seam 25 25 0.89
seam 26 6 1.00
seam 26 7 1.00
seam 26 22 1.00
seam 26 23 1.00
seam 26 25 0.98
seam 26 26 1.00
