; NEON-CASTER - sector15's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 140.020   offset 0.0340   bars 26   tail 25
source sector15.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    peak
clip D  bars 17-24   groove
clip E  bars 1-24    intro
clip F  bars 21-24   groove
clip G  bars 13-20   peak
clip H  bars 13-24   peak
clip I  bars 13-16   peak
clip J  bars 9-12    peak
arrange A E F G H F I J A E G H I J A
seam 1 3 0.53
seam 1 4 0.57
seam 1 6 0.64
seam 1 11 0.35
seam 2 2 0.53
seam 2 4 0.76
seam 2 5 0.54
seam 2 7 0.47
seam 2 8 0.41
seam 3 2 0.57
seam 3 3 0.76
seam 3 5 0.50
seam 3 6 0.36
seam 3 7 0.39
seam 3 8 0.42
seam 4 1 0.89
seam 4 3 0.54
seam 4 4 0.50
seam 4 6 0.38
seam 4 7 0.48
seam 4 8 0.41
seam 4 9 0.41
seam 5 2 0.64
seam 5 4 0.36
seam 5 5 0.38
seam 5 7 0.62
seam 5 8 0.42
seam 6 3 0.47
seam 6 4 0.39
seam 6 5 0.48
seam 6 6 0.62
seam 6 8 0.51
seam 7 3 0.41
seam 7 4 0.42
seam 7 5 0.41
seam 7 6 0.42
seam 7 7 0.51
seam 8 5 0.41
seam 8 10 0.48
seam 8 11 0.43
seam 8 13 0.47
seam 8 14 0.43
seam 8 17 0.64
seam 8 21 0.42
seam 9 11 0.99
seam 9 12 0.96
seam 9 13 0.96
seam 9 14 1.00
seam 9 15 0.96
seam 9 22 0.83
seam 10 10 0.99
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 1.00
seam 10 19 0.79
seam 11 10 0.96
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 1.00
seam 11 16 0.79
seam 12 1 0.52
seam 12 9 0.47
seam 12 10 0.96
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 1.00
seam 12 21 0.81
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 1.00
seam 13 22 0.82
seam 14 10 0.96
seam 14 11 1.00
seam 14 12 1.00
seam 14 13 1.00
seam 14 14 1.00
seam 14 19 0.76
seam 15 10 0.73
seam 15 11 0.72
seam 15 12 0.79
seam 15 13 0.73
seam 15 14 0.75
seam 15 15 0.73
seam 16 9 0.64
seam 16 11 0.56
seam 16 13 0.60
seam 16 19 0.62
seam 16 21 0.68
seam 16 23 0.60
seam 17 19 0.91
seam 17 20 0.90
seam 17 21 0.88
seam 17 22 0.93
seam 17 23 0.86
seam 17 24 0.88
seam 18 18 0.91
seam 18 20 0.97
seam 18 21 1.00
seam 18 22 1.00
seam 18 23 1.00
seam 18 24 0.99
seam 19 18 0.90
seam 19 19 0.97
seam 19 21 0.96
seam 19 22 1.00
seam 19 23 0.98
seam 19 24 1.00
seam 20 13 0.81
seam 20 18 0.88
seam 20 19 1.00
seam 20 20 0.96
seam 20 22 0.99
seam 20 23 1.00
seam 20 24 0.98
seam 21 18 0.93
seam 21 19 1.00
seam 21 20 1.00
seam 21 21 0.99
seam 21 23 1.00
seam 21 24 1.00
seam 22 18 0.86
seam 22 19 1.00
seam 22 20 0.98
seam 22 21 1.00
seam 22 22 1.00
seam 22 24 1.00
seam 23 18 0.88
seam 23 19 0.99
seam 23 20 1.00
seam 23 21 0.98
seam 23 22 1.00
seam 23 23 1.00
seam 24 1 0.30
seam 24 13 0.80
seam 24 17 0.50
seam 24 19 0.99
seam 24 20 0.99
seam 24 21 1.00
seam 24 22 1.00
seam 24 23 1.00
seam 24 24 1.00
