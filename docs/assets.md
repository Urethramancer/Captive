# Original asset inspection

The supplied Amiga payloads remain in read-only `reference/Captive/Fed1`.
All unpacked payloads and inspection output belong in ignored build directories.
No original artwork or sound is committed.

The Meh inspection module is fresh code. `assets-inspect.meh` accepts decoded
payloads; it does not silently decompress or guess their format.

```sh
tools/inspect-assets.sh
mehc test assets_test.meh
mehc build assets-inspect.meh -o .build/assets-inspect
.build/assets-inspect planar build/extracted/Fed2-A.pic .build/doors-grey.ppm
.build/assets-inspect svx build/extracted/Fed_Sounds .build/sounds.wav
```

The supplied `Fed2-A.pic` is 40,000 bytes: five consecutive 8,000-byte
bitplanes, each holding 200 rows of 40 bytes. Bit 7 is the leftmost pixel
and the first plane supplies the least significant colour-index bit.
A diagnostic conversion was inspected visually and shows recognisable doors,
switches and terminals. The converter produces 320×200 PPM images. Without
an explicit 96-byte RGB palette, it uses **diagnostic grey**, not recovered
original colours. Pass `PALETTE.rgb` as the fourth argument to select a
verified 32-colour palette. The supplied `federation` contains the default palette at file offset
`0x644` (32 big-endian `0RGB` words), followed by the active palette buffer
at `0x684`. Code at `0x6c8` copies that buffer to Amiga colour registers
`0xdff180` onwards. `tools/inspect-assets.sh` extracts this local table,
expands each nibble to 8-bit RGB, and converts all standalone sheets with it.
The resulting `Fed4.pic` image was inspected: panel shapes and droid colour
stripes align. The table applies to this supplied binary; animations and
scene palette changes still require runtime verification.

`Fed_Sounds` decodes to IFF `FORM/8SVX`: its VHDR declares 5593 Hz,
uncompressed mono, and its BODY begins at offset 104 with 52,100 signed
8-bit samples. The converter validates FORM bounds, chunk lengths, padding,
VHDR/BODY presence, compression and channel mode, then writes unsigned 8-bit
mono PCM WAV without changing the declared sampling rate. This is the whole
sample bank for inspection, not individual effects at their game pitches.

The [disk directory documentation](https://captive.atari.org/Technical/Directory/Directory.php)
identifies the sheet families; its sizes describe the Atari release and must
not be applied to these larger Amiga sheets. The
[sound documentation](https://captive.atari.org/Technical/Sounds/Sounds.php)
provides a useful effect index. The Amiga effect offsets, lengths and replay
periods still require verification against the supplied executable before
being used in gameplay.

Tests cover plane and row ordering, malformed dimensions and truncation,
odd IFF chunk padding, corrupt and compressed 8SVX rejection, native rate
preservation, and signed-to-unsigned PCM conversion including WAV padding.
