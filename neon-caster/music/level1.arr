; NEON-CASTER - level1's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 135.000   offset 0.0350   bars 23   tail 24
source level1.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     groove
clip C  bars 9-16    peak
clip D  bars 17-23   groove
clip E  bars 17-20   groove
clip F  bars 9-20    peak
clip G  bars 13-20   peak
clip H  bars 13-16   peak
clip I  bars 9-12    peak
arrange E F G C H I F*2 G E C H I F H
seam 5 7 0.62
seam 5 8 0.62
seam 5 18 0.69
seam 5 19 0.65
seam 5 20 0.62
seam 5 21 0.60
seam 6 6 0.62
seam 6 8 0.82
seam 6 9 0.59
seam 6 18 0.59
seam 6 19 0.65
seam 6 20 0.57
seam 7 6 0.62
seam 7 7 0.82
seam 7 9 0.65
seam 7 18 0.61
seam 7 19 0.65
seam 7 20 0.66
seam 8 10 0.76
seam 8 12 0.76
seam 8 13 0.79
seam 8 18 0.74
seam 8 19 0.83
seam 8 21 0.73
seam 9 11 1.00
seam 9 12 1.00
seam 9 13 0.98
seam 9 14 1.00
seam 9 15 0.97
seam 9 16 0.96
seam 10 10 1.00
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 0.99
seam 10 15 1.00
seam 10 16 0.94
seam 11 10 1.00
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 0.97
seam 11 16 1.00
seam 12 10 0.98
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 1.00
seam 12 16 0.98
seam 13 10 1.00
seam 13 11 0.99
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 1.00
seam 13 16 1.00
seam 14 10 0.97
seam 14 11 1.00
seam 14 12 0.97
seam 14 13 1.00
seam 14 14 1.00
seam 14 16 1.00
seam 15 10 0.96
seam 15 11 0.94
seam 15 12 1.00
seam 15 13 0.98
seam 15 14 1.00
seam 15 15 1.00
seam 16 11 0.86
seam 16 13 0.88
seam 16 16 0.87
seam 16 18 0.87
seam 16 19 0.92
seam 16 20 0.93
seam 17 10 0.81
seam 17 12 0.80
seam 17 17 0.87
seam 17 19 1.00
seam 17 20 1.00
seam 17 21 0.96
seam 18 11 0.86
seam 18 17 0.92
seam 18 18 1.00
seam 18 20 1.00
seam 18 21 0.88
seam 18 22 0.87
seam 19 11 0.83
seam 19 12 0.83
seam 19 17 0.93
seam 19 18 1.00
seam 19 19 1.00
seam 19 21 0.82
seam 20 12 0.76
seam 20 17 0.77
seam 20 18 0.96
seam 20 19 0.88
seam 20 20 0.82
seam 20 23 0.80
seam 21 10 0.71
seam 21 11 0.73
seam 21 17 0.78
seam 21 18 0.76
seam 21 19 0.87
seam 21 20 0.81
seam 22 12 0.54
seam 22 16 0.54
seam 22 17 0.55
seam 22 18 0.61
seam 22 19 0.56
seam 22 21 0.80
seam 23 17 0.42
seam 23 18 0.43
seam 23 19 0.44
seam 23 21 0.51
seam 23 22 0.59
seam 23 23 0.69
