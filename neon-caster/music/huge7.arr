; NEON-CASTER - huge7's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.000   offset 0.0220   bars 24   tail 25
source huge7.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     groove
clip B  bars 5-8     build
clip C  bars 9-16    peak
clip D  bars 17-24   peak
clip E  bars 5-12    build
clip F  bars 1-24    groove
clip G  bars 21-24   peak
clip H  bars 13-20   peak
clip I  bars 13-24   peak
clip J  bars 5-24    build
arrange E F G H I G J H I E A
seam 1 3 0.75
seam 1 4 0.48
seam 1 10 0.48
seam 1 11 0.48
seam 1 14 0.48
seam 1 15 0.48
seam 2 2 0.75
seam 2 4 0.65
seam 2 11 0.51
seam 2 12 0.49
seam 2 14 0.46
seam 2 15 0.50
seam 3 2 0.48
seam 3 3 0.65
seam 3 11 0.47
seam 3 12 0.61
seam 3 20 0.53
seam 3 24 0.49
seam 5 7 0.64
seam 5 8 0.45
seam 6 6 0.64
seam 7 6 0.45
seam 9 11 1.00
seam 9 12 0.98
seam 9 13 0.91
seam 9 14 1.00
seam 9 15 0.99
seam 9 18 0.91
seam 10 10 1.00
seam 10 12 0.97
seam 10 13 0.98
seam 10 14 1.00
seam 10 15 1.00
seam 10 19 0.91
seam 11 10 0.98
seam 11 11 0.97
seam 11 13 0.93
seam 11 14 0.95
seam 11 15 0.95
seam 11 20 0.93
seam 12 10 0.91
seam 12 11 0.98
seam 12 12 0.93
seam 12 14 0.95
seam 12 15 0.95
seam 12 19 0.92
seam 13 10 1.00
seam 13 11 1.00
seam 13 12 0.95
seam 13 13 0.95
seam 13 15 1.00
seam 13 20 0.88
seam 14 10 0.99
seam 14 11 1.00
seam 14 12 0.95
seam 14 13 0.95
seam 14 14 1.00
seam 14 19 0.87
seam 17 10 0.91
seam 17 12 0.87
seam 17 19 0.88
seam 17 20 0.88
seam 17 21 0.84
seam 17 22 1.00
seam 18 10 0.90
seam 18 11 0.91
seam 18 13 0.92
seam 18 20 0.88
seam 18 21 0.88
seam 18 23 1.00
seam 19 10 0.90
seam 19 12 0.93
seam 19 19 0.88
seam 19 22 0.90
seam 19 23 0.90
seam 19 24 1.00
seam 20 13 0.90
seam 20 19 0.88
seam 20 20 0.87
seam 20 22 0.89
seam 20 23 0.89
seam 20 24 0.84
seam 21 10 0.88
seam 21 18 1.00
seam 21 19 0.88
seam 21 20 0.90
seam 21 21 0.89
seam 21 23 0.90
seam 22 13 0.89
seam 22 19 1.00
seam 22 20 0.90
seam 22 21 0.89
seam 22 22 0.90
seam 22 24 0.87
seam 23 12 0.92
seam 23 14 0.88
seam 23 20 1.00
seam 23 21 0.84
seam 23 22 0.86
seam 23 23 0.87
seam 24 12 0.82
seam 24 13 0.82
seam 24 20 0.93
seam 24 21 0.88
seam 24 23 0.81
seam 24 24 0.93
