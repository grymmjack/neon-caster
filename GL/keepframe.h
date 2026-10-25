// GL/keepframe.h - NEON-CASTER: the last frame, kept on the card.
// Included inline by QB64-PE through GL/OPENGL.BI (DECLARE LIBRARY).
//
// QB64PE clears the window to black before every SUB _GL and shows what's
// there after it. While the editor rebuilds the sector (EditApply's hold,
// glEdHold) SUB _GL can't draw - the map's half built - and every frame of
// the hold came out black: the whole window, toolbar and pane too, blinked
// at each change. So in the editor each finished frame is copied into a
// texture (keepframe_save, a copy on the card - nothing comes back to us),
// and a held frame draws that instead (keepframe_draw).
#pragma once
#include <stdint.h>

static GLuint keepframe_tex = 0;
static int32_t keepframe_w = 0, keepframe_h = 0, keepframe_ok = 0;

// Copy the window's picture (w x h, the frame just drawn) into the texture
static void keepframe_save(int32_t w, int32_t h) {
    if (w < 1 || h < 1) return;
    if (glBindFramebuffer != NULL) glBindFramebuffer(GL_FRAMEBUFFER, 0); // (the window, not a render target)
    if (!keepframe_tex) glGenTextures(1, &keepframe_tex);
    glBindTexture(GL_TEXTURE_2D, keepframe_tex);
    if (w != keepframe_w || h != keepframe_h) {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        keepframe_w = w; keepframe_h = h;
    }
    glReadBuffer(GL_BACK);
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, w, h);
    glBindTexture(GL_TEXTURE_2D, 0);
    keepframe_ok = 1;
}

// The kept frame no longer stands for what's there (out of the editor)
static void keepframe_forget(void) { keepframe_ok = 0; }

// Draw the kept frame over the whole window - if there is one, and the
// window's still its size
static void keepframe_draw(int32_t w, int32_t h) {
    if (!keepframe_ok || w != keepframe_w || h != keepframe_h) return;
    if (glUseProgram != NULL) glUseProgram(0);
    if (glActiveTexture != NULL) glActiveTexture(GL_TEXTURE0);
    if (glBindFramebuffer != NULL) glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, w, h);
    glDisable(GL_DEPTH_TEST); glDisable(GL_BLEND); glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST); glDisable(GL_ALPHA_TEST); glDisable(GL_LIGHTING); glDisable(GL_FOG);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, keepframe_tex);
    glColor4f(1, 1, 1, 1);
    glMatrixMode(GL_TEXTURE); glPushMatrix(); glLoadIdentity();
    glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity();
    glMatrixMode(GL_MODELVIEW); glPushMatrix(); glLoadIdentity();
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(-1, -1);
    glTexCoord2f(1, 0); glVertex2f(1, -1);
    glTexCoord2f(1, 1); glVertex2f(1, 1);
    glTexCoord2f(0, 1); glVertex2f(-1, 1);
    glEnd();
    glMatrixMode(GL_TEXTURE); glPopMatrix();
    glMatrixMode(GL_PROJECTION); glPopMatrix();
    glMatrixMode(GL_MODELVIEW); glPopMatrix();
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
}
