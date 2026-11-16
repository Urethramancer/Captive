#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The project plan builds the native bridge alongside the Meh sources.
MEH_CACHE_DIR="${MEH_CACHE_DIR:-$PWD/.build/meh-cache}" mehc build --static -F "$PWD"
cp captive .build/captive
