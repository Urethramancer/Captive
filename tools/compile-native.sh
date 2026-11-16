#!/bin/bash
# mehc compiles Objective-C implementations without selecting ARC itself.
set -euo pipefail
run_compiler()
{
	if [[ -n "${CAPTIVE_NATIVE_CC:-}" ]]; then
		exec "$CAPTIVE_NATIVE_CC" "$@"
	fi
	exec xcrun clang "$@"
}
for argument in "$@"; do
	case "$argument" in
		*.m|*.mm) run_compiler -fobjc-arc "$@" ;;
	esac
done
run_compiler "$@"
