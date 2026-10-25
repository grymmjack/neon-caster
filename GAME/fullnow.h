// GAME/fullnow.h - NEON-CASTER: the full screen mode QB64PE is in now.
// Included inline by QB64-PE through GAME/ARCADE.BI (DECLARE LIBRARY).
//
// _FULLSCREEN answers the mode asked for, even before QB64PE has switched
// (it does at its next frame). SHELL goes by the one in effect: given a
// full screen game it leaves full screen, and after the program it waits,
// with no end, to be back in - which a window manager can keep from ever
// happening (the game hung). So the game leaves full screen itself first,
// and waits for this to say it has.
#pragma once
#include <stdint.h>

extern int32_t full_screen; // (libqb's: 0 windowed, 1 stretched, 2 square pixels)

static int32_t fullnow_mode(void) { return full_screen; }
