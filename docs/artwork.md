# Remastered artwork

`assets/remaster/` holds new raster artwork generated for this internal remaster
with imagegen. It is separate from extracted original game graphics, which stay
under ignored local build directories. The project's licence remains undecided;
this directory carries no blanket MIT declaration.

The visual kit uses a future imagined through old televisions and typewriters:
ivory moulded cases, brass fasteners, heavy connectors, muted oxblood bands,
olive recesses and amber practical lighting. `style-kit.png` established the
corridor, door, terminal, droid, enemy and equipment language before individual
assets were generated. Text is rendered by the application, never baked into
the illustrations.

`wall.png` is a straight-on wall module for projection by the renderer.
`wall-reactor.png` uses heat-exchanger fins, dark cast metal and locking ports;
`wall-service.png` uses green enamel, a braced hatch and an inspection window.
These complementary materials vary the first base's three recovered sectors.
Selection is stable in world coordinates and independent of gameplay randomness.
Later bases should receive distinct architectural kits, floors, ceilings,
lighting and fixture silhouettes through the configurable material set.
`door.png` is an isolated bulkhead with transparency. `generator.png` retains
the original sloped reactor silhouette and top connector; `terminal.png` and
`droid.png` extend the same visual language.

`tree.png`, `scavenger.png` and `brains.png` were generated using the original
[encounter screenshots](https://captive.atari.org/Environment/Encounters/Encounters.php)
as design references, with the kit as their style reference. They preserve the
plant creature, green-tunic/blue-trouser humanoid and pale robed keeper identities.
Runtime wall and sprite images are 1024×1024, downsampled from the generated
1254×1254 masters at the user's request. Sprite alpha transparency is preserved;
the user will handle the subsequent lossless ImageOptim pass. The kit's security-robot
study is art direction only, not evidence of a robot encounter in the first base.

Original palette changes, perspective composition and sprite placement remain
subject to comparison against the original. Generated concept art must not be
described as recovered original evidence.
