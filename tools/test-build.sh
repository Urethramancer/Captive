#!/bin/bash
# Check the public build command without prebuilt native objects or a warm cache.
set -euo pipefail
cd "$(dirname "$0")/.."
project_root=$PWD
checkout=$(mktemp -d "${TMPDIR:-/tmp}/captive-build.XXXXXX")
trap 'rm -rf "$checkout"' EXIT
git ls-files -z -- '*.meh' '*.m' '*.h' mehkfile tools/compile-native.sh |
	tar --null -T - -cf - | tar -xf - -C "$checkout"
# Include the new wrapper when testing an uncommitted working tree.
mkdir -p "$checkout/tools"
cp tools/compile-native.sh "$checkout/tools/compile-native.sh"
(
	cd "$checkout"
	MEH_CACHE_DIR="$checkout/.build/cache" mehc build
	test -x captive
	test ! -e .build/native/libcaptive_native.a
)
# The same plan must also resolve relative/native paths from another directory.
cd "$project_root"
MEH_CACHE_DIR="$checkout/.build/cache" mehc build "$checkout"
