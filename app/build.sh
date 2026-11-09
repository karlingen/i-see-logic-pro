#!/bin/sh
# Builds "I See Logic Pro.app" beside this script, with the theme library inside.
# Run it again after a Logic Pro update.
cd "$(dirname "$0")" || exit 1
../theme/build.sh || exit 1
app='I See Logic Pro.app'
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -parse-as-library -O -target arm64-apple-macos14 -o "$app/Contents/MacOS/ISeeLogicPro" ISeeLogicPro.swift || exit 1
cp ../theme/light-theme.dylib "$app/Contents/Resources/"
logic_build=$(defaults read '/Applications/Logic Pro.app/Contents/Info' CFBundleVersion) || exit 1
# CFBundleIdentifier must match SETTINGS_DOMAIN in light-theme.m. The app compares
# LogicBuildVersion with the installed Logic Pro to find an update after this build.
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>CFBundleExecutable</key><string>ISeeLogicPro</string>
   <key>CFBundleIdentifier</key><string>io.github.karlingen.i-see-logic-pro</string>
   <key>CFBundleName</key><string>I See Logic Pro</string>
   <key>CFBundlePackageType</key><string>APPL</string>
   <key>CFBundleShortVersionString</key><string>1.0</string>
   <key>LSMinimumSystemVersion</key><string>14.0</string>
   <key>LogicBuildVersion</key><string>$logic_build</string>
</dict>
</plist>
EOF
codesign -s - -f "$app"
