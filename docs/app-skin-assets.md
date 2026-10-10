# App skin asset catalog

The bundled skins use one semantic contract across every collection. Each
collection supplies the same 16 controls with normal, selected, light, and
dark artwork. The navigation group is `home`, `library`, `discover`, `ai`,
and `profile`; the common action group is `back`, `forward`, `close`,
`search`, `more`, `settings`, `refresh`, `add`, `share`, `delete`, and
`check`. A theme can therefore replace global toolbar controls and navigation
items without matching Material glyph names or screen-specific widget code.

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
JPEGs are 1200 x 1800, 8-bit sRGB. The complete replacement set contains 192
icons and six backgrounds. The tall backgrounds keep the center quiet so text
and the existing glass surfaces remain legible; decoration is concentrated
near the edges.

## Design source and rights basis

The semantic icon geometry is adapted from ByteDance IconPark `v1.4.2`,
commit `994225c538b1a42b553bd79be707500e3979ca43`, licensed under Apache-2.0.
The selected upstream sources are `Home.ts`, `Bookshelf.ts`, `CompassOne.ts`,
`MagicWand.ts`, `User.ts`, `LeftSmall.ts`, `RightSmall.ts`, `CloseSmall.ts`,
`Search.ts`, `More.ts`, `Setting.ts`, `Refresh.ts`, `Add.ts`, `ShareOne.ts`,
`Delete.ts`, and `CheckSmall.ts` from `packages/svg/src/icons`. Origo X redrew
and optically adjusted these shapes, added the three badge systems and
palettes, and produced selected and dark variants. The complete upstream
license is bundled at
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

Inspect regenerated icons at 24 px as well as 128 px. The badge is decorative,
but each semantic symbol must remain recognizable, especially destructive and
directional actions. When adding a collection, provide all 16 slots and all
four icon states rather than silently mixing an illustration set with
unrelated emoji or platform glyphs. Update the manifest, credits, and license
registration together.
