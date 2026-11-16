#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export MEH_CACHE_DIR="${MEH_CACHE_DIR:-$PWD/.build/meh-cache}"
export GOCACHE="${GOCACHE:-$PWD/.build/go-cache}"
for suite in rnc_test.meh assets_test.meh audio_test.meh tests/session*_test.meh persistence_test.meh; do
	if [[ "$suite" == rnc_test.meh ]]; then
		# The installed direct backend rejects the decoder's error-valued field.
		MEH_BACKEND=llvm mehc test "$suite"
	else
		mehc test "$suite"
	fi
done
GO111MODULE=off go test ./tools/mapgen-export ./tools/main-export
