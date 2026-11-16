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
actions=(window quit)
if [[ "${1:-}" == --campaign ]]; then
	test -f "$root/.build/first-base-complete.captive"
	actions+=(travel)
fi
for action in "${actions[@]}"; do
	rm -rf "$scratch/saves"
	if [[ "$action" == travel ]]; then
		mkdir -p "$scratch/saves"
		cp "$root/.build/first-base-complete.captive" "$scratch/saves/quick.captive"
	fi
	CAPTIVE_TEST_CLOSE="$action" DYLD_INSERT_LIBRARIES="$root/.build/native/launch-check.dylib" "$scratch/captive"
	# A normal launch must initialise, edit inline, save and exit without arguments.
	test -f "$scratch/saves/base-0-entry.captive"
	test -f "$scratch/saves/quick.captive"
	if [[ "$action" == travel ]]; then
		ruby -rjson - "$scratch/saves" "$root/.build/first-base-complete.captive" <<'RUBY'
def state(path)
	JSON.parse(File.read(path).split("\n",3).last)
end
directory, departure = ARGV
first = state("#{directory}/base-0-entry.captive")
second = state("#{directory}/base-1-entry.captive")
moved = state("#{directory}/before-checkpoint.captive")
restored = state("#{directory}/quick.captive")
raise 'first checkpoint changed base' unless first['base'] == 0
raise 'travel lost party condition' unless second['droids'].map{|d| d['parts']} == state(departure)['droids'].map{|d| d['parts']}
raise 'travel did not enter second base' unless second['base'] == 1 && second['x'] == 12 && second['y'] == 0
raise "movement input did not leave the entry: #{moved.values_at('base','x','y','facing','paused','moveTimer').inspect}" unless moved['base'] == 1 && moved['x'] == 13
raise 'checkpoint restored the wrong base or position' unless restored['base'] == 1 && restored['x'] == 12 && restored['y'] == 0
RUBY
	else
		ruby -rjson -e 's=JSON.parse(File.read(ARGV[0]).split("\n",3).last); raise "inline name was not saved" unless s["droids"][0]["name"]=="Zed"' "$scratch/saves/quick.captive"
	fi
done
printf 'Zero-argument launch, inline rename/save, close and Command-Q passed.\n'
if [[ "${1:-}" == --campaign ]]; then
	printf 'Swan travel, party condition and per-base checkpoint restore passed.\n'
fi
