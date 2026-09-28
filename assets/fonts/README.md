# Reader indentation font

`ReaderIndent.ttf` is original Origo X layout data under the repository's
[AGPL license](../../LICENSE). It contains only an empty U+00A0 (no-break space)
glyph with an advance of exactly one em. Use it only for generated reader
indentation; it is neither a reading font nor a fallback for body text.

Its ascent, descent, and line gap are zero. The indentation span must explicitly
use `height: kTextHeightNone`, `letterSpacing: 0`, and `wordSpacing: 0`; inheriting
a nonzero line-height multiplier with zero font metrics can produce invalid
layout metrics. Paragraph separators must keep the body font and line height.

Regenerate with `python3 tool/generate_reader_indent_font.py`, or verify the
checked-in bytes with `python3 tool/generate_reader_indent_font.py --check`.
The generator uses only the Python standard library and fixed metadata.

# On-demand fonts

The following on-demand fonts are third-party works. They are not relicensed
under Origo X's AGPL license.

| Flutter family | Upstream font | Purpose | License |
| --- | --- | --- | --- |
| `SourceHanSerifCN` | Noto Serif SC / Source Han Serif | Default App UI serif and optional reading font | SIL OFL 1.1 (`licenses/NotoSerifSC-OFL.txt`) |
| `SourceHanSansCN` | Source Han Sans CN | App UI and reading sans serif | SIL OFL 1.1 (`licenses/SourceHanSans-OFL.txt`) |
| `InstrumentSans` | Instrument Sans | Optional App UI sans serif | SIL OFL 1.1 (`licenses/InstrumentSans-OFL.txt`) |
| `Newsreader` | Newsreader 16pt | Optional editorial reading serif | SIL OFL 1.1 (`licenses/Newsreader-OFL.txt`) |
| `JetBrainsMono` | JetBrains Mono | Optional technical/monospace font | SIL OFL 1.1 (`licenses/JetBrainsMono-OFL.txt`) |
| `HarmonyOSSansSC` | HarmonyOS Sans SC Regular | Optional App UI and reading sans serif | HarmonyOS Sans Fonts License Agreement (`licenses/HarmonyOSSans-License.txt`) |

Font binaries are downloaded on demand and stored in the app-private directory.
HarmonyOS Sans is read unchanged from Huawei's official archive; the application
does not use a third-party font mirror. Keep the corresponding license notice
with every redistributed copy of a font.

Purchase illustrations use the bundled Phosphor icon font in `assets/purchase/Phosphor.ttf` (MIT, notice in `licenses/Phosphor-MIT.txt`). It contains decorative/interface glyphs rather than reading text; constant IconData references allow release icon tree shaking. Text fonts above remain on demand.
