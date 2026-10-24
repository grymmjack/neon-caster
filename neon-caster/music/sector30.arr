; NEON-CASTER - sector30's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 135.000   offset 0.0320   bars 25   tail 26
source sector30.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    groove
clip D  bars 17-24   groove
clip E  bars 13-24   groove
clip F  bars 21-24   groove
clip G  bars 13-16   groove
clip H  bars 13-20   groove
clip I  bars 17-20   groove
arrange E F G H E I*2 E*2 F E I G H D I
seam 2 4 0.63
seam 3 3 0.63
seam 5 7 0.77
seam 5 18 0.37
seam 5 22 0.41
seam 5 23 0.38
seam 5 24 0.37
seam 6 6 0.77
seam 6 22 0.37
seam 6 23 0.39
seam 6 24 0.38
seam 6 25 0.38
seam 9 11 0.95
seam 9 12 0.94
seam 9 14 0.97
seam 9 15 0.93
seam 9 16 0.95
seam 9 18 1.00
seam 10 12 1.00
seam 10 13 1.00
seam 10 15 1.00
seam 10 16 0.98
seam 10 19 1.00
seam 10 20 1.00
seam 11 11 1.00
seam 11 13 0.99
seam 11 14 1.00
seam 11 15 1.00
seam 11 16 1.00
seam 11 20 1.00
seam 12 11 1.00
seam 12 12 0.99
seam 12 14 0.99
seam 12 15 1.00
seam 12 16 1.00
seam 12 21 0.95
seam 13 10 0.97
seam 13 11 0.97
seam 13 12 1.00
seam 13 13 0.99
seam 13 15 1.00
seam 13 16 0.99
seam 14 11 1.00
seam 14 12 1.00
seam 14 13 1.00
seam 14 14 1.00
seam 14 16 1.00
seam 14 21 0.99
seam 15 11 0.98
seam 15 12 1.00
seam 15 13 1.00
seam 15 14 0.99
seam 15 15 1.00
seam 15 20 0.99
seam 16 12 0.91
seam 16 13 0.94
seam 16 14 0.93
seam 16 15 0.94
seam 16 16 0.92
seam 16 21 0.93
seam 17 10 1.00
seam 17 11 0.90
seam 17 14 0.93
seam 17 19 0.92
seam 17 20 0.92
seam 17 22 0.93
seam 18 11 1.00
seam 18 15 0.98
seam 18 20 1.00
seam 18 21 0.99
seam 18 23 1.00
seam 18 24 0.97
seam 19 11 1.00
seam 19 12 1.00
seam 19 15 0.98
seam 19 16 0.99
seam 19 19 1.00
seam 19 23 1.00
seam 20 13 0.95
seam 20 15 0.99
seam 20 19 0.99
seam 20 20 0.95
seam 20 23 0.96
seam 20 24 0.99
seam 21 18 0.93
seam 21 19 0.96
seam 21 20 0.95
seam 21 23 0.97
seam 21 24 0.97
seam 21 25 0.94
seam 22 15 0.95
seam 22 19 1.00
seam 22 20 1.00
seam 22 21 0.96
seam 22 22 0.97
seam 22 24 0.98
seam 23 15 0.93
seam 23 19 0.97
seam 23 20 0.95
seam 23 21 0.99
seam 23 22 0.97
seam 23 23 0.98
seam 24 19 0.87
seam 24 20 0.83
seam 24 21 0.91
seam 24 22 0.94
seam 24 23 0.90
seam 24 24 0.93
seam 25 19 0.82
seam 25 21 0.81
seam 25 22 0.91
seam 25 23 0.88
seam 25 24 0.88
seam 25 25 0.95
