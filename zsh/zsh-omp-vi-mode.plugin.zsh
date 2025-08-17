_omp_redraw-prompt() {
    local precmd
    for precmd in $precmd_functions; do
        $precmd
    done

    zle .reset-prompt
}

function _omp_zle-keymap-select() {
    if [ "${KEYMAP}" = 'vicmd' ]; then
        export POSH_VI_MODE="command"
    else
        export POSH_VI_MODE="insert"
    fi

    _omp_redraw-prompt
}
_omp_create_widget zle-keymap-select _omp_zle-keymap-select

# reset to default mode at the end of line input reading
function _omp_zle-line-finish() {
    export POSH_VI_MODE="insert"
}
_omp_create_widget zle-line-finish _omp_zle-line-finish

# Fix a bug when you C-c in CMD mode, you'd be prompted with CMD mode indicator
# while in fact you would be in INS mode.
# Fixed by catching SIGINT (C-c), set mode to INS and repropagate the SIGINT,
# so if anything else depends on it, we will not break it.
TRAPINT() {
    export POSH_VI_MODE="insert"
    return $(( 128 + $1 ))
}
