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

// And whether QB64PE thinks its window is hidden. _SCREENSHOW asks the
// window manager to show it and looks once, at once: under KWin (X on
// Wayland) it isn't shown yet then - and QB64PE, thinking it hidden, never
// draws it again (the game went on, its picture frozen). Asked again
// (_SCREENSHOW again) once it is, it knows.
bool GLUTEmu_WindowIsHidden(); // (libqb's, glut-emu.h)
static int32_t fullnow_hidden(void) { return GLUTEmu_WindowIsHidden() ? -1 : 0; }

// And whether it's minimized - KWin minimizes the game's window as it goes
// back to full screen without the focus (after a program) - and the window
// restored and given the focus (both queued to the window's thread)
bool GLUTEmu_WindowIsMinimized(); // (libqb's, glut-emu.h)
void GLUTEmu_WindowRestore();
void GLUTEmu_WindowFocus();
static int32_t fullnow_minimized(void) { return GLUTEmu_WindowIsMinimized() ? -1 : 0; }
static void fullnow_restore(void) { GLUTEmu_WindowRestore(); GLUTEmu_WindowFocus(); }
