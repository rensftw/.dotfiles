# -A: disable directory auto-enter in type-to-nav mode
# -c: cli-only using NNN_OPENER
# -d: detail mode
# -H: show hidden files
# -J: disable auto-jump on selection (eg. selecting an entry will no longer move cursor to the next entry)
# -r: show cp, mv progress
export NNN_OPTS='AcdHJr'
export NNN_OPENER="$HOME/.dotfiles/nnn/.config/nnn/plugins/nuke"
export NNN_PLUG='p:preview-tui;o:fzopen;f:fzcd;d:diffs;m:nmount;v:vmount;u:getplugs;y:.cbcp'
export NNN_BMS="v:/Volumes;b:/Volumes/Backup;d:$HOME/.dotfiles"
export NNN_FIFO='/tmp/nnn.fifo'

# Configue nnn to cd on quit
nn() {
    # Block nesting of nnn in subshells
    if [[ "${NNNLVL:-0}" -ge 1 ]]; then
        echo "nnn is already running"
        return
    fi

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The backslash allows one to alias n to nnn if desired without making an
    # infinitely recursive alias
    \nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}
