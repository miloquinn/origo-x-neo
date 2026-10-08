# Shared glass button visual acceptance

Captured from `tool/preview_glass_buttons.dart` on the iOS 27 iPhone 18 Pro
Max simulator (`B747AC4A-A940-4BBC-A2BB-DE72F5EDE816`) with Impeller enabled.
All controls in the fixtures are production widgets.

The 19 captures include 12 shared-control fixtures covering liquid glass at
0%, 50%, and 100% opacity, liquid dark mode, frosted light and dark modes,
glass disabled, reduced motion, 1.8x text, and the rest / pressed / pulled /
released spring states. Seven reader fixtures exercise the production
`ImageReaderChrome` and `ReaderSelectionToolbar` with the pure-black reader
palette inside a light app, at wide and 320 px widths, in liquid and frosted
modes, and at 1.8x text scale.

Visual verdict: pass. The 48 px liquid button keeps its refracted background
and rim aligned while pressed and pulled, then returns pixel-identically to its
rest state. The 44 px toolbar, text capsule, disabled state, top-bar actions,
and reader dark palette remain legible in every material mode. Large text
truncates or wraps inside its bounds without layout overflow; reduced motion
keeps the resting geometry.

The reader fixtures also pass. All four image-reader actions fit at 320 px,
the disabled Copy action remains visibly dimmed, and the selection overflow
trigger shows one spring response. At 1.8x text scale, Flutter's native vertical
overflow icon inherits the reader's white foreground. Its real popup opens with
white text and icons on pure black, then dismisses without leaving a route or
visual artifact.

Capture command:

```sh
/Users/xiaoyuan/flutter/bin/flutter run --no-pub --enable-impeller \
  -d B747AC4A-A940-4BBC-A2BB-DE72F5EDE816 \
  -t tool/preview_glass_buttons.dart \
  --dart-define=PREVIEW_CAPTURE=true
```

Reader capture command:

```sh
/Users/xiaoyuan/flutter/bin/flutter run --no-pub --enable-impeller \
  -d B747AC4A-A940-4BBC-A2BB-DE72F5EDE816 \
  -t tool/preview_glass_buttons.dart \
  --dart-define=PREVIEW_CAPTURE=true \
  --dart-define=PREVIEW_CAPTURE_SET=reader
```
