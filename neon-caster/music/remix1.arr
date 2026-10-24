; NEON-CASTER - remix1's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 145.000   offset 1.4551   bars 27   tail 28
source remix1.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-7     intro
clip B  bars 8-15    groove
clip C  bars 16-23   groove
clip D  bars 1-8     intro
clip E  bars 21-24   groove
clip F  bars 5-20    intro
clip G  bars 17-20   groove
clip H  bars 9-16    groove
clip I  bars 9-12    groove
clip J  bars 13-16   groove
clip K  bars 13-24   groove
clip L  bars 5-12    intro
clip M  bars 1-24    intro
clip N  bars 1-12    intro
clip O  bars 9-24    groove
arrange D E F G H I G J K L E M N O
seam 1 3 0.67
seam 1 4 0.63
seam 1 5 0.52
seam 1 6 0.82
seam 1 7 0.50
seam 1 26 0.83
seam 2 2 0.67
seam 2 4 0.60
seam 2 6 0.54
seam 2 7 0.79
seam 2 25 0.56
seam 2 27 0.80
seam 3 2 0.63
seam 3 3 0.60
seam 3 6 0.62
seam 3 7 0.58
seam 3 8 0.65
seam 3 26 0.71
seam 4 6 0.62
seam 4 7 0.68
seam 4 21 0.55
seam 4 25 0.98
seam 4 26 0.63
seam 4 27 0.79
seam 5 2 0.82
seam 5 4 0.62
seam 5 5 0.62
seam 5 7 0.71
seam 5 26 1.00
seam 5 27 0.66
seam 6 3 0.79
seam 6 5 0.68
seam 6 6 0.71
seam 6 25 0.77
seam 6 26 0.65
seam 6 27 0.95
seam 7 4 0.65
seam 7 12 0.66
seam 7 16 0.65
seam 7 20 0.72
seam 7 24 0.55
seam 7 26 0.58
seam 8 11 0.97
seam 8 13 1.00
seam 8 15 0.88
seam 8 17 1.00
seam 8 19 0.90
seam 8 21 1.00
seam 9 12 0.97
seam 9 14 1.00
seam 9 16 0.93
seam 9 18 1.00
seam 9 20 0.91
seam 9 22 1.00
seam 10 9 0.97
seam 10 15 1.00
seam 10 17 1.00
seam 10 19 1.00
seam 10 21 1.00
seam 10 23 1.00
seam 11 10 0.97
seam 11 14 0.88
seam 11 16 1.00
seam 11 18 1.00
seam 11 20 1.00
seam 11 22 0.92
seam 12 9 1.00
seam 12 11 0.93
seam 12 17 1.00
seam 12 19 0.92
seam 12 21 1.00
seam 12 23 0.88
seam 13 10 1.00
seam 13 15 0.90
seam 13 18 1.00
seam 13 19 0.93
seam 13 20 0.89
seam 13 22 1.00
seam 14 11 1.00
seam 14 17 0.91
seam 14 19 1.00
seam 14 21 0.96
seam 14 22 0.91
seam 14 23 1.00
seam 15 10 0.93
seam 15 12 1.00
seam 15 18 0.97
seam 15 20 1.00
seam 15 22 1.00
seam 15 23 0.89
seam 16 9 1.00
seam 16 11 1.00
seam 16 13 1.00
seam 16 19 0.92
seam 16 21 1.00
seam 16 23 0.97
seam 17 10 1.00
seam 17 12 1.00
seam 17 14 1.00
seam 17 16 0.97
seam 17 20 0.92
seam 17 22 1.00
seam 18 11 1.00
seam 18 14 0.93
seam 18 15 1.00
seam 18 17 0.92
seam 18 21 1.00
seam 18 23 1.00
seam 19 10 0.91
seam 19 12 1.00
seam 19 16 1.00
seam 19 18 0.92
seam 19 19 0.89
seam 19 22 0.94
seam 20 9 1.00
seam 20 11 1.00
seam 20 13 1.00
seam 20 15 0.96
seam 20 17 1.00
seam 20 19 1.00
seam 21 10 1.00
seam 21 12 0.92
seam 21 14 1.00
seam 21 16 1.00
seam 21 18 1.00
seam 21 20 0.94
seam 22 11 1.00
seam 22 15 1.00
seam 22 17 0.97
seam 22 19 1.00
seam 22 21 0.94
seam 22 22 0.92
seam 23 10 0.71
seam 23 12 0.80
seam 23 16 0.80
seam 23 18 0.71
seam 23 20 0.83
seam 23 22 0.70
seam 24 5 0.98
seam 24 6 0.60
seam 24 7 0.77
seam 24 9 0.59
seam 24 21 0.62
seam 24 27 0.81
seam 25 2 0.83
seam 25 4 0.71
seam 25 5 0.63
seam 25 6 1.00
seam 25 7 0.65
seam 25 27 0.62
seam 26 3 0.80
seam 26 5 0.79
seam 26 6 0.66
seam 26 7 0.95
seam 26 25 0.81
seam 26 26 0.62
seam 27 4 0.71
seam 27 5 0.70
seam 27 6 0.75
seam 27 7 0.81
seam 27 26 0.78
seam 27 27 0.80
