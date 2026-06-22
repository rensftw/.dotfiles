# Homebrew environment for all zsh invocations.
# Keep this file lightweight: .zshenv is sourced by every zsh, including scripts.
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX=/usr/local
elif [[ "$(uname -m)" == "arm64" ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
else
  export HOMEBREW_PREFIX=/usr/local
fi
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export HOMEBREW_NO_ANALYTICS=1

typeset -U path
path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "${path[@]}")
export PATH
[[ -z ${MANPATH-} ]] || export MANPATH=":${MANPATH#:}"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
