; NEON-CASTER - new7's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 125.000   offset 0.0240   bars 23   tail 24
source new7.wav
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     intro
clip B  bars 5-8     peak
clip C  bars 9-16    groove
clip D  bars 17-23   break
clip E  bars 5-20    peak
clip F  bars 13-20   groove
clip G  bars 5-12    peak
clip H  bars 13-16   groove
clip I  bars 9-12    groove
clip J  bars 5-16    peak
clip K  bars 9-20    groove
arrange E F E G E H I E J K
seam 1 3 0.48
seam 1 4 1.00
seam 1 12 0.38
seam 1 20 0.38
seam 2 2 0.48
seam 2 4 0.48
seam 2 5 0.36
seam 2 13 0.37
seam 2 21 0.36
seam 3 2 1.00
seam 3 3 0.48
seam 3 12 0.37
seam 3 20 0.37
seam 4 7 0.39
seam 4 11 0.69
seam 4 13 1.00
seam 4 19 0.70
seam 4 21 1.00
seam 4 23 0.39
seam 5 7 0.70
seam 5 8 0.76
seam 5 14 1.00
seam 5 16 0.75
seam 5 22 1.00
seam 5 23 0.70
seam 6 6 0.70
seam 6 8 0.67
seam 6 14 0.70
seam 6 15 1.00
seam 6 22 0.70
seam 6 23 1.00
seam 7 6 0.76
seam 7 7 0.67
seam 7 14 0.76
seam 7 16 1.00
seam 7 22 0.74
seam 7 23 0.68
seam 8 7 0.49
seam 8 8 0.50
seam 8 15 0.49
seam 8 16 0.50
seam 8 17 1.00
seam 8 23 0.49
seam 9 9 0.48
seam 9 11 0.49
seam 9 17 0.48
seam 9 18 1.00
seam 9 19 0.47
seam 9 20 0.41
seam 10 5 0.69
seam 10 13 0.69
seam 10 15 0.64
seam 10 19 1.00
seam 10 21 0.70
seam 10 23 0.63
seam 11 6 0.43
seam 11 10 0.40
seam 11 14 0.43
seam 11 18 0.41
seam 11 20 1.00
seam 11 22 0.43
seam 12 5 1.00
seam 12 7 0.39
seam 12 11 0.69
seam 12 19 0.69
seam 12 21 1.00
seam 12 23 0.39
seam 13 6 1.00
seam 13 7 0.70
seam 13 8 0.76
seam 13 16 0.76
seam 13 22 1.00
seam 13 23 0.70
seam 14 6 0.69
seam 14 7 1.00
seam 14 8 0.67
seam 14 14 0.69
seam 14 22 0.69
seam 14 23 1.00
seam 15 6 0.75
seam 15 7 0.67
seam 15 8 1.00
seam 15 14 0.76
seam 15 22 0.74
seam 15 23 0.68
seam 16 7 0.50
seam 16 8 0.51
seam 16 9 1.00
seam 16 15 0.50
seam 16 16 0.51
seam 16 23 0.50
seam 17 9 0.46
seam 17 10 1.00
seam 17 11 0.47
seam 17 17 0.47
seam 17 19 0.45
seam 17 20 0.43
seam 18 5 0.70
seam 18 7 0.61
seam 18 11 1.00
seam 18 13 0.69
seam 18 15 0.62
seam 18 21 0.71
seam 19 6 0.44
seam 19 10 0.41
seam 19 12 1.00
seam 19 14 0.44
seam 19 18 0.43
seam 19 22 0.44
seam 20 5 1.00
seam 20 7 0.40
seam 20 11 0.70
seam 20 13 1.00
seam 20 19 0.71
seam 20 23 0.40
seam 21 6 1.00
seam 21 7 0.70
seam 21 8 0.74
seam 21 14 1.00
seam 21 16 0.74
seam 21 23 0.70
seam 22 6 0.70
seam 22 7 1.00
seam 22 8 0.68
seam 22 14 0.70
seam 22 15 1.00
seam 22 22 0.70
seam 23 6 0.81
seam 23 7 0.87
seam 23 14 0.80
seam 23 15 0.87
seam 23 22 0.80
seam 23 23 0.87
