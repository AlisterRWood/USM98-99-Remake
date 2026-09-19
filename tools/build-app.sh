#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --product USM98
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$PWD/dist/Ultimate Soccer Manager.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/USM98" "$APP/Contents/MacOS/USM98"
# SwiftPM resolves the bundle through Bundle.main.resourceURL in a macOS app.
cp -R "$BIN_DIR/UltimateSoccerManager_USMApp.bundle" "$APP/Contents/Resources/"
cp Sources/USMApp/Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Ultimate Soccer Manager</string>
<key>CFBundleDisplayName</key><string>Ultimate Soccer Manager</string>
<key>CFBundleIdentifier</key><string>local.usm98.native</string>
<key>CFBundleExecutable</key><string>USM98</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.6</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleVersion</key><string>9</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf 'Built: %s\n' "$APP"
