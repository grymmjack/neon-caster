; NEON-CASTER - new4's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 144.971   offset 0.0091   bars 28   tail 29
source new4.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-24   build
clip D  bars 25-28   peak
clip E  bars 1-12    intro
clip F  bars 5-8     intro
clip G  bars 1-24    intro
clip H  bars 13-16   groove
clip I  bars 1-4     intro
clip J  bars 21-28   build
clip K  bars 21-24   build
clip L  bars 13-20   groove
arrange E F G H E I G J K L H E I*2
seam 1 3 1.00
seam 1 4 0.85
seam 1 5 0.89
seam 1 6 0.92
seam 1 7 0.85
seam 1 10 0.70
seam 2 2 1.00
seam 2 4 0.98
seam 2 5 0.80
seam 2 6 0.83
seam 2 7 0.81
seam 2 10 0.64
seam 3 2 0.85
seam 3 3 0.98
seam 3 5 0.88
seam 3 6 0.77
seam 3 7 0.80
seam 3 12 0.69
seam 4 1 1.00
seam 4 2 0.89
seam 4 3 0.80
seam 4 4 0.88
seam 4 6 0.90
seam 4 7 0.81
seam 4 13 0.83
seam 5 2 0.92
seam 5 5 0.90
seam 5 7 1.00
seam 5 10 0.85
seam 5 14 0.86
seam 5 15 0.85
seam 6 2 0.85
seam 6 3 0.81
seam 6 5 0.81
seam 6 6 1.00
seam 6 10 0.84
seam 6 15 0.89
seam 8 1 0.82
seam 8 5 0.12
seam 9 6 0.85
seam 9 11 1.00
seam 9 12 1.00
seam 9 13 0.98
seam 9 14 1.00
seam 9 15 1.00
seam 10 6 0.83
seam 10 10 1.00
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 1.00
seam 11 6 0.80
seam 11 10 1.00
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 0.98
seam 11 15 1.00
seam 12 1 0.70
seam 12 5 0.83
seam 12 10 0.98
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 0.98
seam 13 6 0.86
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 0.98
seam 13 13 1.00
seam 13 15 1.00
seam 14 7 0.89
seam 14 10 1.00
seam 14 11 1.00
seam 14 12 1.00
seam 14 13 0.98
seam 14 14 1.00
seam 15 10 0.54
seam 15 11 0.53
seam 15 12 0.58
seam 15 13 0.58
seam 15 14 0.54
seam 15 15 0.54
seam 16 1 0.53
seam 16 9 0.12
seam 16 12 0.44
seam 16 13 0.49
seam 16 14 0.46
seam 16 18 0.44
seam 16 21 0.46
seam 16 22 0.44
seam 17 19 0.99
seam 17 20 0.87
seam 17 21 0.93
seam 17 22 1.00
seam 17 23 1.00
seam 17 24 0.86
seam 18 18 0.99
seam 18 20 0.89
seam 18 21 0.84
seam 18 22 1.00
seam 18 23 0.97
seam 18 24 0.85
seam 19 18 0.87
seam 19 19 0.89
seam 19 21 0.82
seam 19 22 0.87
seam 19 23 0.92
seam 19 24 0.97
seam 20 13 0.65
seam 20 18 0.93
seam 20 19 0.84
seam 20 22 0.91
seam 20 23 0.91
seam 20 24 0.83
seam 20 25 0.82
seam 21 18 1.00
seam 21 19 1.00
seam 21 20 0.87
seam 21 21 0.91
seam 21 23 0.99
seam 21 24 0.86
seam 22 18 1.00
seam 22 19 0.97
seam 22 20 0.92
seam 22 21 0.91
seam 22 22 0.99
seam 22 24 0.89
seam 23 18 0.86
seam 23 19 0.85
seam 23 20 0.97
seam 23 21 0.83
seam 23 22 0.86
seam 23 23 0.89
seam 24 1 0.41
seam 24 13 0.60
seam 24 17 0.39
seam 24 18 0.74
seam 24 19 0.75
seam 24 21 0.82
seam 24 24 0.73
seam 24 26 0.78
seam 24 28 0.73
seam 25 18 0.61
seam 25 20 0.59
seam 25 21 0.59
seam 25 25 0.78
seam 25 27 0.88
seam 25 28 0.92
seam 26 19 0.57
seam 26 20 0.57
seam 26 22 0.55
seam 26 25 0.73
seam 26 26 0.88
seam 26 28 0.85
seam 27 20 0.64
seam 27 21 0.54
seam 27 24 0.59
seam 27 25 0.73
seam 27 26 0.92
seam 27 27 0.85
seam 28 20 0.53
seam 28 21 0.52
seam 28 25 0.71
seam 28 26 0.86
seam 28 27 0.86
seam 28 28 0.93
