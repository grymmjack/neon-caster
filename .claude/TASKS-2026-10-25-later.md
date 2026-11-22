# Rick's asks, 2026-10-25 (after v0.8.0)

## ✅ LOOP DONE — every item finished

## 🔨 NOW

(nothing)

## Queued (Rick: "for later")

(none)

## Done

- [x] L6. Glass cracks in 3 stages (chipped at 1 hit, cracked, falling apart with a hole) x 4 patterns (strike point, crack count, wander), picked per cell so neighbours differ (GlassSlot, both renderers); stage from hits left of the tuned pane health. Checked: picture sheet + level 1's row in OpenGL and software. a936dcf
- [x] L8. Lights that change in play: console/trigger `light N on|off|toggle|colour|bright|fx`, `ambient BRIGHT [RRGGBB] [FX]`, `celllight X0 Y0 X1 Y1 BRIGHT RRGGBB [FX]|off`; saves keep them (lightLog$ replayed); new `calm` trigger (alarm stops); TRIGGERS pane CALM + LAMP O/I, AREA RED, AREA OFF. Tested on Xvfb: colours/ambient/cell light change, save+load restores, calm fires. Guide + CLAUDE.md. 493f984. (Caveat: a recoloured light's lamp picture keeps its old tint)
- [x] L7. WINDOW SIZE (SETTINGS > VIDEO): _RESIZE ON (4:3 kept, stretched); 10 sizes 800x600-2880x2160 (multiples + 4:3 display sizes); a drag settles 0.4 s after on the nearest (taller only if it fits) and is saved; _STRETCH at multiples, _SMOOTH between; CORE/winsize.h sets the size via GLFW. Tested on Xvfb 1920x1080: 1000x750->1024x768, 1550x1162->1440x1080, 700x525->800x600, set window_size 4 -> 1280x960, OpenGL fills 1024x768. 74c0e51. (Also L5's glow was drawn at the corner: gunX unshared - fixed 992bf5d; CI demo test passed for L5)
- [x] L5. CHARGED SHOTS (SETTINGS > GAMEPLAY, on): blaster/railgun - first press fires, held on charges (40 frames; new mastered sounds charge/charge-full), muzzle glow + gun lit + crosshair ring; let go full = 2x damage, 2x ammo, sooner = ordinary shot. Demo header 'charge 1' (none = off: old demos unchanged), bot taps. Tested: hold 70 = 3 cells (1 + charged 2), hold 20 = 2, off = 5 shots. Tutorial, CLAUDE.md. 65f49fb (CI demo test 40217709036)
- [x] L9. The editor's whole-window blink at each change: QB64PE clears the window before every _GL, and frames held mid-rebuild (glEdHold) drew nothing - black toolbar, pane, picker. Now each editor frame is kept on the card (GL/keepframe.h) and held frames draw it. Probed on the real GPU (weston): 5 edits, 10 held frames, all drew the kept frame, 100% lit; no hang. 39d5d8e
- [x] L4. Ctrl+Alt+Shift+R = REVERT TO SAVED (SectorReloadKey/SectorReload, EDITOR/SESSION.BM): both editor views always; in play only in an edit session (chapter 7, not in demos/network/dead); Ctrl+R record doesn't fire on it. Tested: 27 killed -> reload -> 27 back; no session: nothing, no demo. Guide. Also fixed on the way: program hand-over froze the picture under KWin (6694b31)
- [x] L3. Per face (per piece): FILTERS pane's OPENGL row - NO BUMPS / NO SHINE / NO NEON (letters F M N after the filters: the piece's own slot sent with bump/shine/neon 0 - glTexBump, GLPieceFx$). Probe-checked on a test sector; guide + CLAUDE.md; 315b813. (Smooth light, moving lights, bloom are whole-screen passes: not per face)
- [x] L2. CI demo test is its own workflow (.github/workflows/demo-test.yml: push to main touching code/levels/demos, or by hand with any demos; fails red on a demo out of step), taken out of build-release.yml - pushed 3c82eec (first run 40212951837)
- [x] E1. Editor rebuilds only what changed (was ~1.5 s and a half-drawn frame per edit): face slots kept across rebuilds (PcSlotFor/PcFreeSlot/PcForget, texUsed), OpenGL sends only changed slots (texDirty, GLSendDirty), clears only the sector's area (bldN), OpenGL holds off mid-rebuild (glEdHold/glEdAck). Measured on custom17: 14.4 s -> 72 ms (Xvfb). Hold keeps the last frame (no black); camera unchanged; both renderers; pushed f6a1ab5
- [x] L1. 3D editor help (F1): keys 1-8 named on both sheets and the guide, pushed 2772b8a
