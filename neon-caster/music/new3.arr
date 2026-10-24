; NEON-CASTER - new3's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 134.899   offset 0.0031   bars 25   tail 25
source new3.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-24   groove
clip D  bars 1-12    intro
clip E  bars 1-20    intro
clip F  bars 13-20   groove
clip G  bars 13-16   groove
clip H  bars 9-12    groove
clip I  bars 1-4     intro
clip J  bars 5-20    intro
clip K  bars 5-8     intro
arrange D E F*2 G H D I D J G H K I
seam 1 3 0.91
seam 1 4 0.86
seam 1 5 0.85
seam 1 6 0.91
seam 1 7 0.83
seam 1 14 0.59
seam 2 2 0.91
seam 2 4 1.00
seam 2 5 1.00
seam 2 6 1.00
seam 2 7 1.00
seam 2 13 0.62
seam 3 2 0.86
seam 3 3 1.00
seam 3 5 1.00
seam 3 6 1.00
seam 3 7 1.00
seam 3 12 0.60
seam 4 1 0.82
seam 4 2 0.85
seam 4 3 1.00
seam 4 4 1.00
seam 4 6 1.00
seam 4 7 1.00
seam 4 13 0.65
seam 5 2 0.91
seam 5 3 1.00
seam 5 4 1.00
seam 5 5 1.00
seam 5 7 1.00
seam 5 13 0.61
seam 6 2 0.83
seam 6 3 1.00
seam 6 4 1.00
seam 6 5 1.00
seam 6 6 1.00
seam 6 13 0.60
seam 7 3 0.36
seam 7 4 0.37
seam 7 5 0.40
seam 7 6 0.37
seam 7 7 0.38
seam 7 16 0.62
seam 8 1 0.52
seam 8 5 0.26
seam 8 12 0.36
seam 8 13 0.41
seam 8 14 0.38
seam 8 17 0.68
seam 9 11 0.95
seam 9 12 0.95
seam 9 13 0.94
seam 9 14 1.00
seam 9 15 0.93
seam 9 22 0.82
seam 10 10 0.95
seam 10 12 1.00
seam 10 13 1.00
seam 10 14 0.99
seam 10 15 1.00
seam 10 22 0.73
seam 11 10 0.95
seam 11 11 1.00
seam 11 13 1.00
seam 11 14 1.00
seam 11 15 1.00
seam 11 22 0.77
seam 12 1 0.62
seam 12 5 0.65
seam 12 9 0.41
seam 12 10 0.94
seam 12 11 1.00
seam 12 12 1.00
seam 12 14 0.95
seam 12 15 0.93
seam 12 21 0.77
seam 13 10 1.00
seam 13 11 0.99
seam 13 12 1.00
seam 13 13 0.95
seam 13 15 0.95
seam 13 22 0.79
seam 14 10 0.93
seam 14 11 1.00
seam 14 12 1.00
seam 14 13 0.93
seam 14 14 0.95
seam 14 22 0.75
seam 15 8 0.62
seam 16 9 0.68
seam 16 13 0.29
seam 17 10 0.74
seam 17 19 0.82
seam 17 20 1.00
seam 17 21 0.89
seam 17 22 0.99
seam 17 23 0.81
seam 18 11 0.71
seam 18 18 0.82
seam 18 20 0.89
seam 18 21 1.00
seam 18 22 0.97
seam 18 23 0.92
seam 19 15 0.74
seam 19 18 1.00
seam 19 19 0.89
seam 19 21 0.95
seam 19 22 1.00
seam 19 23 0.82
seam 20 1 0.32
seam 20 5 0.32
seam 20 13 0.77
seam 20 18 0.89
seam 20 19 1.00
seam 20 20 0.95
seam 20 22 0.99
seam 20 23 0.89
seam 21 10 0.82
seam 21 18 0.99
seam 21 19 0.97
seam 21 20 1.00
seam 21 21 0.99
seam 21 23 0.91
seam 22 18 0.81
seam 22 19 0.92
seam 22 20 0.82
seam 22 21 0.89
seam 22 22 0.91
seam 22 24 0.69
seam 23 18 0.55
seam 23 19 0.57
seam 23 20 0.59
seam 23 21 0.61
seam 23 22 0.65
seam 23 23 0.69
seam 24 17 0.06
seam 24 18 0.46
seam 24 20 0.44
seam 24 21 0.46
seam 24 22 0.52
seam 24 23 0.55
seam 24 24 0.76
