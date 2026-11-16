# First-base recovery

Recovered 16 November 2026. Original-derived output belongs in ignored local build data, never in Git. `reference/` was read without modification.

The supplied Amiga `fed_MapGen` is a generator executable, not a stored first-level map. Its RNC header declares 29,448 unpacked bytes. Decoded SHA-256: `02807b28e52ce384ceb9059d279e14fa1153bdfcabd75f95d6750a95d40ca276`.

## Independent original map export

The [official MapGen guide](https://www.mocagh.org/mindscape/captive-hintbook.pdf), pp. 1–3, identifies the first base as seed **0000**, describes map/object/switch export, and states that MapGen uses the game's generator across the Amiga, ST and PC versions. This is an inspection oracle; its code is not incorporated into Captive.

Downloaded [original DOS MapGen](https://captive.atari.org/Miscellaneous/Tools/MapGen.zip), whose `MAPGEN.EXE` SHA-256 is `6bcf34752108c6cd79f10fbdabd1b00a95786f6249fe1da4cc8f1e379536bde5`. Ran this executable in QEMU's i386 interpreter under FreeDOS 1.4 with CuteMouse. Select Mission 0001, Level 00, Seed 0000, Full Base, all three text lists, and Echo Output to Disk. Page through each text screen to finish `MAPGEN.TXT`; MapGen also writes `MAP-0000.LBM`.

For the observed process, CS was `2394` and DS was `275b`. These are relocation-dependent, not fixed interfaces. Saved physical memory using QEMU monitor `pmemsave 0 0x100000 "/tmp/captive-generated-memory.bin"` after generation. Inspection of the original DOS renderer establishes these DS-relative arrays:

| Offset | Representation |
| --- | --- |
| `1428` | 2,048 little-endian terrain/generation words |
| `2438` | 2,048 little-endian object/feature words |
| `3448` | 2,048 little-endian root-path/detail words |
| `1410`, `1412` | Starting x and y, respectively |
| `4992` | Generated display text, 32 rows of a row label, 64 encoded glyphs and newline |

All offsets above are hexadecimal. Index each cell as `y * 64 + x`; east increases x and south increases y. `.build/recovery/base0.tsv` records all three raw words for every coordinate. Do not interpret the terrain words as general floor-type identifiers: positive values are digger sequence numbers; negative values also encode occupied/special locations.

Other local evidence: `.build/recovery/mapgen-seed0.txt`, `mapgen-seed0.lbm` and `mapgen-legend.png`. The first TSV SHA-256 is `5c12ee6936e588ce85fbca96a57552e60fad569283fb7589f373b00e1de6e5bc`.

## Verified first-base facts

The exported map starts at decimal **(30, 1)**, with the entrance at **(30, 0)**. This matches the decoded Amiga executable's special first-base routine near code offset `7270`: it tests the base number, sets d2=1 and d1=30, then creates explosives (item `1b`) and a Ratt message (`66`). Code offsets exclude the 32-byte Amiga hunk header.

The [floor-layout investigation](https://captive.atari.org/Technical/MapGen/FloorSections.php) confirms that the first base is specially arranged into sections 2, 6 and 10 on one floor. The recovered footprint agrees. Generic map-generation descriptions are insufficient to reconstruct these exceptions by guesswork.

The raw object low byte identifies these features (an enemy-presence bit `80` may overlay it):

| ID | Meaning | Decimal coordinates |
| --- | --- | --- |
| `09` | Nine generators | x=18..20, y=9..11 |
| `0e` | Pushable wall | (30,3), (22,4), (30,11) |
| `12` | Shop | (24,2), (19,15), (27,17), (21,19), (24,22), (29,22) |
| `13` | Probe computer | (18,2) |
| `15` | Door | (21,0), (20,2), (25,7), (18,13), (20,13), (16,15), (25,16), (29,19) |
| `2c` | Wall fixture/decor/cupboard | See raw array; high byte retains subtype |

The entrance retains a separate `7e0f` object word. The nine-generator interpretation is supported by the DOS placement routine, which chooses a suitable room and stamps a 3×3 region with ID `09`, and the [generator investigation](https://captive.atari.org/Technical/MapGen/PlacingGenerators.php).

The original text export lists Brains at (19,2), carrying clipboard `0002`; three Zlot weapons at (26,1), (25,14), (28,18); five bags of gold; and explosives plus Ratt's message at (30,1). Enemy group positions, member strength, armour and skill values are retained in the original export. Tree encounters inside this base are genuine generated enemies, not exterior vegetation substituted into the map.

This base has **zero ladders, zero holes, zero fire/water tiles, zero raiser walls, zero mines/grates and zero logic-switch records**. Its obstacles include doors, pushable walls and three traps. Campaign features absent from this base must not be invented as first-base requirements.

The [starting-game guide](https://captive.atari.org/Main/StartGame/StartGame.php) corroborates the entrance combination TL, BL, TR, BR; initial explosives/message; chip initialisation; airlock pushable wall; and using a socket to charge the leader's hand. The [item documentation](https://captive.atari.org/Tools/Items/Items.php) identifies computer passwords as the way to obtain planet probes, and touching a generator while holding explosives as sabotage. Therefore probe recovery is computer interaction, not a fabricated ground pickup.

## Second-base export

The original DOS MapGen was run again for mission 1, level 1 (seed 0001),
with complete map, encounter, object and switch reports. Its map starts at
(12,1), with the entrance at (12,0). The section levels at DS:`13f0` are
`1,2,2,2,6,2,2,6,6,6,6,6,6,6,6,6`; level six denotes unused sections here.
The floor offset tables at DS:`1400` and `1408` give a 16-cell horizontal
offset between the two occupied floors. The paired ladder coordinates are
(8,3)/(24,3) and (2,4)/(18,4). There are four switch-to-door records, six
shops and nine generators. All output remains ignored local inspection data.

The second map TSV SHA-256 is
`fa567ba232b043bced17826b74f0c29dab6f7a62baa0f6b27ccdf0de9796bfc6`;
the complete text report SHA-256 is
`7195cc2c3cac183774eda07e1e3d22f1bb697410ac1fe54f872d0a87d355c10d`.
`mapgen-export -info FILE` preserves the seed, entrance and section levels.
`main-export -seed 1` applies the recovered availability and quality rules,
including the seed-dependent price increment, to produce 198 offers.

## Remaining gameplay verification

The [original English manual](https://captive.atari.org/Main/ReleaseInfo/Manual/CaptiveManualEnglish.pdf) and original MapGen hintbook provide complementary primary evidence. The actual Amiga game has not yet been played through alongside the export. The recovered first-base interactions, equipment and original sabotage structure are implemented; exact numerical reproduction remains a separate fidelity task.

Provisional tuning includes the 60 Hz simulation with six ticks per original sabotage update, AI pacing, damage and shielding, equipment wear, movement and energy conversion, and ordinary equipment repair/resale formulas. Droid name-derived starting values are also provisional. Original topology, generated encounter data, weights, stock gates, purchase prices, quality masks, Ratt resale, endurance display conversion and root directions retain their verified values. The original 100/14 sabotage update counts are preserved without claiming an exact original frequency in seconds.

## Progression and interpretation

The [computer-placement description](https://captive.atari.org/Technical/MapGen/ShopsAndComputers.php) associates each probe computer with a Brains encounter and password clipboard. It also explicitly states that shop stock is managed by the game, outside the generator. Thus the generator export does **not** verify shop inventory or prices.

Original numerical combat stats are retained locally. Translating them into hit points, damage or timing requires the main-game rules rather than assuming equivalence. Verified main-module results and their binary offsets are recorded below.

## Repeating extraction

Use an existing QEMU installation and external FreeDOS/CuteMouse binaries solely for local inspection. Do not check these binaries into Git. A suitable invocation is:

```sh
qemu-system-i386 \
  -drive file=/tmp/captive-fdboot.img,format=raw,if=floppy \
  -drive file=fat:rw:/tmp/captive-mapgen,format=raw \
  -boot a -display none -monitor stdio -m 16
```

Boot to DOS, run `C:`, `CTMOUSE`, then `MAPGEN`. A mouse-driver issue in this environment required debugger injection of menu coordinates and the existing click flag, without changing map generation. In the observed relocated process those fields were CS:`0008` (x word), CS:`000a` (y word), CS:`0017` (click byte). Setting x=320,y=268 and click=`ff` selects Construct. DS:`47cc`=`0170` selects all text reports and echo-to-disk. These process addresses must be rediscovered after each launch.

The extracted TSV SHA-256 is `5c12ee6936e588ce85fbca96a57552e60fad569283fb7589f373b00e1de6e5bc`. The first captured generated memory SHA-256 is `5e3f47d61fd34d1a22584564dc4eaa665fa669715a463a8a4a01563a6d2939de`; full-memory hashes are run-specific. Ignored local evidence resides in `.build/recovery/`, including arrays, text report, LBM map, memory image and a legend screenshot.

## Confirmed main-module details

The decoded Amiga `federation` provides these additional facts (offsets exclude its 32-byte hunk header):

- Probe password code `102d6`–`1034c` uses a 16-bit `n = n * 1509 + 41` generator and four syllable tables. Base zero, computer zero gives **CHAESELUME**. Brains' item `66`/code `0002` is a special Ratt message; `0002` must not be treated as computer index two.
- The door type is the raw object high byte masked with `07`. The animation at `8990`–`8a34` gives type zero automatic closing and leaves type five open. Bit `08` supplies orientation, not open/closed state. These match blue and button doors respectively.
- MapGen's raw wall fixture `2c` high byte is a mask of available wall faces, not a socket subtype. The Amiga converter at `431c` copies it into the runtime map; the click handler at `a0f0` consults a separate registry.
- The DOS fixture registry is found through DS:`4972`, with count DS:`493c`; records are four bytes: x, y, type, extra. Type zero is a power socket; type one a laser terminal; types two through five are decoration. Seed zero has 94 registry records and 19 sockets, including the initial socket at **(29,1)**. `.build/recovery/base0-fixtures.tsv` exports them.
- Raw object `21` maps to runtime cell `2a` via Amiga converter `4388`. It is a shootable blockage/reserved push-wall destination, **not** a cupboard trap. The first push wall at (30,3) reserves (30,4), so a push must accept that reserved destination.

The portable inspection tool can repeat the map and fixture exports without incorporating original code:

```sh
go run tools/mapgen-export/main.go -ds 0x275b \
  -fixtures .build/recovery/base0-fixtures.tsv \
  .build/recovery/mapgen-seed0-memory.bin .build/recovery/base0.tsv
go test tools/mapgen-export/main.go tools/mapgen-export/main_test.go
```

Invalid or truncated memory is rejected before replacing existing exports. The export was compared byte for byte with the first recovered TSV.

Cupboard traps are now independently recovered: DOS DS:`4980` points to a 32×4-byte registry, whose count is DS:`47c2`. Seed zero has three links: cupboard (26,1) opens wall (27,0); (25,14) opens (26,13); (28,18) opens (28,20). The original routine `27418`–`274b8` stores the paired coordinates and removes the remote cell from the ordinary floor. `.build/recovery/base0-traps.tsv` preserves these records. Export them with `-traps OUTPUT.tsv`.

Generators are traversable floor machinery. Amiga MapGen converter `42f2` maps raw ID `09` to runtime ID `28` (hexadecimal); the game's movement check at `5526`–`555a` explicitly blocks computers (`2e`), shops (`2c`) and shootable blockages (`2a`), while generator `28` reaches the successful branch at `5598`. Blocking all nine cells incorrectly disconnects the recovered map.

All three recovered raw item `36` weapons are **Zlot 1.9**, corresponding to the Knuckle-Duster, rather than generic firearms. Main decoding at `2858` subtracts 18 from raw item codes; the name lookup subtracts one further, giving name-table index `23`. Packed words `e028`, `603e`, `c01d` encode qualities Super, IV, VII and endurance bytes 40, 62, 29 respectively. The display scales endurance by 100/256 (15%, 24%, 11%). These are melee weapons; inventing ammunition for them would materially alter the first base.

The original native loader at code `767c` explicitly sets heading **2 (south)** after map generation. Starting inside at (30,1) must face the pushable wall at (30,3), with the entrance behind the party.

## Shop records

Main shop metadata is an eight-byte record table at decoded main code `4102`: weight/item data word, base price word, quality-increment word, availability-group byte and flags byte. The first 84 display names follow the table beginning at code `3d0e`; the remaining zero-price records are inactive. The original-derived decoded table is local only: `.build/recovery/original-shop-table.tsv`.

The shop number is significant. DOS DS:`496e` points to nine ordered coordinate pairs, terminated with `ffff`. Seed zero's numbers are 1=(27,17), 2=(24,2), 3=(19,15), 4=(24,22), 5=(21,19), 6=(29,22). `.build/recovery/base0-shops.tsv` is exported with `-shops OUTPUT.tsv`. Row-major scanning would assign incorrect stock.

Main routine `21b6` gates stock by availability group, current seed and shop number. For seed zero, group zero is available in all shops, armour group one is unavailable, brawling group two is available only in shop two, and groups three through nine are unavailable. In particular, swords and firearms must not be offered as first-base stock. Batteries, explosives, devices, optics, cameras, balls and ammunition use group-zero stock, subject to their record's non-zero price and quality mask.

Main routine `1f50` constructs a deterministic quality mask. For ordinary stock, start with `rol16(material,4)`, add the item index, its first table word and shop number, rotate left by four, add the seed, apply `n=(n*1509+41)&ffff`, then use `(ror16(n,3)^0800)&ff`, replacing a zero mask with `80`. Basic corresponds to bit seven and Super to bit zero. The separate armour/material branch is irrelevant to seed zero's unavailable armour stock.

Routine `1f90` computes quality-priced stock as `basePrice + increment*(material*32+quality)` when flags bit zero is set. Flags bit five adds the seed-dependent increment (capped at 32768 for that contribution), as for explosives. Selling and repair apply additional condition and stock-dependent adjustments in `2016`, `2036` and their callers; displaying the base price as an exact sell or repair offer would be wrong.

`tools/main-export` now reproduces seed-zero shop offers from the supplied decoded main executable and numbered shop registry:

```sh
go run tools/main-export/main.go build/extracted/federation \
  .build/recovery/base0-shops.tsv .build/recovery/base0-stock.tsv
go test tools/main-export/main.go tools/main-export/main_test.go
```

It checks the Amiga hunk descriptor, declared code bounds and exact supplied-main SHA-256 (`8545561236cf6e0f773cd1ae886be13cc9bedf51c53595c28c3b2e259c4dabbc`) before using revision-specific offsets. The ignored TSV contains 180 offers: raw item identifier, kind, category, quality, price, original item data and flags, together with the numbered shop's position. Shop two offers Knuckle-Duster qualities 0,1,2,3,5,7 and Battle-Glove qualities 0,2,6,7. The respective Basic prices are 49 and 99. Exporter tests cover descriptor bounds, unsupported checksums, stock gates, quality-mask vectors and invalid shop registries.

## Sabotage sequence

Main code `9fbe`–`9ff8` consumes one explosive, stores the selected generator coordinate and starts state one with a counter of 100 simulation updates. Routine `7faa` advances to state two when this reaches zero. The shutdown scan at `7ffa`–`8036` opens blue/laser doors and raiser walls, while the interaction routines reject powered facilities after shutdown.

The subsequent destructive wave uses root-path directions. Routine `8088` advances the front every 14 updates, follows one root-path step through `8136`, and paints the front cell plus its four neighbours as fire. The original root direction order is **north, west, south, east** (values 0,1,2,3), independently established by the displacement tables at `815a` and `8162`. This direction order differs from a common clockwise heading enum. Preserve it when translating raw detail words. The original scheduler's update frequency has not yet been established; these counts must not be labelled exact seconds.

The sale routine at `1bcc`–`1c08` explicitly gives raw item `66` (Message from Ratt) a fixed **200 gold** offer, regardless of message code. Both the starting message (`0000`) and Brains' message (`0002`) therefore sell for 200. Generic probe-password clipboards (`64`) and maps (`62`) receive 500. Ratt's first table word `0078` is weight 120, not a sale valuation.

Weight routine `332e`–`3378` reads the first table word directly for ordinary items. Thus `itemData` is the integer weight for batteries, devices, optics, cameras, weapons, explosives, ammunition, mines and balls. Quality does not modify ordinary-item weight. Gold adds the amount shifted right by six; armour uses a separate material/quality multiplier. Integer weights are in tenths of the displayed units.

Fake-wall generation is gated by seed: Amiga MapGen `6ea8`–`6ee4` returns for seeds zero through five, then replaces plain floor object `07` with **raw object `32` (hexadecimal)**. Converter `43ea` maps this to runtime `3e`, which remains traversable. Spinner generation at `6ee6`–`6f40` returns for seeds zero through three, then writes raw `30`/`31`. The DOS routines independently match these gates and identifiers. Seed zero has none of these three raw IDs and reports zero false walls and spinners. Vision Corrector may be active in the first base with no walls to remove.

The fire-wave painter at main `8104` bounds-checks the target coordinate and then replaces any terrain/fixture with fire, retaining the enemy-presence bit. It does not skip walls. Detonation's initial shutdown does not ignite the selected generator's cross: the first 14-update advance follows the root once and then paints the new cross. Wave completion occurs when the next root step produces a negative y coordinate, past entrance row zero.
