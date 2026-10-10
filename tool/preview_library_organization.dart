// flutter test --no-pub tool/preview_library_organization.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const captureKey = ValueKey('library-preview-capture');
  const paths = MethodChannel('plugins.flutter.io/path_provider');
  late Directory support;
  setUpAll(() async {
    support = await Directory.systemTemp.createTemp('library_preview_');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      paths,
      (_) async => support.path,
    );
  });
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
    await support.delete(recursive: true);
  });
  for (final brightness in Brightness.values) {
    testWidgets('organization ${brightness.name}', (tester) async {
      // This executable is a Flutter test fixture outside test/.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      late AppSettingsNotifier settings;
      await tester.runAsync(() async {
        final bytes = await File(
          '/System/Library/Fonts/Hiragino Sans GB.ttc',
        ).readAsBytes();
        await (FontLoader(
          'LibraryPreview',
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        final flutterRoot = Platform.resolvedExecutable
            .split('/bin/cache')
            .first;
        final icons = await File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(icons)))).load();
        settings = AppSettingsNotifier();
        while (!settings.isInitialized) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await settings.setLibraryLayoutMode(LibraryLayoutMode.grid);
      });
      final controller = LibraryPageController();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final preset = AppThemes.findColorPreset('graphite')!;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: brightness == Brightness.light
                  ? preset.theme.lightColorScheme
                  : preset.theme.darkColorScheme,
              fontFamily: 'LibraryPreview',
              extensions: const [
                UiStyleThemeExtension(
                  style: AppUiStyle.glass,
                  glassStyle: GlassStyle.frosted,
                ),
              ],
            ),
            builder: (context, child) => RepaintBoundary(
              key: captureKey,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 48, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 48, bottom: 34),
                ),
                child: child!,
              ),
            ),
            home: HomeMobileChromeScope(
              metrics: const HomeMobileChromeMetrics(
                systemTopInset: 48,
                systemBottomInset: 34,
              ),
              child: Stack(
                children: [
                  LibraryPage(
                    controller: controller,
                    booksLoader: () async => [
                      for (final (index, title) in [
                        '人类简史',
                        '雪国',
                        '一个人的朝圣',
                        '月亮与六便士',
                      ].indexed)
                        Book(
                          id: index + 1,
                          title: title,
                          filePath: '/preview-$index.epub',
                          format: 'EPUB',
                          importDate: DateTime.utc(2026, 10, 10 - index),
                          readingProgress: .15 + index * .2,
                        ),
                    ],
                    foldersLoader: () async => [
                      ShelfFolder(
                        id: 'literature',
                        name: '文学',
                        parentId: null,
                        createdAt: DateTime.utc(2026, 10, 8),
                      ),
                      ShelfFolder(
                        id: 'history',
                        name: '历史',
                        parentId: null,
                        createdAt: DateTime.utc(2026, 10, 7),
                      ),
                    ],
                    reorderSaver: (_, _) async {},
                  ),
                  Positioned(
                    top: 48,
                    left: 20,
                    right: 16,
                    height: 60,
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '书库',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: controller.reordering,
                            builder: (_, reordering, _) =>
                                LibraryOrganizationButton(
                                  active: false,
                                  reordering: reordering,
                                  onOrganize: controller.showOrganizationMenu,
                                  onDone: controller.finishReordering,
                                ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.search_rounded),
                          const SizedBox(width: 16),
                          const Icon(Icons.add_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(controller.showOrganizationMenu());
      await tester.pumpAndSettle();
      Future<void> capture(String suffix) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File(
            'build/library-organization-preview/${brightness.name}-$suffix.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('menu');
      await tester.tap(find.byKey(const ValueKey('library-start-reordering')));
      await tester.pumpAndSettle();
      await capture('drag');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      settings.dispose();
      await tester.binding.setSurfaceSize(null);
    });
  }
}
