#!/bin/bash
# Standalone NOVEC Hot Corners installer; no n8n or admin access needed.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "NOVEC Hot Corners requires macOS." >&2
  exit 1
fi
ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$ROOT/NOVEC Hot Corners.app"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/NOVEC Hot Corners.app"
LABEL="online.novec.hotcorners"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
APP_BINARY="$DEST_APP/Contents/MacOS/novec-hot-corners"

if [[ ! -f "$SOURCE_APP/Contents/Info.plist" || ! -x "$SOURCE_APP/Contents/MacOS/novec-hot-corners" ]]; then
  echo "Application missing. Extract the entire release ZIP before installing." >&2
  exit 1
fi

# Validate the bundle before touching any existing installation.
codesign --verify --deep --strict "$SOURCE_APP"
mkdir -p "$DEST_DIR" "$HOME/Library/LaunchAgents"

# Stop only the previously installed NOVEC helper.
pkill -TERM -f "^$APP_BINARY$" 2>/dev/null || true

# Back up previous version for manual rollback.
if [[ -d "$DEST_APP" ]]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$DEST_DIR/NOVEC Hot Corners.backup-$stamp.app"
  mv "$DEST_APP" "$backup"
  echo "Previous app backed up to $backup"
fi

ditto "$SOURCE_APP" "$DEST_APP"
codesign --verify --deep --strict "$DEST_APP"

# Native Mission Control (top-left) and NOVEC-managed other three corners.
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0
for corner in bl tr br; do
  defaults write com.apple.dock "wvous-$corner-corner" -int 1
  defaults write com.apple.dock "wvous-$corner-modifier" -int 0
done
killall Dock 2>/dev/null || true

cat > "$PLIST" <<PLIST_XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array>
<string>/usr/bin/open</string><string>-a</string><string>$DEST_APP</string><string>--args</string><string>--background</string>
</array>
<key>RunAtLoad</key><true/>
<key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PLIST_XML

plutil -lint "$PLIST"
# Show the new settings GUI on first launch. The login agent uses --background.
if ! open -a "$DEST_APP"; then
  echo "macOS blocked the launch. Open System Settings > Privacy & Security, use Open Anyway, then open NOVEC Hot Corners again." >&2
  exit 2
fi
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null; then
  echo "Automatic startup registered."
else
  echo "Automatic startup will be applied on next GUI login."
fi

echo ""
echo "Installed at $DEST_APP"
echo "Enable NOVEC Hot Corners in System Settings > Privacy & Security > Accessibility."
echo "Ensure Dictation is enabled in System Settings > Keyboard."
echo "Settings: use the NOVEC menu bar icon to configure each corner.\nDefaults: TL Mission Control; TR Fn+D Dictation; BL Screenshot; BR Enter."
