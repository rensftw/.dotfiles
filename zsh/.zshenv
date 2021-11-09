ARCH=$(arch)

# Export global brew variables:
if [[ $ARCH =~ 'arm' ]]; then
    # For Apple Silicon mac
    PATH=$PATH:/opt/homebrew/bin
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # For Intel mac
    PATH=$PATH:/usr/local/bin
    eval "$(brew shellenv)"
fi
