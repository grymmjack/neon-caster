; NEON-CASTER - level10's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 124.947   offset 1.6666   bars 19   tail 20
source level10.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-7     intro
clip B  bars 8-15    peak
clip C  bars 16-19   groove
clip D  bars 4-7     intro
clip E  bars 4-11    intro
clip F  bars 12-15   peak
clip G  bars 8-11    peak
clip H  bars 12-19   peak
arrange A D*2 E B F B*2 F*2 G*2 B*3 H
seam 1 3 0.90
seam 1 4 0.82
seam 1 5 0.71
seam 1 6 0.61
seam 1 7 0.81
seam 1 8 0.59
seam 2 2 0.90
seam 2 4 1.00
seam 2 5 0.92
seam 2 6 0.86
seam 2 7 0.98
seam 2 8 0.80
seam 3 2 0.82
seam 3 3 1.00
seam 3 5 0.90
seam 3 6 0.87
seam 3 7 0.97
seam 3 8 0.81
seam 4 2 0.71
seam 4 3 0.92
seam 4 4 0.90
seam 4 6 0.70
seam 4 7 0.81
seam 4 8 0.68
seam 5 2 0.61
seam 5 3 0.86
seam 5 4 0.87
seam 5 5 0.70
seam 5 7 0.78
seam 5 8 0.51
seam 6 2 0.81
seam 6 3 0.98
seam 6 4 0.97
seam 6 5 0.81
seam 6 6 0.78
seam 6 8 0.74
seam 7 1 0.25
seam 7 3 0.80
seam 7 4 0.81
seam 7 7 0.74
seam 7 9 0.74
seam 7 11 0.73
seam 7 12 0.71
seam 8 10 0.99
seam 8 11 0.99
seam 8 12 0.93
seam 8 13 1.00
seam 8 14 0.95
seam 8 15 0.99
seam 9 9 0.99
seam 9 11 0.99
seam 9 12 0.93
seam 9 13 0.90
seam 9 14 1.00
seam 9 15 1.00
seam 10 9 0.99
seam 10 10 0.99
seam 10 12 0.94
seam 10 13 0.91
seam 10 14 0.94
seam 10 15 1.00
seam 11 4 0.48
seam 11 8 0.71
seam 11 9 0.93
seam 11 10 0.93
seam 11 11 0.94
seam 11 13 0.93
seam 11 14 0.92
seam 11 15 0.93
seam 12 9 1.00
seam 12 10 0.90
seam 12 11 0.91
seam 12 12 0.93
seam 12 14 0.99
seam 12 15 0.93
seam 13 9 0.95
seam 13 10 1.00
seam 13 11 0.94
seam 13 12 0.92
seam 13 13 0.99
seam 13 15 1.00
seam 14 9 0.99
seam 14 10 1.00
seam 14 11 1.00
seam 14 12 0.93
seam 14 13 0.93
seam 14 14 1.00
seam 15 8 0.53
seam 15 9 0.75
seam 15 11 0.77
seam 15 12 0.81
seam 15 13 0.75
seam 15 14 0.71
seam 15 15 0.80
seam 16 9 0.61
seam 16 10 0.56
seam 16 12 0.52
seam 16 13 0.67
seam 16 14 0.64
seam 16 15 0.53
seam 17 9 0.54
seam 17 10 0.63
seam 17 11 0.60
seam 17 14 0.63
seam 17 15 0.67
seam 17 19 0.51
seam 18 9 0.49
seam 18 10 0.47
seam 18 11 0.50
seam 18 12 0.48
seam 18 15 0.48
seam 18 18 0.51
seam 19 1 0.30
seam 19 10 0.41
seam 19 11 0.41
seam 19 12 0.42
seam 19 14 0.40
seam 19 15 0.40
seam 19 16 0.41
seam 19 18 0.40
seam 19 19 0.74
