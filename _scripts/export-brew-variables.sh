# Make sure the brew command is available for
 ARCH=$(arch)
 if [[ $ARCH =~ 'arm' ]]; then
     # For Apple Silicon mac
     eval "$(/opt/homebrew/bin/brew shellenv)"
 else
     # For Intel mac
     eval "$(brew shellenv)"
 fi
