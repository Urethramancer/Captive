#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
xcrun clang -std=c11 -fobjc-arc -Wall -Wextra -Werror -dynamiclib \
	-mmacosx-version-min=15.0 native/tests/launch.m -framework AppKit \
	-o .build/native/launch-check.dylib
scratch=$(mktemp -d /tmp/captive-launch.XXXXXX)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/.build" "$scratch/assets"
cp .build/captive "$scratch/captive"
ln -s "$root/.build/recovery" "$scratch/.build/recovery"
ln -s "$root/.build/data" "$scratch/.build/data"
ln -s "$root/assets/remaster" "$scratch/assets/remaster"
cd /tmp
for action in window quit; do
	rm -rf "$scratch/saves"
	CAPTIVE_TEST_CLOSE="$action" DYLD_INSERT_LIBRARIES="$root/.build/native/launch-check.dylib" "$scratch/captive"
	# A normal launch must initialise, edit inline, save and exit without arguments.
	[[ -f "$scratch/saves/base-entry.captive" ]]
	[[ -f "$scratch/saves/quick.captive" ]]
	rg -q 'Zed' "$scratch/saves/quick.captive"
done
printf 'Zero-argument launch, inline rename/save, close and Command-Q passed.\n'
