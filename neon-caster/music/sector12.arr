; NEON-CASTER - sector12's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 123.601   offset 0.5574   bars 22   tail 19
source sector12.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     peak
clip B  bars 5-12    build
clip C  bars 13-18   peak
clip D  bars 9-12    build
clip E  bars 5-8     build
clip F  bars 9-16    build
clip G  bars 13-16   peak
clip H  bars 5-16    build
arrange D E B F G F G D F D E B H G*2 D*2
seam 1 3 0.95
seam 1 4 1.00
seam 1 5 0.64
seam 1 6 0.38
seam 1 11 0.38
seam 1 14 0.39
seam 2 2 0.95
seam 2 4 0.95
seam 2 5 0.69
seam 2 6 0.41
seam 2 12 0.39
seam 2 15 0.40
seam 3 2 1.00
seam 3 3 0.95
seam 3 5 0.70
seam 3 6 0.43
seam 3 12 0.43
seam 3 14 0.42
seam 4 2 0.64
seam 4 3 0.69
seam 4 4 0.70
seam 4 6 0.61
seam 4 12 0.61
seam 4 15 0.66
seam 5 7 0.86
seam 5 8 0.86
seam 5 11 0.87
seam 5 12 0.87
seam 5 13 0.86
seam 5 15 0.92
seam 6 8 0.98
seam 6 9 0.96
seam 6 10 0.94
seam 6 11 0.87
seam 6 12 0.89
seam 6 15 0.90
seam 7 7 0.98
seam 7 9 1.00
seam 7 10 1.00
seam 7 11 0.98
seam 7 12 0.98
seam 7 15 0.92
seam 8 7 0.96
seam 8 8 1.00
seam 8 10 1.00
seam 8 11 1.00
seam 8 12 1.00
seam 8 15 0.97
seam 9 7 0.94
seam 9 8 1.00
seam 9 9 1.00
seam 9 11 1.00
seam 9 12 0.94
seam 9 14 0.92
seam 10 8 0.98
seam 10 9 1.00
seam 10 10 1.00
seam 10 12 0.94
seam 10 14 0.91
seam 10 15 0.89
seam 11 7 0.89
seam 11 8 0.98
seam 11 9 1.00
seam 11 10 0.94
seam 11 11 0.94
seam 11 15 1.00
seam 12 6 0.86
seam 12 8 0.88
seam 12 9 0.92
seam 12 10 0.91
seam 12 15 1.00
seam 12 16 1.00
seam 13 7 0.87
seam 13 8 0.88
seam 13 9 0.91
seam 13 10 0.92
seam 13 11 0.91
seam 13 12 0.89
seam 14 6 0.92
seam 14 8 0.92
seam 14 9 0.97
seam 14 12 1.00
seam 14 13 1.00
seam 14 16 0.93
seam 15 9 0.84
seam 15 13 1.00
seam 15 14 0.82
seam 15 15 0.93
seam 15 17 1.00
seam 15 18 0.82
seam 16 7 0.69
seam 16 13 0.83
seam 16 14 0.66
seam 16 15 0.78
seam 16 16 1.00
seam 16 18 0.98
seam 17 7 0.53
seam 17 13 0.65
seam 17 14 0.60
seam 17 15 0.55
seam 17 16 0.82
seam 17 17 0.98
seam 18 13 0.61
seam 18 14 0.57
seam 18 15 0.55
seam 18 16 0.73
seam 18 17 0.85
seam 18 18 0.98
