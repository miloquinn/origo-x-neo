# App skin asset catalog

The bundled skins use one semantic contract across every collection. Each
collection supplies the same 62 controls with normal, selected, light, and
dark artwork. A theme can therefore replace navigation, title-bar actions,
reader controls, library tools, and common settings without matching Material
glyph names or screen-specific widget code.

The contract is grouped by purpose:

- Primary navigation: `home`, `library`, `discover`, `ai`, `profile`.
- Global actions: `back`, `forward`, `close`, `search`, `more`, `settings`,
  `refresh`, `add`, `remove`, `share`, `delete`, `check`.
- Reading and playback: `bookmark`, `catalog`, `readAloud`, `locate`, `play`,
  `pause`, `stop`, `previous`, `next`, `rewind`, `fastForward`, `speed`,
  `timer`, `volume`, `volumeOff`, `expand`, `collapse`.
- Library and content: `filter`, `sort`, `layoutGrid`, `layoutList`,
  `download`, `upload`, `folder`, `createFolder`, `moveFolder`, `edit`,
  `copy`, `note`, `highlight`, `history`.
- System and appearance: `help`, `info`, `cloud`, `sync`, `save`, `restore`,
  `link`, `palette`, `font`, `image`, `device`, `key`, `extension`, `network`.

## Bundled collections

| ID | Visual language | Light background | Dark background |
| --- | --- | --- | --- |
| `tidal` | Sea-glass pebble badges, aqua and coral | `assets/skins/backgrounds/tidal.jpg` | `assets/skins/backgrounds/tidal-dark.jpg` |
| `botanical` | Organic leaf badges, sage and terracotta | `assets/skins/backgrounds/botanical.jpg` | `assets/skins/backgrounds/botanical-dark.jpg` |
| `celestial` | Faceted orbit badges, lilac and amber | `assets/skins/backgrounds/celestial.jpg` | `assets/skins/backgrounds/celestial-dark.jpg` |

Every icon follows this path contract:

```text
assets/skins/collections/<skin-id>/icons/<slot>.png
assets/skins/collections/<skin-id>/icons/<slot>-dark.png
assets/skins/collections/<skin-id>/icons/<slot>-selected.png
assets/skins/collections/<skin-id>/icons/<slot>-selected-dark.png
```

The PNGs are transparent 128 x 128, 8-bit palette images. The background
JPEGs are 1200 x 1800, 8-bit sRGB. The complete replacement set contains 744
icons and six backgrounds. The tall backgrounds keep the center quiet so text
and the existing glass surfaces remain legible; decoration is concentrated
near the edges.

## Design source and rights basis

The original 16 semantic icon geometries are adapted from ByteDance IconPark `v1.4.2`,
commit `994225c538b1a42b553bd79be707500e3979ca43`, licensed under Apache-2.0.
The selected upstream sources are `Home.ts`, `Bookshelf.ts`, `CompassOne.ts`,
`MagicWand.ts`, `User.ts`, `LeftSmall.ts`, `RightSmall.ts`, `CloseSmall.ts`,
`Search.ts`, `More.ts`, `Setting.ts`, `Refresh.ts`, `Add.ts`, `ShareOne.ts`,
`Delete.ts`, and `CheckSmall.ts` from `packages/svg/src/icons`. Origo X redrew
and optically adjusted these shapes, added the three badge systems and
palettes, and produced selected and dark variants. The remaining 46 semantic
symbols are original Origo X vector geometry authored in the generator on the
same 48 x 48 design grid. They do not derive from IconPark or another icon
library. The complete upstream license for the original 16 is bundled at
`assets/skins/LICENSE-ICONPARK-APACHE-2.0.txt`.

Official source:
`https://github.com/bytedance/IconPark/tree/v1.4.2/packages/svg/src/icons`

All six background compositions are original Origo X vector artwork. They
were built from geometric paths by
`assets/skins/source/generate_builtin_skins.py`; no stock photograph,
proprietary character, logo, or third-party background was used.

`assets/skins/MANIFEST.sha256` records the exact hash of every deliverable,
the generator, and the bundled IconPark license. This is a production rights
record for the stated app use, not a legal opinion.

## Maintenance

The generator uses macOS `sips` for standards-compliant SVG rasterization and
ImageMagick only for final PNG/JPEG optimization. This separation is
intentional: ImageMagick's stock MSVG delegate drops some strokes and can fill
`fill="none"` paths, which made back/search controls unreadable.

Use `--expanded-only --skip-backgrounds` when changing only the expanded
contract; this preserves the original 16 raster files and all six backgrounds.
Use `--write-manifest` after a verified generation to refresh the integrity
record across every output.

Inspect regenerated icons at 24 px, 32 px, and 128 px. The badge is decorative,
but each semantic symbol must remain recognizable, especially destructive and
directional actions. Playback pairs must remain visibly distinct: `play` uses
one triangle in a circle, `pause` two bars, `stop` a square, `previous`/`next`
one triangle plus an end bar, and `rewind`/`fastForward` two triangles. When
adding a collection, provide all 62 slots and all
four icon states rather than silently mixing an illustration set with
unrelated emoji or platform glyphs. Update the manifest, credits, and license
registration together.
