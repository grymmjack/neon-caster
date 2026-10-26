''
' NEON-CASTER - LOOP/07-FRAME.BI
' =============================================================================
' Chapter 7 of the game loop - included in place, inside the DO ... LOOP
' in neon-caster.bas, so it runs every frame.
'

    IF demoPlay AND demoSpeed <> PL_SPEED_1 AND NOT demoFast THEN ' (a demo at another speed - DEMO/PLAYLIST.BM: the same frames, coming faster or slower)
        _LIMIT 60 * DemoSpeedX!(demoSpeed)
    ELSEIF NOT (demoFast AND demoPlay) THEN
        _LIMIT 60
    END IF
    ' Commands waiting (the command line's, an exec's): one a frame - or
    ' as many as come before a "wait"
    SfxFrame : earDX = dirX : earDY = dirY ' (the limiter's memory fades; your ears face where you do)
    STEAM_update : achFrame = achFrame + 1 ' (Steam's callbacks: achievements and stats arriving)
    ' The sector's clock stops while the game does: a frame that took over
    ' half a second was a loop of its own (the menu, the console, the
    ' editor, a terminal) - that time doesn't count
    frameGap! = TIMER - frameAt! : IF frameGap! < 0 THEN frameGap! = frameGap! + 86400
    IF frameAt! <> 0 AND frameGap! > 0.5 THEN levelStart! = levelStart! + frameGap! - 1 / 60
    frameAt! = TIMER
    ' F10: PHOTO MODE on and off (GAME/PHOTO.BM) - the game frozen, its clocks too
    IF _KEYDOWN(17408) AND NOT photoKeyWas AND NOT edTyping THEN PhotoSet NOT photoOn
    photoKeyWas = _KEYDOWN(17408)
    IF photoOn AND frameAt! <> 0 AND frameGap! <= 0.5 THEN levelStart! = levelStart! + frameGap! ' (the sector clock waits too - a longer frame it skips already, above)
    IF NOT editMode AND NOT photoOn THEN lvFrame = lvFrame + 1 ' (the sector's clock in frames: a trigger's "time", and a demo's)
    IF dead THEN deadTicks = deadTicks + 1 ELSE deadTicks = 0
    IF dead AND NOT achDeadSeen THEN achDeadSeen = -1 : AchAdd "Deaths", 1 ELSE IF NOT dead THEN achDeadSeen = 0
    gridOn = editMode AND edGrid : gridW = MaxOf(1, texSize \ 64) : gridA = edGridAlpha ' (the editor's grid this frame: chapter 21)
    ' THE GRID IN PLAY: ' shows or hides it, ; makes it weaker and : stronger
    ' (Shift+;) - the editor's grid, over the world while you play: where
    ' each cell starts, to see where things are
    gridKey = 0 : IF NOT editMode AND NOT edTyping THEN IF _KEYDOWN(39) THEN gridKey = 1 ELSE IF _KEYDOWN(58) THEN gridKey = 3 ELSE IF _KEYDOWN(59) THEN gridKey = 2
    IF gridKey <> 0 AND gridKey <> gridKeyWas THEN
        SELECT CASE gridKey
            CASE 1 : setting(SET_GRID) = 1 - setting(SET_GRID)
            CASE 2 : setting(SET_GRID) = 1 : setting(SET_GRIDA) = MaxOf(setMin(SET_GRIDA), setting(SET_GRIDA) - setStep(SET_GRIDA))
            CASE 3 : setting(SET_GRID) = 1 : setting(SET_GRIDA) = MinOf(setMax(SET_GRIDA), setting(SET_GRIDA) + setStep(SET_GRIDA))
        END SELECT
        IF setting(SET_GRID) THEN ShowMsg "Grid " + LTRIM$(STR$(setting(SET_GRIDA))) + "%   ( ' off   ; weaker   : stronger )" ELSE ShowMsg "Grid off"
        SaveSettings
    END IF
    gridKeyWas = gridKey
    IF NOT editMode AND setting(SET_GRID) THEN gridOn = -1 : gridA = setting(SET_GRIDA) * 255 \ 100
    SpeechFrame ' (NEXUS: what it says, when - chapter 19)
    DemoPlayFrame ' (a demo playing: . next, , previous, / at random, - and = its speed - and EACH's cut)
    IF plGoWant THEN plGoWant = 0 : PlGo ' (the demo playlist, or NEXT and the like: the next demo - DEMO/PLAYLIST.BM; here, where DEMO REPLAYS starts one too)
    IF demoMenuWant THEN demoMenuWant = 0 : menuInGame = 0 : menuOpenDemos = -1 : RunMenu ' (a demo from DEMO REPLAYS is over: the title menu, at that list)
    IF demoAttractMenu THEN demoAttractMenu = 0 : menuInGame = 0 : RunMenu ' (attract mode: a demo over - the title menu again)
    IF demoAttract THEN ' (attract mode: a key, or a click - back to the title menu)
        IF _KEYHIT > 0 OR attractQuit THEN
            demoAttract = 0 : attractQuit = 0 : _KEYCLEAR
            IF demoPlay THEN DemoStop
            menuInGame = 0 : RunMenu
        END IF
    END IF
    IF conWait > 0 THEN conWait = conWait - 1
    DO WHILE conWait = 0 AND conQHead < conQTail AND glShotReq = 0 ' (a screenshot asked for: the rest waits until it's saved)
        conQHead = conQHead + 1 : conCmd$ = conQ$(conQHead)
        IF LEFT$(conCmd$, 1) = CHR$(2) THEN conCmd$ = MID$(conCmd$, 2) : conFromTrig = -1 ' (a trigger's command, queued behind a wait)
        ConExec : conFromTrig = 0
    LOOP
    IF conQHead >= conQTail THEN conQHead = 0 : conQTail = 0
    ' ` (or ~): the console
    conKey = (_KEYDOWN(96) OR _KEYDOWN(126)) AND NOT edTyping ' (typing a name in the editor: not the console)
    IF conKey AND NOT conKeyWas THEN RunConsole
    conKeyWas = conKey
    ' Ctrl+R: record this sector - it starts again, with what you came into
    ' it with, and every key from there goes into a demo (run1, run2...) -
    ' and Ctrl+R again (or the exit) keeps it: DEMO REPLAYS lists it. At the
    ' exit it goes on: the next sector records too (DemoChainNext)
    altShift = (_KEYDOWN(100307) OR _KEYDOWN(100308)) AND (_KEYDOWN(100303) OR _KEYDOWN(100304))
    recKey = (_KEYDOWN(114) OR _KEYDOWN(82)) AND (_KEYDOWN(100305) OR _KEYDOWN(100306)) AND NOT edTyping
    IF recKey AND NOT recKeyWas AND NOT editMode AND NOT hudEdit AND NOT photoOn THEN
        ' (Ctrl+Alt+Shift+R: the sector as last saved - only in an edit session: EDITOR/SESSION.BM)
        IF altShift THEN
            IF editSession AND NOT cyberOn AND NOT dead AND NOT demoPlay AND NOT demoRec THEN SectorReload
        ELSE
            DemoRecordKey
        END IF
    END IF
    recKeyWas = recKey
    ' F3: where you are, in numbers (DrawInfo, chapter 18) - on or off
    IF _KEYDOWN(15616) AND NOT infoKeyWas AND NOT edTyping THEN infoOn = NOT infoOn
    infoKeyWas = _KEYDOWN(15616)
    ' F4: MATRIX VIEW - the sector in the network's look, on and off (GAME/NETWORK.BM)
    IF _KEYDOWN(15872) AND NOT cyberLookKeyWas AND NOT edTyping AND NOT editMode AND NOT cyberOn THEN CyberLookSet NOT cyberLook
    cyberLookKeyWas = _KEYDOWN(15872)
    ' F2: the level editor (chapter 21) - into it, at the map from above
    edKey = _KEYDOWN(15360)
    IF edKey AND NOT edKeyWas AND NOT cyberOn AND NOT dead AND NOT edTyping AND NOT photoOn THEN
        IF editMode THEN EditLeave ELSE EditEnter
    END IF
    edKeyWas = _KEYDOWN(15360)
    IF editMode AND editView = 0 THEN RunEditor : edKeyWas = _KEYDOWN(15360) ' (the map from above: a loop of its own - F2 there, still held, isn't a new press here)
    IF editMode THEN EditFP ' (walking round in it: its keys)
