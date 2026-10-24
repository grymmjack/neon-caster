; NEON-CASTER - level7's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.000   offset 0.0290   bars 20   tail 20
source level7.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 1-12    intro
clip D  bars 1-16    intro
clip E  bars 13-16   groove
clip F  bars 5-12    intro
clip G  bars 5-16    intro
clip H  bars 1-4     intro
arrange C D E F G F H*2 D E F*2 H
seam 1 3 1.00
seam 1 4 0.97
seam 1 5 0.83
seam 1 6 0.88
seam 1 7 0.85
seam 1 14 0.66
seam 2 2 1.00
seam 2 4 0.97
seam 2 5 0.89
seam 2 6 0.91
seam 2 7 0.91
seam 2 12 0.70
seam 3 2 0.97
seam 3 3 0.97
seam 3 5 0.80
seam 3 6 0.77
seam 3 7 0.76
seam 3 12 0.77
seam 4 1 0.78
seam 4 2 0.83
seam 4 3 0.89
seam 4 4 0.80
seam 4 6 0.83
seam 4 7 0.83
seam 4 13 0.69
seam 5 2 0.88
seam 5 3 0.91
seam 5 4 0.77
seam 5 5 0.83
seam 5 7 1.00
seam 5 8 0.68
seam 6 2 0.85
seam 6 3 0.91
seam 6 4 0.76
seam 6 5 0.83
seam 6 6 1.00
seam 6 8 0.70
seam 7 4 0.43
seam 7 5 0.54
seam 7 6 0.68
seam 7 7 0.70
seam 8 1 0.49
seam 8 5 0.38
seam 8 6 0.56
seam 8 7 0.55
seam 8 10 0.41
seam 8 13 0.39
seam 8 18 0.38
seam 9 11 1.00
seam 9 12 1.00
seam 9 13 0.89
seam 9 14 1.00
seam 9 15 0.90
seam 9 18 0.78
seam 10 10 1.00
seam 10 12 0.94
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 0.84
seam 10 17 0.73
seam 11 4 0.77
seam 11 10 1.00
seam 11 11 0.94
seam 11 13 0.94
seam 11 14 1.00
seam 11 15 0.83
seam 12 1 0.53
seam 12 4 0.72
seam 12 5 0.69
seam 12 10 0.89
seam 12 11 1.00
seam 12 12 0.94
seam 12 14 1.00
seam 12 15 0.88
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 0.90
seam 13 16 0.76
seam 14 10 0.90
seam 14 11 0.84
seam 14 12 0.83
seam 14 13 0.88
seam 14 14 0.90
seam 14 16 0.88
seam 15 10 0.67
seam 15 11 0.70
seam 15 12 0.76
seam 15 13 0.71
seam 15 14 0.76
seam 15 15 0.88
seam 16 1 0.28
seam 16 5 0.57
seam 16 9 0.34
seam 16 11 0.73
seam 16 12 0.58
seam 16 13 0.70
seam 16 14 0.71
seam 16 15 0.61
seam 16 16 0.62
seam 17 10 0.78
seam 17 11 0.66
seam 17 12 0.60
seam 17 13 0.65
seam 17 14 0.62
seam 17 15 0.57
seam 18 5 0.46
seam 18 11 0.37
seam 18 12 0.39
seam 18 14 0.42
seam 18 15 0.42
seam 18 17 0.46
seam 19 5 0.44
seam 19 6 0.68
seam 19 7 0.68
seam 19 8 0.56
seam 19 9 0.41
seam 19 19 0.39
