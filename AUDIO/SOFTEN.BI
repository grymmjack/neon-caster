''
' NEON-CASTER - AUDIO/SOFTEN.BI
' =============================================================================
' SOFTEN HIGHS (SETTINGS > AUDIO): a low-pass filter over every sound effect
' and voice line, run on their samples in memory (AUDIO/SOFTEN.BM).
'

' Every sound opened with OpenSnd& (LoadSnd&, NEXUS's lines): its handle and
' file, so SoftenAll can filter them all - and a copy of its samples as
' they were (sndRegB, made the first time it's filtered: the sound engine
' keeps one copy of a sound however it's opened again, so it can't be read
' back from the file). softenNow = the strength their samples have now (0 =
' as loaded).
CONST SND_REG_MAX = 800
DIM SHARED sndRegH&(SND_REG_MAX), sndRegF$(SND_REG_MAX), sndRegN, softenNow
DIM SHARED sndRegB(SND_REG_MAX) AS _MEM, sndRegHasB(SND_REG_MAX)
' The strengths: LIGHT one 12 dB/octave filter at 10 kHz, STRONG two at 7 kHz
CONST SOFTEN_LIGHT_HZ = 10000, SOFTEN_STRONG_HZ = 7000
