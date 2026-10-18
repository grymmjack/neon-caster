''
' NEON-CASTER - CORE/STATE.BI
' =============================================================================
' The main program's working variables, shared with its SUBs: the loop's
' counters, and the values the main program and its parameterless SUBs
' (HitMonster, RunEvents, LoadLevel...) pass to each other. A SUB with a
' local of the same name DIMs its own.
'

' The main program's working variables, shared with its SUBs
DIM SHARED a, aimAmount, aimTarget, alive, arcDeco, armor, ax, ay, B, b1, b2, barrel, bd, best, bestScore
DIM SHARED bh, bi, blastAtX, blastAtY, bobPhase, boxDist, bSide, bt, bw, bx, bx0, bx1, by, by0, by1, c, c$
DIM SHARED cameraX, click, clicked, conA$, conCmd$, conDone, conFire, conKeyWas, conLine$, conUse, currentGun
DIM SHARED cutAlongX, cutX, cutY, cx, cy, cyberWon, c~&, d, damage, dead, deadAt!, decoByMon, dFile$, dirX
DIM SHARED dirY, distance, dSeedWant#, dv, e, edClickL, edClickR, editFresh, escWas, ev, eyeY, f, fireDown
DIM SHARED fireWait, fireWas, flyMode, fog&, frameAt!, fu, fx, fy, fz, g, gEnd, gKeyWas, glassAtX, glassAtY
DIM SHARED glassDmg, glassHitX, glassHitY, godMode, goX, goY, gU, gx, gy, half, head, headZ, health, hitDamage
DIM SHARED hitKick, hurtElectric, hurtFlash, hurtFromX, hurtFromY, i, ic&, inside, j, k, k&, kd, keyCode&
DIM SHARED kickWas, kills, kKeyWas, l, l$, left, level, levelName$, levelStart!, levelTime!, lightB&, lightG&
DIM SHARED lightR&, litX, litY, lk, loadOK, mapKeyWas, mapOpen, menuOpenDemos, mtype, muzzleFlash, mx, my, n
DIM SHARED n0, newBlastSize, newBlastX, newBlastY, nextGun, nm$, noTarget, nvKeyWas, nx, ny, ok, p, pic$
DIM SHARED pickFlash, placed, planeX, planeY, press, pressed, pressWas, px, py, pzResume, pzSolved, pzTerm, q$
DIM SHARED qb$, r, railBeam, rayDirX, rayDirY, recoil, recSet, ri, rk, rowDist, savedArmor, savedCells
DIM SHARED savedGun, savedHealth, savedShells, saveSlot, score, semi, shake, shakeX, shakeY, shiftOn, slammed
DIM SHARED slot, sndAmmo&, sndArmor&, sndBarrel&, sndDecoHit&, sndDie&, sndExit&, sndHealth&, sndHurt&
DIM SHARED sndLocked&, sndMenuBack&, sndMenuMove&, sndMenuSelect&, sndStep1&, spaceDown, spaceWas, spBot
DIM SHARED spriteH, spriteSlot, spriteSz, spriteTop, spriteU, spTop, st, st$, swapTimer, sx, sy, t, t$, taken
DIM SHARED target, targetDeco, tc~&, texel~&, tm, toPlayerX, toPlayerY, totalKills, totalMonsters, totalTime!
DIM SHARED trigK, trigRun$, tx, ty, ux, uy, v, viewH, w, w$, wallX, win, x0, y0, y1, zoom
