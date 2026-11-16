# Captive: first playable macOS remaster

## Summary

Build a playable reconstruction of the original first base, from its entrance through probe recovery, sabotage and escape. Retain four-droid management, real-time combat, grid movement and quarter turns.

Use Meh and native macOS presentation, following Pinball’s architecture. Its GPL code will not be copied or adapted. Keep the project internal and its licence undecided, choosing dependencies compatible with a possible future MIT release.

## Implementation stages

1. **Establish the project**
   - Initialise Git with `reference/` ignored before the first commit. Also exclude extracted original assets, saves, caches, binaries and app bundles.
   - Add concise build instructions, source notices and a root TODO for deferred campaign work.
   - Keep Pinball unchanged. Write fresh AppKit/CoreGraphics and AVAudioEngine bridges; exclude its gameplay, artwork and GPL-derived code.

2. **Recover the first base**
   - Implement a bounded RNC method-1 decoder in Meh, using [Ancient’s BSD-licensed implementation](https://github.com/temisu/ancient/blob/master/src/RNCDecompressor.cpp) as a reference and preserving applicable notices.
   - Decode the supplied graphics and sounds for inspection. Recover the first base’s layout, encounters, objects and puzzle dependencies from the supplied binaries, checked against the [map-generator documentation](https://captive.atari.org/Technical/MapGen/Introduction.php) and original manual.
   - Store original-derived extraction output in ignored local build data. Keep `reference/` read-only.
   - Establish the base layout before substantial gameplay work. Report unrecoverable requirements explicitly; do not substitute an invented base.

3. **Implement the complete base loop**
   - Separate asset loading, gameplay, presentation, audio and persistence into small modules.
   - Keep gameplay independent of rendering: a headless session receives actions and fixed simulation ticks, then supplies presentation state and sound events.
   - Implement droid initialisation, formation and leadership; body-part condition, energy, inventory, equipment and skills; combat, ammunition and loot; shops, repairs and charging.
   - Implement the first base’s actual doors, switches, movable walls, vertical connections, hazards and puzzles, plus probe recovery, generator sabotage and escape.
   - Support equipment available in this base with working behaviour. Defer the wider campaign, space travel and later equipment.
   - Preserve verified rules. Record uncertain numerical values and timings as provisional tuning rather than presenting them as exact reproductions.

4. **Create the remastered presentation**
   - Use layered HD corridor illustrations and sprites, preserving the original perspective and occlusion.
   - Establish one consistent visual kit before producing the full asset set: corridor, door, terminal, robot, enemy and equipment.
   - Follow the described future imagined through television and typewriters: CRTs, physical switches, heavy connectors, moulded cases and peculiar machinery. Improve clarity without erasing that character.
   - Retain the briefcase-computer identity, with a large viewport, four visible droid status panels and accessible hand actions. Render text separately from artwork.
   - Support resizable windows and fullscreen, with readable controls from 1280×800 through 4K. Preserve viewport proportions.
   - Provide an original-art comparison mode and use decoded original sound effects initially.

5. **Add conveniences and package**
   - Include tooltips, visible bindings, pause, manual saves, quicksave/quickload and a separate base-entry checkpoint.
   - Default movement: W/S forward/back, A/D strafe, Q/E turn. Use mouse interaction for world objects and hands, F1–F4 for inventories, F5/F9 for quicksave/load and Escape for pause.
   - Preserve equipment-gated navigation aids; add no unrestricted automap.
   - Save complete session state, including random state and active timers, using atomic writes.
   - Package an internal macOS app with its required local assets. Use current compiler-supported options rather than copying Pinball’s build flags.

## Verification and acceptance

- Test decompression checksums, truncation, invalid references and corrupt input.
- Verify recovered base topology and progression dependencies against original evidence.
- Test movement, formation-dependent combat, resource consumption, equipment transactions, puzzles and sabotage/escape behaviour independently of the GUI.
- Verify deterministic save/load continuation and pause behaviour; corrupt saves must leave the current session intact.
- Check artwork alignment, interaction coordinates, readable scaling and audio lifecycle.
- Complete the entire base in the packaged app, including saving and resuming midway.

Build and run relevant tests before committing each completed stage.

## Assumptions

- Initial target: the current Mac architecture, macOS 15 or newer.
- New code remains separately identified from original game data and remastered artwork; no blanket MIT declaration.
- No publishing, release tags or version numbers are introduced.
- The first base is the acceptance milestone; campaign generation and travel remain subsequent work.
