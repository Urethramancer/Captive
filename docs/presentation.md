# macOS presentation and local packaging

`main.meh` connects the headless session to the fresh AppKit bridge.
`src/presentation` owns the 1280×800 layout and view state. A 60 Hz fixed
simulation runs independently of drawing. The native view scales and letterboxes
the complete canvas; hit testing uses the same logical coordinates.

The corridor casts 460 grid rays in HD mode (230 in original-art mode) and retains wall depth for each column.
Wall and door illustrations are projected as texture strips; creature and
fixture billboards use the same depth values for occlusion. This is a new
renderer, not a claim to reproduce the original perspective implementation.
There is no unrestricted map display.

Four droid panels remain visible. Click a name to lead, FRONT/REAR to swap rows,
or right-click that field to swap columns. Click a hand to use it. F1–F4 open
paginated inventories; left/right clicks equip the corresponding hand. Hovering
items shows condition, ammunition and charge. Click a body-part bar facing a
shop to repair it; SELL HELD sells the selected droid's left-hand clipboard.
Facing a power socket and using a hand charges that droid. The displayed combat
skill and unspecified rates remain provisional.

The ART control switches wall, door and supported creature imagery in the
same scene. `tools/original-comparison.swift` decodes and crops local Amiga
sheets with the recovered palette and transparent colour-index zero.
The Brains comparison is explicitly a cross-version exception: it derives a
small pale-character/staff mask from the original Atari encounter screenshot
used by the artwork references. It is stored only in ignored local data.
The original Amiga Brains composite and exact animated palette changes remain
unverified. Comparison mode does not claim pixel-exact original composition.

Manual saves, quicksaves and the separate base-entry checkpoint use the same
validated atomic persistence layer. Starting a fresh party resets its entry
checkpoint while preserving manual and quick saves. Packaged saves live under
`~/Library/Application Support/Captive`; `--saves DIR` overrides that location.

```sh
./tools/package-macos.sh --smoke
.build/Captive.app/Contents/MacOS/captive --replay .build/base-playthrough.tsv \
  --saves /tmp/captive-replay
```

The bounded replay reads the generated `kind/a/b/ticks` transcript, dispatches
actual `session.Action` calls and fixed ticks, and draws every action. Explicit
save/load rows write and read a midway snapshot through the production
persistence layer and verify its complete encoding. It requires probe recovery,
sabotage, escape and a saved continuation before returning success. Midway and
final PNG captures are written beside the replay save. Closing early returns
failure. Replay advances only the transcript's ticks; normal play uses wall time.

Packaging embeds the current architecture's static Meh executable, local base,
fixture and trap exports, generated art, comparison crops and verified original
sound cues. It creates an internal ad-hoc-signed app, with no publishing,
version numbers or release tags.
