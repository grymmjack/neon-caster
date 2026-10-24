; NEON-CASTER - remix2's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 145.000   offset 0.0269   bars 27   tail 28
source remix2.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-12    build
clip C  bars 13-16   groove
clip D  bars 17-20   groove
clip E  bars 21-27   groove
clip F  bars 1-8     intro
clip G  bars 5-8     build
clip H  bars 5-24    build
clip I  bars 21-24   groove
clip J  bars 13-24   groove
clip K  bars 17-24   groove
clip L  bars 13-20   groove
arrange F G H I J*3 K L J K J
seam 1 3 1.00
seam 1 4 0.87
seam 1 5 0.60
seam 1 7 0.51
seam 1 8 0.54
seam 1 10 0.50
seam 2 2 1.00
seam 2 4 0.84
seam 2 5 0.62
seam 2 7 0.50
seam 2 8 0.52
seam 2 9 0.50
seam 3 2 0.87
seam 3 3 0.84
seam 3 5 0.52
seam 3 7 0.44
seam 3 8 0.54
seam 3 9 0.44
seam 4 2 0.60
seam 4 3 0.62
seam 4 6 0.61
seam 4 8 0.59
seam 4 9 0.74
seam 4 10 0.63
seam 5 5 0.61
seam 5 7 0.98
seam 5 8 0.88
seam 5 9 0.83
seam 5 10 0.95
seam 5 11 0.75
seam 6 5 0.59
seam 6 6 0.98
seam 6 8 0.92
seam 6 9 0.88
seam 6 10 0.92
seam 6 11 0.80
seam 7 6 0.88
seam 7 7 0.92
seam 7 9 0.87
seam 7 10 0.92
seam 7 11 0.73
seam 7 12 0.68
seam 8 5 0.74
seam 8 6 0.83
seam 8 7 0.88
seam 8 8 0.87
seam 8 10 0.93
seam 8 11 0.74
seam 9 5 0.63
seam 9 6 0.95
seam 9 7 0.92
seam 9 8 0.92
seam 9 9 0.93
seam 9 11 0.83
seam 10 6 0.75
seam 10 7 0.80
seam 10 8 0.73
seam 10 9 0.74
seam 10 10 0.83
seam 10 12 0.78
seam 11 11 0.78
seam 11 13 0.73
seam 11 16 0.76
seam 11 23 0.70
seam 11 24 0.75
seam 11 27 0.69
seam 12 14 0.78
seam 12 15 0.78
seam 12 23 0.78
seam 12 24 0.79
seam 12 25 0.86
seam 12 26 0.79
seam 13 15 1.00
seam 13 22 0.99
seam 13 23 0.96
seam 13 24 0.98
seam 13 26 1.00
seam 13 27 0.99
seam 14 14 1.00
seam 14 22 0.98
seam 14 23 0.99
seam 14 25 0.97
seam 14 26 1.00
seam 14 27 1.00
seam 15 15 0.95
seam 15 22 0.95
seam 15 23 0.93
seam 15 24 1.00
seam 15 26 0.95
seam 15 27 0.99
seam 16 16 0.72
seam 16 18 0.76
seam 16 19 0.70
seam 16 24 0.72
seam 16 25 0.73
seam 16 27 0.71
seam 17 17 0.76
seam 17 19 0.97
seam 17 20 0.86
seam 17 21 0.65
seam 17 24 0.54
seam 17 25 0.58
seam 18 17 0.70
seam 18 18 0.97
seam 18 20 0.84
seam 18 21 0.64
seam 18 24 0.57
seam 18 25 0.57
seam 19 16 0.52
seam 19 17 0.68
seam 19 18 0.86
seam 19 19 0.84
seam 19 21 0.55
seam 19 24 0.54
seam 20 15 0.65
seam 20 18 0.65
seam 20 19 0.64
seam 20 24 0.65
seam 20 25 0.76
seam 20 26 0.66
seam 21 14 0.99
seam 21 15 0.98
seam 21 16 0.95
seam 21 23 0.98
seam 21 26 1.00
seam 21 27 1.00
seam 22 14 0.96
seam 22 15 0.99
seam 22 22 0.98
seam 22 24 0.99
seam 22 26 0.96
seam 22 27 1.00
seam 23 14 0.98
seam 23 16 1.00
seam 23 23 0.99
seam 23 25 0.96
seam 23 26 0.96
seam 23 27 1.00
seam 24 14 0.94
seam 24 15 0.97
seam 24 23 0.94
seam 24 24 0.96
seam 24 26 0.98
seam 24 27 0.96
seam 25 14 1.00
seam 25 15 1.00
seam 25 22 1.00
seam 25 24 0.96
seam 25 25 0.98
seam 25 27 1.00
seam 26 15 1.00
seam 26 16 0.99
seam 26 22 1.00
seam 26 23 1.00
seam 26 24 1.00
seam 26 26 1.00
seam 27 22 1.00
seam 27 23 1.00
seam 27 24 1.00
seam 27 25 1.00
seam 27 26 1.00
seam 27 27 1.00
