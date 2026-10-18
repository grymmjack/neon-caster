''
' NEON-CASTER - ACH/ACHIEVEMENTS.BI
' =============================================================================
' Achievements (chapter 23): each one's Steam name and words.
'

' ACHIEVEMENTS (chapter 23: AchSetup, Achieve, AchAdd): each one's Steam API
' name, title, what it asks, whether it's hidden till you get it, and - for
' a count (100 kills) - the stat it follows and the goal. The stats are
' kept by Steam (or the mock's file). achCheat: god mode, give, the editor
' and the like were used this game - achievements wait for a new one.
' achToast$: the pop-ups waiting to show, achToastT how long the one up
' has been showing.
CONST NUM_ACH = 49, NUM_ACHSTATS = 13, NEON_APP_ID = 0 ' (NEON_APP_ID: the game's Steam App ID, once there is one - 0 keeps to the stand-in)
DIM SHARED achApi$(NUM_ACH), achTitle$(NUM_ACH), achDesc$(NUM_ACH), achHidden(NUM_ACH) AS INTEGER, achStat$(NUM_ACH), achGoal(NUM_ACH) AS LONG
DIM SHARED achN AS INTEGER, achStatName$(NUM_ACHSTATS), achStatN AS INTEGER, achCheat AS INTEGER, achTest AS INTEGER, achReady AS INTEGER
DIM SHARED achToast$(16), achToastN AS INTEGER, achToastT AS INTEGER, sndAchieve&, conFromTrig AS INTEGER
DIM SHARED achSect(16) AS INTEGER, achSectN AS INTEGER ' (the achievements unlocked in this sector: their badges on the tally)
DIM SHARED achFrame AS LONG, achHeadAt AS LONG ' (the frame a headshot was last counted in)
DIM SHARED achIcon&(NUM_ACH), achIconOff&(NUM_ACH), achToastI(16) AS INTEGER ' (each one's badge, achievements/NAME.png, and its grey one, NAME_locked.png - the same pictures Steam shows)
DIM SHARED achLevelHurt AS INTEGER, achOtherGun AS INTEGER, achAmpKills AS INTEGER, achBlastKills AS INTEGER, achInBlast AS INTEGER, achInLava AS INTEGER, achRunFrom AS INTEGER, achDeadSeen AS INTEGER
sndAchieve& = LoadSnd&("achievement.wav")
