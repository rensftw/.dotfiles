#!/usr/bin/env zsh
################################################################################
# Startup benchmark suite (see _benchmarks/README.md)
#
# Stdlib-only Python benchmarks for Zsh, Neovim, and the Pi agent. Run any with
# --help for options; --interactive (zsh), --compile-cache (pi) for deeper modes.
################################################################################

alias bench-zsh="$DOTFILES_LOCATION/_benchmarks/zsh-benchmark.py"
alias bench-nvim="$DOTFILES_LOCATION/_benchmarks/neovim-benchmark.py"
alias bench-pi="$DOTFILES_LOCATION/_benchmarks/pi-benchmark.py"
