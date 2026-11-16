# Native macOS bridge

`native/captive_native.m` is a fresh implementation using AppKit, CoreGraphics,
ImageIO and AVAudioEngine. It contains no gameplay or original-game data and does
not derive from Pinball. It targets macOS 15 and newer.

Build with the installed Xcode command-line tools:

```sh
./tools/build-native.sh
./tools/build-native.sh --smoke
```

The first command creates `.build/native/libcaptive_native.a` for the isolated
native test. The game build compiles these sources itself. The second command also
links and runs a short window and silent audio lifecycle check. The run needs
access to the logged-in macOS window and audio services. Tests check key input,
letterboxed mouse coordinates at 1280×800 through offscreen 4K sizes, event
overflow, image crop orientation and PNG
capture pixels, unsigned 8-bit WAV caching, invalid PCM, eight-voice limits,
pause, clearing and replay, and window closure. This does not verify final
artwork, audible sound fidelity, fullscreen animation or an actual game session.

## C interface

All calls in `native/captive_native.h` run on the process's main thread. Retain
the opaque host pointer returned by `captive_host_create`, pump AppKit events
regularly with `captive_host_pump`, then drain `captive_host_event`. Destroy the
host exactly once. A false pump result indicates a closed window. Event fields
are `kind`, `code`, `x`, `y`, `repeat`; the C layout is 32 bytes on arm64, with
double coordinates at byte offsets 8 and 16. Unknown keys have code zero.

Events distinguish key down/up, mouse down/up, close, focus loss and mouse movement.
Consecutive mouse movements coalesce. On focus
loss, clear held controls. The 128-event queue drops stale input on overflow and
inserts a focus-loss event before fresh input. W/S/A/D/Q/E, Escape, F1–F4, F5,
F9, Enter and Space have stable bridge codes. Command-Q closes the host window.
Fullscreen is an explicit call so gameplay can choose its binding.

Frames use a 1280×800 canvas with a top-left origin. The view uniformly scales
and centres that canvas, clipping to its bounds and filling unused margins with
black. Mouse coordinates use the same transform. Drawing consists of a complete
begin/rect/text/image/submit sequence; AppKit retains the submitted frame for
expose and resize redraws. RGBA colours are packed as `0xRRGGBBAA`. Text stays
separate from bitmap artwork. ImageIO loads images once; integer image handles
belong to the host until destruction. A frame accepts up to 8192 commands and a
host up to 1024 images. The renderer ignores invalid numeric coordinates.
Image crops take a normalised top-left source rectangle. Frame capture writes
a 1280×800 PNG from the retained view, without screen-recording permission.
Images up to 320×200 use nearest-neighbour sampling to preserve original pixels;
larger remastered images use high-quality interpolation.

Audio accepts copied, finite mono float samples in [-1,1], at 8–96 kHz, from one
frame through ten seconds. Gain is [0,1]. Each of eight player nodes reserves
one eighth of full scale to bound simultaneous mixing. A ninth active effect
is rejected. Pause freezes the engine and rejects new effects; clear stops
scheduled effects. Generation counters prevent old completion callbacks from
stopping a reused voice. Host destruction clears effects and stops the engine.
Up to 128 mono sound files can be decoded and cached through AVAudioFile, including
the extracted unsigned 8-bit 22050 Hz WAV effects. File samples have the same
duration and sample-rate limits as direct PCM.

Image or audio failures set `captive_host_error` and log an error. The returned
UTF-8 error pointer remains valid until the next error or host destruction.
Invalid arguments and voice exhaustion return false. Audio framework exceptions
are converted to errors so an unavailable audio device does not crash gameplay.

The Meh executable links the compiled bridge plus the AppKit,
AVFoundation and ImageIO frameworks. The bridge does not advance simulation
time, manage saves, choose a base layout or add unrestricted navigation aids.

## Meh adapter

`src/host/host.meh` exposes `host.Window` with an explicit `Close` operation.
Its Objective-C adapter uses integer handles and scalar event accessors. The
`PlayPCM` method borrows a Meh byte list during the call, converts signed 8-bit
PCM to float and copies it into native-owned storage. `LoadSound`/`PlaySound`
and the cached `PlayWAV` convenience accept the extracted WAV files directly.
`ResourcePath` returns the app bundle's Resources directory, or an empty string
for a standalone executable. `Prompt` opens a native text prompt and returns an
empty string on cancellation. `MouseX`/`MouseY` support hover tooltips.

The current compiler's `@impl objc` compilation does not enable ARC. The root
`mehkfile` selects `tools/compile-native.sh` through `CC`; it enables ARC for
Objective-C inputs and preserves a caller-selected C compiler through
`CAPTIVE_NATIVE_CC`. The native implementation is declared by `main.meh` and
compiled alongside its adapter. No prebuilt archive or preliminary script is
required. The plan resolves its entry source to an absolute path to avoid the
compiler's duplicated relative native-asset path. Plain `mehc build` works from
the project directory. The game's `--smoke` mode exercises the Meh adapter with
real artwork. No special Pinball flags are required.

`tools/build-game.sh` runs the complete static Meh project build using the
compiler's default backend, then places the app executable at `.build/captive`.
Use the project plan so the native compiler is configured. The build cache defaults
to ignored `.build/meh-cache`; an existing `MEH_CACHE_DIR` setting takes precedence.
