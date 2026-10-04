#!/usr/bin/env bash
# make-sfx.sh - NEON-CASTER's sound effects, made with PWMSFXR's command line
#
# Each sound is a .pwmsfx patch (made here the first time, then yours to
# tweak: open it in PWMSFXR, save over it) rendered to a .wav the game loads.
#
#   ./make-sfx.sh          make missing patches, render every .wav
#   ./make-sfx.sh -new     remake every patch from the recipes below too
#
# QB64PE=/path/to/qb64pe to build PWMSFXR with another compiler.
set -euo pipefail
cd "$(dirname "$0")"

SOUND=../../../SOUND/PWMSFXR
PWMSFXR="$SOUND/PWMSFXR.run"
QB64PE="${QB64PE:-$HOME/git/qb64pe/qb64pe}"

# (re)build PWMSFXR when it's missing or older than its source
if [[ ! -x $PWMSFXR || $SOUND/PWMSFXR.BAS -nt $PWMSFXR || ../../../SOUND/PCSFXR/SFXR.BM -nt $PWMSFXR ]]; then
    echo "Building PWMSFXR..."
    "$QB64PE" -x -c "$SOUND/PWMSFXR.BAS" -o "$(realpath "$SOUND")/PWMSFXR.run" >/dev/null
fi

NEW=0
[[ ${1:-} == -new ]] && NEW=1

# patch NAME args... : design NAME.pwmsfx (only if missing, or with -new)
patch() {
    local name=$1; shift
    if [[ $NEW == 1 || ! -f $name.pwmsfx ]]; then
        "$PWMSFXR" -seed 1 -clear -name "$name" "$@" -save "$name.pwmsfx" >/dev/null
        echo "designed $name.pwmsfx"
    fi
}

# Times: sustain/decay p -> p^2 * 2.27 s (0.1 = 23 ms, 0.2 = 91 ms, 0.3 = 0.2 s)
# Pitch: base_freq f -> about 3528 * f^2 Hz (0.15 = 80 Hz, 0.24 = 200 Hz)

# footsteps on a metal grate: a soft thump, a low knock and a little clink
patch step1 \
    -voice 1 -on -wave brown  -vol 0.8 -set base_freq=0.35,sustain=0.09,decay=0.19,punch=0.4,lpf_freq=0.3 \
    -voice 2 -on -wave sine   -vol 0.6 -set base_freq=0.15,freq_ramp=-0.3,sustain=0.11,decay=0.2 \
    -voice 3 -on -wave metal  -vol 0.2 -set base_freq=0.6,sustain=0.05,decay=0.1,hpf_freq=0.3
patch step2 \
    -voice 1 -on -wave brown  -vol 0.8 -set base_freq=0.32,sustain=0.09,decay=0.19,punch=0.4,lpf_freq=0.3 \
    -voice 2 -on -wave sine   -vol 0.6 -set base_freq=0.17,freq_ramp=-0.3,sustain=0.11,decay=0.2 \
    -voice 3 -on -wave metal  -vol 0.2 -set base_freq=0.55,sustain=0.05,decay=0.1,hpf_freq=0.3

# walking into a wall: a heavy body thud on a metal panel
patch bump \
    -voice 1 -on -wave brown  -vol 0.9 -set base_freq=0.25,sustain=0.12,decay=0.35,punch=0.6,lpf_freq=0.25 \
    -voice 2 -on -wave sine   -vol 0.9 -set base_freq=0.12,freq_ramp=-0.25,sustain=0.1,decay=0.3,punch=0.5 \
    -voice 3 -on -wave metal  -vol 0.3 -set base_freq=0.3,sustain=0.05,decay=0.18,lpf_freq=0.5

# Space on a plain wall: a slap and a low "uh-uh" buzz - nothing opens
patch wallhump \
    -voice 1 -on -wave square -vol 0.6 -set base_freq=0.24,duty=0.3,sustain=0.17,decay=0.12,lpf_freq=0.45 \
    -voice 2 -on -wave square -vol 0.6 -delay 0.1 -set base_freq=0.2,duty=0.3,sustain=0.17,decay=0.12,lpf_freq=0.45 \
    -voice 3 -on -wave brown  -vol 0.6 -set base_freq=0.2,sustain=0.05,decay=0.2,punch=0.5

# a door sliding open (~0.42 s, as long as it takes in the game): pneumatic
# hiss, a rising motor whine, and a clunk when it's open
patch door \
    -voice 1 -on -wave pink     -vol 0.5  -set attack=0.15,sustain=0.42,decay=0.25,base_freq=0.5,lpf_freq=0.45,lpf_ramp=-0.05,hpf_freq=0.15 \
    -voice 2 -on -wave sawtooth -vol 0.35 -set base_freq=0.17,freq_ramp=0.08,sustain=0.42,decay=0.15,vib_strength=0.15,vib_speed=0.5,lpf_freq=0.35 \
    -voice 3 -on -wave brown    -vol 0.9  -delay 0.42 -set base_freq=0.25,sustain=0.08,decay=0.25,punch=0.6,lpf_freq=0.3 \
    -voice 4 -on -wave metal    -vol 0.35 -delay 0.42 -set base_freq=0.35,sustain=0.05,decay=0.2,lpf_freq=0.6

# picking up a keycard: a bright rising two-note chime with a shimmer
patch keycard \
    -voice 1 -on -wave square   -vol 0.6 -set base_freq=0.42,duty=0.4,arp_mod=0.4,arp_speed=0.55,sustain=0.12,decay=0.3 \
    -voice 2 -on -wave triangle -vol 0.5 -delay 0.05 -set base_freq=0.55,arp_mod=0.4,arp_speed=0.55,sustain=0.1,decay=0.35 \
    -voice 3 -on -wave sine     -vol 0.3 -delay 0.1 -set base_freq=0.75,vib_strength=0.3,vib_speed=0.6,sustain=0.08,decay=0.4

# Space on a locked door without its key: a falling "denied" buzz and a
# rattle of the lock
patch locked \
    -voice 1 -on -wave square -vol 0.6 -set base_freq=0.3,duty=0.35,arp_mod=-0.4,arp_speed=0.45,sustain=0.15,decay=0.12,lpf_freq=0.5 \
    -voice 2 -on -wave metal  -vol 0.5 -set base_freq=0.4,sustain=0.03,decay=0.15 \
    -voice 3 -on -wave brown  -vol 0.5 -set base_freq=0.22,sustain=0.04,decay=0.15,punch=0.4

# --- combat ---

# the blaster: a falling laser zap with a noisy kick
patch shoot \
    -voice 1 -on -wave square   -vol 0.7 -set base_freq=0.55,freq_ramp=-0.35,duty=0.3,duty_ramp=0.2,sustain=0.1,decay=0.2 \
    -voice 2 -on -wave sawtooth -vol 0.4 -set base_freq=0.5,freq_ramp=-0.3,sustain=0.08,decay=0.15 \
    -voice 3 -on -wave noise    -vol 0.3 -set base_freq=0.6,sustain=0.03,decay=0.1,punch=0.5

# a drone spots you: a rising robotic chirp, then a blip
patch drone-alert \
    -voice 1 -on -wave square   -vol 0.6 -set base_freq=0.3,freq_ramp=0.25,duty=0.2,vib_strength=0.4,vib_speed=0.7,sustain=0.12,decay=0.1 \
    -voice 2 -on -wave triangle -vol 0.5 -delay 0.12 -set base_freq=0.45,sustain=0.08,decay=0.1

# a drone bites: an electric crackle
patch drone-attack \
    -voice 1 -on -wave metal    -vol 0.7 -set base_freq=0.5,sustain=0.08,decay=0.15 \
    -voice 2 -on -wave sawtooth -vol 0.5 -set base_freq=0.3,freq_ramp=-0.2,sustain=0.06,decay=0.12

# a drone takes a hit: a metal clang and a squeal
patch drone-hit \
    -voice 1 -on -wave metal  -vol 0.7 -set base_freq=0.45,sustain=0.04,decay=0.15,punch=0.4 \
    -voice 2 -on -wave square -vol 0.4 -set base_freq=0.5,freq_ramp=-0.4,duty=0.3,sustain=0.04,decay=0.1

# a drone dies: a small explosion and a falling whine
patch drone-die \
    -voice 1 -on -wave noise    -vol 0.8 -set base_freq=0.3,freq_ramp=-0.1,sustain=0.15,decay=0.45,punch=0.5 \
    -voice 2 -on -wave brown    -vol 0.9 -set base_freq=0.2,sustain=0.15,decay=0.5 \
    -voice 3 -on -wave sawtooth -vol 0.4 -set base_freq=0.45,freq_ramp=-0.25,sustain=0.15,decay=0.3

# you get hurt: a low grunt-ish buzz and a thud
patch hurt \
    -voice 1 -on -wave square -vol 0.7 -set base_freq=0.18,freq_ramp=-0.2,duty=0.5,vib_strength=0.3,vib_speed=0.5,sustain=0.1,decay=0.15,lpf_freq=0.3 \
    -voice 2 -on -wave brown  -vol 0.6 -set base_freq=0.2,sustain=0.05,decay=0.2,punch=0.5

# you die: a long fall and a rumble
patch die \
    -voice 1 -on -wave square -vol 0.7 -set base_freq=0.3,freq_ramp=-0.15,duty=0.5,sustain=0.4,decay=0.5,lpf_freq=0.4 \
    -voice 2 -on -wave brown  -vol 0.8 -set base_freq=0.15,sustain=0.4,decay=0.6

# health pack: a soft rising sine sweep with a sparkle
patch health \
    -voice 1 -on -wave sine     -vol 0.7 -set base_freq=0.35,freq_ramp=0.3,sustain=0.15,decay=0.25 \
    -voice 2 -on -wave triangle -vol 0.4 -delay 0.08 -set base_freq=0.6,vib_strength=0.3,vib_speed=0.7,sustain=0.08,decay=0.3

# ammo: a mechanical clack and a short charge-up blip
patch ammo \
    -voice 1 -on -wave metal  -vol 0.6 -set base_freq=0.4,sustain=0.03,decay=0.1,punch=0.5 \
    -voice 2 -on -wave square -vol 0.5 -delay 0.06 -set base_freq=0.4,freq_ramp=0.35,duty=0.25,sustain=0.06,decay=0.1

# out of ammo: a dry click
patch empty \
    -voice 1 -on -wave metal -vol 0.6 -set base_freq=0.7,sustain=0.01,decay=0.06,hpf_freq=0.3

# --- more doors ---

# heavy shutter rolling up: a motor rumble, rattling slats, a clank at the top
patch door-shutter \
    -voice 1 -on -wave brown    -vol 0.9 -set attack=0.1,sustain=0.45,decay=0.2,base_freq=0.3,lpf_freq=0.35 \
    -voice 2 -on -wave square   -vol 0.3 -set base_freq=0.12,freq_ramp=0.05,duty=0.4,sustain=0.45,decay=0.15,repeat_speed=0.62,lpf_freq=0.3 \
    -voice 3 -on -wave metal    -vol 0.5 -delay 0.42 -set base_freq=0.3,sustain=0.06,decay=0.25,punch=0.5

# split doors: two quick pneumatic hisses, one per half
patch door-split \
    -voice 1 -on -wave pink -vol 0.6 -pan -0.4 -set attack=0.05,sustain=0.2,decay=0.2,base_freq=0.6,hpf_freq=0.2,lpf_freq=0.6,lpf_ramp=-0.1 \
    -voice 2 -on -wave pink -vol 0.6 -pan 0.4 -delay 0.06 -set attack=0.05,sustain=0.2,decay=0.2,base_freq=0.55,hpf_freq=0.2,lpf_freq=0.6,lpf_ramp=-0.1 \
    -voice 3 -on -wave sine -vol 0.4 -set base_freq=0.4,freq_ramp=0.2,sustain=0.1,decay=0.15

# --- gunner robot ---
patch gunner-alert \
    -voice 1 -on -wave square -vol 0.6 -set base_freq=0.4,duty=0.15,arp_mod=-0.3,arp_speed=0.5,sustain=0.15,decay=0.1 \
    -voice 2 -on -wave square -vol 0.5 -delay 0.16 -set base_freq=0.4,duty=0.15,arp_mod=-0.3,arp_speed=0.5,sustain=0.15,decay=0.1
patch gunner-shoot \
    -voice 1 -on -wave sine     -vol 0.7 -set base_freq=0.35,freq_ramp=-0.25,vib_strength=0.5,vib_speed=0.8,sustain=0.12,decay=0.2 \
    -voice 2 -on -wave sawtooth -vol 0.3 -set base_freq=0.3,freq_ramp=-0.2,sustain=0.08,decay=0.15
patch gunner-hit \
    -voice 1 -on -wave metal  -vol 0.7 -set base_freq=0.55,sustain=0.04,decay=0.12,punch=0.4 \
    -voice 2 -on -wave square -vol 0.4 -set base_freq=0.35,freq_ramp=-0.3,duty=0.2,sustain=0.04,decay=0.1
patch gunner-die \
    -voice 1 -on -wave noise  -vol 0.8 -set base_freq=0.35,sustain=0.12,decay=0.4,punch=0.5 \
    -voice 2 -on -wave square -vol 0.4 -set base_freq=0.45,freq_ramp=-0.35,duty=0.2,sustain=0.2,decay=0.3 \
    -voice 3 -on -wave metal  -vol 0.5 -delay 0.15 -set base_freq=0.3,sustain=0.05,decay=0.25

# --- heavy brute ---
patch heavy-alert \
    -voice 1 -on -wave sawtooth -vol 0.8 -set base_freq=0.1,freq_ramp=-0.05,vib_strength=0.5,vib_speed=0.4,sustain=0.35,decay=0.3,lpf_freq=0.3 \
    -voice 2 -on -wave brown    -vol 0.8 -set base_freq=0.2,sustain=0.3,decay=0.3
patch heavy-attack \
    -voice 1 -on -wave brown -vol 1   -set base_freq=0.2,sustain=0.1,decay=0.35,punch=0.8,lpf_freq=0.3 \
    -voice 2 -on -wave sine  -vol 0.9 -set base_freq=0.1,freq_ramp=-0.3,sustain=0.1,decay=0.3,punch=0.6 \
    -voice 3 -on -wave metal -vol 0.5 -set base_freq=0.25,sustain=0.05,decay=0.2
patch heavy-hit \
    -voice 1 -on -wave metal -vol 0.7 -set base_freq=0.25,sustain=0.05,decay=0.2,punch=0.5 \
    -voice 2 -on -wave brown -vol 0.6 -set base_freq=0.2,sustain=0.05,decay=0.15
patch heavy-die \
    -voice 1 -on -wave noise    -vol 0.9 -set base_freq=0.2,freq_ramp=-0.1,sustain=0.25,decay=0.6,punch=0.6 \
    -voice 2 -on -wave brown    -vol 1   -set base_freq=0.15,sustain=0.3,decay=0.6 \
    -voice 3 -on -wave sawtooth -vol 0.5 -set base_freq=0.15,freq_ramp=-0.15,vib_strength=0.4,vib_speed=0.3,sustain=0.3,decay=0.4

# --- more guns ---
patch scatter \
    -voice 1 -on -wave noise -vol 0.9 -set base_freq=0.35,freq_ramp=-0.1,sustain=0.08,decay=0.35,punch=0.7 \
    -voice 2 -on -wave brown -vol 0.9 -set base_freq=0.3,sustain=0.06,decay=0.3,punch=0.6 \
    -voice 3 -on -wave metal -vol 0.4 -delay 0.25 -set base_freq=0.45,sustain=0.03,decay=0.08 \
    -voice 4 -on -wave metal -vol 0.4 -delay 0.33 -set base_freq=0.4,sustain=0.03,decay=0.08
patch repeater \
    -voice 1 -on -wave square -vol 0.6 -set base_freq=0.65,freq_ramp=-0.4,duty=0.2,sustain=0.04,decay=0.1 \
    -voice 2 -on -wave noise  -vol 0.3 -set base_freq=0.7,sustain=0.02,decay=0.06
patch bolt-wall \
    -voice 1 -on -wave noise -vol 0.6 -set base_freq=0.5,sustain=0.03,decay=0.15,lpf_freq=0.5 \
    -voice 2 -on -wave sine  -vol 0.4 -set base_freq=0.5,freq_ramp=-0.4,sustain=0.03,decay=0.1
patch weapon \
    -voice 1 -on -wave metal    -vol 0.6 -set base_freq=0.35,sustain=0.04,decay=0.12,punch=0.5 \
    -voice 2 -on -wave metal    -vol 0.6 -delay 0.12 -set base_freq=0.45,sustain=0.04,decay=0.12,punch=0.5 \
    -voice 3 -on -wave triangle -vol 0.5 -delay 0.2 -set base_freq=0.45,arp_mod=0.5,arp_speed=0.5,sustain=0.1,decay=0.3
patch shells \
    -voice 1 -on -wave metal -vol 0.6 -set base_freq=0.5,sustain=0.02,decay=0.08 \
    -voice 2 -on -wave metal -vol 0.5 -delay 0.07 -set base_freq=0.55,sustain=0.02,decay=0.08 \
    -voice 3 -on -wave metal -vol 0.4 -delay 0.14 -set base_freq=0.6,sustain=0.02,decay=0.08

# render: every patch through the PC speaker (PWM, cone filter on, louder
# than the window's default gain) -> .wav
for p in *.pwmsfx; do
    "$PWMSFXR" -load "$p" -cone on -gain 0.5 -wav "${p%.pwmsfx}.wav" >/dev/null
    echo "rendered ${p%.pwmsfx}.wav"
done
