# Captive

Internal macOS reconstruction of Captive's first base, written in Meh with fresh
AppKit/CoreGraphics and AVAudioEngine bridges. Targets macOS 15 or newer on the
current Mac architecture. It uses the recovered seed-0000 base rather than a
newly designed level. Licence undecided; this is not a public release.

Original installation files belong under `reference/Captive/`. They are read-only
inputs and are excluded from Git. All extracted original data and build output
belong under `.build/`; neither original assets nor binaries are committed.

## Development

Install a current `mehc` compiler, Xcode command-line tools and Go for the local
inspection tools. Check `mehc --version`; development began with the installed
v0.76.0 compiler. The build script uses its default backend and builds the fresh
native bridge before linking the statically embedded Meh libraries. The RNC
extractor explicitly selects LLVM for a current direct-backend limitation.

```sh
./tools/extract-originals.sh
./tools/inspect-assets.sh
MEH_BACKEND=llvm mehc build audio-export.meh -o .build/audio-export -F
.build/audio-export build/extracted/federation build/extracted/Fed_Sounds .build/data/audio
./tools/build-game.sh
./.build/captive
```

The map, fixture, trap, shop and encounter exports under `.build/recovery/` are
also required. They are already present in this working copy. To reproduce them,
see [recovery.md](docs/recovery.md), including the original DOS MapGen inspection
and tested export tools. Do not substitute an invented map when these files are
missing. Original graphics comparison crops are prepared by the packaging script.

```sh
./tools/test.sh
./tools/package-macos.sh
open .build/Captive.app
```

The app includes its required local assets. Manual saves, quicksaves and its
separate base-entry checkpoint live in Application Support when packaged; the
development executable uses `saves/`. Neither location is tracked.

The action-driven acceptance replay generates its transcript from the recovered
base and checks disk continuation during combat:

```sh
mehc build base-playthrough.meh -o .build/base-playthrough -F
.build/base-playthrough
.build/Captive.app/Contents/MacOS/captive --replay .build/base-playthrough.tsv \
  --saves /tmp/captive-replay
```

## Controls

W/S move forward/back, A/D strafe and Q/E turn by a quarter turn. Click the view
or Interact for world objects, and click a droid's hands to use equipment.
F1–F4 open inventories, F5/F9 quicksave/load and Escape pauses. The toolbar offers
manual save/load, the entry checkpoint, original artwork and fullscreen.
Hover controls for details; the droid panels remain visible during play.

Runtime artwork is 1024×1024 with sprite transparency preserved. The first base
uses cream entry panels, dark reactor metal and green service hatches across
its three recovered sectors. Material sets are configurable for later bases.

The simulation advances at fixed ticks independently of rendering. Saves preserve
party, world, random state and active timers, and replace existing files atomically.
Invalid saves are decoded separately and cannot replace the active session.

The real topology, placements, shop offers and binary rules are distinguished
from provisional combat and scheduler tuning in [recovery.md](docs/recovery.md).
See [presentation.md](docs/presentation.md) for rendering and original-art
comparison details, [TODO.md](TODO.md) for remaining work and
[NOTICES.md](NOTICES.md) for source and original-data boundaries.
