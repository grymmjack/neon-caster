; NEON-CASTER - level3's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 90.000   offset 0.0316   bars 15   tail 15
source level3.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     intro
clip B  bars 9-14    peak
clip C  bars 1-4     intro
clip D  bars 1-12    intro
clip E  bars 5-12    intro
arrange C*3 D E*6
seam 1 3 0.55
seam 1 4 0.39
seam 1 5 0.50
seam 1 6 0.89
seam 1 12 0.45
seam 1 14 0.46
seam 2 4 0.75
seam 2 6 0.65
seam 2 7 1.00
seam 2 12 0.77
seam 2 13 0.81
seam 2 14 0.70
seam 3 3 0.75
seam 3 5 0.64
seam 3 7 0.72
seam 3 8 0.96
seam 3 12 0.56
seam 3 13 0.58
seam 4 1 0.79
seam 4 2 0.50
seam 4 3 0.54
seam 4 4 0.64
seam 4 8 0.50
seam 4 11 0.49
seam 4 13 0.53
seam 5 2 0.89
seam 5 3 0.65
seam 5 11 0.59
seam 5 12 0.73
seam 5 13 0.61
seam 5 14 0.82
seam 6 3 1.00
seam 6 4 0.72
seam 6 11 0.64
seam 6 12 0.90
seam 6 13 0.90
seam 6 14 0.83
seam 7 3 0.58
seam 7 4 0.96
seam 7 5 0.50
seam 7 7 0.62
seam 7 12 0.53
seam 7 13 0.51
seam 8 5 0.39
seam 9 11 0.45
seam 10 3 0.59
seam 10 6 0.59
seam 10 7 0.64
seam 10 12 0.85
seam 10 13 0.76
seam 10 14 0.75
seam 11 3 0.77
seam 11 6 0.73
seam 11 7 0.90
seam 11 11 0.85
seam 11 13 1.00
seam 11 14 1.00
seam 12 1 0.26
seam 12 3 0.81
seam 12 5 0.53
seam 12 6 0.61
seam 12 7 0.90
seam 12 11 0.76
seam 12 12 1.00
seam 12 14 1.00
seam 13 3 0.70
seam 13 6 0.82
seam 13 7 0.83
seam 13 11 0.75
seam 13 12 1.00
seam 13 13 1.00
seam 14 3 0.81
seam 14 7 0.95
seam 14 11 0.75
seam 14 12 1.00
seam 14 13 1.00
seam 14 14 1.00
