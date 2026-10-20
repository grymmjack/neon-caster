''
' NEON-CASTER - GAME/GUNS.BI
' =============================================================================
' The guns (chapter 4): the gun table (SetGun), aiming down the sights,
' and the guns' pictures.
'

' W_ = Weapon: the guns, numbered 1-5. They number the gun arrays below
' (gunName$(W_RAIL) is "RAILGUN") and are the keys you press to pick them.
' The rocket launcher (W_ROCKET) fires a rocket, not a shot that's there at
' once: it flies, and bursts on what it meets (GAME/ROCKETS.BM).
CONST W_BLASTER = 1, W_SCATTER = 2, W_REPEATER = 3, W_RAIL = 4, W_ROCKET = 5, NUM_GUNS = 5
DIM SHARED hasGun(NUM_GUNS) AS INTEGER
' Per gun: name, ammo kind, ammo per shot, frames between shots, pellets,
' spread (of the view's width), damage per hit, whether a shot goes through
' every monster in its line, recoil, how far it zooms when you aim down its
' sights (1 = not at all, 2 = twice as close - chapter 8), sound, picture,
' and where its muzzle is
DIM SHARED gunName$(NUM_GUNS), gunAmmoType(NUM_GUNS), gunAmmoPerShot(NUM_GUNS), gunDelay(NUM_GUNS), gunPellets(NUM_GUNS), gunSpread(NUM_GUNS)
DIM SHARED gunDamage(NUM_GUNS), gunPierce(NUM_GUNS), gunKick(NUM_GUNS), gunZoom(NUM_GUNS)
DIM SHARED gunSnd&(NUM_GUNS), gunImg&(NUM_GUNS), gunMuzzleX(NUM_GUNS), gunMuzzleY(NUM_GUNS), gunSize(NUM_GUNS)
' ...the light on the gun (1 = as bright as its picture; chapter 17), and
' for the software renderer, each gun's picture no taller than
' GUN_SOFT_MAX (it's shrunk to our 800 x 600 screen anyway) to tint
DIM SHARED gunLightR, gunLightG, gunLightB, gunSoftImg&(NUM_GUNS)
CONST GUN_SOFT_MAX = 512, GUN_DARKEST = 0.22, GUN_BRIGHTEST = 1.3
CONST GUN_TINT = 1.6 ' How strongly coloured light colours the gun (1 = just as it is)
gunLightR = 1 : gunLightG = 1 : gunLightB = 1
' ...and each gun's picture for OpenGL (chapter 24): a copy with its colours
' "premultiplied" (see GLDrawHUD), and its size
DIM SHARED gunGLMem(NUM_GUNS) AS _MEM, gunGLW(NUM_GUNS) AS LONG, gunGLH(NUM_GUNS) AS LONG
' ADS_ = Aiming Down the Sights (hold the right mouse button - chapter 8):
'   ADS_ZOOM       how much the view zooms in (1 = not at all, 2 = twice as
'                  close) - for most guns; each gun's own zoom is the last
'                  column of the guns table below, so the railgun can zoom
'                  in like a scope
'   ADS_FRAMES     frames to raise the gun to your eye, or lower it again
'   ADS_MUZZLE_Y   where the muzzle comes up to on the screen (the
'                  crosshair is at y = 300)
'   ADS_GUN_GROW   how much bigger the gun looks, held up close - at least.
'                  A gun whose muzzle is low in its picture grows more, so
'                  its bottom still reaches below the screen; but never more
'                  than ADS_GUN_GROW_MAX (then its muzzle stops a bit lower)
CONST ADS_ZOOM = 1.6, ADS_FRAMES = 8, ADS_MUZZLE_Y = 318
CONST ADS_GUN_GROW = 1.15, ADS_GUN_GROW_MAX = 1.7
'      gun name        ammo       cost delay pellets spread damage pierce recoil zoom
SetGun 1,  "BLASTER",  AM_CELLS,  1,   16,   1,      0,     1,     0,     1,     ADS_ZOOM
SetGun 2,  "SCATTER",  AM_SHELLS, 1,   40,   7,      0.12,  1,     0,     1.7,   ADS_ZOOM
SetGun 3,  "REPEATER", AM_ROUNDS, 1,   5,    1,      0.025, 1,     0,     0.45,  ADS_ZOOM
SetGun 4,  "RAILGUN",  AM_SLUGS,  1,   55,   1,      0,     5,     -1,    2.2,   4
SetGun 5,  "LAUNCHER", AM_ROCKETS, 1,  30,   1,      0,     ROCKET_HIT, 0, 2.6,   3.5
CONST SWAP_FRAMES = 14 ' Frames to lower one gun and raise the next
' The guns you hold are kept as ordinary images (not arrays): they're drawn
' over the finished view with _PUTIMAGE, at full size (chapter 18). LoadGun
' also works out where each one's muzzle is, for the muzzle flash.
'
' gunSize is how tall each one is drawn, in screen pixels - whatever size
' its picture is. So a gun can be drawn again in more detail (twice, four
' times, eight times as many pixels across) and dropped in as it is: it
' comes out the same size. More detail shows with OpenGL, which draws the
' gun at the window's full size (chapter 24); the software renderer
' shrinks it to our 800 x 600 screen. Keep the picture square, and its
' muzzle in the same place, and aiming down the sights still lines up.
gunSize(1) = 288 : gunSize(2) = 346 : gunSize(3) = 384 : gunSize(4) = 346 : gunSize(5) = 384
CONST GUN_Y = 600 ' A gun's bottom sits here, its muzzle straight below the crosshair
' (LoadGun 1 to 5: in LoadPictures)
