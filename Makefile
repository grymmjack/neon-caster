# NEON-CASTER - build with QB64PE (as ~/git/DRAW's Makefile does)
#
#   make            build neon-caster.run (C++ optimized)
#   make dev        faster build, C++ optimization off - testing only
#   make run        build, then play (ARGS="+map 3 +give all" passes + commands)
#   make clean      delete neon-caster.run (never neon-caster/saves)
#   make help       this list
#
# The output is neon-caster.run, never neon-caster: that's the asset folder.
# -ffp-contract=off is what CI builds with: without it a Mac fuses
# multiply-adds and plays a Linux demo differently.

SHELL := /bin/bash

QB64PE    ?= $(HOME)/git/qb64pe/qb64pe
THREADS   ?= 16
QB64FLAGS := -w -x -f:MaxCompilerProcesses=$(THREADS) -f:SplitObjectfiles=true -f:ExtraCppFlags=-ffp-contract=off
ARGS      ?=

SRC     := neon-caster.bas
OUT     := neon-caster.run
SOURCES := $(SRC) $(wildcard */*.BI */*.BM */*.h lib/*/*.BI lib/*/*.BM lib/*/*.h)

.PHONY: all dev dev-run run clean help
.DEFAULT_GOAL := all

help:  #: Show this help
	@awk 'BEGIN{FS="[ \t]*#: "} /^[a-zA-Z][a-zA-Z0-9_-]*:([^=]|$$)/ && /#: / {name=$$1; sub(/:.*/,"",name); printf "  \033[36m%-8s\033[0m %s\n", name, $$2}' $(MAKEFILE_LIST)
	@printf '\nVariables (append VAR=value):\n'
	@printf '  ARGS="+map 3 ..."   the game'"'"'s + commands for run / dev-run\n'
	@printf '  QB64PE=/full/path   the compiler (default ~/git/qb64pe/qb64pe)\n'
	@printf '  THREADS=N           parallel compiler processes (default 16)\n'

all: $(OUT)  #: Build neon-caster.run (C++ optimized)

dev: QB64FLAGS += -f:OptimizeCppProgram=false
dev: $(OUT)  #: Faster build, C++ optimization off - testing only
	@printf '  \033[33m[dev build: C++ optimization OFF - use `make` for anything you ship]\033[0m\n'

dev-run: dev  #: Dev build, then play
	./$(OUT) $(ARGS)

# QB64PE reports most mistakes without the word "error" (e.g. "Name already
# in use"): a build is good only if it prints its Output: line.
$(OUT): $(SOURCES)
	$(QB64PE) $(QB64FLAGS) $(SRC) -o $(OUT) 2>&1 \
	    | sed -u 's/\x1b\[[0-9;]*[A-Za-z]//g' \
	    | grep --line-buffered -v '^\[[ .]*\][[:space:]]*[0-9]\+%' \
	    | tee compilelog.txt
	@grep -q '^Output:' compilelog.txt || { rm -f $(OUT); echo 'build failed: no Output: line (see compilelog.txt)'; exit 1; }

run: $(OUT)  #: Build, then play
	./$(OUT) $(ARGS)

clean:  #: Delete neon-caster.run (your saves are never touched)
	rm -f $(OUT)
