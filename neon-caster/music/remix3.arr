; NEON-CASTER - remix3's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 90.000   offset 2.0270   bars 16   tail 16
source remix3.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-12    peak
clip C  bars 1-8     intro
clip D  bars 1-12    intro
clip E  bars 9-12    peak
arrange A*2 C*4 A D E*4
seam 1 3 0.50
seam 1 4 0.73
seam 1 5 0.81
seam 1 6 0.47
seam 1 12 0.43
seam 1 14 0.41
seam 2 2 0.50
seam 2 4 0.63
seam 2 5 0.63
seam 2 6 0.60
seam 2 13 0.41
seam 2 15 0.38
seam 3 2 0.73
seam 3 3 0.63
seam 3 5 0.65
seam 3 6 0.56
seam 3 12 0.48
seam 3 14 0.45
seam 4 1 0.67
seam 4 2 0.81
seam 4 3 0.63
seam 4 4 0.65
seam 4 12 0.49
seam 4 13 0.49
seam 4 15 0.49
seam 5 3 0.60
seam 5 8 0.64
seam 5 9 0.70
seam 5 10 0.67
seam 5 12 0.71
seam 5 14 0.69
seam 6 8 0.75
seam 6 9 0.99
seam 6 10 1.00
seam 6 11 0.67
seam 6 13 0.74
seam 6 15 0.80
seam 7 7 0.75
seam 7 9 0.79
seam 7 10 0.94
seam 7 11 0.79
seam 7 13 0.67
seam 7 14 0.73
seam 8 1 0.54
seam 8 7 0.99
seam 8 8 0.79
seam 8 10 0.82
seam 8 11 0.78
seam 8 13 0.77
seam 8 15 0.79
seam 9 7 1.00
seam 9 8 0.94
seam 9 9 0.82
seam 9 13 0.70
seam 9 14 0.70
seam 9 15 0.70
seam 10 8 0.79
seam 10 9 0.78
seam 10 12 0.72
seam 10 13 0.82
seam 10 14 0.77
seam 10 15 0.80
seam 11 6 0.71
seam 11 9 0.71
seam 11 11 0.72
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 1.00
seam 12 1 0.41
seam 12 5 0.49
seam 12 7 0.74
seam 12 9 0.77
seam 12 11 0.82
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 1.00
seam 13 8 0.73
seam 13 9 0.71
seam 13 11 0.77
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 1.00
seam 14 7 0.80
seam 14 9 0.79
seam 14 11 0.80
seam 14 12 1.00
seam 14 13 1.00
seam 14 14 1.00
seam 15 9 0.72
seam 15 11 0.81
seam 15 12 1.00
seam 15 13 1.00
seam 15 14 1.00
seam 15 15 1.00
