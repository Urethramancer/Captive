#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/extracted
MEH_BACKEND=llvm mehc build rnc-extract.meh -o build/rnc-extract -F
count=0
for input in reference/Captive/Fed1/*; do
	if [[ "$(xxd -p -l 4 "$input")" == 524e4301 ]]; then
		build/rnc-extract "$input" "build/extracted/$(basename "$input")"
		count=$((count + 1))
	fi
done
printf 'Extracted %s original RNC1 resources.\n' "$count"
