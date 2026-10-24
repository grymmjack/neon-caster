; NEON-CASTER - sector13's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 134.979   offset 1.5638   bars 24   tail 24
source sector13.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    peak
clip D  bars 17-23   groove
clip E  bars 1-20    intro
clip F  bars 13-16   peak
clip G  bars 9-20    peak
clip H  bars 13-20   peak
clip I  bars 9-12    peak
arrange A*2 E F C G H G H I C G*2
seam 1 3 0.50
seam 1 4 0.67
seam 1 5 0.57
seam 1 6 0.75
seam 1 10 0.43
seam 1 14 0.45
seam 2 2 0.50
seam 2 5 0.61
seam 2 6 0.49
seam 2 7 0.55
seam 2 11 0.44
seam 2 13 0.42
seam 3 2 0.67
seam 3 5 0.54
seam 3 6 0.55
seam 3 10 0.44
seam 3 12 0.47
seam 3 14 0.44
seam 4 1 0.78
seam 4 2 0.57
seam 4 3 0.61
seam 4 4 0.54
seam 4 6 0.56
seam 4 7 0.53
seam 4 13 0.46
seam 5 2 0.75
seam 5 3 0.49
seam 5 4 0.55
seam 5 5 0.56
seam 5 7 0.50
seam 5 14 0.48
seam 6 3 0.55
seam 6 5 0.53
seam 6 6 0.50
seam 6 13 0.47
seam 6 15 0.59
seam 6 23 0.49
seam 7 9 0.50
seam 7 10 0.53
seam 7 13 0.47
seam 7 14 0.49
seam 7 15 0.50
seam 7 16 0.72
seam 8 5 0.31
seam 8 10 0.75
seam 8 11 0.79
seam 8 13 0.77
seam 8 14 0.68
seam 8 15 0.75
seam 8 17 0.90
seam 9 11 0.95
seam 9 12 1.00
seam 9 13 0.93
seam 9 14 1.00
seam 9 18 0.99
seam 9 22 0.97
seam 10 10 0.95
seam 10 12 0.95
seam 10 13 1.00
seam 10 14 0.95
seam 10 15 0.94
seam 10 19 0.99
seam 11 10 1.00
seam 11 11 0.95
seam 11 13 0.97
seam 11 14 1.00
seam 11 18 0.92
seam 11 22 1.00
seam 12 9 0.77
seam 12 10 0.93
seam 12 11 1.00
seam 12 12 0.97
seam 12 14 1.00
seam 12 15 0.96
seam 12 19 0.97
seam 13 10 1.00
seam 13 11 0.95
seam 13 12 1.00
seam 13 13 1.00
seam 13 18 0.98
seam 13 22 1.00
seam 14 11 0.94
seam 14 12 0.84
seam 14 13 0.96
seam 14 14 0.88
seam 14 19 0.91
seam 14 23 1.00
seam 15 10 0.77
seam 15 12 0.76
seam 15 14 0.73
seam 15 15 0.72
seam 15 18 0.77
seam 15 22 0.79
seam 16 9 0.90
seam 16 13 0.81
seam 16 18 0.84
seam 16 19 0.82
seam 16 22 0.84
seam 16 23 0.86
seam 17 10 0.99
seam 17 14 0.98
seam 17 19 0.98
seam 17 20 0.99
seam 17 22 1.00
seam 17 23 0.92
seam 18 11 0.99
seam 18 13 0.97
seam 18 18 0.98
seam 18 21 0.99
seam 18 22 1.00
seam 18 23 1.00
seam 19 10 0.84
seam 19 12 0.89
seam 19 14 0.90
seam 19 18 0.99
seam 19 19 0.86
seam 19 22 0.94
seam 20 1 0.47
seam 20 9 0.55
seam 20 11 0.89
seam 20 13 0.89
seam 20 18 0.85
seam 20 19 0.99
seam 20 22 0.86
seam 20 23 0.92
seam 21 10 0.97
seam 21 12 1.00
seam 21 14 1.00
seam 21 18 1.00
seam 21 19 1.00
seam 21 23 0.95
seam 22 13 0.92
seam 22 15 1.00
seam 22 18 0.92
seam 22 19 1.00
seam 22 21 0.92
seam 22 22 0.95
seam 23 15 0.91
seam 23 17 0.86
seam 23 18 0.93
seam 23 19 0.93
seam 23 22 0.93
seam 23 23 0.95
