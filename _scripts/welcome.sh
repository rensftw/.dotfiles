#!/usr/bin/env bash

# Display a welcome message; change to your name :)
NAME="Irena"

if command -v toilet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
    toilet -f smblock "Welcome $NAME" | lolcat --spread '1.0'
else
    printf '%s\n' "Welcome $NAME"
fi
