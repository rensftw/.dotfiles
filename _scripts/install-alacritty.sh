#!/usr/bin/env bash
################################################################################
# Install or update Alacritty from its GitHub release DMG
################################################################################

# Homebrew disabled the alacritty cask on 2026-09-01 (the app isn't notarized,
# so it fails Homebrew's Gatekeeper check), and `brew upgrade` skips disabled
# casks. This script replaces the cask: it installs the latest release,
# recreates the cask's CLI/completion/man-page links under the Homebrew prefix,
# and installs Alacritty's terminfo. Safe to re-run — it only downloads when
# the installed version differs from the latest release, or when the old cask
# still needs to be adopted.
#
#   bash _scripts/install-alacritty.sh [--dry-run]
set -Eeuo pipefail

DOTFILES_LOCATION="${DOTFILES_LOCATION:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES_LOCATION/_scripts/colors.sh"
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"
enable_error_trap

APP="/Applications/Alacritty.app"
STAGED_APP="/Applications/.Alacritty.app.new"
OLD_APP="/Applications/.Alacritty.app.old"
RELEASE_API="https://api.github.com/repos/alacritty/alacritty/releases/latest"
# Same target the cask used; ncurses looks here before the system database.
TERMINFO_DIR="${TERMINFO:-$HOME/.terminfo}"
BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || true)}"

tmp_dir=""
dmg_mounted=false

cleanup() {
    if [[ "$dmg_mounted" == true ]]; then
        hdiutil detach -quiet "$tmp_dir/mnt" || true
    fi
    [[ -n "$tmp_dir" ]] && rm -rf -- "$tmp_dir"
    # Only left behind if the run failed between staging and the swap.
    [[ -d "$STAGED_APP" ]] && rm -rf -- "$STAGED_APP"
    return 0
}
trap cleanup EXIT

installed_version() {
    [[ -d "$APP" ]] || return 0
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || true
}

cask_installed() {
    [[ -n "$BREW_PREFIX" && -d "$BREW_PREFIX/Caskroom/alacritty" ]]
}

install_app() {
    local tag="$1" dmg_url="$2" dmg_digest="$3"
    local dmg="Alacritty-${tag}.dmg" actual_digest=""

    if is_dry_run; then
        print_command curl -fL -o "${TMPDIR:-/tmp}/$dmg" "$dmg_url"
        log "  (verify $dmg_digest)"
        print_command hdiutil attach -nobrowse -readonly "${TMPDIR:-/tmp}/$dmg"
        print_command ditto "/Volumes/Alacritty/Alacritty.app" "$STAGED_APP"
        cask_installed && print_command brew uninstall --cask alacritty
        print_command mv "$STAGED_APP" "$APP"
        return 0
    fi

    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/alacritty.XXXXXX")"

    log "Downloading $dmg"
    curl -fL --retry 3 --progress-bar -o "$tmp_dir/$dmg" "$dmg_url"
    actual_digest="sha256:$(shasum -a 256 "$tmp_dir/$dmg" | awk '{print $1}')"
    [[ "$actual_digest" == "$dmg_digest" ]] || die "Checksum mismatch for $dmg: expected $dmg_digest, got $actual_digest"

    hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$tmp_dir/mnt" "$tmp_dir/$dmg"
    dmg_mounted=true
    [[ -d "$tmp_dir/mnt/Alacritty.app" ]] || die "$dmg does not contain Alacritty.app"

    # Stage inside /Applications so the swap below is two same-volume renames:
    # a running Alacritty keeps working, and picks up the new version on relaunch.
    rm -rf -- "$STAGED_APP" "$OLD_APP"
    ditto "$tmp_dir/mnt/Alacritty.app" "$STAGED_APP"
    hdiutil detach -quiet "$tmp_dir/mnt"
    dmg_mounted=false
    # curl doesn't set the quarantine flag, but a copied-in DMG might carry it.
    xattr -dr com.apple.quarantine "$STAGED_APP" 2>/dev/null || true

    # The disabled cask would otherwise stay registered: every `brew upgrade`
    # warns about it, and `brew uninstall` would later delete this install.
    if cask_installed; then
        log "Removing the disabled Homebrew cask (it can no longer be upgraded)"
        brew uninstall --cask alacritty
    fi

    [[ -d "$APP" ]] && mv "$APP" "$OLD_APP"
    mv "$STAGED_APP" "$APP"
    rm -rf -- "$OLD_APP"
}

# Recreate the links the cask used to manage. They point into the app bundle,
# whose path is stable, so they survive future updates.
link_app_files() {
    local resources="$APP/Contents/Resources" entry target link_path

    if [[ -z "$BREW_PREFIX" ]]; then
        warn "Homebrew not found; skipping the alacritty CLI, completion, and man page links"
        return 0
    fi

    for entry in \
        "$APP/Contents/MacOS/alacritty|bin/alacritty" \
        "$resources/completions/_alacritty|share/zsh/site-functions/_alacritty" \
        "$resources/completions/alacritty.bash|etc/bash_completion.d/alacritty" \
        "$resources/completions/alacritty.fish|share/fish/vendor_completions.d/alacritty.fish" \
        "$resources/alacritty.1.gz|share/man/man1/alacritty.1.gz" \
        "$resources/alacritty-msg.1.gz|share/man/man1/alacritty-msg.1.gz" \
        "$resources/alacritty.5.gz|share/man/man5/alacritty.5.gz" \
        "$resources/alacritty-bindings.5.gz|share/man/man5/alacritty-bindings.5.gz"; do
        target="${entry%%|*}"
        link_path="$BREW_PREFIX/${entry#*|}"

        [[ -L "$link_path" && "$(readlink "$link_path")" == "$target" ]] && continue
        if [[ -e "$link_path" && ! -L "$link_path" ]]; then
            warn "Not replacing existing file: $link_path"
            continue
        fi
        run mkdir -p "$(dirname "$link_path")"
        run ln -sfn "$target" "$link_path"
    done
}

# macOS's terminfo database has no alacritty entry. Without one, TERM=alacritty
# leaves zsh unable to redraw the line (doubled characters, stray spaces).
install_terminfo() {
    local entry src dest

    for entry in alacritty alacritty-direct; do
        src="$APP/Contents/Resources/61/$entry"
        dest="$TERMINFO_DIR/61/$entry"

        if [[ ! -f "$src" ]]; then
            is_dry_run && { print_command cp "$src" "$dest"; continue; }
            die "Terminfo entry missing from the app bundle: $src"
        fi

        # Real copies, not the cask's symlinks, so TERM keeps resolving while
        # the app is being swapped or if it's ever removed.
        [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest" && continue
        run mkdir -p "$TERMINFO_DIR/61"
        # Never write through an old cask symlink into the app bundle.
        run rm -f "$dest"
        run cp "$src" "$dest"
    done
}

# GitHub allows 60 anonymous API requests an hour per IP address, shared with
# every other tool on the machine (and anyone behind the same NAT), so use a
# token when one is available — 5,000 requests an hour. Headers go through
# stdin so the token never appears in `ps`.
fetch_release_json() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}" response="" status="" reset="" body=""

    if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
        token="$(gh auth token 2>/dev/null || true)"
    fi

    response="$(
        {
            printf 'Accept: application/vnd.github+json\n'
            # An `if`, not `&&`: a false test would fail the pipeline under pipefail.
            if [[ -n "$token" ]]; then
                printf 'Authorization: Bearer %s\n' "$token"
            fi
        } | curl -sSL --retry 3 -H @- -w '\n%{http_code} %header{x-ratelimit-reset}' "$RELEASE_API"
    )" || die "Could not reach $RELEASE_API"

    status="${response##*$'\n'}"
    body="${response%$'\n'*}"
    reset="${status#* }"
    status="${status%% *}"

    case "$status" in
        200)
            printf '%s' "$body"
            ;;
        403|429)
            if [[ -z "$token" && "$reset" =~ ^[0-9]+$ ]]; then
                die "GitHub's anonymous API limit (60 requests/hour) is used up until $(date -r "$reset" +%H:%M). Run \`gh auth login\` (or set GITHUB_TOKEN) to raise it."
            fi
            die "GitHub refused $RELEASE_API (HTTP $status)${reset:+; limit resets at $(date -r "$reset" +%H:%M 2>/dev/null)}"
            ;;
        *)
            die "GitHub returned HTTP $status for $RELEASE_API"
            ;;
    esac
}

printf "$CYAN$BOLD%s$NORMAL\n" "🖥️  Installing Alacritty"

command -v jq >/dev/null 2>&1 || die "jq is required (brew install jq)"

# die already explained the failure inside the subshell; just stop.
release_json="$(fetch_release_json)" || exit 1
tag="$(jq -r '.tag_name' <<<"$release_json")"
latest="${tag#v}"
dmg_url="$(jq -r --arg name "Alacritty-${tag}.dmg" '.assets[] | select(.name == $name) | .browser_download_url' <<<"$release_json")"
dmg_digest="$(jq -r --arg name "Alacritty-${tag}.dmg" '.assets[] | select(.name == $name) | .digest // empty' <<<"$release_json")"
[[ -n "$dmg_url" ]] || die "Release $tag has no Alacritty-${tag}.dmg asset"
# Releases carry no GPG signatures; GitHub's asset digest is the only check.
[[ "$dmg_digest" == sha256:* ]] || die "Release $tag publishes no sha256 digest for its DMG; refusing to install unverified"

current="$(installed_version)"
installed=false

if [[ "$current" == "$latest" ]] && ! cask_installed; then
    printf "  $GREEN%s$NC\n" "✔ Alacritty $latest is up to date"
else
    if [[ -z "$current" ]]; then
        log "Installing Alacritty $latest"
    elif [[ "$current" == "$latest" ]]; then
        log "Reinstalling Alacritty $latest from GitHub to replace the disabled Homebrew cask"
    else
        log "Updating Alacritty $current → $latest"
    fi
    install_app "$tag" "$dmg_url" "$dmg_digest"
    installed=true
fi

link_app_files
install_terminfo

if [[ "$installed" == true ]] && ! is_dry_run; then
    printf "  $GREEN%s$NC\n" "✔ Alacritty $latest installed at $APP (relaunch to use it)"
fi
