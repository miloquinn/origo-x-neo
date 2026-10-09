// Historical motion fixture; current material preview: preview_shared_glass_background.dart.
// flutter test --no-pub tool/preview_glass_elastic_chrome.dart
// Requires ffmpeg in PATH and a Chinese font (macOS system default or CHROME_PREVIEW_FONT).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/widgets/app_menu.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_pill_navigation_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_item.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';

const _font = String.fromEnvironment(
  'CHROME_PREVIEW_FONT',
  defaultValue: '/System/Library/Fonts/Hiragino Sans GB.ttc',
);

const _output = String.fromEnvironment(
  'CHROME_PREVIEW_OUTPUT',
  defaultValue: 'build/previews/glass-elastic',
);

void main() {
  testWidgets('render glass navigation and shared menu motion', (tester) async {
    await tester.runAsync(() async {
      final font = await File(_font).readAsBytes();
      await (FontLoader(
        'ChromePreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final sdk = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    debugDisableShadows = false;
    addTearDown(() {
      tester.view.reset();
      debugDisableShadows = true;
    });

    for (final dark in [false, true]) {
      final name = dark ? 'dark' : 'light';
      await tester.pumpWidget(_ChromePreview(key: ValueKey(name), dark: dark));
      await tester.pumpAndSettle();
      await _capture(tester, '$name-rest.png');
      final bar = tester.getRect(find.byType(ElasticPillNavigationBar));
      final gesture = await tester.startGesture(
        Offset(bar.left + bar.width / 8, bar.center.dy),
      );
      await tester.pump();
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 30));
        await _capture(tester, '$name-nav/frame-$frame.png');
      }
      await _capture(tester, '$name-pressed.png');
      for (var frame = 8; frame < 22; frame++) {
        final fraction = (frame - 7) / 14;
        await gesture.moveTo(
          Offset(
            bar.left + bar.width * (0.125 + 0.75 * fraction),
            bar.center.dy,
          ),
        );
        await tester.pump(const Duration(milliseconds: 30));
        await _capture(tester, '$name-nav/frame-$frame.png');
      }
      await _capture(tester, '$name-dragged.png');
      await gesture.up();
      for (var frame = 22; frame < 44; frame++) {
        await tester.pump(const Duration(milliseconds: 30));
        await _capture(tester, '$name-nav/frame-$frame.png');
      }
      await tester.pumpAndSettle();
      await _capture(tester, '$name-selected.png');

      await tester.tap(find.byKey(const ValueKey('preview-menu')));
      await tester.pump();
      for (var frame = 0; frame <= 25; frame++) {
        await _capture(tester, '$name-menu/frame-$frame.png');
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      await _capture(tester, '$name-menu-open.png');
      await tester.tap(find.text('管理书架'));
      await tester.pump();
      for (var frame = 26; frame < 42; frame++) {
        await _capture(tester, '$name-menu/frame-$frame.png');
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.runAsync(() async {
        for (final kind in ['nav', 'menu']) {
          final result = await Process.run('ffmpeg', [
            '-y',
            '-framerate',
            '33.333',
            '-i',
            '$_output/$name-$kind/frame-%d.png',
            '-vf',
            kind == 'nav'
                ? 'crop=780:300:0:1388,scale=390:150:flags=lanczos'
                : 'crop=780:940:0:0,scale=390:470:flags=lanczos',
            '-loop',
            '0',
            '$_output/$name-$kind.gif',
          ]);
          expect(result.exitCode, 0, reason: '${result.stderr}');
        }
      });
    }
    debugDisableShadows = true;
  });
}

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('chrome-preview-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_output/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _ChromePreview extends StatefulWidget {
  const _ChromePreview({super.key, required this.dark});
  final bool dark;

  @override
  State<_ChromePreview> createState() => _ChromePreviewState();
}

class _ChromePreviewState extends State<_ChromePreview> {
  int _selected = 0;
  Offset? _pointer;
  static const _items = [
    FloatingPillNavigationItem(
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      label: '书架',
    ),
    FloatingPillNavigationItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: '发现',
    ),
    FloatingPillNavigationItem(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'AI',
    ),
    FloatingPillNavigationItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3978B8),
        brightness: widget.dark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: 'ChromePreview',
      extensions: const [
        UiStyleThemeExtension(
          style: AppUiStyle.glass,
          glassStyle: GlassStyle.frosted,
        ),
      ],
    );
    return MaterialApp(
      theme: theme,
      builder: (_, child) => RepaintBoundary(
        key: const ValueKey('chrome-preview-boundary'),
        child: child!,
      ),
      home: Scaffold(
        body: Listener(
          onPointerDown: (event) =>
              setState(() => _pointer = event.localPosition),
          onPointerMove: (event) =>
              setState(() => _pointer = event.localPosition),
          onPointerUp: (_) => setState(() => _pointer = null),
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 130, 24, 0),
                  children: [
                    for (final (index, title) in [
                      '山海之间',
                      '时间的形状',
                      '长安故事',
                      '星河笔记',
                      '阅读与生活',
                    ].indexed)
                      Container(
                        height: 126,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 66,
                              decoration: BoxDecoration(
                                color: Colors.primaries[index * 2].withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(title.substring(0, 2))),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '已读 ${(index + 1) * 12}% · 本地书籍',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 56,
                left: 24,
                right: 16,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '动效预览',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppPopupMenuButton<String>(
                      key: const ValueKey('preview-menu'),
                      icon: const Icon(Icons.more_horiz_rounded),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'manage',
                          child: ListTile(
                            leading: Icon(Icons.library_books_outlined),
                            title: Text('管理书架'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'sort',
                          child: ListTile(
                            leading: Icon(Icons.sort_rounded),
                            title: Text('排序方式'),
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'import',
                          child: ListTile(
                            leading: Icon(Icons.add_rounded),
                            title: Text('导入书籍'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: 28,
                child: FloatingPillNavigationSurface(
                  width: 350,
                  height: 64,
                  child: ElasticPillNavigationBar(
                    selectedIndex: _selected,
                    onSelected: (index) => setState(() => _selected = index),
                    children: [
                      for (final (index, item) in _items.indexed)
                        FloatingPillNavigationButton(
                          item: item,
                          isSelected: index == _selected,
                          showLabel: true,
                          showSelectionIndicator: false,
                          onTap: () => setState(() => _selected = index),
                        ),
                    ],
                  ),
                ),
              ),
              if (_pointer case final point?)
                Positioned(
                  left: point.dx - 11,
                  top: point.dy - 11,
                  child: IgnorePointer(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.28,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.65,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
