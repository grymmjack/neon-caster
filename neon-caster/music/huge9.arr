; NEON-CASTER - huge9's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 128.000   offset 0.2335   bars 24   tail 25
source huge9.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     build
clip C  bars 9-16    groove
clip D  bars 17-24   peak
clip E  bars 13-16   groove
clip F  bars 1-12    intro
clip G  bars 1-20    intro
clip H  bars 13-20   groove
arrange E F G H*2 F G*2 H
seam 1 3 0.96
seam 1 4 0.91
seam 1 14 0.71
seam 1 18 0.75
seam 1 19 0.68
seam 1 22 0.67
seam 2 2 0.96
seam 2 4 0.95
seam 2 15 0.70
seam 2 19 0.80
seam 2 20 0.64
seam 2 23 0.67
seam 3 2 0.91
seam 3 3 0.95
seam 3 12 0.66
seam 3 18 0.61
seam 3 19 0.70
seam 3 20 0.81
seam 4 1 0.61
seam 4 2 0.61
seam 4 3 0.63
seam 4 4 0.60
seam 4 13 0.60
seam 4 19 0.50
seam 4 21 0.59
seam 5 2 0.44
seam 5 5 0.47
seam 5 7 0.62
seam 5 18 0.35
seam 6 6 0.62
seam 8 5 0.08
seam 9 11 0.87
seam 9 12 0.50
seam 9 14 0.46
seam 9 17 0.43
seam 9 18 0.46
seam 9 22 0.44
seam 10 10 0.87
seam 10 12 0.86
seam 10 15 0.67
seam 10 18 0.63
seam 10 19 0.70
seam 10 23 0.66
seam 11 13 0.89
seam 11 14 0.87
seam 11 18 0.88
seam 11 19 0.89
seam 11 20 0.95
seam 11 21 0.87
seam 12 1 0.67
seam 12 14 1.00
seam 12 18 0.99
seam 12 19 0.99
seam 12 20 1.00
seam 12 21 1.00
seam 12 22 0.94
seam 13 13 1.00
seam 13 18 1.00
seam 13 19 0.99
seam 13 20 0.99
seam 13 21 1.00
seam 13 22 1.00
seam 14 14 0.94
seam 14 18 0.94
seam 14 19 1.00
seam 14 20 0.91
seam 14 22 0.91
seam 14 23 1.00
seam 15 12 0.72
seam 15 15 0.66
seam 15 18 0.62
seam 15 19 0.62
seam 15 20 0.75
seam 15 23 0.64
seam 16 1 0.71
seam 16 9 0.08
seam 16 12 0.68
seam 16 13 0.78
seam 16 18 0.67
seam 16 19 0.67
seam 16 20 0.66
seam 16 21 0.75
seam 17 13 0.99
seam 17 14 1.00
seam 17 19 1.00
seam 17 20 1.00
seam 17 21 0.98
seam 17 22 1.00
seam 18 13 0.99
seam 18 14 0.99
seam 18 15 1.00
seam 18 18 1.00
seam 18 20 1.00
seam 18 23 0.99
seam 19 13 1.00
seam 19 14 0.99
seam 19 18 1.00
seam 19 19 1.00
seam 19 21 1.00
seam 19 22 0.97
seam 20 1 0.67
seam 20 13 1.00
seam 20 14 1.00
seam 20 18 0.98
seam 20 19 0.98
seam 20 20 1.00
seam 20 22 0.94
seam 21 13 0.94
seam 21 14 1.00
seam 21 18 1.00
seam 21 19 0.98
seam 21 20 0.97
seam 21 21 0.94
seam 22 14 0.90
seam 22 15 1.00
seam 22 18 0.92
seam 22 19 0.99
seam 22 20 0.90
seam 22 22 0.88
seam 24 17 0.07
