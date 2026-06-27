#!/usr/bin/env bash

source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

NNN_PLUGIN_SOURCE="$DOTFILES_LOCATION/nnn/.config/nnn/nnn-repo/plugins"
NNN_PLUGIN_DESTINATION="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins"

if [[ ! -d "$NNN_PLUGIN_SOURCE" ]]; then
    if is_dry_run; then
        warn "nnn's pinned plugin source is missing; run 'bash install.sh' to fetch submodules."
        return 0 2>/dev/null || exit 0
    fi
    die "nnn's pinned plugin source is missing. Run 'bash install.sh' first."
fi

printf "$CYAN$BOLD%s$NORMAL\n" "🧰 Installing plugins from the pinned nnn source"
run mkdir -p "$NNN_PLUGIN_DESTINATION"

while IFS= read -r -d '' plugin_source; do
    plugin_name="$(basename "$plugin_source")"
    plugin_destination="$NNN_PLUGIN_DESTINATION/$plugin_name"

    if [[ -e "$plugin_destination" ]]; then
        if cmp -s "$plugin_source" "$plugin_destination"; then
            continue
        fi
        warn "Leaving locally modified nnn plugin in place: $plugin_destination"
        continue
    fi

    run cp -p "$plugin_source" "$plugin_destination"
done < <(find "$NNN_PLUGIN_SOURCE" -maxdepth 1 -type f \
    ! -name '*.md' ! -name getplugs -print0)
