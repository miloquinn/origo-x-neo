# App skin asset catalog

The built-in image skins use a fixed, offline catalog. Runtime code never
downloads artwork and does not substitute platform emoji fonts. The catalog is
defined in `lib/models/app_skin.dart`; every icon path resolves to a bundled
PNG and every background path resolves to a bundled JPEG.

## Built-in skins

| ID | Page/navigation artwork | Home | Library | Discover | AI | Profile |
| --- | --- | --- | --- | --- | --- | --- |
| `tidal` | Hokusai wave | house | books | compass | crystal ball | surfer |
| `botanical` | Van Gogh irises | house with garden | open book | seedling | magic wand | person |
| `celestial` | NASA Blue Marble | house | books | telescope | robot | astronaut |

The `back`, `search`, and `more` slots intentionally have no image assets.
Renderers fall back to the existing Material glyphs so universal navigation
controls stay familiar. Visible text labels and semantics remain unchanged.

The wave and irises JPEGs reuse the already bundled Met Open Access files.
Twemoji graphics are pinned to official upstream release `v14.0.2`, rasterized from SVG
to 128 px PNG, and shared between skins where the same symbol is appropriate.
The NASA image is the official 1041 px Apollo 17 download, below the 1500 px
background budget. The complete new asset directory is under 0.5 MiB.

## Attribution and maintenance

- `assets/skins/APP_CREDITS.txt` is concise user-facing attribution loaded by
  `registerAppSkinLicenses()` for Flutter's license page.
- `assets/skins/NOTICE.md` records exact source URLs, transformations, rights
  basis, dimensions, sizes, and SHA-256 hashes.
- `assets/skins/LICENSE-TWEMOJI-CC-BY-4.0.txt` is the complete upstream
  Creative Commons Attribution 4.0 graphics license.
- `assets/purchase/ARTWORK-NOTICE.txt` remains the source record for the two
  reused Met images.

When replacing an asset, update the catalog path, NOTICE row, source URL,
transformation note, byte size and SHA-256 together. Do not overwrite a file
with differently licensed artwork while keeping its old provenance record.
