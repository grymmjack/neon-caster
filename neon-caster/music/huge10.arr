; NEON-CASTER - huge10's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 140.000   offset 0.0299   bars 26   tail 27
source huge10.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    groove
clip D  bars 17-24   peak
clip E  bars 9-12    groove
clip F  bars 13-20   groove
clip G  bars 17-20   peak
clip H  bars 9-24    groove
clip I  bars 21-24   peak
clip J  bars 13-24   groove
clip K  bars 13-16   groove
clip L  bars 9-20    groove
arrange C E C F G H I G F E C J I G K L G E
seam 1 3 1.00
seam 1 4 1.00
seam 2 2 1.00
seam 2 4 1.00
seam 3 2 1.00
seam 3 3 1.00
seam 4 1 0.06
seam 5 7 0.87
seam 5 8 0.85
seam 5 11 0.67
seam 5 12 0.78
seam 5 14 0.67
seam 5 18 0.65
seam 6 6 0.87
seam 6 8 0.96
seam 6 11 1.00
seam 6 12 0.95
seam 6 15 0.75
seam 6 19 0.71
seam 7 6 0.85
seam 7 7 0.96
seam 7 11 0.89
seam 7 12 1.00
seam 7 16 0.72
seam 7 20 0.64
seam 8 5 0.14
seam 8 13 0.90
seam 8 15 0.72
seam 8 16 0.66
seam 8 17 0.73
seam 8 19 0.71
seam 8 20 0.67
seam 9 14 0.90
seam 9 15 0.86
seam 9 16 0.78
seam 9 18 0.85
seam 9 19 0.87
seam 9 20 0.78
seam 10 7 1.00
seam 10 8 0.89
seam 10 10 0.77
seam 10 12 0.93
seam 10 15 0.89
seam 10 19 0.90
seam 11 6 0.78
seam 11 7 0.95
seam 11 8 1.00
seam 11 11 0.93
seam 11 16 0.78
seam 11 20 0.69
seam 12 7 0.71
seam 12 9 0.90
seam 12 15 0.86
seam 12 17 0.88
seam 12 18 0.70
seam 12 19 0.79
seam 13 10 0.90
seam 13 15 1.00
seam 13 16 1.00
seam 13 18 1.00
seam 13 19 1.00
seam 13 20 1.00
seam 14 14 1.00
seam 14 16 1.00
seam 14 17 0.99
seam 14 18 0.97
seam 14 19 1.00
seam 14 20 0.99
seam 15 14 1.00
seam 15 15 1.00
seam 15 17 0.87
seam 15 18 0.99
seam 15 19 1.00
seam 15 20 1.00
seam 16 9 0.73
seam 16 13 0.88
seam 16 14 0.86
seam 16 15 0.99
seam 16 16 0.87
seam 16 19 0.99
seam 16 20 0.85
seam 17 10 0.85
seam 17 14 1.00
seam 17 15 0.97
seam 17 16 0.99
seam 17 19 0.98
seam 17 20 0.99
seam 18 14 1.00
seam 18 15 1.00
seam 18 16 1.00
seam 18 17 0.99
seam 18 18 0.98
seam 18 20 0.97
seam 19 14 1.00
seam 19 15 0.99
seam 19 16 1.00
seam 19 17 0.85
seam 19 18 0.99
seam 19 19 0.97
seam 20 9 0.61
seam 20 13 0.68
seam 20 14 0.71
seam 20 15 0.75
seam 20 17 0.84
seam 20 19 0.78
seam 20 23 0.76
seam 20 25 0.71
seam 21 14 0.82
seam 21 18 0.77
seam 21 23 0.71
seam 21 24 0.69
seam 21 25 0.68
seam 21 26 1.00
seam 22 17 0.66
seam 22 21 0.76
seam 22 22 0.71
seam 22 24 0.72
seam 22 25 0.67
seam 22 26 0.66
seam 23 14 0.51
seam 23 18 0.55
seam 23 22 0.69
seam 23 23 0.72
seam 23 25 0.69
seam 23 26 0.65
seam 24 9 0.32
seam 24 13 0.31
seam 24 17 0.53
seam 24 19 0.55
seam 24 21 0.71
seam 24 22 0.68
seam 24 23 0.67
seam 24 24 0.69
seam 24 26 0.70
seam 25 10 0.75
seam 25 14 0.77
seam 25 15 0.67
seam 25 18 0.75
seam 25 22 1.00
seam 25 25 0.70
seam 26 14 0.80
seam 26 15 0.79
seam 26 18 0.78
seam 26 22 0.88
seam 26 23 0.77
seam 26 26 0.90
