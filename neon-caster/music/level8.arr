; NEON-CASTER - level8's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 109.967   offset 1.7308   bars 16   tail 17
source level8.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     groove
clip B  bars 5-8     build
clip C  bars 9-16    groove
clip D  bars 1-12    groove
clip E  bars 5-16    build
clip F  bars 13-16   groove
clip G  bars 1-8     groove
clip H  bars 5-12    build
clip I  bars 1-16    groove
arrange D E F B G D H I B D B
seam 1 3 0.59
seam 1 4 0.59
seam 1 6 0.76
seam 1 7 0.65
seam 1 10 1.00
seam 1 14 0.69
seam 2 4 0.77
seam 2 7 0.97
seam 2 8 0.66
seam 2 11 1.00
seam 2 12 0.70
seam 2 15 0.70
seam 3 3 0.77
seam 3 5 0.78
seam 3 7 0.80
seam 3 11 0.81
seam 3 12 1.00
seam 3 13 0.84
seam 4 3 0.62
seam 4 4 0.78
seam 4 7 0.64
seam 4 8 0.65
seam 4 12 0.81
seam 4 13 0.99
seam 5 2 0.76
seam 5 4 0.66
seam 5 8 0.66
seam 5 10 0.72
seam 5 12 0.57
seam 5 14 0.95
seam 6 2 0.65
seam 6 3 0.97
seam 6 4 0.80
seam 6 11 0.92
seam 6 12 0.71
seam 6 15 0.65
seam 7 3 0.66
seam 7 4 0.76
seam 7 5 0.65
seam 7 6 0.66
seam 7 10 0.62
seam 7 12 0.69
seam 8 4 0.60
seam 8 7 0.60
seam 8 11 0.72
seam 8 12 0.62
seam 8 13 0.57
seam 8 15 0.61
seam 9 2 1.00
seam 9 6 0.72
seam 9 11 0.68
seam 9 12 0.76
seam 9 14 0.77
seam 9 16 0.63
seam 10 3 1.00
seam 10 4 0.81
seam 10 7 0.92
seam 10 12 0.81
seam 10 13 0.78
seam 10 15 0.74
seam 11 4 1.00
seam 11 5 0.81
seam 11 10 0.76
seam 11 11 0.81
seam 11 13 0.84
seam 11 14 0.74
seam 12 4 0.84
seam 12 5 0.99
seam 12 7 0.63
seam 12 8 0.60
seam 12 11 0.78
seam 12 12 0.84
seam 13 2 0.69
seam 13 4 0.57
seam 13 6 0.95
seam 13 8 0.58
seam 13 10 0.77
seam 13 12 0.74
seam 14 3 0.70
seam 14 7 0.65
seam 14 9 0.61
seam 14 11 0.74
seam 14 12 0.65
seam 14 13 0.56
seam 15 4 0.55
seam 15 10 0.63
seam 15 11 0.56
seam 15 12 0.62
seam 15 13 0.58
seam 15 15 0.55
seam 16 4 0.55
seam 16 10 0.56
seam 16 11 0.60
seam 16 12 0.69
seam 16 13 0.61
seam 16 16 0.69
