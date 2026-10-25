// CORE/winsize.h - NEON-CASTER: the window's size, set by the game.
// Included inline by QB64-PE through CORE/WINDOW.BI (DECLARE LIBRARY).
//
// _RESIZE ON lets the player drag the window to any size (QB64PE keeps it
// 4:3 and stretches our screen to fill it), but QB64PE has no way to set
// a window's size: WINDOW SIZE and the snap after a drag (WindowFrame,
// CORE/SETTINGS.BM) ask GLFW through QB64PE's own call - queued to the
// window's thread when it's asked from ours.
#pragma once
#include <stdint.h>
#include <utility>

void GLUTEmu_WindowResize(int width, int height); // (libqb's, glut-emu.h)
std::pair<int, int> GLUTEmu_WindowGetSize();

static void winsize_set(int32_t w, int32_t h) { if (w > 0 && h > 0) GLUTEmu_WindowResize(w, h); }
static int32_t winsize_w(void) { return GLUTEmu_WindowGetSize().first; }
static int32_t winsize_h(void) { return GLUTEmu_WindowGetSize().second; }
