; NEON-CASTER - huge2's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.031   offset 0.9333   bars 24   tail 24
source huge2.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-8     peak
clip B  bars 9-16    peak
clip C  bars 17-23   break
clip D  bars 13-20   peak
clip E  bars 1-12    peak
clip F  bars 9-12    peak
clip G  bars 5-8     peak
clip H  bars 1-4     peak
clip I  bars 5-20    peak
clip J  bars 1-16    peak
clip K  bars 5-12    peak
arrange D E F G H E G I H J K A E
seam 1 4 1.00
seam 1 6 1.00
seam 1 8 0.93
seam 1 10 1.00
seam 1 11 0.83
seam 1 12 0.94
seam 2 5 1.00
seam 2 6 0.97
seam 2 7 1.00
seam 2 9 0.93
seam 2 10 0.93
seam 2 11 1.00
seam 3 2 1.00
seam 3 6 1.00
seam 3 8 0.99
seam 3 10 0.97
seam 3 11 0.88
seam 3 12 0.99
seam 4 1 1.00
seam 4 3 1.00
seam 4 6 0.92
seam 4 7 1.00
seam 4 9 0.99
seam 4 11 0.97
seam 4 13 0.93
seam 5 2 1.00
seam 5 3 0.97
seam 5 4 1.00
seam 5 7 0.98
seam 5 10 1.00
seam 5 11 0.99
seam 6 3 1.00
seam 6 5 1.00
seam 6 6 0.98
seam 6 9 0.93
seam 6 10 0.95
seam 6 11 1.00
seam 7 2 0.93
seam 7 4 0.99
seam 7 6 0.93
seam 7 7 0.78
seam 7 10 0.89
seam 7 12 0.97
seam 8 1 1.00
seam 8 3 0.93
seam 8 5 0.99
seam 8 7 0.93
seam 8 10 0.83
seam 8 11 0.89
seam 8 13 0.88
seam 9 2 1.00
seam 9 3 0.93
seam 9 4 0.97
seam 9 6 1.00
seam 9 7 0.95
seam 9 11 0.97
seam 10 3 1.00
seam 10 5 0.97
seam 10 6 0.99
seam 10 7 1.00
seam 10 9 0.89
seam 10 10 0.97
seam 11 2 0.94
seam 11 4 0.99
seam 11 6 0.91
seam 11 8 0.97
seam 11 10 0.87
seam 11 14 0.86
seam 12 1 0.69
seam 12 3 0.91
seam 12 5 0.93
seam 12 6 0.71
seam 12 7 0.84
seam 12 9 0.88
seam 12 11 0.87
seam 13 2 0.71
seam 13 4 0.76
seam 13 6 0.76
seam 13 8 0.70
seam 13 10 0.71
seam 13 12 0.86
seam 14 3 0.70
seam 14 5 0.65
seam 14 7 0.70
seam 14 9 0.61
seam 14 11 0.66
seam 14 13 0.67
seam 15 2 0.55
seam 15 4 0.70
seam 15 6 0.61
seam 15 8 0.75
seam 15 10 0.56
seam 15 12 0.69
seam 16 1 0.54
seam 16 5 0.64
seam 16 9 0.62
seam 16 18 0.59
seam 16 19 0.61
seam 16 21 0.61
seam 16 22 0.61
seam 17 17 0.59
seam 17 19 0.87
seam 17 20 0.74
seam 17 21 0.72
seam 17 22 1.00
seam 17 23 0.59
seam 18 17 0.61
seam 18 18 0.87
seam 18 20 0.67
seam 18 21 0.72
seam 18 22 0.89
seam 18 23 0.72
seam 19 17 0.48
seam 19 18 0.74
seam 19 19 0.67
seam 19 21 0.56
seam 19 22 0.70
seam 19 23 0.56
seam 20 1 0.53
seam 20 3 0.50
seam 20 5 0.47
seam 20 13 0.42
seam 20 17 0.61
seam 20 18 0.72
seam 20 19 0.72
seam 20 20 0.56
seam 20 22 0.75
seam 21 17 0.61
seam 21 18 1.00
seam 21 19 0.89
seam 21 20 0.70
seam 21 21 0.75
seam 21 23 0.63
seam 22 17 0.43
seam 22 18 0.59
seam 22 19 0.72
seam 22 20 0.56
seam 22 21 0.50
seam 22 22 0.63
seam 23 17 0.24
seam 23 18 0.40
seam 23 19 0.43
seam 23 20 0.43
seam 23 21 0.40
seam 23 22 0.43
seam 23 23 0.63
