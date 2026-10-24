; NEON-CASTER - cyber's bars, clips and arrangement (music/arrange.py; bars count from 1)
; arrange: clips in order, CLIP*N repeats one; the file loops as a whole. seam I J S: after bar I, bar J can follow (S: how alike, 0-1)
bpm 124.000   offset 0.0021   bars 15   tail 16
source cyber.flac
auto yes          ; yes: arrange.py --analyze may rewrite the clips and arrangement - no: they're yours
clip A  bars 1-2     intro
clip B  bars 3-10    peak
clip C  bars 11-15   groove
clip D  bars 7-14    peak
clip E  bars 11-14   groove
clip F  bars 3-14    peak
clip G  bars 7-10    peak
clip H  bars 3-6     peak
arrange D B D E D*2 B F G D E H B F E
seam 1 6 0.40
seam 1 10 0.40
seam 1 14 0.40
seam 2 1 0.13
seam 2 7 0.63
seam 2 11 0.63
seam 2 15 0.63
seam 3 6 0.41
seam 3 8 0.98
seam 3 10 0.42
seam 3 12 0.98
seam 3 14 0.42
seam 4 6 0.44
seam 4 9 0.98
seam 4 11 0.44
seam 4 13 0.98
seam 4 14 0.44
seam 4 15 0.44
seam 5 8 0.45
seam 5 9 0.45
seam 5 10 1.00
seam 5 12 0.45
seam 5 13 0.45
seam 5 14 1.00
seam 6 3 0.63
seam 6 5 0.44
seam 6 9 0.46
seam 6 11 1.00
seam 6 13 0.46
seam 6 15 1.00
seam 7 4 0.98
seam 7 6 0.45
seam 7 10 0.46
seam 7 12 1.00
seam 7 14 0.46
seam 8 5 0.98
seam 8 7 0.46
seam 8 11 0.46
seam 8 13 1.00
seam 8 14 0.45
seam 8 15 0.46
seam 9 6 1.00
seam 9 8 0.46
seam 9 9 0.45
seam 9 12 0.46
seam 9 13 0.45
seam 9 14 1.00
seam 10 3 0.63
seam 10 5 0.44
seam 10 7 1.00
seam 10 9 0.46
seam 10 13 0.46
seam 10 15 1.00
seam 11 4 0.98
seam 11 6 0.45
seam 11 8 1.00
seam 11 10 0.46
seam 11 14 0.46
seam 12 5 0.98
seam 12 7 0.46
seam 12 9 1.00
seam 12 11 0.46
seam 12 14 0.45
seam 12 15 0.46
seam 13 6 1.00
seam 13 8 0.46
seam 13 9 0.45
seam 13 10 1.00
seam 13 12 0.46
seam 13 13 0.45
seam 14 3 0.63
seam 14 5 0.44
seam 14 7 1.00
seam 14 9 0.46
seam 14 11 1.00
seam 14 13 0.46
seam 15 4 0.44
seam 15 7 0.57
seam 15 8 0.51
seam 15 11 0.57
seam 15 12 0.51
seam 15 15 0.58
