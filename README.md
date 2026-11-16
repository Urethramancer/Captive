# Captive

Internal macOS reconstruction of Captive's first base, written in Meh with fresh
native AppKit/CoreGraphics and AVAudioEngine bridges. The target is macOS 15 or
newer on the current Mac architecture. The first-base recovery is in progress;
there is no playable remaster yet.

Original installation files belong under `reference/Captive/`. They are read-only
inputs and are excluded from Git. All extracted original data and build output
belong under `.build/`; neither original assets nor binaries are committed.

## Development

Install a current `mehc` compiler and Xcode command-line tools. Build and test
commands will be added alongside the tools they exercise. The installed compiler
can be checked with `mehc --version`.

The approved implementation sequence is project setup, verified first-base
recovery, headless gameplay, native presentation, then saves and app packaging.
Recovery must establish the real base before substantial gameplay implementation.
See [TODO.md](TODO.md) for outstanding work and [NOTICES.md](NOTICES.md) for source
and original-data boundaries.
