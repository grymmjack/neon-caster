; NEON-CASTER - huge3's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 128.000   offset 0.0220   bars 24   tail 22
source huge3.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-12    peak
clip C  bars 13-20   peak
clip D  bars 5-20    peak
clip E  bars 1-16    intro
clip F  bars 9-16    peak
clip G  bars 1-20    intro
clip H  bars 1-12    intro
clip I  bars 9-12    peak
clip J  bars 13-16   peak
clip K  bars 9-20    peak
arrange D E F C G H I F J K A
seam 1 3 0.60
seam 1 4 0.39
seam 2 2 0.60
seam 2 4 0.70
seam 3 2 0.39
seam 3 3 0.70
seam 4 1 0.31
seam 5 7 0.92
seam 5 8 0.87
seam 5 16 0.82
seam 5 17 0.82
seam 5 18 0.82
seam 5 19 0.81
seam 6 6 0.92
seam 6 8 0.98
seam 6 9 0.90
seam 6 10 0.86
seam 6 11 0.85
seam 6 12 0.85
seam 7 6 0.87
seam 7 7 0.98
seam 7 9 0.96
seam 7 10 0.91
seam 7 11 0.91
seam 7 12 0.90
seam 8 8 0.96
seam 8 10 0.96
seam 8 11 0.96
seam 8 12 0.96
seam 8 13 0.95
seam 8 14 0.92
seam 9 9 0.96
seam 9 11 1.00
seam 9 12 1.00
seam 9 13 1.00
seam 9 14 1.00
seam 9 15 0.98
seam 10 9 0.96
seam 10 10 1.00
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 1.00
seam 10 15 0.98
seam 11 9 0.96
seam 11 10 1.00
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 0.98
seam 12 1 0.34
seam 12 5 0.29
seam 12 9 0.95
seam 12 10 1.00
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 1.00
seam 12 15 1.00
seam 12 16 0.96
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 1.00
seam 13 13 1.00
seam 13 15 1.00
seam 13 16 1.00
seam 14 13 1.00
seam 14 14 1.00
seam 14 16 1.00
seam 14 17 1.00
seam 14 18 0.99
seam 14 19 0.99
seam 15 13 0.96
seam 15 14 1.00
seam 15 15 1.00
seam 15 17 1.00
seam 15 18 1.00
seam 15 19 1.00
seam 16 1 0.36
seam 16 9 0.85
seam 16 13 0.94
seam 16 14 0.97
seam 16 15 1.00
seam 16 16 1.00
seam 16 18 1.00
seam 16 19 1.00
seam 17 13 0.92
seam 17 14 0.96
seam 17 15 0.99
seam 17 16 1.00
seam 17 17 1.00
seam 17 19 1.00
seam 18 13 0.91
seam 18 14 0.94
seam 18 15 0.99
seam 18 16 1.00
seam 18 17 1.00
seam 18 18 1.00
seam 19 14 0.89
seam 19 15 0.89
seam 19 16 0.91
seam 19 17 0.90
seam 19 18 0.90
seam 19 19 0.90
seam 20 1 0.56
seam 20 5 0.23
seam 20 9 0.52
seam 20 10 0.57
seam 20 11 0.57
seam 20 12 0.57
seam 20 13 0.56
seam 20 14 0.56
seam 20 15 0.57
seam 20 17 0.56
seam 21 8 0.39
seam 21 9 0.39
seam 21 10 0.38
seam 21 11 0.39
seam 21 12 0.39
seam 21 21 0.61
