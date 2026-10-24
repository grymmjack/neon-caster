''
' NEON-CASTER - EDITOR/ARRANGER.BI
' =============================================================================
' The MUSIC ARRANGER (SOUND TEST: E on a track; the arranger command): one
' track's bars, clips and arrangement - music/NAME.arr, written by
' music/arrange.py - seen, heard and changed.
'
' Every track was a ~45 second take that looped abruptly. arrange.py found
' each one's beat and bars, cut it into clips that start and end on bar
' lines, and walked them into 3-4 minutes that loop (NAME.ogg, what the game
' plays). Here you hear the same thing put together live from the take
' itself (music/edit/NAME.flac: arrange.py --sources), so a change is heard
' at once: the arrangement played block by block, any clip launched to
' start on the next bar (as a DAW's clip launcher does), or the take as it
' is. What you launch can be recorded into the arrangement. Ctrl+S saves the
' .arr; arrange.py --render NAME makes the .ogg from it (Ctrl+E runs that).
'
' The sound is pushed to the card a little ahead (_SNDRAWBATCH, about a
' tenth of a second), sample by sample from the take: a jump from one bar to
' another is an equal-power crossfade just before the bar line - the same
' join the renderer makes.
'

CONST AR_TPB = 32 ' (time is counted in steps of a 32nd of a bar - a 32nd note: AR_TPB a bar, 8 a beat. Step t is bar t \ AR_TPB; bar 0, the lead-in, is steps 0-31)
CONST AR_CLIPS = 64, AR_SEQ = 256, AR_SEAMS = 4096, AR_UNDO = 64, AR_RING = 256, AR_REC = 1024
CONST AR_SOURCE = 1, AR_ARRANGE = 2, AR_SESSION = 3 ' (what the player walks: the take as it is, the arrangement, launched clips)
CONST AR_X0 = 16 ' (the take's strip and the arrangement's row: arW pixels across from AR_X0)
DIM SHARED arW, arPadsRow, arOvW ' (as wide as the screen is: scrW - 32, the pads a row - ArLayout; the width the waveform overview was worked out for)
arW = 768 : arPadsRow = 13
CONST AR_XF = 0.015, AR_LEAD = 0.1 ' (a jump's crossfade, and how far ahead the sound is pushed - seconds)
CONST AR_SRC_Y0 = 76, AR_SRC_Y1 = 156, AR_LANE_Y = 162, AR_LANE_H = 18, AR_LANES = 5 ' (the take, and its clips in lanes under it)
CONST AR_PAD_Y = 274, AR_PAD_W = 56, AR_PAD_H = 38 ' (the clip launcher's pads: arPadsRow a row)
CONST AR_SEQ_Y0 = 378, AR_SEQ_Y1 = 418 ' (the arrangement's blocks)

' The .arr: tempo (a bar is 4 beats), where bar 1 starts (seconds into the
' take), how many bars, where the fade at the end starts; the clips (a run
' of steps each - from arClipA up to, not including, arClipE - named A,
' B...); the arrangement (clips in order, each so many times); the seams
' (after bar I, bar J can follow - how alike, 0-1)
DIM SHARED arName$, arBpm AS DOUBLE, arOffs AS DOUBLE, arBars, arTail, arSource$, arAuto, arLoaded
DIM SHARED arClipN, arClipName$(AR_CLIPS), arClipA(AR_CLIPS), arClipE(AR_CLIPS), arClipKind$(AR_CLIPS), arLane(AR_CLIPS)
DIM SHARED arSeqN, arSeqClip(AR_SEQ), arSeqTimes(AR_SEQ)
DIM SHARED arSeamN, arSeamI(AR_SEAMS), arSeamJ(AR_SEAMS), arSeamS(AR_SEAMS) AS SINGLE

' The take's samples (arFrames a channel, arRate a second), and its
' waveform squeezed to arW columns
REDIM SHARED arL(0) AS SINGLE, arR(0) AS SINGLE
DIM SHARED arFrames AS LONG, arRate AS DOUBLE
REDIM SHARED arOvMin(767) AS SINGLE, arOvMax(767) AS SINGLE

' The player: the step being pushed (arTick, arPos frames into it), the
' block and time through it (arK, arRep) or the clip launched (arClip), the
' step decided on next (arNext: AR_UNDECIDED not yet, -1 the end) and the
' clip queued (arQueued - on the next bar, or at the clip's end with
' arQuantClip); arClock: steps played since it started (a launch waits for
' a whole bar of them)
CONST AR_UNDECIDED = -2
DIM SHARED arPipe&, arPlaying, arMode, arTick, arPos AS DOUBLE, arK, arRep, arClip, arClock AS LONG
DIM SHARED arNext, arNextK, arNextRep, arNextClip, arQueued, arQuantClip
DIM SHARED arStep AS DOUBLE, arOutRate AS DOUBLE, arGen AS DOUBLE, arFadeIn
DIM SHARED arBuf(1023) AS SINGLE ' (512 frames, left and right)
' What was pushed when (a line each bar), so what's being HEARD can be
' worked out: the sound pushed less what's still queued (arH...)
DIM SHARED arRingN, arRingCnt, arRingF(AR_RING - 1) AS DOUBLE, arRingTick(AR_RING - 1), arRingPos(AR_RING - 1) AS DOUBLE
DIM SHARED arRingK(AR_RING - 1), arRingRep(AR_RING - 1), arRingClip(AR_RING - 1), arRingMode(AR_RING - 1)
DIM SHARED arHTick, arHPos AS DOUBLE, arHK, arHRep, arHClip, arHMode, arHeard
' Recording what's launched: runs of steps, each in one clip (arRecOn: started - at a clip's first step)
DIM SHARED arRec, arRecOn, arRecN, arRecClip(AR_REC), arRecA(AR_REC), arRecB(AR_REC)
' Editing: the clip and block picked, unsaved changes, undo and redo (the
' clips and arrangement as text), the message line, the mouse's drags
DIM SHARED arSelClip, arSelK, arDirty, arMsg$, arMsgT AS DOUBLE, arLeave, arDone
DIM SHARED arUndoN, arUndo$(AR_UNDO), arRedoN, arRedo$(AR_UNDO)
DIM SHARED arDrag, arDragClip, arDragEdge, arDragK, arDragPushed, arClickT AS DOUBLE, arClickK
DIM SHARED arLoopK ' (the block the arrangement loops back to - 0: the start; the blocks before it are an intro, played once: a | in the .arr)
DIM SHARED arDragA, arDragB, arDragX, arDragMoved ' (across the take: the grid squares a new clip will be, first and last - arDrag 3; arDragX where it was pressed - moved 4 pixels: a drag, which makes a clip, else a click, which plays)
' The take's strip zoomed: frames arView0# on, arViewN# of them across (the wheel over it zooms,
' the middle button shows it all); the waveform worked out for that (arOvV0#, arOvN#); the grid
' a drag or an end snaps to, in steps (as fine as the zoom shows: ArGridNow)
DIM SHARED arView0 AS DOUBLE, arViewN AS DOUBLE, arOvV0 AS DOUBLE, arOvN AS DOUBLE, arGrid
DIM SHARED arCtrlK, arShiftK ' (Ctrl and Shift as the key queue has them - a quick Ctrl+S is up again before the S is read)
DIM SHARED arRenderLog$, arRenderT AS DOUBLE, arRenderWhat$ ' (Ctrl+E: arrange.py --render writing its log there - Ctrl+B: daw.py's export; arRenderWhat$ which)
