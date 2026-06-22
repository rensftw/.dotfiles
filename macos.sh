#!/usr/bin/env bash
set -Eeuo pipefail
# Based on https://mths.be/macos

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"
enable_error_trap
source "$DOTFILES_LOCATION/_scripts/preflight.sh"
run_preflight macos
enable_dry_run_command_shims

printf "$BOLD%s$NORMAL\n" "This script will apply macOS preferences and then restart the computer."
if is_dry_run; then
    log "DRY RUN: skipping macOS preferences confirmation prompt."
    ANSWER="y"
else
    printf "$YELLOW_BACKGROUND$BOLD%s$NORMAL\n" "Proceed? [y/n]"
    read -r ANSWER
fi

if [ "$ANSWER" != "y" ]; then
    exit
fi

printf "$MAGENTA_BACKGROUND$BOLD%s$NORMAL\n" "Applying macOS preferences"
# Close System Settings so it does not overwrite preferences while quitting.
# System Preferences was renamed and removed from current macOS releases.
if is_dry_run; then
    run killall "System Settings"
else
    killall "System Settings" &> /dev/null || true
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `apply-macos-preferences.sh` has finished
if ! is_dry_run; then
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable windows opening animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Trackpad: enable tap to click for this user
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map two-finger tap to right-click
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Set the timezone; see `sudo systemsetup -listtimezones` for other values
sudo systemsetup -settimezone "Europe/Sofia"

###############################################################################
# Power management                                                            #
###############################################################################

if is_dry_run; then
    PMSET_CAPABILITIES="lidwake standbydelayhigh standbydelaylow highstandbythreshold"
else
    PMSET_CAPABILITIES="$(pmset -g cap 2>/dev/null || true)"
fi

set_pmset_if_supported() {
    local scope="$1"
    local setting="$2"
    local value="$3"

    if is_dry_run || printf '%s\n' "$PMSET_CAPABILITIES" | grep -Eq "(^|[[:space:]])${setting}([[:space:]]|$)"; then
        sudo pmset "$scope" "$setting" "$value"
    else
        warn "Skipping unsupported pmset setting '$setting' on this Mac."
    fi
}

# Enable lid wakeup when the Mac exposes that capability
set_pmset_if_supported -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Sleep the display after 30 minutes
sudo pmset -a displaysleep 30

# Set machine sleep to 30 minutes on charger
sudo pmset -c sleep 30

# Set machine sleep to 30 minutes on battery
sudo pmset -b sleep 30

# On current macOS, standby delay has separate high- and low-battery keys.
# Hibernate after 24 hours above 50% battery and after 3 hours below it.
set_pmset_if_supported -a standbydelayhigh 86400
set_pmset_if_supported -a standbydelaylow 10800
set_pmset_if_supported -a highstandbythreshold 50

###############################################################################
# Security & Privacy                                                          #
###############################################################################

# Report security state without making recovery-key or network-policy choices.
if is_dry_run; then
    run /usr/bin/fdesetup status
    run /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
else
    FILEVAULT_STATUS="$(/usr/bin/fdesetup status 2>&1 || true)"
    FIREWALL_STATUS="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1 || true)"
    log "FileVault: $FILEVAULT_STATUS"
    log "Firewall: $FIREWALL_STATUS"
    [[ "$FILEVAULT_STATUS" == *"FileVault is On"* ]] || warn "FileVault is not on. Enable it in System Settings after saving the recovery key safely."
    [[ "$FIREWALL_STATUS" == *"enabled"* ]] || warn "The application firewall is not enabled. Review System Settings > Network > Firewall."
fi

# Require a password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

###############################################################################
# Terminal.app                                                                #
###############################################################################

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
# Command to find and remove .DS_Store files (which keep track of previously used views)
# sudo find / -name ".DS_Store" -exec rm {} \;
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "genie"

# Put the Dock at the bottom of the screen
defaults write com.apple.dock orientation -string "bottom"

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Wipe all (default) app icons from the Dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
defaults write com.apple.dock persistent-apps -array

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# Top left screen corner → Start screensaver
defaults write com.apple.dock wvous-tl-corner -int 5
defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right screen corner → Lock screen
defaults write com.apple.dock wvous-tr-corner -int 13
defaults write com.apple.dock wvous-tr-modifier -int 0

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

# Privacy: don’t send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari’s home page to `about:blank` for faster loading
defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting the Backspace key to go to the previous page in history
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# Hide Safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
# Disable auto-correct
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# Disable AutoFill
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false

# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

# Safari's current privacy controls are managed in supported UI rather than by
# stable public defaults keys. Do not pretend deprecated keys enforce them.
warn "After restart, verify Safari > Settings > Privacy: Prevent cross-site tracking and Hide IP address."

###############################################################################
# Mail                                                                        #
###############################################################################

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
	"cfprefsd" \
	"Dock" \
	"Finder" \
	"Mail" \
	"Safari" \
	"SystemUIServer"; do
    if is_dry_run; then
        run killall "${app}"
    else
	    killall "${app}" &> /dev/null || true
    fi
done

printf "$GREEN$BOLD%s$NC\n" "✔ Preferences have been applied."

# Restart computer in 1 minute
if is_dry_run; then
    log "DRY RUN: would restart the computer in 1 minute."
else
    printf "$YELLOW_BACKGROUND$BOLD%s$NC\n" "Restarting computer in 1 minute."
    sudo shutdown -r +1
fi
