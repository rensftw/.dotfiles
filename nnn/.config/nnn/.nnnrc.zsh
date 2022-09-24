# -A: disable directory auto-enter in type-to-nav mode
# -e: open text files in $VISUAL (else $EDITOR, fallback vi) [preferably CLI]
# -d: detail mode
# -H: show hidden files
# -J: disable auto-jump on selection (eg. selecting an entry will no longer move cursor to the next entry)
# -r: show cp, mv progress
export NNN_OPTS='AedHJr'
export NNN_PLUG='p:preview-tui;o:fzopen;d:diffs;m:nmount;v:vmount;u:getplugs'
export NNN_BMS="v:/Volumes;b:/Volumes/Backup;d:$HOME/.dotfiles"
export NNN_FIFO='/tmp/nnn.fifo'
