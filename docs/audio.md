# Original Amiga effects

Build and export the individual effects:

```sh
MEH_BACKEND=llvm mehc build audio-export.meh -o .build/audio-export -F
.build/audio-export build/extracted/federation build/extracted/Fed_Sounds .build/data/audio
MEH_BACKEND=llvm mehc test audio_test.meh
```

Each `effect-N.wav` contains one original effect reconstructed from the
supplied Amiga executable's descriptor, not the complete sample bank.
No audio files are committed.

The decoded `federation` executable has its sound table at file offset
`0xd184`, with eight-byte records and a zero/silent first entry. Runtime IDs
1–52 occupy `0xd18c`–`0xd32b`. Each record is four big-endian words:
absolute byte offset into decoded `Fed_Sounds`, length in Paula DMA words,
Paula period and a packed control word. The latter is retained in the
original binary but its control/priority bits are not yet modelled.

Code at file offset `0xd3aa` is `LEA -552(PC),A0`, pointing to `0xd184`;
`ASL.W #3,D0` then indexes the eight-byte records. Nearby code copies the
second word into the audio length and the third into the period. Thus the
metadata is recovered from the Amiga binary, rather than copied from the
Atari table. For example, automatic fire uses offset 104, length 1354 words
(2708 bytes), period 514. Some lengths intentionally differ from the Atari
list; Amiga DMA rounds lengths to words and some entries also have different
ranges. The exporter checks this release's reference/index opcodes before
using its table and bounds every sample against the supplied bank.

[The sound documentation](https://captive.atari.org/Technical/Sounds/Sounds.php)
identifies the shared sample categories, pitch reuse and individual effects.
Its sorted IDs and pitch values describe the Atari release and are not the
Amiga runtime IDs below. The mapping uses each recovered sample offset and
its position in the corresponding family; multiple pitch variants share PCM.

| Amiga ID | Effect |
| --- | --- |
| 1 | Automatic fire |
| 2 | Reload |
| 3–14 | Elevator pitch variants |
| 15 | Laser shot |
| 16 | Spraygun |
| 17, 24 | Metallic hit variants |
| 18 | Wall hit |
| 19 | Door |
| 20 | Bouncing ball |
| 21–23 | Handgun, rifle, cannon |
| 25 | Moving raiser wall |
| 26–27 | Iris door, laser door |
| 28 | Raiser wall impact |
| 29 | Tick |
| 30 | Droid damage |
| 31 | Electric bolt |
| 32 | Brawling/sword |
| 33 | Gold |
| 34–35 | Fire damage, bump damage |
| 36 | Metallic door impact |
| 37 | Chest |
| 38–45 | Explosion pitch variants |
| 46–47 | Dragon/Diplocus, Tyrana/Dog |
| 48 | Minor/Guard/Tripos |
| 49 | Pod fire |
| 50–51 | Fire/Terradak, Tree/Lizard |
| 52 | Critter |

Output uses 22050 Hz signed sample reconstruction with linear interpolation
before conversion to unsigned eight-bit RIFF PCM. Duration derives from
sample count and period, using a nominal PAL Paula clock of 3546895 Hz;
clock selection is a presentation assumption, not an assertion of identical
playback on every original machine. Original random pitch variation and
sound priority interruption are deferred until simulation events drive them.

Validation: the audio suite passes 215 checks over the actual supplied bank,
covering all 52 descriptors, first sample polarity, output rate and duration,
unsupported executable markers and out-of-bounds sample references.
