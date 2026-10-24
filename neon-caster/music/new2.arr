; NEON-CASTER - new2's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 120.000   offset 1.2525   bars 22   tail 23
source new2.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-6     groove
clip B  bars 7-14    build
clip C  bars 17-22   groove
clip D  bars 1-12    groove
clip E  bars 5-12    groove
clip F  bars 1-4     groove
clip G  bars 9-12    build
clip H  bars 1-8     groove
clip I  bars 5-8     groove
clip J  bars 1-16    groove
arrange D E F D G H D I J G*2 F D
seam 1 3 0.94
seam 1 4 0.95
seam 1 6 0.92
seam 1 10 0.96
seam 1 12 0.83
seam 1 14 1.00
seam 2 2 0.94
seam 2 4 0.94
seam 2 11 1.00
seam 2 13 0.94
seam 2 14 0.92
seam 2 15 1.00
seam 3 2 0.95
seam 3 3 0.94
seam 3 11 0.81
seam 3 12 1.00
seam 3 14 0.82
seam 3 15 0.83
seam 4 1 1.00
seam 4 2 0.74
seam 4 3 0.88
seam 4 9 0.73
seam 4 11 0.73
seam 4 13 0.94
seam 4 15 0.73
seam 5 2 0.92
seam 5 3 0.73
seam 5 5 0.68
seam 5 10 0.73
seam 5 11 0.64
seam 5 14 0.77
seam 6 1 0.28
seam 6 3 0.47
seam 7 2 0.44
seam 7 4 0.44
seam 7 10 0.38
seam 7 12 0.38
seam 7 14 0.37
seam 7 16 0.37
seam 8 1 0.92
seam 8 5 0.73
seam 8 10 0.80
seam 8 11 0.88
seam 8 12 0.83
seam 8 13 1.00
seam 8 14 0.75
seam 8 15 0.88
seam 9 2 0.96
seam 9 11 0.99
seam 9 12 0.92
seam 9 13 0.93
seam 9 14 1.00
seam 9 15 0.93
seam 10 3 1.00
seam 10 10 0.99
seam 10 12 0.97
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 1.00
seam 11 4 1.00
seam 11 10 0.92
seam 11 11 0.97
seam 11 13 0.93
seam 11 14 0.99
seam 11 15 0.99
seam 12 1 1.00
seam 12 3 0.94
seam 12 5 0.94
seam 12 9 1.00
seam 12 11 1.00
seam 12 14 0.95
seam 12 15 0.99
seam 13 2 1.00
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 0.99
seam 13 13 0.95
seam 13 15 0.99
seam 14 3 1.00
seam 14 7 0.33
seam 14 10 0.93
seam 14 11 1.00
seam 14 12 0.99
seam 14 13 0.99
seam 14 14 0.99
seam 15 10 0.74
seam 15 11 0.71
seam 15 12 0.75
seam 15 14 0.84
seam 15 15 0.74
seam 15 22 0.74
seam 16 1 0.30
seam 16 9 0.66
seam 16 18 0.88
seam 16 19 0.83
seam 16 20 0.69
seam 16 21 0.82
seam 16 22 0.79
seam 17 16 0.62
seam 17 17 0.88
seam 17 19 0.89
seam 17 20 0.77
seam 17 21 0.62
seam 17 22 1.00
seam 18 16 0.57
seam 18 17 0.83
seam 18 18 0.89
seam 18 20 0.73
seam 18 21 0.73
seam 18 22 0.80
seam 19 16 0.65
seam 19 17 0.69
seam 19 18 0.77
seam 19 19 0.73
seam 19 21 0.54
seam 19 22 0.73
seam 20 15 0.46
seam 20 17 0.82
seam 20 18 0.62
seam 20 19 0.73
seam 20 20 0.54
seam 20 22 0.62
seam 21 16 0.74
seam 21 17 0.79
seam 21 18 1.00
seam 21 19 0.80
seam 21 20 0.73
seam 21 21 0.62
seam 22 17 0.85
seam 22 18 0.93
seam 22 19 0.97
seam 22 20 0.77
seam 22 21 0.75
seam 22 22 0.94
