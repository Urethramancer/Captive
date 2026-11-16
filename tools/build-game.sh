#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./tools/build-native.sh
# Build the declared project: direct source-file builds omit its archive links.
# Absolute input also avoids the current nested @impl relative-path issue.
MEH_CACHE_DIR="${MEH_CACHE_DIR:-$PWD/.build/meh-cache}" MEH_BACKEND=llvm mehc build --static -F "$PWD"
cp captive .build/captive
