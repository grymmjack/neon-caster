; NEON-CASTER - huge4's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 134.969   offset 0.0200   bars 25   tail 25
source huge4.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-24   groove
clip D  bars 1-20    intro
clip E  bars 13-20   groove
clip F  bars 5-12    intro
clip G  bars 5-8     intro
clip H  bars 1-24    intro
clip I  bars 21-24   groove
clip J  bars 13-16   groove
clip K  bars 1-16    intro
arrange D E F G H I*2 E J A K A
seam 1 4 0.73
seam 1 6 0.68
seam 1 10 0.96
seam 1 12 0.71
seam 1 14 0.75
seam 1 18 0.81
seam 2 5 1.00
seam 2 7 1.00
seam 2 11 0.96
seam 2 13 0.91
seam 2 15 0.83
seam 2 19 0.79
seam 3 2 0.73
seam 3 6 1.00
seam 3 12 1.00
seam 3 14 0.91
seam 3 20 0.84
seam 3 22 0.80
seam 4 3 1.00
seam 4 7 1.00
seam 4 11 0.92
seam 4 13 0.89
seam 4 15 0.78
seam 4 21 0.86
seam 5 4 1.00
seam 5 5 0.72
seam 5 12 0.91
seam 5 14 0.77
seam 5 20 0.78
seam 5 22 0.79
seam 6 3 1.00
seam 6 5 1.00
seam 6 11 0.78
seam 6 13 0.84
seam 6 15 0.69
seam 6 21 0.77
seam 7 4 0.55
seam 7 6 0.52
seam 7 12 0.61
seam 7 14 0.54
seam 7 22 0.54
seam 7 24 0.57
seam 8 1 1.00
seam 8 5 0.35
seam 8 11 0.45
seam 8 13 0.53
seam 8 15 0.46
seam 8 17 0.41
seam 8 21 0.44
seam 8 23 0.43
seam 9 2 0.96
seam 9 12 0.76
seam 9 14 0.83
seam 9 18 1.00
seam 9 20 0.76
seam 9 22 0.77
seam 10 3 0.96
seam 10 13 1.00
seam 10 15 1.00
seam 10 19 1.00
seam 10 21 0.99
seam 10 23 0.99
seam 11 4 1.00
seam 11 6 0.91
seam 11 14 1.00
seam 11 20 1.00
seam 11 22 1.00
seam 11 24 0.88
seam 12 3 0.91
seam 12 5 0.89
seam 12 11 1.00
seam 12 15 1.00
seam 12 19 0.93
seam 12 21 0.98
seam 12 23 1.00
seam 13 4 0.91
seam 13 11 0.92
seam 13 12 1.00
seam 13 15 0.89
seam 13 20 0.96
seam 13 22 0.98
seam 14 11 1.00
seam 14 13 1.00
seam 14 14 0.89
seam 14 19 0.90
seam 14 21 0.87
seam 14 23 1.00
seam 15 12 0.44
seam 15 14 0.51
seam 15 15 0.42
seam 15 20 0.39
seam 15 22 0.40
seam 15 24 0.49
seam 16 1 0.87
seam 16 9 0.41
seam 16 11 0.36
seam 16 13 0.35
seam 16 15 0.37
seam 16 19 0.39
seam 16 21 0.39
seam 16 23 0.37
seam 17 2 0.81
seam 17 10 1.00
seam 17 14 0.79
seam 17 19 0.77
seam 17 20 0.88
seam 17 22 0.91
seam 18 11 1.00
seam 18 13 0.93
seam 18 15 0.90
seam 18 20 0.83
seam 18 21 1.00
seam 18 23 1.00
seam 19 4 0.84
seam 19 12 1.00
seam 19 14 0.96
seam 19 18 0.88
seam 19 22 1.00
seam 19 24 1.00
seam 20 1 0.53
seam 20 5 0.86
seam 20 11 0.99
seam 20 13 0.98
seam 20 15 0.87
seam 20 19 1.00
seam 20 23 1.00
seam 21 12 1.00
seam 21 14 0.98
seam 21 18 0.91
seam 21 20 1.00
seam 21 21 0.84
seam 21 24 1.00
seam 22 11 0.99
seam 22 13 1.00
seam 22 15 1.00
seam 22 19 1.00
seam 22 21 1.00
seam 22 22 0.80
seam 23 12 0.88
seam 23 14 0.87
seam 23 18 0.76
seam 23 20 1.00
seam 23 22 1.00
seam 23 23 0.73
seam 24 1 0.30
seam 24 13 0.80
seam 24 17 0.24
seam 24 19 0.80
seam 24 20 0.86
seam 24 21 0.86
seam 24 22 0.86
seam 24 23 0.86
seam 24 24 0.86
