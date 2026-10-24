; NEON-CASTER - huge1's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 135.000   offset 0.0252   bars 25   tail 25
source huge1.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    peak
clip D  bars 17-24   peak
clip E  bars 1-24    intro
clip F  bars 17-20   peak
clip G  bars 13-16   peak
clip H  bars 9-12    peak
clip I  bars 1-20    intro
clip J  bars 9-20    peak
clip K  bars 1-16    intro
arrange A E F G H I A E J K A
seam 1 3 0.68
seam 1 6 0.84
seam 1 14 0.65
seam 1 18 0.70
seam 1 19 0.68
seam 1 20 0.65
seam 2 2 0.68
seam 2 4 1.00
seam 2 5 0.58
seam 2 6 0.58
seam 2 7 0.70
seam 2 11 0.54
seam 3 2 0.48
seam 3 3 1.00
seam 3 5 0.62
seam 3 7 0.53
seam 3 12 0.52
seam 3 20 0.42
seam 4 1 1.00
seam 4 3 0.58
seam 4 4 0.62
seam 4 6 0.53
seam 4 13 0.69
seam 4 20 0.54
seam 4 21 0.57
seam 5 2 0.84
seam 5 7 0.75
seam 5 14 0.92
seam 5 19 0.76
seam 5 20 0.76
seam 5 22 0.74
seam 6 11 0.77
seam 6 12 0.76
seam 6 15 0.98
seam 6 19 0.82
seam 6 20 0.84
seam 6 23 0.76
seam 7 7 0.68
seam 7 15 0.65
seam 7 16 1.00
seam 7 19 0.62
seam 7 20 0.67
seam 7 24 0.70
seam 8 5 0.30
seam 8 13 0.63
seam 8 16 0.65
seam 8 17 1.00
seam 8 20 0.59
seam 8 21 0.68
seam 8 23 0.61
seam 9 11 0.81
seam 9 14 0.97
seam 9 18 1.00
seam 9 19 0.91
seam 9 20 0.82
seam 9 22 0.84
seam 10 12 1.00
seam 10 13 0.87
seam 10 14 0.90
seam 10 15 1.00
seam 10 19 1.00
seam 10 20 1.00
seam 11 11 1.00
seam 11 13 0.77
seam 11 14 0.84
seam 11 15 0.99
seam 11 19 0.93
seam 11 20 1.00
seam 12 1 0.88
seam 12 9 0.63
seam 12 11 0.87
seam 12 12 0.77
seam 12 15 0.78
seam 12 19 0.90
seam 12 20 0.84
seam 12 21 0.95
seam 13 6 0.92
seam 13 10 0.97
seam 13 11 0.90
seam 13 18 0.98
seam 13 19 0.94
seam 13 22 0.91
seam 14 7 0.98
seam 14 11 1.00
seam 14 12 0.99
seam 14 19 0.98
seam 14 20 0.95
seam 14 23 0.85
seam 15 8 1.00
seam 15 15 0.83
seam 15 19 0.77
seam 15 20 0.80
seam 15 21 0.77
seam 15 24 0.79
seam 16 1 0.82
seam 16 9 1.00
seam 16 13 0.69
seam 16 18 0.76
seam 16 19 0.74
seam 16 21 0.81
seam 16 22 0.72
seam 16 23 0.73
seam 17 10 1.00
seam 17 14 0.98
seam 17 19 0.96
seam 17 20 0.93
seam 17 22 1.00
seam 17 23 0.92
seam 18 11 1.00
seam 18 15 0.98
seam 18 18 0.96
seam 18 20 1.00
seam 18 22 0.98
seam 18 23 0.97
seam 19 11 1.00
seam 19 12 1.00
seam 19 15 0.95
seam 19 19 1.00
seam 19 22 0.94
seam 19 23 1.00
seam 20 1 0.85
seam 20 9 0.68
seam 20 13 0.95
seam 20 17 0.81
seam 20 19 0.94
seam 20 20 0.90
seam 20 22 0.90
seam 20 23 0.91
seam 20 24 0.91
seam 21 14 0.91
seam 21 18 1.00
seam 21 19 0.98
seam 21 20 0.94
seam 21 23 1.00
seam 21 24 0.91
seam 22 18 0.92
seam 22 19 0.97
seam 22 20 1.00
seam 22 21 0.91
seam 22 22 1.00
seam 22 24 1.00
seam 23 16 0.79
seam 23 19 0.83
seam 23 20 0.85
seam 23 21 0.91
seam 23 22 0.91
seam 23 23 1.00
seam 24 1 0.30
seam 24 9 0.67
seam 24 17 0.78
seam 24 18 0.75
seam 24 21 0.80
seam 24 22 0.91
seam 24 23 1.00
seam 24 24 1.00
