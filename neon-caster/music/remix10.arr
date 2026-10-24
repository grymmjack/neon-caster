; NEON-CASTER - remix10's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.000   offset 0.2546   bars 23   tail 24
source remix10.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    peak
clip D  bars 17-23   peak
clip E  bars 1-16    intro
clip F  bars 13-20   peak
clip G  bars 17-20   peak
clip H  bars 9-20    peak
clip I  bars 13-16   peak
arrange A*2 E F G F H G F C*2 F H I
seam 1 3 0.39
seam 1 6 1.00
seam 1 7 0.38
seam 1 10 0.39
seam 2 2 0.39
seam 2 6 0.38
seam 2 7 1.00
seam 2 11 0.38
seam 3 8 0.97
seam 3 10 0.38
seam 3 11 0.38
seam 3 12 0.38
seam 3 18 0.37
seam 3 20 0.38
seam 4 1 1.00
seam 4 9 0.66
seam 4 10 0.35
seam 5 2 1.00
seam 5 3 0.38
seam 5 7 0.38
seam 5 10 0.41
seam 6 2 0.38
seam 6 3 1.00
seam 6 6 0.38
seam 6 11 0.40
seam 7 4 0.97
seam 7 10 0.44
seam 7 11 0.43
seam 7 12 0.44
seam 7 18 0.44
seam 7 20 0.45
seam 8 5 0.66
seam 8 11 0.65
seam 8 13 0.65
seam 8 15 0.68
seam 8 17 0.67
seam 8 23 0.63
seam 9 11 0.87
seam 9 12 0.88
seam 9 14 0.95
seam 9 16 0.87
seam 9 18 1.00
seam 9 22 0.93
seam 10 13 0.90
seam 10 15 0.99
seam 10 17 0.90
seam 10 19 1.00
seam 10 21 0.90
seam 10 23 0.99
seam 11 10 0.88
seam 11 14 0.94
seam 11 16 1.00
seam 11 18 0.92
seam 11 20 1.00
seam 11 22 0.91
seam 12 11 0.90
seam 12 14 0.90
seam 12 15 0.94
seam 12 17 1.00
seam 12 19 0.91
seam 12 21 1.00
seam 13 10 0.95
seam 13 12 0.94
seam 13 15 0.94
seam 13 16 0.94
seam 13 18 1.00
seam 13 22 1.00
seam 14 11 0.99
seam 14 13 0.94
seam 14 14 0.94
seam 14 19 1.00
seam 14 21 0.94
seam 14 23 1.00
seam 15 10 0.87
seam 15 12 1.00
seam 15 14 0.94
seam 15 18 0.91
seam 15 20 1.00
seam 15 22 0.91
seam 16 1 0.27
seam 16 9 0.67
seam 16 11 0.90
seam 16 13 1.00
seam 16 15 0.94
seam 16 19 0.91
seam 16 21 1.00
seam 16 23 0.91
seam 17 10 1.00
seam 17 12 0.92
seam 17 14 1.00
seam 17 16 0.91
seam 17 20 0.93
seam 17 22 1.00
seam 18 11 1.00
seam 18 15 1.00
seam 18 17 0.91
seam 18 18 0.91
seam 18 21 0.93
seam 18 23 1.00
seam 19 10 0.86
seam 19 12 1.00
seam 19 14 0.93
seam 19 16 1.00
seam 19 18 0.93
seam 19 22 0.93
seam 20 9 0.62
seam 20 11 0.90
seam 20 13 1.00
seam 20 15 0.94
seam 20 17 1.00
seam 20 19 0.93
seam 20 23 0.92
seam 21 10 0.93
seam 21 12 0.91
seam 21 14 1.00
seam 21 16 0.91
seam 21 18 1.00
seam 21 20 0.93
seam 22 11 0.99
seam 22 14 0.90
seam 22 15 1.00
seam 22 17 0.91
seam 22 19 1.00
seam 22 21 0.92
seam 23 11 0.89
seam 23 15 0.92
seam 23 17 0.76
seam 23 18 0.93
seam 23 19 0.93
seam 23 22 0.91
seam 23 23 0.92
