''
' NEON-CASTER - GAME/NEXUS.BI
' =============================================================================
' NEXUS's voice: each line's words and sound.
'

' NEXUS's voice: each line's sound (neon-caster/speech/KEY.wav) and words,
' looked up by key (Say); what's on screen (speechText$, until
' speechUntil!), and frames till the next taunt
CONST MAX_LINES = 160
DIM SHARED lineKey$(MAX_LINES), lineText$(MAX_LINES), lineSnd&(MAX_LINES), numLines AS INTEGER
DIM SHARED speechText$, speechUntil!, tauntWait AS LONG, lastTaunt AS INTEGER, cliMode AS INTEGER, nexusImg&
' NEXUS's lines (and its minions' barks): key, then words
RESTORE SpeechLines
DO
    READ k$, t$ : IF k$ = "" THEN EXIT DO
    numLines = numLines + 1 : lineKey$(numLines) = k$ : lineText$(numLines) = t$
    p$ = AssetPath$("speech/" + k$ + ".wav") : IF _FILEEXISTS(p$) THEN lineSnd&(numLines) = _SNDOPEN(p$, "noasync")
LOOP
tauntWait = 3600
