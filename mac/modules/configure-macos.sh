#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Close any open System Settings panes, to prevent them from overriding settings we're about to change
osascript -e 'tell application "System Settings" to quit'


###############################################################################
# General UI/UX                                                               #
###############################################################################
echo "Configuring General UI/UX..."

# Detect hardware model and set computer name
MODEL_NAME=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/{print $2}')
case "$MODEL_NAME" in
  *"MacBook Air"*)  MODEL_SUFFIX="MacBook Air";;
  *"MacBook Pro"*)  MODEL_SUFFIX="MacBook Pro";;
  *"MacBook"*)      MODEL_SUFFIX="MacBook";;
  *"Mac mini"*)     MODEL_SUFFIX="Mac Mini";;
  *"Mac Pro"*)      MODEL_SUFFIX="Mac Pro";;
  *"Mac Studio"*)   MODEL_SUFFIX="Mac Studio";;
  *"iMac"*)         MODEL_SUFFIX="iMac";;
  *)                MODEL_SUFFIX="Mac";;
esac

COMPUTER_NAME="Hector's ${MODEL_SUFFIX}"
# LocalHostName must be DNS-safe: no spaces, no apostrophes
LOCAL_NAME="${MODEL_SUFFIX// /-}"

# Set computer name (as done via System Settings → General → Sharing)
sudo scutil --set ComputerName "$COMPUTER_NAME"
# Clear HostName if previously set — let macOS derive it from LocalHostName
if scutil --get HostName &>/dev/null; then
  sudo scutil --remove HostName
  echo "Cleared explicit HostName (macOS will derive it automatically)"
fi
sudo scutil --set LocalHostName "$LOCAL_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$LOCAL_NAME"
echo "Computer name set to: $COMPUTER_NAME (local: $LOCAL_NAME)"

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "

# Set highlight color to green
# defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

# Reset sidebar icon size to system default
defaults delete NSGlobalDomain NSTableViewDefaultSizeMode 2>/dev/null || true

# Showing scrollbars
# defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# Possible values: `WhenScrolling`, `Automatic` and `Always`

# Reset focus ring animation to system default (enabled)
defaults delete NSGlobalDomain NSUseAnimatedFocusRing 2>/dev/null || true

# Reset save panel to system default (collapsed)
defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode 2>/dev/null || true
defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 2>/dev/null || true

# Reset print panel to system default (collapsed)
defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint 2>/dev/null || true
defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint2 2>/dev/null || true

# Save to disk (not to iCloud) by default
# defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
# defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
# WARNING: This disables Gatekeeper protections — security risk on a fresh machine
# defaults write com.apple.LaunchServices LSQuarantine -bool false

# Remove duplicates in the "Open With" menu (also see `lscleanup` alias)
# NOTE: This rebuilds the entire Launch Services database and is slow — run manually if needed
# /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Display ASCII control characters using caret notation in standard text views
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
# defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# Set Help Viewer windows to non-floating mode
# defaults write com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName


# Never go into computer sleep mode
# sudo systemsetup -setcomputersleep Off > /dev/null

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Reset smart dashes to system default (enabled)
defaults delete NSGlobalDomain NSAutomaticDashSubstitutionEnabled 2>/dev/null || true

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Reset smart quotes to system default (enabled)
defaults delete NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null || true

# Disable auto-correct
# defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set a custom wallpaper image. `DefaultDesktop.jpg` is already a symlink, and
# all wallpapers are in `/Library/Desktop Pictures/`. The default is `Wave.jpg`.
#rm -rf ~/Library/Application Support/Dock/desktoppicture.db
#sudo rm -rf /System/Library/CoreServices/DefaultDesktop.jpg
#sudo ln -s /path/to/your/image /System/Library/CoreServices/DefaultDesktop.jpg

echo "✓ General UI/UX configured"

###############################################################################
# Power management                                                            #
###############################################################################
echo "Configuring Power management..."

# NOTE: On Apple Silicon Macs, hibernation is managed by the system and
# changing hibernatemode is not recommended. Only uncomment on Intel Macs.
# sudo pmset -a hibernatemode 0

echo "✓ Power management configured"

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################
echo "Configuring Trackpad, keyboard, and input..."

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Trackpad: enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
# Reset natural scrolling to system default (enabled)
defaults delete NSGlobalDomain com.apple.swipescrolldirection 2>/dev/null || true

# NOTE: Bluetooth SBC bitpool tuning is obsolete on modern macOS (AAC/LC3 codecs are used)

# Reset full keyboard access to system default
defaults delete NSGlobalDomain AppleKeyboardUIMode 2>/dev/null || true

# Use scroll gesture with the Ctrl (^) modifier key to zoom
# defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
# defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
# Follow the keyboard focus while zoomed in
# defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Reset press-and-hold to system default (enabled — shows accent menu)
defaults delete NSGlobalDomain ApplePressAndHoldEnabled 2>/dev/null || true

# Reset keyboard repeat rate to system default
defaults delete NSGlobalDomain KeyRepeat 2>/dev/null || true
defaults delete NSGlobalDomain InitialKeyRepeat 2>/dev/null || true

# Set language and text formats
# Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
# `Inches`, `en_GB` with `en_US`, and `true` with `false`.
# defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
# defaults write NSGlobalDomain AppleLocale -string "en_GB@currency=EUR"
# defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
# defaults write NSGlobalDomain AppleMetricUnits -bool true

# Show language menu in the top right corner of the boot screen
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set the timezone; see `sudo systemsetup -listtimezones` for other values
# (systemsetup is deprecated since macOS 12.3 but timezone setting still works)
sudo systemsetup -settimezone "America/Los_Angeles" > /dev/null

# Stop iTunes from responding to the keyboard media keys
#launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

# ⚠️  MANUAL STEP REQUIRED: Swap Command ↔ Control keys (Windows-like shortcuts)
#
# This CANNOT be automated by the script because macOS stores modifier key
# mappings per-keyboard using hardware vendor/product IDs, which vary depending
# on which keyboards are connected. This is actually preferable — it lets you
# swap keys on your main keyboard while keeping other keyboards (e.g. Logitech)
# with their default layout.
#
# After running this script, do the following ONCE per keyboard:
#   1. Open System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys
#   2. Select your keyboard from the "Select keyboard" dropdown
#   3. Set "Control (^) Key" → Command
#   4. Set "Command Key" → Control (^)
#   5. Click "Done"
#
# The setting persists across reboots automatically — no LaunchAgent needed.
#
# Cleanup: Remove any leftover hidutil remapping from older versions of this script
if [ -f "$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist" ]; then
  launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist"
  echo "Removed old hidutil key remapping LaunchAgent"
fi
hidutil property --set '{"UserKeyMapping":[]}' > /dev/null 2>&1 || true

echo "✓ Trackpad, keyboard, and input configured"

###############################################################################
# Screen                                                                      #
###############################################################################
echo "Configuring Screen settings..."

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# NOTE: Subpixel font rendering (AppleFontSmoothing) was removed in macOS Mojave
# and is a no-op on all Retina/Apple Silicon Macs.

# NOTE: HiDPI display modes are native on all Apple Silicon and modern Macs.
# DisplayResolutionEnabled is no longer needed.

echo "✓ Screen settings configured"

###############################################################################
# Finder                                                                      #
###############################################################################
echo "Configuring Finder..."

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Set Desktop as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: show toolbar
defaults write com.apple.finder ShowToolbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
# WARNING: Skipping verification allows tampered .dmg files to install silently
# defaults write com.apple.frameworks.diskimages skip-verify -bool true
# defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
# defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Show item info near icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Show item info below the icons on the desktop
/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom true" ~/Library/Preferences/com.apple.finder.plist

# Group icons by kind on the desktop and snap-to-grid in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy kind" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Increase grid spacing for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Increase the size of icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 64" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 64" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 64" ~/Library/Preferences/com.apple.finder.plist

# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `Nlsv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes


# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

echo "✓ Finder configured"

###############################################################################
# Dock and hot corners                                                        #
###############################################################################
echo "Configuring Dock and hot corners..."

# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set the icon size of Dock items to 50 pixels
defaults write com.apple.dock tilesize -int 50

# Reset minimize/maximize window effect to system default (genie)
defaults delete com.apple.dock mineffect 2>/dev/null || true

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't wipe Dock apps — keep whatever is currently pinned
# To reset Dock to defaults on a fresh install, uncomment:
# defaults write com.apple.dock persistent-apps -array

# Show only open applications in the Dock
#defaults write com.apple.dock static-only -bool true

# Don’t animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don’t group windows by application in Mission Control
# (i.e. use the old Exposé behavior instead)
defaults write com.apple.dock expose-group-by-app -bool false

# NOTE: Dashboard was removed in macOS Catalina — no settings needed

# Reset auto-rearrange Spaces to system default (enabled)
defaults delete com.apple.dock mru-spaces 2>/dev/null || true

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
# defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Reset show recent applications in Dock to system default (enabled)
defaults delete com.apple.dock show-recents 2>/dev/null || true

# Disable the Launchpad gesture (pinch with thumb and three fingers)
defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

# Reset Launchpad, but keep the desktop wallpaper intact
find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete

# NOTE: Xcode simulators are registered automatically in modern macOS — manual symlinks not needed

# Add a spacer to the left side of the Dock (where the applications are)
#defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'
# Add a spacer to the right side of the Dock (where the Trash is)
#defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'

echo "✓ Dock and hot corners configured"
###############################################################################
# Spotlight                                                                   #
###############################################################################
echo "Configuring Spotlight..."

# NOTE: Spotlight icon cannot be hidden via chmod on sealed system volume (SIP)
# Use System Settings > Control Center to manage menu bar items instead

# Disable Spotlight indexing for any volume that gets mounted and has not yet
# been indexed before.
# Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
# Commented because: Could not write domain /.Spotlight-V100/VolumeConfiguration; exiting
# sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

# Change indexing order and disable some search results
# Yosemite-specific search results (remove them if you are using macOS 10.9 or older):
# 	MENU_DEFINITION
# 	MENU_CONVERSION
# 	MENU_EXPRESSION
# 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
# 	MENU_WEBSEARCH             (send search queries to Apple)
# 	MENU_OTHER
defaults write com.apple.spotlight orderedItems -array \
	'{"enabled" = 1;"name" = "APPLICATIONS";}' \
	'{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
	'{"enabled" = 1;"name" = "DIRECTORIES";}' \
	'{"enabled" = 1;"name" = "PDF";}' \
	'{"enabled" = 1;"name" = "FONTS";}' \
	'{"enabled" = 0;"name" = "DOCUMENTS";}' \
	'{"enabled" = 0;"name" = "MESSAGES";}' \
	'{"enabled" = 0;"name" = "CONTACT";}' \
	'{"enabled" = 0;"name" = "EVENT_TODO";}' \
	'{"enabled" = 0;"name" = "IMAGES";}' \
	'{"enabled" = 0;"name" = "BOOKMARKS";}' \
	'{"enabled" = 0;"name" = "MUSIC";}' \
	'{"enabled" = 0;"name" = "MOVIES";}' \
	'{"enabled" = 0;"name" = "PRESENTATIONS";}' \
	'{"enabled" = 0;"name" = "SPREADSHEETS";}' \
	'{"enabled" = 0;"name" = "SOURCE";}' \
	'{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
	'{"enabled" = 0;"name" = "MENU_OTHER";}' \
	'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
	'{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
	'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
	'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
# Load new settings before rebuilding the index
killall mds > /dev/null 2>&1
# Make sure indexing is enabled for the main volume
sudo mdutil -i on / > /dev/null
# Rebuild the index from scratch
sudo mdutil -E / > /dev/null

# Set Spotlight shortcut to Control+Space
# Since Cmd↔Ctrl are swapped per-keyboard via System Settings, the physical
# Command key sends Control — so Ctrl+Space keeps the same finger position
# Key combo: Control (262144 = 0x40000) + Space (keyCode 49)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"

echo "✓ Spotlight configured"

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################
echo "Configuring Terminal & iTerm..."

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Enable “focus follows mouse” for Terminal.app and all X11 apps
# i.e. hover over a window and start typing in it without clicking first
#defaults write com.apple.terminal FocusFollowsMouse -bool true
#defaults write org.x.X11 wm_ffm -bool true

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# Disable the annoying line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# Import the custom "ClearDarkBlack" profile and make it the default.
#
# We import a bundled .terminal profile file (CaskaydiaCove Nerd Font + pure
# black background at 80% opacity, no blur) rather than editing
# com.apple.Terminal.plist directly. Terminal.app caches its preferences in
# memory and rewrites the plist on quit, so direct plist edits are ignored while
# it is running and clobbered on quit — and AppleScript cannot set window
# opacity. Importing a .terminal file (named after the file => profile
# "ClearDarkBlack") is the only channel that reliably carries transparency and
# survives a relaunch. macOS 26 / Tahoe retired the old "Pro" profile, so we
# ship our own instead of relying on a built-in one.
TERM_PROFILE="ClearDarkBlack"
TERM_PROFILE_FILE="$SCRIPT_DIR/../config/${TERM_PROFILE}.terminal"
if [ -f "$TERM_PROFILE_FILE" ]; then
  open "$TERM_PROFILE_FILE"
  sleep 1
  defaults write com.apple.terminal "Default Window Settings" -string "$TERM_PROFILE"
  defaults write com.apple.terminal "Startup Window Settings" -string "$TERM_PROFILE"
  echo "Imported Terminal profile '$TERM_PROFILE' and set it as default"
else
  echo "⚠ Terminal profile not found: $TERM_PROFILE_FILE"
fi

# Set font in VS Code settings
# VS Code uses JSONC (JSON with comments & trailing commas), so we use a
# regex-based approach instead of strict json.load() which would choke on it.
FONT_NAME="CaskaydiaCove Nerd Font Mono"
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
  python3 -c "
import re, sys
path = sys.argv[1]
font = sys.argv[2]
with open(path) as f:
    text = f.read()
# Strip single-line comments (// ...) for parsing, but we'll do a targeted edit
if re.search(r'\"terminal\.integrated\.fontFamily\"', text):
    text = re.sub(
        r'(\"terminal\.integrated\.fontFamily\"\s*:\s*)\"[^\"]*\"',
        r'\1\"' + font + '\"',
        text
    )
else:
    # Insert before the last closing brace
    text = re.sub(
        r'\}\s*\Z',
        ',\n    \"terminal.integrated.fontFamily\": \"' + font + '\"\n}',
        text
    )
with open(path, 'w') as f:
    f.write(text)
" "$VSCODE_SETTINGS" "${FONT_NAME}" && echo "Set VS Code terminal font to ${FONT_NAME}" || echo "⚠ Could not update VS Code settings"
else
  mkdir -p "$HOME/Library/Application Support/Code/User"
  echo '{ "terminal.integrated.fontFamily": "'"${FONT_NAME}"'" }' > "$VSCODE_SETTINGS"
  echo "Created VS Code settings with terminal font ${FONT_NAME}"
fi
# Don’t display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

echo "✓ Terminal & iTerm configured"

###############################################################################
# Time Machine                                                                #
###############################################################################
echo "Configuring Time Machine..."

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable local Time Machine backups
# Commented because: disablelocal: Unrecognized verb.
# hash tmutil &> /dev/null && sudo tmutil disablelocal

echo "✓ Time Machine configured"

###############################################################################
# Activity Monitor                                                            #
###############################################################################
echo "Configuring Activity Monitor..."

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

echo "✓ Activity Monitor configured"

###############################################################################
# Contacts, TextEdit, and Disk Utility                                        #
###############################################################################
echo "Configuring Contacts, TextEdit, and Disk Utility..."

# Enable the debug menu in Contacts
# NOTE: Contacts is sandboxed on macOS Sonoma+ — this may silently fail
defaults write com.apple.addressbook ABShowDebugMenu -bool true 2>/dev/null || true

# NOTE: Dashboard was removed in macOS Catalina — devmode setting removed

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Auto-play videos when opened with QuickTime Player
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

echo "✓ Contacts, TextEdit, and Disk Utility configured"

###############################################################################
# Mac App Store                                                               #
###############################################################################
echo "Configuring Mac App Store..."

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Automatically download apps purchased on other Macs
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Allow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

echo "✓ Mac App Store configured"

###############################################################################
# Photos                                                                      #
###############################################################################
echo "Configuring Photos..."

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

echo "✓ Photos configured"

###############################################################################
# Messages                                                                    #
###############################################################################
echo "Configuring Messages..."

# Disable automatic emoji substitution (i.e. use plain text smileys)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

# Disable smart quotes as it’s annoying for messages that contain code
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# Disable continuous spell checking
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

echo "✓ Messages configured"

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################
echo "Configuring Google Chrome..."

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the all too sensitive backswipe on Magic Mouse
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

echo "✓ Google Chrome configured"

###############################################################################
# Modern macOS settings (macOS 13+)                                           #
###############################################################################
echo "Configuring Modern macOS settings..."

# Disable Stage Manager (set to true to enable)
defaults write com.apple.WindowManager GloballyEnabled -bool false

# Show battery percentage in menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

echo "✓ Modern macOS settings configured"

###############################################################################
# Security                                                                    #
###############################################################################
echo "Configuring Security..."

# Enable the macOS firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Check FileVault status (enable manually via System Settings > Privacy & Security if off)
echo "FileVault status:"
fdesetup status

echo "✓ Security configured"

###############################################################################
# Kill affected applications                                                  #
###############################################################################
echo "Restarting affected applications..."

# Restart cfprefsd first to flush preferences to disk
killall "cfprefsd" &> /dev/null
sleep 1

for app in "Activity Monitor" \
	"Calendar" \
	"Contacts" \
	"Dock" \
	"Finder" \
	"Google Chrome" \
	"Mail" \
	"Messages" \
	"Photos" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done
echo "✓ Done. Note that some of these changes require a logout/restart to take effect."