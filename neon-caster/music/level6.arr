; NEON-CASTER - level6's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 122.000   offset 0.8768   bars 19   tail 20
source level6.ogg (lossy)
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-2     intro
clip B  bars 3-8     build
clip C  bars 9-16    peak
clip D  bars 13-16   peak
clip E  bars 5-12    build
clip F  bars 5-16    build
clip G  bars 9-12    peak
clip H  bars 5-8     build
arrange D E*2 C D F D G H E F C F D
seam 1 3 0.35
seam 1 6 0.49
seam 1 10 0.40
seam 1 11 0.38
seam 1 12 0.37
seam 1 17 0.40
seam 2 1 0.21
seam 2 7 0.92
seam 2 10 0.56
seam 2 11 0.60
seam 2 13 0.57
seam 2 14 0.62
seam 2 17 0.61
seam 3 5 0.77
seam 3 7 0.66
seam 3 8 0.81
seam 3 11 0.63
seam 3 12 0.69
seam 3 17 0.58
seam 4 4 0.77
seam 4 6 0.80
seam 4 8 0.79
seam 4 9 0.78
seam 4 11 0.78
seam 4 12 0.82
seam 5 5 0.80
seam 5 10 0.82
seam 5 11 0.95
seam 5 12 0.93
seam 5 13 0.98
seam 5 17 0.83
seam 6 3 0.92
seam 6 6 0.78
seam 6 11 0.81
seam 6 12 0.82
seam 6 13 0.90
seam 6 14 0.98
seam 7 4 0.81
seam 7 5 0.79
seam 7 7 0.76
seam 7 9 0.64
seam 7 12 0.78
seam 7 13 0.65
seam 8 3 0.33
seam 8 5 0.78
seam 8 6 0.79
seam 8 10 0.73
seam 8 11 0.76
seam 8 12 0.73
seam 8 13 0.77
seam 9 6 0.82
seam 9 9 0.73
seam 9 11 0.99
seam 9 12 1.00
seam 9 13 0.86
seam 9 17 0.98
seam 10 6 0.95
seam 10 7 0.81
seam 10 10 0.99
seam 10 12 1.00
seam 10 13 1.00
seam 10 17 1.00
seam 11 6 0.93
seam 11 7 0.82
seam 11 10 1.00
seam 11 11 1.00
seam 11 13 0.95
seam 11 17 1.00
seam 12 5 0.73
seam 12 6 0.98
seam 12 7 0.90
seam 12 9 0.77
seam 12 11 1.00
seam 12 12 0.95
seam 12 14 0.95
seam 12 17 0.95
seam 13 7 0.98
seam 13 11 0.79
seam 13 12 0.78
seam 13 13 0.95
seam 13 18 0.74
seam 13 19 0.79
seam 14 8 0.58
seam 14 12 0.64
seam 14 14 0.73
seam 14 16 0.55
seam 14 18 0.57
seam 14 19 0.66
seam 15 10 0.65
seam 15 11 0.65
seam 15 12 0.68
seam 15 13 0.61
seam 15 17 0.76
seam 15 19 0.58
seam 16 5 0.66
seam 16 6 0.83
seam 16 7 0.76
seam 16 9 0.67
seam 16 10 0.98
seam 16 11 1.00
seam 16 12 1.00
seam 16 13 0.95
seam 17 10 0.66
seam 17 11 0.78
seam 17 12 0.71
seam 17 13 0.79
seam 17 14 0.74
seam 17 17 0.73
seam 18 7 0.62
seam 18 10 0.68
seam 18 12 0.59
seam 18 14 0.79
seam 18 15 0.66
seam 18 18 0.58
seam 19 4 0.71
seam 19 11 0.66
seam 19 14 0.81
seam 19 15 0.85
seam 19 16 0.69
seam 19 19 0.80
