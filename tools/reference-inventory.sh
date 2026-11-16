#!/bin/bash
# Record local evidence without modifying the supplied installation.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -d reference/Captive/Fed1 ]]; then
	printf '%s\n' 'Missing original installation: reference/Captive/Fed1' >&2
	exit 1
fi
mkdir -p .build/evidence
manifest=$(mktemp .build/evidence/inventory.XXXXXX)
trap 'rm -f "$manifest"' EXIT
while IFS= read -r -d '' source; do
	shasum -a 256 "$source" >> "$manifest"
done < <(find reference -type f -print0 | sort -z)
mv "$manifest" .build/evidence/reference.sha256
find reference -type f -exec file {} + > .build/evidence/reference-types.txt
printf '%s\n' 'Recorded original-file hashes and types in .build/evidence/'
