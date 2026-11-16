#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for required in .build/recovery/base0.tsv .build/recovery/mapgen-seed0.txt .build/recovery/base0-fixtures.tsv .build/recovery/base0-traps.tsv .build/recovery/base0-stock.tsv \
	.build/data/Fed8.pic.ppm .build/data/audio/effect-19.wav \
	assets/remaster/wall.png assets/remaster/door.png assets/remaster/tree.png \
	assets/remaster/scavenger.png assets/remaster/brains.png; do
	if [[ ! -f "$required" ]]; then
		printf 'Missing required local asset: %s\n' "$required" >&2
		exit 1
	fi
done
swift tools/original-comparison.swift
./tools/build-game.sh
app='.build/Captive.app'
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/original/audio" "$app/Contents/Resources/remaster"
cp .build/captive "$app/Contents/MacOS/captive"
cp .build/recovery/base0.tsv .build/recovery/mapgen-seed0.txt .build/recovery/base0-fixtures.tsv .build/recovery/base0-traps.tsv .build/recovery/base0-stock.tsv "$app/Contents/Resources/"
for art in wall door tree scavenger brains generator terminal droid; do
	cp "assets/remaster/$art.png" "$app/Contents/Resources/remaster/"
done
cp .build/data/original-*.png "$app/Contents/Resources/original/"
for id in 19 29 30 32 33 35 38; do
	cp ".build/data/audio/effect-$id.wav" "$app/Contents/Resources/original/audio/"
done
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Captive</string>
<key>CFBundleDisplayName</key><string>Captive</string>
<key>CFBundleExecutable</key><string>captive</string>
<key>CFBundleIdentifier</key><string>org.grimdork.captive.internal</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict></plist>
PLIST
plutil -lint "$app/Contents/Info.plist"
codesign --force --sign - "$app"
printf 'Packaged %s\n' "$app"
if [[ "${1:-}" == '--smoke' ]]; then
	"$app/Contents/MacOS/captive" --smoke
fi
