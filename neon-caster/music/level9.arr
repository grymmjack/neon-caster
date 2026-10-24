; NEON-CASTER - level9's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 120.053   offset 1.3056   bars 17   tail 17
source level9.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-2     intro
clip B  bars 3-10    groove
clip C  bars 13-16   peak
clip D  bars 9-16    groove
clip E  bars 5-8     groove
clip F  bars 5-16    groove
clip G  bars 5-12    groove
arrange D E F*2 C D G*2 F D F C E
seam 1 3 0.44
seam 2 4 0.79
seam 2 5 0.52
seam 2 6 0.49
seam 2 7 0.49
seam 2 8 0.48
seam 2 13 0.51
seam 3 3 0.79
seam 3 5 0.98
seam 3 6 0.85
seam 3 7 0.80
seam 3 8 0.74
seam 3 14 0.74
seam 4 4 0.98
seam 4 6 1.00
seam 4 7 0.99
seam 4 8 0.98
seam 4 9 0.70
seam 4 14 0.77
seam 5 4 0.85
seam 5 5 1.00
seam 5 7 1.00
seam 5 8 0.93
seam 5 9 0.83
seam 5 15 0.67
seam 6 4 0.80
seam 6 5 0.99
seam 6 6 1.00
seam 6 8 1.00
seam 6 9 0.82
seam 6 10 0.63
seam 7 4 0.74
seam 7 5 0.98
seam 7 6 0.93
seam 7 7 1.00
seam 7 9 0.98
seam 7 10 0.75
seam 8 5 0.70
seam 8 6 0.83
seam 8 7 0.82
seam 8 8 0.98
seam 8 10 0.98
seam 8 11 0.81
seam 9 7 0.63
seam 9 8 0.75
seam 9 9 0.98
seam 9 11 1.00
seam 9 12 0.83
seam 9 13 0.72
seam 10 8 0.61
seam 10 9 0.81
seam 10 10 1.00
seam 10 12 0.83
seam 10 13 0.69
seam 10 14 0.56
seam 11 8 0.59
seam 11 9 0.69
seam 11 10 0.83
seam 11 11 0.83
seam 11 13 0.70
seam 11 14 0.65
seam 12 4 0.72
seam 12 10 0.72
seam 12 12 0.70
seam 12 14 0.84
seam 12 15 0.82
seam 12 16 0.76
seam 13 4 0.74
seam 13 5 0.77
seam 13 6 0.67
seam 13 13 0.84
seam 13 15 1.00
seam 13 16 1.00
seam 14 4 0.65
seam 14 5 0.66
seam 14 6 0.67
seam 14 13 0.82
seam 14 14 1.00
seam 14 16 1.00
seam 15 4 0.64
seam 15 5 0.62
seam 15 6 0.64
seam 15 13 0.76
seam 15 14 1.00
seam 15 15 1.00
seam 16 4 0.70
seam 16 6 0.71
seam 16 13 0.87
seam 16 14 1.00
seam 16 15 1.00
seam 16 16 1.00
