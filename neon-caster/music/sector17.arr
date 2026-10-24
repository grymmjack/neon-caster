; NEON-CASTER - sector17's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.000   offset 0.0087   bars 24   tail 25
source sector17.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-16    groove
clip C  bars 17-24   groove
clip D  bars 13-24   groove
clip E  bars 21-24   groove
clip F  bars 13-16   groove
clip G  bars 13-20   groove
clip H  bars 5-24    intro
clip I  bars 17-20   groove
arrange D C E F D G D H I D G C
seam 1 3 0.42
seam 1 4 0.52
seam 1 5 0.41
seam 1 6 0.48
seam 1 9 0.36
seam 2 2 0.42
seam 2 4 0.42
seam 2 5 0.52
seam 2 6 0.59
seam 2 14 0.39
seam 2 22 0.39
seam 3 2 0.52
seam 3 13 0.48
seam 3 14 0.51
seam 3 18 0.47
seam 3 21 0.46
seam 3 22 0.52
seam 4 3 0.52
seam 4 4 0.46
seam 4 13 0.45
seam 4 15 0.42
seam 4 21 0.44
seam 4 23 0.42
seam 5 2 0.48
seam 5 3 0.59
seam 5 5 0.37
seam 5 7 0.44
seam 5 14 0.36
seam 5 22 0.38
seam 6 3 0.38
seam 6 6 0.44
seam 7 4 0.43
seam 8 4 0.40
seam 8 13 0.43
seam 8 14 0.38
seam 8 17 0.41
seam 8 21 0.42
seam 8 22 0.39
seam 9 14 1.00
seam 9 18 1.00
seam 9 20 0.84
seam 9 22 1.00
seam 9 23 0.84
seam 9 24 0.86
seam 10 12 0.90
seam 10 15 1.00
seam 10 19 1.00
seam 10 20 0.90
seam 10 23 1.00
seam 10 24 0.93
seam 11 11 0.90
seam 11 13 0.91
seam 11 15 0.92
seam 11 16 1.00
seam 11 20 1.00
seam 11 24 1.00
seam 12 12 0.91
seam 12 16 0.94
seam 12 17 1.00
seam 12 20 0.91
seam 12 21 1.00
seam 12 23 0.90
seam 13 10 1.00
seam 13 13 0.89
seam 13 16 0.89
seam 13 18 1.00
seam 13 22 1.00
seam 13 24 0.90
seam 14 11 1.00
seam 14 16 0.94
seam 14 19 1.00
seam 14 20 0.92
seam 14 23 1.00
seam 14 24 0.92
seam 15 12 1.00
seam 15 13 0.94
seam 15 15 0.94
seam 15 20 1.00
seam 15 23 0.93
seam 15 24 1.00
seam 16 13 1.00
seam 16 15 0.89
seam 16 16 0.91
seam 16 19 0.89
seam 16 21 1.00
seam 16 23 0.90
seam 17 10 1.00
seam 17 14 1.00
seam 17 15 0.88
seam 17 16 0.89
seam 17 22 1.00
seam 17 24 0.89
seam 18 11 1.00
seam 18 15 1.00
seam 18 16 0.92
seam 18 21 0.90
seam 18 23 1.00
seam 18 24 0.90
seam 19 12 1.00
seam 19 13 0.91
seam 19 15 0.92
seam 19 16 1.00
seam 19 23 0.91
seam 19 24 1.00
seam 20 13 1.00
seam 20 16 0.90
seam 20 17 1.00
seam 20 19 0.90
seam 20 20 0.91
seam 20 23 0.91
seam 21 10 1.00
seam 21 14 1.00
seam 21 16 0.89
seam 21 18 1.00
seam 21 20 0.90
seam 21 24 0.91
seam 22 11 1.00
seam 22 15 1.00
seam 22 16 0.93
seam 22 19 1.00
seam 22 21 0.91
seam 22 24 0.91
seam 23 11 0.93
seam 23 12 1.00
seam 23 15 0.92
seam 23 16 1.00
seam 23 20 1.00
seam 23 22 0.91
seam 24 12 0.97
seam 24 16 0.98
seam 24 19 0.95
seam 24 20 0.98
seam 24 23 0.94
seam 24 24 0.98
