# Bundled app skin assets

Verified: 2026-10-10.

These files are decorative parts of the built-in Origo X app skins. The
third-party icon geometry remains governed by its upstream license and is not
relicensed under the application's AGPL license.

## IconPark-derived semantic icons

- Upstream: official `bytedance/IconPark` release `v1.4.2`.
- Pinned commit: `994225c538b1a42b553bd79be707500e3979ca43`.
- Source:
  `https://github.com/bytedance/IconPark/tree/v1.4.2/packages/svg/src/icons`.
- Copyright notice: Copyright 2019-present Bytedance Inc.
- License: Apache License 2.0; the complete upstream license is bundled as
  `LICENSE-ICONPARK-APACHE-2.0.txt`.
- Selected sources: `Home.ts`, `Bookshelf.ts`, `CompassOne.ts`,
  `MagicWand.ts`, `User.ts`, `LeftSmall.ts`, `RightSmall.ts`, `CloseSmall.ts`,
  `Search.ts`, `More.ts`, `Setting.ts`, `Refresh.ts`, `Add.ts`, `ShareOne.ts`,
  `Delete.ts`, and `CheckSmall.ts`.
- Changes: the semantic paths were redrawn and optically adjusted; Origo X
  added original pebble, leaf, and orbit badge systems, three palettes,
  selected states, dark variants, and transparent 128 x 128 raster exports.

Output directories:

```text
collections/tidal/icons/
collections/botanical/icons/
collections/celestial/icons/
```

Each directory contains 62 semantic slots in normal, selected, light, and
dark states, for 744 PNG files across the three collections.

The 16 IconPark-derived slots are `home`, `library`, `discover`, `ai`,
`profile`, `back`, `search`, `more`, `close`, `forward`, `settings`,
`refresh`, `add`, `share`, `delete`, and `check`.

The additional 46 slots are original Origo X vector geometry authored in
`source/generate_builtin_skins.py`: `bookmark`, `catalog`, `readAloud`,
`locate`, `play`, `pause`, `stop`, `previous`, `next`, `rewind`,
`fastForward`, `speed`, `timer`, `volume`, `volumeOff`, `expand`, `collapse`,
`remove`, `filter`, `sort`, `layoutGrid`, `layoutList`, `download`, `upload`,
`folder`, `createFolder`, `moveFolder`, `edit`, `copy`, `note`, `highlight`,
`history`, `help`, `info`, `cloud`, `sync`, `save`, `restore`, `link`,
`palette`, `font`, `image`, `device`, `key`, `extension`, and `network`.
These symbols do not derive from IconPark or another third-party icon set.

## Original Origo X backgrounds

The six files below are original geometric compositions authored for Origo X
in `source/generate_builtin_skins.py`. They contain no stock image,
proprietary character, third-party mark, or real person likeness.

```text
backgrounds/tidal.jpg
backgrounds/tidal-dark.jpg
backgrounds/botanical.jpg
backgrounds/botanical-dark.jpg
backgrounds/celestial.jpg
backgrounds/celestial-dark.jpg
```

Light and dark files are authored variants rather than runtime color filters.

## Integrity and reproduction

- `MANIFEST.sha256` records every deliverable hash plus the generator and
  IconPark license hashes.
- `source/generate_builtin_skins.py` is the reproducible source. It uses
  macOS `sips` to preserve SVG strokes and transparency and ImageMagick for
  final compression.
- Visual QA was performed at native 128 px and at the app's 24 px and 32 px
  display sizes for all 62 semantic slots in all three collections. Playback
  controls were checked as a set so play, pause, stop, previous, next, rewind,
  and fast-forward remain distinguishable at control-bar size.

This record documents the production basis for the assets and is not legal
advice.
