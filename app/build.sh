#!/bin/sh
# Builds "I See Logic Pro.app" beside this script, with the theme library inside.
# VERSION sets the app version, for example VERSION=1.0.0 app/build.sh.
cd "$(dirname "$0")" || exit 1
../theme/build.sh || exit 1
app='I See Logic Pro.app'
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -parse-as-library -O -target arm64-apple-macos14 -o "$app/Contents/MacOS/ISeeLogicPro" ISeeLogicPro.swift || exit 1
cp ../theme/light-theme.dylib "$app/Contents/Resources/"
# The Logic Pro build that this version was tested with. The app shows a warning for
# other builds, because the theme uses internal names that an update can change.
tested_logic_build=7801
# CFBundleIdentifier must match SETTINGS_DOMAIN in light-theme.m.
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>CFBundleExecutable</key><string>ISeeLogicPro</string>
   <key>CFBundleIdentifier</key><string>io.github.karlingen.i-see-logic-pro</string>
   <key>CFBundleName</key><string>I See Logic Pro</string>
   <key>CFBundlePackageType</key><string>APPL</string>
   <key>CFBundleShortVersionString</key><string>${VERSION:-dev}</string>
   <key>LSMinimumSystemVersion</key><string>14.0</string>
   <key>TestedLogicBuild</key><string>$tested_logic_build</string>
</dict>
</plist>
EOF
codesign -s - -f "$app"
