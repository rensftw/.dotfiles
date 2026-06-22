#!/usr/bin/env bash

# This helper is sourced by uninstall.sh while constructing the selected scope
# inventory and planned commands, before confirmation or mutation. It has no
# standalone argument path: state comes from the top-level entrypoint.
source "$DOTFILES_LOCATION/_scripts/lib.sh"

BREWFILE="$DOTFILES_LOCATION/_homebrew/Brewfile"
HOMEBREW_UNINSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
BREW_BIN=""
BREW_PREFIX=""
HOMEBREW_UNINSTALLER=""
MATCHED_INSTALLED_NAME=""

MANAGED_FORMULAE=()
MANAGED_CASKS=()
MANAGED_TAPS=()
INSTALLED_FORMULAE=()
INSTALLED_CASKS=()
INSTALLED_TAPS=()
FORMULAE_TO_REMOVE=()
CASKS_TO_REMOVE=()
TAPS_TO_REMOVE=()

find_brew_binary() {
    if command -v brew >/dev/null 2>&1; then
        BREW_BIN="$(command -v brew)"
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_BIN="/usr/local/bin/brew"
    else
        return 1
    fi
}

append_lines() {
    local destination="$1"
    local output="$2"
    local item

    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        case "$destination" in
            managed-formula) MANAGED_FORMULAE+=("$item") ;;
            managed-cask) MANAGED_CASKS+=("$item") ;;
            managed-tap) MANAGED_TAPS+=("$item") ;;
            installed-formula) INSTALLED_FORMULAE+=("$item") ;;
            installed-cask) INSTALLED_CASKS+=("$item") ;;
            installed-tap) INSTALLED_TAPS+=("$item") ;;
            *) die "Unknown inventory destination: $destination" ;;
        esac
    done <<< "$output"
}

read_brewfile_inventory() {
    local output

    [[ -r "$BREWFILE" ]] || die "Cannot read Brewfile: $BREWFILE"

    if ! output="$(HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" bundle list --formula --file "$BREWFILE")"; then
        die "Failed to parse formulae from $BREWFILE."
    fi
    append_lines managed-formula "$output"

    if ! output="$(HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" bundle list --cask --file "$BREWFILE")"; then
        die "Failed to parse casks from $BREWFILE."
    fi
    append_lines managed-cask "$output"

    if ! output="$(HOMEBREW_NO_AUTO_UPDATE=1 "$BREW_BIN" bundle list --tap --file "$BREWFILE")"; then
        die "Failed to parse taps from $BREWFILE."
    fi
    append_lines managed-tap "$output"
}

read_installed_inventory() {
    local output

    if ! output="$("$BREW_BIN" list --formula --full-name)"; then
        die "Failed to inventory installed Homebrew formulae."
    fi
    append_lines installed-formula "$output"

    if ! output="$("$BREW_BIN" list --cask --full-name)"; then
        die "Failed to inventory installed Homebrew casks."
    fi
    append_lines installed-cask "$output"

    if ! output="$("$BREW_BIN" tap)"; then
        die "Failed to inventory Homebrew taps."
    fi
    append_lines installed-tap "$output"
}

is_managed_installed_tap() {
    local requested_tap="$1"
    local managed_tap
    local installed_tap

    if (( ${#MANAGED_TAPS[@]} == 0 || ${#INSTALLED_TAPS[@]} == 0 )); then
        return 1
    fi

    for managed_tap in "${MANAGED_TAPS[@]}"; do
        [[ "$managed_tap" == "$requested_tap" ]] || continue
        for installed_tap in "${INSTALLED_TAPS[@]}"; do
            [[ "$installed_tap" == "$requested_tap" ]] && return 0
        done
    done
    return 1
}

find_installed_name() {
    local requested="$1"
    local installed
    local installed_tap
    local suffix_match=""
    local suffix_matches=0
    shift
    MATCHED_INSTALLED_NAME=""

    # Prefer an exact installed name before considering the fully-qualified
    # form of a short Brewfile token.
    for installed in "$@"; do
        if [[ "$installed" == "$requested" ]]; then
            MATCHED_INSTALLED_NAME="$installed"
            return 0
        fi
    done

    [[ "$requested" == */* ]] && return 1

    for installed in "$@"; do
        if [[ "$installed" == */"$requested" ]]; then
            installed_tap="${installed%/*}"
            is_managed_installed_tap "$installed_tap" || continue
            suffix_match="$installed"
            suffix_matches=$((suffix_matches + 1))
        fi
    done

    if (( suffix_matches == 1 )); then
        MATCHED_INSTALLED_NAME="$suffix_match"
        return 0
    fi
    if (( suffix_matches > 1 )); then
        return 2
    fi
    return 1
}

select_managed_installed_entries() {
    local installed_name
    local item
    local match_status

    if (( ${#MANAGED_FORMULAE[@]} && ${#INSTALLED_FORMULAE[@]} )); then
        for item in "${MANAGED_FORMULAE[@]}"; do
            if find_installed_name "$item" "${INSTALLED_FORMULAE[@]}"; then
                installed_name="$MATCHED_INSTALLED_NAME"
                FORMULAE_TO_REMOVE+=("$installed_name")
            else
                match_status=$?
                if (( match_status == 2 )); then
                    die "Ambiguous installed formula name for Brewfile entry: $item"
                fi
            fi
        done
    fi

    if (( ${#MANAGED_CASKS[@]} && ${#INSTALLED_CASKS[@]} )); then
        for item in "${MANAGED_CASKS[@]}"; do
            if find_installed_name "$item" "${INSTALLED_CASKS[@]}"; then
                installed_name="$MATCHED_INSTALLED_NAME"
                CASKS_TO_REMOVE+=("$installed_name")
            else
                match_status=$?
                if (( match_status == 2 )); then
                    die "Ambiguous installed cask name for Brewfile entry: $item"
                fi
            fi
        done
    fi

    if (( ${#MANAGED_TAPS[@]} && ${#INSTALLED_TAPS[@]} )); then
        for item in "${MANAGED_TAPS[@]}"; do
            if find_installed_name "$item" "${INSTALLED_TAPS[@]}"; then
                installed_name="$MATCHED_INSTALLED_NAME"
                TAPS_TO_REMOVE+=("$item")
            fi
        done
    fi
}

print_inventory_group() {
    local heading="$1"
    local item
    shift

    printf '%s (%d):\n' "$heading" "$#"
    if (( $# == 0 )); then
        printf '  (none)\n'
        return 0
    fi

    for item in "$@"; do
        printf '  - %s\n' "$item"
    done
}

print_homebrew_plan() {
    case "$UNINSTALL_SCOPE" in
        brewfile)
            printf '%s\n' "Homebrew plan: remove only currently installed Brewfile entries."
            if (( ${#CASKS_TO_REMOVE[@]} )); then
                print_inventory_group "Casks" "${CASKS_TO_REMOVE[@]}"
            else
                print_inventory_group "Casks"
            fi
            if (( ${#FORMULAE_TO_REMOVE[@]} )); then
                print_inventory_group "Formulae" "${FORMULAE_TO_REMOVE[@]}"
            else
                print_inventory_group "Formulae"
            fi
            if (( ${#TAPS_TO_REMOVE[@]} )); then
                print_inventory_group "Taps" "${TAPS_TO_REMOVE[@]}"
            else
                print_inventory_group "Taps"
            fi
            ;;
        all-homebrew)
            printf "Homebrew plan: remove every cask and run Homebrew's official uninstaller for %s.\n" "$BREW_PREFIX"
            if (( ${#INSTALLED_CASKS[@]} )); then
                print_inventory_group "Casks" "${INSTALLED_CASKS[@]}"
            else
                print_inventory_group "Casks"
            fi
            if (( ${#INSTALLED_FORMULAE[@]} )); then
                print_inventory_group "Formulae removed with the prefix" "${INSTALLED_FORMULAE[@]}"
            else
                print_inventory_group "Formulae removed with the prefix"
            fi
            if (( ${#INSTALLED_TAPS[@]} )); then
                print_inventory_group "Taps removed with the prefix" "${INSTALLED_TAPS[@]}"
            else
                print_inventory_group "Taps removed with the prefix"
            fi
            warn "The official uninstaller also targets Homebrew caches, logs, and integration files outside the prefix; its exact file list depends on the machine."
            ;;
    esac

    if [[ "$UNINSTALL_ZAP_APP_DATA" == "1" ]]; then
        warn "Cask zap is enabled for the casks listed above."
    else
        log "Cask app-data zap is disabled."
    fi
}

remove_brewfile_entries() {
    printf "$GREEN$BOLD%s$NORMAL\n" "📦 Removing installed Brewfile entries"

    if (( ${#CASKS_TO_REMOVE[@]} )); then
        if [[ "$UNINSTALL_ZAP_APP_DATA" == "1" ]]; then
            run env HOMEBREW_NO_AUTOREMOVE=1 \
                "$BREW_BIN" uninstall --cask --zap "${CASKS_TO_REMOVE[@]}"
        else
            run env HOMEBREW_NO_AUTOREMOVE=1 \
                "$BREW_BIN" uninstall --cask "${CASKS_TO_REMOVE[@]}"
        fi
    else
        log "No installed Brewfile casks to remove."
    fi

    if (( ${#FORMULAE_TO_REMOVE[@]} )); then
        run env HOMEBREW_NO_AUTOREMOVE=1 \
            "$BREW_BIN" uninstall --formula "${FORMULAE_TO_REMOVE[@]}"
    else
        log "No installed Brewfile formulae to remove."
    fi

    if (( ${#TAPS_TO_REMOVE[@]} )); then
        # Homebrew refuses to untap a repository still needed by an installed
        # formula or cask. Do not add --force: unrelated packages win.
        run "$BREW_BIN" untap "${TAPS_TO_REMOVE[@]}"
    else
        log "No installed Brewfile taps to remove."
    fi

    log "Homebrew itself and unrelated packages were preserved."
    log "Dependencies not declared in the Brewfile were excluded from automatic cleanup."
    if [[ "$UNINSTALL_ZAP_APP_DATA" == "0" ]]; then
        log "Homebrew cask zap procedures were not requested."
    fi
}

cleanup_homebrew_uninstaller() {
    if [[ -n "$HOMEBREW_UNINSTALLER" && -f "$HOMEBREW_UNINSTALLER" ]]; then
        rm -f -- "$HOMEBREW_UNINSTALLER"
    fi
}

prepare_homebrew_uninstaller() {
    local temp_directory="${TMPDIR:-/tmp}"
    local temp_template

    if [[ "$temp_directory" == "/" ]]; then
        temp_template="/homebrew-uninstall.XXXXXX"
    else
        temp_template="${temp_directory%/}/homebrew-uninstall.XXXXXX"
    fi

    if is_dry_run; then
        HOMEBREW_UNINSTALLER="$temp_template"
        run /usr/bin/curl \
            --proto '=https' \
            --tlsv1.2 \
            --fail \
            --silent \
            --show-error \
            --location \
            --output "$HOMEBREW_UNINSTALLER" \
            "$HOMEBREW_UNINSTALLER_URL"
        run /bin/bash -n "$HOMEBREW_UNINSTALLER"
        return 0
    fi

    HOMEBREW_UNINSTALLER="$(mktemp "$temp_template")"
    trap cleanup_homebrew_uninstaller EXIT

    if ! /usr/bin/curl \
        --proto '=https' \
        --tlsv1.2 \
        --fail \
        --silent \
        --show-error \
        --location \
        --output "$HOMEBREW_UNINSTALLER" \
        "$HOMEBREW_UNINSTALLER_URL"; then
        die "Failed to download Homebrew's official uninstaller. No Homebrew package was removed."
    fi

    if ! /bin/bash -n "$HOMEBREW_UNINSTALLER"; then
        die "Downloaded Homebrew uninstaller failed its shell syntax check. No Homebrew package was removed."
    fi
}

remove_all_homebrew() {
    local uninstaller_status

    printf "$GREEN$BOLD%s$NORMAL\n" "📟 Removing every installed Homebrew cask"
    if (( ${#INSTALLED_CASKS[@]} )); then
        if [[ "$UNINSTALL_ZAP_APP_DATA" == "1" ]]; then
            run env HOMEBREW_NO_AUTOREMOVE=1 \
                "$BREW_BIN" uninstall --cask --zap "${INSTALLED_CASKS[@]}"
        else
            run env HOMEBREW_NO_AUTOREMOVE=1 \
                "$BREW_BIN" uninstall --cask "${INSTALLED_CASKS[@]}"
        fi
    else
        log "No installed Homebrew casks to remove."
    fi

    printf "$GREEN$BOLD%s$NORMAL\n" "🍺 Running Homebrew's official whole-prefix uninstaller"
    if is_dry_run; then
        run env NONINTERACTIVE=1 /bin/bash "$HOMEBREW_UNINSTALLER" --path "$BREW_PREFIX"
        return 0
    fi

    if env NONINTERACTIVE=1 /bin/bash "$HOMEBREW_UNINSTALLER" --path "$BREW_PREFIX"; then
        uninstaller_status=0
    else
        uninstaller_status=$?
    fi

    cleanup_homebrew_uninstaller
    trap - EXIT

    if (( uninstaller_status != 0 )); then
        die "Homebrew's official uninstaller failed with status $uninstaller_status."
    fi
}

prepare_homebrew_plan() {
    find_brew_binary || die "Homebrew is unavailable; use --links-only to unlink without it."
    read_installed_inventory

    case "$UNINSTALL_SCOPE" in
        brewfile)
            read_brewfile_inventory
            select_managed_installed_entries
            ;;
        all-homebrew)
            BREW_PREFIX="$("$BREW_BIN" --prefix)"
            guard_brew_prefix "$BREW_PREFIX"
            ;;
        *)
            die "Unsupported Homebrew uninstall scope: $UNINSTALL_SCOPE"
            ;;
    esac
}

execute_homebrew_plan() {
    case "$UNINSTALL_SCOPE" in
        brewfile) remove_brewfile_entries ;;
        all-homebrew) remove_all_homebrew ;;
        *) die "Unsupported Homebrew uninstall scope: $UNINSTALL_SCOPE" ;;
    esac
}
