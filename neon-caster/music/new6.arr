; NEON-CASTER - new6's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 100.000   offset 0.0020   bars 19   tail 20
source new6.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-15    peak
clip C  bars 16-19   break
clip D  bars 1-15    intro
clip E  bars 4-11    intro
clip F  bars 8-15    intro
clip G  bars 8-11    intro
clip H  bars 4-15    intro
clip I  bars 4-7     intro
clip J  bars 12-15   peak
arrange D E F G H I E H J G F
seam 1 5 0.36
seam 1 6 0.56
seam 1 10 0.53
seam 1 14 0.59
seam 1 17 0.47
seam 1 18 0.59
seam 2 7 0.57
seam 2 11 0.55
seam 2 15 0.64
seam 3 5 0.58
seam 3 8 0.79
seam 3 9 0.53
seam 3 12 0.77
seam 3 13 0.56
seam 3 16 0.59
seam 4 6 0.85
seam 4 9 1.00
seam 4 10 0.86
seam 4 12 0.83
seam 4 13 1.00
seam 4 14 0.81
seam 5 5 0.85
seam 5 7 0.68
seam 5 9 0.83
seam 5 10 1.00
seam 5 13 0.80
seam 5 14 1.00
seam 6 5 0.65
seam 6 6 0.68
seam 6 10 0.66
seam 6 11 1.00
seam 6 14 0.63
seam 6 15 1.00
seam 7 4 0.79
seam 7 5 0.79
seam 7 9 0.75
seam 7 12 1.00
seam 7 13 0.75
seam 7 16 0.67
seam 8 1 0.55
seam 8 5 1.00
seam 8 6 0.83
seam 8 10 0.84
seam 8 12 0.76
seam 8 13 1.00
seam 8 14 0.79
seam 9 5 0.86
seam 9 6 1.00
seam 9 9 0.84
seam 9 11 0.67
seam 9 13 0.81
seam 9 14 1.00
seam 10 5 0.69
seam 10 6 0.68
seam 10 7 1.00
seam 10 10 0.67
seam 10 12 0.63
seam 10 15 1.00
seam 11 4 0.77
seam 11 5 0.83
seam 11 8 1.00
seam 11 9 0.76
seam 11 13 0.78
seam 11 16 0.73
seam 12 5 1.00
seam 12 6 0.80
seam 12 9 1.00
seam 12 10 0.81
seam 12 12 0.78
seam 12 14 0.76
seam 13 5 0.81
seam 13 6 1.00
seam 13 7 0.63
seam 13 9 0.79
seam 13 10 1.00
seam 13 13 0.76
seam 14 3 0.64
seam 14 5 0.64
seam 14 6 0.67
seam 14 7 1.00
seam 14 10 0.65
seam 14 11 1.00
seam 15 1 0.64
seam 15 4 0.59
seam 15 5 0.51
seam 15 8 0.67
seam 15 9 0.45
seam 15 12 0.73
seam 15 13 0.46
seam 16 2 0.47
seam 16 5 0.55
seam 16 9 0.49
seam 16 13 0.55
seam 16 18 0.69
seam 17 2 0.59
seam 17 5 0.46
seam 17 6 0.39
seam 17 9 0.42
seam 17 13 0.43
seam 17 17 0.69
seam 19 16 0.08
seam 19 19 0.36
