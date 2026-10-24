; NEON-CASTER - remix8's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 139.940   offset 0.6194   bars 26   tail 27
source remix8.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-20   groove
clip D  bars 21-26   peak
clip E  bars 5-8     intro
clip F  bars 5-24    intro
clip G  bars 13-24   groove
clip H  bars 9-12    groove
clip I  bars 9-24    groove
clip J  bars 9-20    groove
arrange A E F G*2 H I*2 G H J
seam 1 3 0.72
seam 1 4 0.46
seam 1 5 0.50
seam 1 6 0.55
seam 1 7 0.43
seam 1 22 0.39
seam 2 2 0.72
seam 2 4 0.78
seam 2 5 0.70
seam 2 6 0.81
seam 2 7 0.72
seam 2 8 0.56
seam 3 3 0.78
seam 3 5 0.78
seam 3 6 0.87
seam 3 7 0.91
seam 3 8 0.73
seam 3 9 0.59
seam 4 3 0.70
seam 4 4 0.78
seam 4 6 1.00
seam 4 7 0.97
seam 4 8 0.82
seam 4 9 0.72
seam 5 3 0.81
seam 5 4 0.87
seam 5 5 1.00
seam 5 7 1.00
seam 5 8 0.89
seam 5 9 0.72
seam 6 3 0.72
seam 6 4 0.91
seam 6 5 0.97
seam 6 6 1.00
seam 6 8 0.95
seam 6 9 0.81
seam 7 4 0.73
seam 7 5 0.82
seam 7 6 0.89
seam 7 7 0.95
seam 7 9 0.91
seam 7 10 0.79
seam 8 8 0.91
seam 8 10 0.96
seam 8 11 0.88
seam 8 12 0.85
seam 8 13 0.84
seam 8 14 0.85
seam 9 9 0.96
seam 9 11 1.00
seam 9 12 1.00
seam 9 13 1.00
seam 9 14 1.00
seam 9 15 1.00
seam 10 10 1.00
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 1.00
seam 10 22 0.89
seam 11 10 1.00
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 1.00
seam 11 22 0.93
seam 12 10 1.00
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 1.00
seam 12 22 0.96
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 1.00
seam 13 22 0.97
seam 14 10 1.00
seam 14 11 1.00
seam 14 12 1.00
seam 14 13 1.00
seam 14 14 1.00
seam 14 23 0.89
seam 15 10 0.82
seam 15 11 0.83
seam 15 12 0.81
seam 15 13 0.87
seam 15 14 0.87
seam 15 15 0.79
seam 16 11 0.64
seam 16 13 0.66
seam 16 14 0.71
seam 16 15 0.65
seam 16 22 0.65
seam 16 24 0.65
seam 17 13 0.66
seam 17 14 0.69
seam 17 15 0.67
seam 17 22 0.66
seam 17 23 0.64
seam 17 24 0.65
seam 18 10 0.44
seam 18 11 0.51
seam 18 12 0.42
seam 18 13 0.42
seam 18 14 0.46
seam 18 15 0.47
seam 20 10 0.56
seam 20 14 0.53
seam 20 22 0.59
seam 20 23 0.57
seam 20 24 0.58
seam 20 25 0.54
seam 21 12 0.93
seam 21 13 0.96
seam 21 14 0.97
seam 21 23 1.00
seam 21 24 1.00
seam 21 25 1.00
seam 22 12 0.91
seam 22 13 0.96
seam 22 14 0.96
seam 22 22 1.00
seam 22 24 1.00
seam 22 25 1.00
seam 23 12 0.89
seam 23 13 0.95
seam 23 14 0.95
seam 23 22 1.00
seam 23 23 1.00
seam 23 25 1.00
seam 24 13 0.88
seam 24 14 0.89
seam 24 15 0.85
seam 24 22 1.00
seam 24 23 1.00
seam 24 24 1.00
seam 25 13 0.76
seam 25 14 0.78
seam 25 22 0.91
seam 25 23 0.88
seam 25 24 0.87
seam 25 25 0.77
seam 26 13 0.71
seam 26 14 0.72
seam 26 22 0.79
seam 26 23 0.80
seam 26 24 0.76
seam 26 26 0.77
