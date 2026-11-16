#!/bin/bash
# Convert locally decoded evidence, leaving original files untouched.
set -euo pipefail
cd "$(dirname "$0")/.."
source_dir=${1:-build/extracted}
output_dir=.build/data
mkdir -p "$output_dir"
if [[ ! -f "$source_dir/federation" || ! -f "$source_dir/Fed_Sounds" ]]; then
	printf '%s\n' 'Decode the original installation first; see README.md.' >&2
	exit 1
fi
mehc build assets-inspect.meh -o .build/assets-inspect -F
# Federation stores the default 32-colour table immediately before its active
# palette buffer. The table is 0x644..0x683 in this supplied Amiga executable.
dd if="$source_dir/federation" of="$output_dir/palette.words" bs=1 skip=1604 count=64 2>/dev/null
.build/assets-inspect palette "$output_dir/palette.words" "$output_dir/palette.rgb"
.build/assets-inspect svx "$source_dir/Fed_Sounds" "$output_dir/sample-bank.wav"
for source in "$source_dir"/*; do
	name=$(basename "$source")
	case "$name" in
		[Ff]ed[2-9]*.pic|[Ff]ed10.pic|FedAnni*.pi)
			.build/assets-inspect planar "$source" "$output_dir/$name.ppm" "$output_dir/palette.rgb"
			;;
	esac
done
printf '%s\n' 'Converted local graphics and sample bank into .build/data/'
