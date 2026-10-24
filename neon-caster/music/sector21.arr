; NEON-CASTER - sector21's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 127.981   offset 0.0078   bars 24   tail 25
source sector21.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-24   peak
clip D  bars 1-12    intro
clip E  bars 1-24    intro
clip F  bars 13-24   groove
clip G  bars 21-24   peak
clip H  bars 5-16    intro
clip I  bars 1-4     intro
clip J  bars 5-8     intro
arrange D E F G H I E F J I
seam 1 3 0.98
seam 1 4 0.92
seam 1 6 0.93
seam 1 7 0.85
seam 1 10 0.81
seam 1 14 0.68
seam 2 2 0.98
seam 2 4 1.00
seam 2 5 0.78
seam 2 6 0.70
seam 2 7 1.00
seam 2 11 0.81
seam 3 2 0.92
seam 3 3 1.00
seam 3 5 0.74
seam 3 6 0.66
seam 3 7 0.86
seam 3 11 0.71
seam 4 1 0.86
seam 4 2 0.66
seam 4 3 0.78
seam 4 4 0.74
seam 4 6 0.53
seam 4 7 0.67
seam 4 13 0.56
seam 5 2 0.93
seam 5 3 0.70
seam 5 4 0.66
seam 5 7 0.65
seam 5 10 0.58
seam 5 14 0.55
seam 6 2 0.85
seam 6 3 1.00
seam 6 4 0.86
seam 6 5 0.67
seam 6 6 0.65
seam 6 11 0.60
seam 7 2 0.42
seam 7 3 0.48
seam 7 4 0.54
seam 7 7 0.40
seam 7 19 0.35
seam 7 20 0.36
seam 8 1 0.76
seam 8 5 0.39
seam 8 11 0.45
seam 8 13 0.40
seam 8 19 0.43
seam 8 20 0.40
seam 8 21 0.43
seam 8 24 0.40
seam 9 11 0.91
seam 9 12 0.83
seam 9 14 0.90
seam 9 15 0.87
seam 9 18 0.97
seam 9 19 1.00
seam 10 10 0.91
seam 10 12 0.96
seam 10 14 0.96
seam 10 15 0.91
seam 10 19 0.86
seam 10 20 0.94
seam 11 10 0.83
seam 11 11 0.96
seam 11 14 0.80
seam 11 18 0.78
seam 11 19 0.79
seam 11 24 0.82
seam 12 1 0.63
seam 12 10 0.76
seam 12 11 0.72
seam 12 12 0.72
seam 12 14 0.67
seam 12 15 0.67
seam 12 19 0.83
seam 13 10 0.90
seam 13 11 0.96
seam 13 12 0.80
seam 13 15 0.83
seam 13 19 0.77
seam 13 20 0.79
seam 14 10 0.87
seam 14 11 0.91
seam 14 14 0.83
seam 14 19 0.76
seam 14 21 0.78
seam 14 23 0.77
seam 15 11 0.37
seam 16 1 0.56
seam 16 5 0.19
seam 16 9 0.24
seam 16 11 0.35
seam 16 18 0.35
seam 17 10 0.97
seam 17 19 1.00
seam 17 21 0.88
seam 17 22 0.92
seam 17 23 0.92
seam 17 24 0.92
seam 18 10 1.00
seam 18 18 1.00
seam 18 20 1.00
seam 18 21 0.97
seam 18 22 0.98
seam 18 24 1.00
seam 19 11 0.94
seam 19 19 1.00
seam 19 21 0.99
seam 19 22 0.97
seam 19 23 0.98
seam 19 24 0.91
seam 20 18 0.88
seam 20 19 0.97
seam 20 20 0.99
seam 20 22 0.99
seam 20 23 1.00
seam 20 24 0.97
seam 21 18 0.92
seam 21 19 0.98
seam 21 20 0.97
seam 21 21 0.99
seam 21 23 1.00
seam 21 24 1.00
seam 22 18 0.92
seam 22 19 0.91
seam 22 20 0.98
seam 22 21 1.00
seam 22 22 1.00
seam 22 24 1.00
seam 23 18 0.92
seam 23 19 1.00
seam 23 20 0.91
seam 23 21 0.97
seam 23 22 1.00
seam 23 23 1.00
seam 24 1 0.30
seam 24 5 0.52
seam 24 13 0.69
seam 24 17 0.07
seam 24 19 1.00
seam 24 20 1.00
seam 24 21 0.97
seam 24 22 0.97
seam 24 23 1.00
seam 24 24 1.00
