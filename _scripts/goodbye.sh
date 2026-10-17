#!/usr/bin/env bash

if command -v toilet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
    toilet -f smblock 'Bye!' | lolcat --spread '1.0'
else
    printf '%s\n' 'Bye!'
fi
