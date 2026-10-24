; NEON-CASTER - level4's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.021   offset 0.0320   bars 22   tail 23
source level4.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    peak
clip C  bars 17-22   peak
clip D  bars 5-8     intro
clip E  bars 1-20    intro
clip F  bars 17-20   peak
clip G  bars 13-16   peak
clip H  bars 13-20   peak
clip I  bars 1-16    intro
clip J  bars 9-20    peak
clip K  bars 1-4     intro
arrange D E F G H G I E J F B G K
seam 1 5 0.44
seam 1 6 0.56
seam 1 14 0.43
seam 1 18 0.45
seam 1 21 0.41
seam 1 22 0.42
seam 2 4 0.51
seam 2 5 0.63
seam 2 6 0.52
seam 2 7 1.00
seam 2 8 0.55
seam 2 19 0.40
seam 3 3 0.51
seam 3 5 0.50
seam 3 6 0.63
seam 3 7 0.57
seam 3 8 1.00
seam 3 12 0.41
seam 4 3 0.63
seam 4 4 0.50
seam 4 6 0.56
seam 4 7 0.63
seam 4 8 0.54
seam 4 9 0.44
seam 5 2 0.56
seam 5 3 0.52
seam 5 4 0.63
seam 5 5 0.56
seam 5 7 0.66
seam 5 8 0.63
seam 6 2 0.38
seam 6 3 1.00
seam 6 4 0.57
seam 6 5 0.63
seam 6 6 0.66
seam 6 8 0.62
seam 7 3 0.55
seam 7 4 1.00
seam 7 5 0.54
seam 7 6 0.63
seam 7 7 0.62
seam 7 12 0.39
seam 8 12 0.51
seam 8 13 0.60
seam 8 16 0.52
seam 8 17 0.59
seam 8 20 0.51
seam 8 21 0.57
seam 9 13 0.86
seam 9 14 1.00
seam 9 17 0.83
seam 9 18 1.00
seam 9 21 0.85
seam 9 22 1.00
seam 10 10 0.75
seam 10 14 0.83
seam 10 15 1.00
seam 10 18 0.81
seam 10 19 1.00
seam 10 22 0.84
seam 11 13 0.77
seam 11 15 0.76
seam 11 16 1.00
seam 11 17 0.74
seam 11 20 1.00
seam 11 21 0.75
seam 12 10 0.86
seam 12 14 0.86
seam 12 17 1.00
seam 12 18 0.87
seam 12 21 1.00
seam 12 22 0.86
seam 13 10 1.00
seam 13 11 0.83
seam 13 13 0.86
seam 13 18 1.00
seam 13 21 0.84
seam 13 22 1.00
seam 14 11 1.00
seam 14 12 0.76
seam 14 14 0.81
seam 14 18 0.81
seam 14 19 1.00
seam 14 22 0.82
seam 15 12 1.00
seam 15 13 0.78
seam 15 15 0.73
seam 15 17 0.73
seam 15 20 1.00
seam 15 21 0.75
seam 16 10 0.83
seam 16 13 1.00
seam 16 14 0.82
seam 16 18 0.83
seam 16 21 1.00
seam 16 22 0.83
seam 17 10 1.00
seam 17 13 0.87
seam 17 14 1.00
seam 17 17 0.83
seam 17 21 0.85
seam 17 22 1.00
seam 18 10 0.75
seam 18 11 1.00
seam 18 14 0.83
seam 18 15 1.00
seam 18 18 0.82
seam 18 22 0.84
seam 19 12 1.00
seam 19 13 0.73
seam 19 15 0.73
seam 19 16 1.00
seam 19 18 0.72
seam 19 21 0.72
seam 20 10 0.85
seam 20 13 1.00
seam 20 14 0.84
seam 20 17 1.00
seam 20 18 0.85
seam 20 22 0.85
seam 21 10 1.00
seam 21 11 0.84
seam 21 13 0.86
seam 21 14 1.00
seam 21 18 1.00
seam 21 21 0.85
seam 22 10 0.95
seam 22 11 0.85
seam 22 14 0.96
seam 22 15 0.85
seam 22 18 0.96
seam 22 22 0.97
