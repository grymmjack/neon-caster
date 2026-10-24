; NEON-CASTER - sector14's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 124.987   offset 1.2036   bars 23   tail 24
source sector14.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-3     intro
clip B  bars 4-11    build
clip C  bars 12-19   peak
clip D  bars 20-23   peak
clip E  bars 8-15    build
clip F  bars 8-11    build
clip G  bars 8-23    build
clip H  bars 16-23   peak
clip I  bars 8-19    build
clip J  bars 16-19   peak
clip K  bars 12-23   peak
arrange E F G H I H I G D J K F
seam 1 3 0.65
seam 1 4 0.44
seam 2 2 0.65
seam 2 4 0.61
seam 3 2 0.44
seam 3 3 0.61
seam 3 5 0.51
seam 3 8 0.40
seam 3 17 0.40
seam 3 20 0.43
seam 4 6 0.60
seam 4 7 0.72
seam 4 8 0.61
seam 4 9 0.86
seam 4 17 0.69
seam 4 21 0.64
seam 5 8 1.00
seam 5 9 0.77
seam 5 10 1.00
seam 5 12 0.83
seam 5 14 0.71
seam 5 18 0.85
seam 6 8 0.74
seam 6 9 1.00
seam 6 11 1.00
seam 6 13 0.75
seam 6 15 0.78
seam 6 19 0.79
seam 7 6 1.00
seam 7 9 0.79
seam 7 10 0.84
seam 7 12 0.98
seam 7 16 0.81
seam 7 18 0.75
seam 8 5 0.86
seam 8 6 0.77
seam 8 7 1.00
seam 8 8 0.79
seam 8 13 0.78
seam 8 17 0.84
seam 9 6 1.00
seam 9 8 0.84
seam 9 9 0.59
seam 9 12 0.63
seam 9 18 0.67
seam 9 22 0.59
seam 10 7 1.00
seam 10 8 0.54
seam 10 9 0.76
seam 10 10 0.54
seam 10 12 0.57
seam 10 19 0.54
seam 11 6 0.83
seam 11 8 0.98
seam 11 13 0.68
seam 11 16 0.72
seam 11 18 0.75
seam 11 20 0.74
seam 12 15 0.98
seam 12 16 0.97
seam 12 17 1.00
seam 12 19 0.98
seam 12 20 0.92
seam 12 21 1.00
seam 13 13 0.88
seam 13 16 1.00
seam 13 18 1.00
seam 13 20 0.98
seam 13 21 0.87
seam 13 22 0.91
seam 14 13 0.98
seam 14 16 0.90
seam 14 17 1.00
seam 14 19 1.00
seam 14 20 0.85
seam 14 21 0.98
seam 15 13 0.97
seam 15 14 1.00
seam 15 17 0.94
seam 15 18 0.99
seam 15 20 1.00
seam 15 21 0.94
seam 16 13 1.00
seam 16 15 1.00
seam 16 16 0.94
seam 16 19 0.99
seam 16 20 0.97
seam 16 21 1.00
seam 17 14 1.00
seam 17 16 0.99
seam 17 17 0.88
seam 17 19 0.90
seam 17 20 1.00
seam 17 22 0.87
seam 18 13 0.98
seam 18 15 1.00
seam 18 17 0.99
seam 18 18 0.90
seam 18 20 0.97
seam 18 21 0.95
seam 19 14 0.98
seam 19 16 1.00
seam 19 17 0.97
seam 19 18 1.00
seam 19 19 0.97
seam 19 21 0.96
seam 20 13 1.00
seam 20 15 0.98
seam 20 17 1.00
seam 20 19 0.95
seam 20 20 0.96
seam 20 22 0.94
seam 21 14 0.91
seam 21 16 0.87
seam 21 18 0.87
seam 21 20 0.80
seam 21 21 0.94
seam 21 23 0.98
seam 22 13 0.72
seam 22 15 0.81
seam 22 17 0.86
seam 22 19 0.80
seam 22 21 0.84
seam 22 22 0.98
seam 23 17 0.86
seam 23 18 0.83
seam 23 20 0.84
seam 23 21 0.91
seam 23 22 1.00
seam 23 23 1.00
