; NEON-CASTER - sector11's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 120.000   offset 1.0118   bars 22   tail 23
source sector11.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     groove
clip B  bars 9-16    build
clip C  bars 17-22   peak
clip D  bars 1-12    groove
clip E  bars 1-20    groove
clip F  bars 13-20   build
clip G  bars 9-12    build
clip H  bars 1-4     groove
clip I  bars 5-20    groove
clip J  bars 5-12    groove
arrange D E F G H*2 D I F G J H
seam 1 3 1.00
seam 1 4 1.00
seam 1 5 1.00
seam 1 6 1.00
seam 1 7 1.00
seam 1 12 0.67
seam 2 2 1.00
seam 2 4 0.99
seam 2 5 1.00
seam 2 6 1.00
seam 2 7 1.00
seam 2 12 0.64
seam 3 2 1.00
seam 3 3 0.99
seam 3 5 0.99
seam 3 6 1.00
seam 3 7 1.00
seam 3 12 0.64
seam 4 1 1.00
seam 4 2 1.00
seam 4 3 1.00
seam 4 4 0.99
seam 4 6 1.00
seam 4 7 1.00
seam 4 13 0.63
seam 5 2 1.00
seam 5 3 1.00
seam 5 4 1.00
seam 5 5 1.00
seam 5 7 1.00
seam 5 12 0.67
seam 6 2 1.00
seam 6 3 1.00
seam 6 4 1.00
seam 6 5 1.00
seam 6 6 1.00
seam 6 12 0.67
seam 7 2 0.46
seam 7 3 0.47
seam 7 4 0.46
seam 7 6 0.46
seam 7 20 0.46
seam 7 22 0.51
seam 8 1 0.32
seam 8 11 0.38
seam 8 13 0.36
seam 8 19 0.42
seam 8 21 0.51
seam 9 11 0.68
seam 9 12 0.77
seam 9 13 0.65
seam 9 18 0.68
seam 9 19 0.59
seam 9 20 0.59
seam 10 10 0.68
seam 10 12 0.96
seam 10 13 1.00
seam 10 14 0.78
seam 10 19 0.83
seam 10 20 0.77
seam 11 10 0.77
seam 11 11 0.96
seam 11 13 0.92
seam 11 14 0.79
seam 11 19 0.76
seam 11 20 0.80
seam 12 1 0.67
seam 12 5 0.63
seam 12 9 0.36
seam 12 11 1.00
seam 12 12 0.92
seam 12 14 0.74
seam 12 18 0.67
seam 12 19 0.82
seam 12 20 0.78
seam 13 10 0.58
seam 13 11 0.78
seam 13 12 0.79
seam 13 13 0.74
seam 13 19 0.64
seam 13 20 0.63
seam 16 9 0.02
seam 17 10 0.68
seam 17 12 0.67
seam 17 13 0.67
seam 17 19 0.75
seam 17 20 0.88
seam 17 22 0.80
seam 18 11 0.83
seam 18 12 0.76
seam 18 13 0.82
seam 18 18 0.75
seam 18 20 0.84
seam 18 21 0.86
seam 19 11 0.77
seam 19 12 0.80
seam 19 13 0.78
seam 19 18 0.88
seam 19 19 0.84
seam 19 22 0.78
seam 20 1 0.39
seam 20 5 0.37
seam 20 9 0.51
seam 20 11 0.60
seam 20 12 0.62
seam 20 13 0.60
seam 20 18 0.61
seam 20 19 0.86
seam 20 20 0.69
seam 21 8 0.51
seam 21 13 0.49
seam 21 18 0.80
seam 21 19 0.53
seam 21 20 0.78
seam 21 21 0.48
seam 22 9 0.45
seam 22 17 0.00
seam 22 18 0.51
seam 22 19 0.55
seam 22 20 0.62
seam 22 21 0.58
seam 22 22 0.64
