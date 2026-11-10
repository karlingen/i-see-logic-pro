#!/bin/sh
# Builds "I See Logic Pro.app" beside this script, with the theme library inside.
# VERSION sets the app version, for example VERSION=1.0.0 app/build.sh.
cd "$(dirname "$0")" || exit 1
../theme/build.sh || exit 1
app='I See Logic Pro.app'
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -parse-as-library -O -target arm64-apple-macos14 -import-objc-header ../theme/gray-rule.h \
   -o "$app/Contents/MacOS/ISeeLogicPro" ISeeLogicPro.swift || exit 1
cp ../theme/light-theme.dylib "$app/Contents/Resources/"
# Draws the icon at 1024 points and scales it to each icon size.
work=$(mktemp -d) || exit 1
swiftc -O -o "$work/app-icon" AppIcon.swift && "$work/app-icon" "$work/icon.png" || exit 1
mkdir "$work/AppIcon.iconset"
for size in 16 32 128 256 512; do
   sips -z $size $size "$work/icon.png" --out "$work/AppIcon.iconset/icon_${size}x${size}.png" > /dev/null
   sips -z $((size * 2)) $((size * 2)) "$work/icon.png" --out "$work/AppIcon.iconset/icon_${size}x${size}@2x.png" > /dev/null
done
iconutil -c icns "$work/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns" || exit 1
rm -r "$work"
# The Logic Pro build that this version was tested with. The app shows a warning for
# other builds, because the theme uses internal names that an update can change.
tested_logic_build=7801
# The bundle identifier is the preferences domain that the theme reads.
domain=$(sed -n 's/^#define SETTINGS_DOMAIN_NAME "\(.*\)"$/\1/p' ../theme/gray-rule.h)
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>CFBundleExecutable</key><string>ISeeLogicPro</string>
   <key>CFBundleIconFile</key><string>AppIcon</string>
   <key>CFBundleIdentifier</key><string>$domain</string>
   <key>CFBundleName</key><string>I See Logic Pro</string>
   <key>CFBundlePackageType</key><string>APPL</string>
   <key>CFBundleShortVersionString</key><string>${VERSION:-dev}</string>
   <key>LSMinimumSystemVersion</key><string>14.0</string>
   <key>TestedLogicBuild</key><string>$tested_logic_build</string>
</dict>
</plist>
EOF
codesign -s - -f "$app" || exit 1
# Finder keeps the icon that it read while the bundle was incomplete, until the bundle date changes.
touch "$app"
