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

# render: every patch through the PC speaker (PWM, cone filter on, louder
# than the window's default gain) -> .wav
for p in *.pwmsfx; do
    "$PWMSFXR" -load "$p" -cone on -gain 0.5 -wav "${p%.pwmsfx}.wav" >/dev/null
    echo "rendered ${p%.pwmsfx}.wav"
done
