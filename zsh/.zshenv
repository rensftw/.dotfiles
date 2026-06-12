# Homebrew environment for all zsh invocations.
# Keep this file lightweight: .zshenv is sourced by every zsh, including scripts.
# This dotfiles setup assumes Apple Silicon Homebrew.
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_REPOSITORY=/opt/homebrew

typeset -U path
path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "${path[@]}")
export PATH
[[ -z ${MANPATH-} ]] || export MANPATH=":${MANPATH#:}"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
