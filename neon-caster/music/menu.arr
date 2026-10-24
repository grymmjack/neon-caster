; NEON-CASTER - menu's bars, clips and arrangement (music/arrange.py; bars count from 1 - bar 0 is the lead-in before it)
; arrange: clips in order, CLIP*N repeats one; it loops as a whole - or, after a |, from there (what's before it plays once: an intro). seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 130.011   offset 1.1653   bars 22   tail 23
source menu.ogg (lossy)
auto no          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-4     groove
clip B  bars 5-8     groove
clip C  bars 9-16    groove
clip D  bars 17-22   break
clip E  bars 13-20   groove
clip F  bars 17-20   break
clip G  bars 1-8     groove
clip H  bars 5-12    groove
clip I  bars 1-20    groove
clip J  bars 9-12    groove
clip K  bars 5-16    groove
clip L  bars 0-0     intro
arrange L | C E F G H I E B A I J K A
seam 1 5 0.49
seam 1 6 1.00
seam 1 10 0.95
seam 1 14 0.92
seam 1 18 0.88
seam 1 22 0.84
seam 2 5 0.48
seam 2 7 1.00
seam 2 9 0.46
seam 2 11 0.87
seam 2 15 0.83
seam 2 19 0.84
seam 3 8 1.00
seam 3 12 0.84
seam 3 13 0.47
seam 3 16 0.74
seam 3 17 0.52
seam 3 20 0.81
seam 4 1 1.00
seam 4 2 0.49
seam 4 9 1.00
seam 4 13 0.90
seam 4 17 0.76
seam 4 18 0.49
seam 4 21 0.85
seam 5 2 1.00
seam 5 5 0.46
seam 5 10 0.93
seam 5 14 0.94
seam 5 18 0.83
seam 5 22 0.89
seam 6 3 1.00
seam 6 5 0.44
seam 6 11 0.83
seam 6 15 0.86
seam 6 19 0.79
seam 6 21 0.43
seam 7 4 1.00
seam 7 12 0.78
seam 7 13 0.46
seam 7 16 0.76
seam 7 17 0.49
seam 7 20 0.75
seam 8 1 1.00
seam 8 5 1.00
seam 8 12 0.51
seam 8 13 0.86
seam 8 17 0.85
seam 8 18 0.49
seam 8 21 0.85
seam 9 2 0.95
seam 9 6 0.93
seam 9 14 1.00
seam 9 16 0.58
seam 9 18 1.00
seam 9 22 1.00
seam 10 3 0.87
seam 10 7 0.83
seam 10 13 0.65
seam 10 15 1.00
seam 10 17 0.65
seam 10 19 1.00
seam 11 4 0.84
seam 11 8 0.78
seam 11 16 1.00
seam 11 17 0.68
seam 11 20 1.00
seam 11 21 0.65
seam 12 1 0.97
seam 12 5 0.90
seam 12 9 0.86
seam 12 11 0.65
seam 12 17 1.00
seam 12 19 0.66
seam 12 21 1.00
seam 13 2 0.92
seam 13 6 0.94
seam 13 10 1.00
seam 13 16 0.65
seam 13 18 1.00
seam 13 22 1.00
seam 14 3 0.83
seam 14 7 0.86
seam 14 11 1.00
seam 14 17 0.62
seam 14 19 1.00
seam 14 21 0.60
seam 15 4 0.74
seam 15 8 0.76
seam 15 12 1.00
seam 15 14 0.65
seam 15 20 1.00
seam 15 22 0.65
seam 16 1 0.89
seam 16 5 0.76
seam 16 9 0.85
seam 16 12 0.68
seam 16 13 1.00
seam 16 20 0.68
seam 16 21 1.00
seam 17 2 0.88
seam 17 6 0.83
seam 17 10 1.00
seam 17 14 1.00
seam 17 16 0.64
seam 17 22 1.00
seam 18 3 0.84
seam 18 7 0.79
seam 18 11 1.00
seam 18 13 0.66
seam 18 15 1.00
seam 18 17 0.66
seam 19 4 0.81
seam 19 8 0.75
seam 19 12 1.00
seam 19 16 1.00
seam 19 17 0.68
seam 19 21 0.64
seam 20 1 0.91
seam 20 5 0.85
seam 20 9 0.85
seam 20 12 0.65
seam 20 13 1.00
seam 20 17 1.00
seam 20 19 0.65
seam 21 2 0.84
seam 21 6 0.89
seam 21 10 1.00
seam 21 14 1.00
seam 21 16 0.65
seam 21 18 1.00
seam 22 11 0.70
seam 22 14 0.68
seam 22 15 0.66
seam 22 17 0.73
seam 22 18 0.64
seam 22 19 0.71
seam 22 22 0.65
