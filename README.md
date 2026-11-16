# Captive

Internal macOS reconstruction of Captive's first two bases, written in Meh with fresh
AppKit/CoreGraphics and AVAudioEngine bridges. Targets macOS 15 or newer on the
current Mac architecture. It uses the recovered seed-0000 and seed-0001 bases.
Licence undecided; this is not a public release.

Original installation files belong under `reference/Captive/`. They are read-only
inputs and are excluded from Git. All extracted original data and build output
belong under `.build/`; neither original assets nor binaries are committed.

## Development

Install a current `mehc` compiler, Xcode command-line tools and Go for the local
inspection tools. Check `mehc --version`; development began with the installed
v0.76.0 compiler. `mehc build` compiles both the Meh code and native bridges;
no prebuilt native archive is required. The project selects a small C compiler
wrapper to enable ARC for Objective-C sources. The RNC
extractor explicitly selects LLVM for a current direct-backend limitation.

```sh
./tools/extract-originals.sh
./tools/inspect-assets.sh
MEH_BACKEND=llvm mehc build audio-export.meh -o .build/audio-export -F
.build/audio-export build/extracted/federation build/extracted/Fed_Sounds .build/data/audio
mehc build
./captive
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
development executable uses `saves/` beside the project executable. Neither location is tracked.
`tools/build-game.sh` builds the static executable at `.build/captive` used by
packaging. `tools/test-build.sh` checks a clean source copy with an empty cache
and no native archive, including builds invoked from another directory.

The action-driven acceptance replay generates its transcript from the recovered
base and checks disk continuation during combat:

```sh
mehc build base-playthrough.meh -o .build/base-playthrough -F
.build/base-playthrough --campaign
.build/Captive.app/Contents/MacOS/captive --replay .build/campaign-playthrough.tsv \
  --saves /tmp/captive-replay
```

## Controls

W/S move forward/back, A/D strafe and Q/E turn by a quarter turn. Click the view
or Interact for world objects, and click a droid's hands to use equipment.
F1–F4 open inventories, F5/F9 quicksave/load and Escape pauses in a normal window.
Control-Command-F or the toolbar toggles fullscreen; Escape leaves fullscreen.
Close the window, press Command-Q or choose Quit Captive to quit, including
while editing. The toolbar offers
manual save/load, the entry checkpoint, original artwork and fullscreen.
Hover controls for details; the droid panels remain visible during play.

Both the app and standalone executable find their data independently of the
working directory; no command arguments are needed for normal play.
The party starts as Rook, Bishop, Knight and Pawn without startup dialogs.
Double-click a droid's name to edit it inline; Enter saves, Escape cancels and
Command-A selects all. Names use 1–19 letters or digits. Computer passwords
also use an inline field. Simulation and audio pause while typing.

After escaping the first base, use the Swan's **Travel to Base 2** action (or
Enter). The probe reveals the route and is consumed; your party, formation,
condition, skills, equipment and credits carry over. Travel creates a fresh
entry checkpoint for that base; CHECKPOINT always restores the current base's
entry. This is a direct Swan transfer; free Holamap flight and
planetary surface exploration remain future work.

The second base has two floors. Stand on a ladder and press Space to climb.
Punch the appropriate doors with a hand and operate wall panels to toggle
their linked doors. Brains drops the second computer's password clipboard.
The original second-base catalogue includes blade weapons; armour upgrades
and other unsupported equipment remain unavailable. Existing first-base saves
continue to load.

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
