''
' NEON-CASTER - GAME/ARCADE.BI
' =============================================================================
' Computers you can use: NEON PONG and programs - their working variables.
'

' This module's working variables, shared by its SUBs (and with the main
' program)
DIM SHARED arcDone, arcWon, pgName$, rc

' The full screen mode in effect now (fullnow.h: _FULLSCREEN is the one asked for)
DECLARE LIBRARY "fullnow"
    FUNCTION fullnow_mode& ()
    FUNCTION fullnow_hidden& ()
END DECLARE

' --- The slot machine (a vending machine: Space on it - SlotUse). Its
' symbols: SL_BOMB a bomb, SL_MON a monster, SL_GUN a gun, SL_MED health,
' SL_AMMO ammo, SL_ARMOR armour, SL_SEVEN the lucky 7. Three alike pays out
' (or goes off: three bombs, a big blast; three monsters, a fight); a pair,
' a little of it; three 7s, the jackpot.
CONST SL_BOMB = 1, SL_MON = 2, SL_GUN = 3, SL_MED = 4, SL_AMMO = 5, SL_ARMOR = 6, SL_SEVEN = 7, SL_KINDS = 7
DIM SHARED slotReel(3) AS INTEGER, slotPair AS INTEGER, slotDeco AS INTEGER
DIM SHARED slotPos(3) AS SINGLE, slotStop(3) AS INTEGER ' (the reels on screen: where each is on its strip, and whether it's stopped)
