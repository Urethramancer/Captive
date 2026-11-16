#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/native
xcrun clang -std=c11 -fobjc-arc -Wall -Wextra -Werror -mmacosx-version-min=15.0 \
	-c native/captive_native.m -o .build/native/captive_native.o
xcrun ar rcs .build/native/libcaptive_native.a .build/native/captive_native.o
if [[ "${1:-}" == "--smoke" ]]; then
	xcrun clang -std=c11 -fobjc-arc -Wall -Wextra -Werror -mmacosx-version-min=15.0 \
		native/tests/smoke.m .build/native/libcaptive_native.a \
		-framework AppKit -framework AVFoundation -framework ImageIO \
		-o .build/native/native-smoke
	.build/native/native-smoke
	xcrun clang -std=c11 -fobjc-arc -Wall -Wextra -Werror -mmacosx-version-min=15.0 \
		native/tests/lifecycle.m .build/native/libcaptive_native.a \
		-framework AppKit -framework AVFoundation -framework ImageIO \
		-o .build/native/native-lifecycle
	for action in close quit fullscreen; do
		.build/native/native-lifecycle "$action"
	done
fi
