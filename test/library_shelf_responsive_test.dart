@Tags(['isolated-process'])
library;

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
import 'package:xxread/pages/home/widgets/home_mobile_top_bar.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/pages/library/library_selection_actions.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_buttons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screenshots = Platform.environment['SHELF_SCREENSHOT_DIR'];
  final motionScreenshots =
      Platform.environment['SHELF_MOTION_SCREENSHOTS'] == '1';
  final motionScene = Platform.environment['SHELF_MOTION_SCENE'];
  final fontPath = Platform.environment['SHELF_PREVIEW_FONT'];
  const parentId = 'b8aefc13-67c9-4e05-91c6-44e7f502659a';
  const childId = 'b8aefc13-67c9-4e05-91c6-44e7f502659b';
  const titles = ['瓦尔登湖', '小王子', '悉达多', '月亮与六便士', '山茶文具店', '人类群星闪耀时'];
  late Directory directory;
  final coverPaths = <String>[];

  // Font/file/codec setup runs with the real clock, outside the widget test's
  // fake-async zone. Screenshots are optional; CI still checks layout and taps.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'library_layout_mode_v1': 'grid'});
    directory = await Directory.systemTemp.createTemp('shelf-preview-');
    if (screenshots == null || fontPath == null) return;
    final font = FontLoader('ShelfPreview');
    font.addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    const colors = [
      Color(0xffe7eedc),
      Color(0xffe9dfcd),
      Color(0xffdce6e8),
      Color(0xffe6dfeb),
      Color(0xfff0e5dc),
      Color(0xffdce5da),
    ];
    for (var i = 0; i < titles.length; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(colors[i], BlendMode.src);
      final ink = Paint()..color = const Color(0xff304749);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 360), ink);
      canvas.drawRect(const Rect.fromLTWH(26, 36, 40, 3), ink);
      final text = TextPainter(
        text: TextSpan(
          text: titles[i],
          style: const TextStyle(
            fontFamily: 'ShelfPreview',
            fontSize: 26,
            height: 1.6,
            color: Color(0xff304749),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 180);
      text.paint(canvas, const Offset(26, 126));
      text.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(240, 360);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${directory.path}/cover-$i.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      coverPaths.add(file.path);
      for (final width in [64, 240]) {
        final key = await ResizeImage(
          FileImage(file),
          width: width,
        ).obtainKey(ImageConfiguration.empty);
        PaintingBinding.instance.imageCache.putIfAbsent(
          key,
          () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image.clone())),
          ),
        );
      }
      image.dispose();
      picture.dispose();
    }
  });
  tearDownAll(() => directory.delete(recursive: true));

  testWidgets(
    'nested shelves stay usable across responsive themes and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => directory.path,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final books = List.generate(
        18,
        (i) => Book(
          id: i + 1,
          title: titles[i % titles.length],
          author: '阅读与生活',
          filePath: '/fixture-$i.txt',
          format: 'TXT',
          shelfFolderId: i < 4
              ? null
              : i < 8
              ? parentId
              : childId,
          coverImagePath: coverPaths.isEmpty
              ? null
              : coverPaths[i % coverPaths.length],
          readingProgress: i / 24,
        ),
      );
      final folders = [
        ShelfFolder(
          id: parentId,
          name: '文学与生活',
          parentId: null,
          createdAt: DateTime(2026),
        ),
        ShelfFolder(
          id: childId,
          name: '长篇小说 · 慢慢读',
          parentId: parentId,
          createdAt: DateTime(2026),
        ),
      ];
      for (final scene in [
        (
          name: 'phone-light',
          size: const Size(390, 844),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'grid',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-dark',
          size: const Size(390, 844),
          brightness: Brightness.dark,
          scale: 1.0,
          layout: 'grid',
          columns: 2,
          details: true,
        ),
        (
          name: 'narrow-large-text',
          size: const Size(320, 740),
          brightness: Brightness.light,
          scale: 1.5,
          layout: 'grid',
          columns: 2,
          details: true,
        ),
        (
          name: 'tablet',
          size: const Size(834, 1194),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'grid',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-card-light',
          size: const Size(390, 844),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'card',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-card-dark',
          size: const Size(390, 844),
          brightness: Brightness.dark,
          scale: 1.0,
          layout: 'card',
          columns: 2,
          details: true,
        ),
        (
          name: 'narrow-card-large-text',
          size: const Size(320, 900),
          brightness: Brightness.light,
          scale: 2.0,
          layout: 'card',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-card-single',
          size: const Size(390, 844),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'card',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-card-empty',
          size: const Size(390, 844),
          brightness: Brightness.dark,
          scale: 1.0,
          layout: 'card',
          columns: 2,
          details: true,
        ),
        (
          name: 'phone-five-columns',
          size: const Size(390, 844),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'grid',
          columns: 5,
          details: true,
        ),
        (
          name: 'narrow-five-columns',
          size: const Size(320, 740),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'grid',
          columns: 5,
          details: true,
        ),
        (
          name: 'phone-five-columns-large-text',
          size: const Size(390, 900),
          brightness: Brightness.light,
          scale: 2.0,
          layout: 'grid',
          columns: 5,
          details: true,
        ),
        (
          name: 'phone-five-columns-cover-only-large-text',
          size: const Size(390, 900),
          brightness: Brightness.dark,
          scale: 3.0,
          layout: 'grid',
          columns: 5,
          details: false,
        ),
        (
          name: 'tablet-five-columns',
          size: const Size(834, 1194),
          brightness: Brightness.light,
          scale: 1.0,
          layout: 'grid',
          columns: 5,
          details: true,
        ),
      ]) {
        final sceneBooks = scene.name == 'phone-card-single'
            ? books
                  .where((book) => book.shelfFolderId == parentId)
                  .take(1)
                  .toList()
            : scene.name == 'phone-card-empty'
            ? <Book>[]
            : books;
        final controller = LibraryPageController();
        SharedPreferences.setMockInitialValues({
          'library_layout_mode_v1': scene.layout,
          'library_grid_columns_v1': scene.columns,
          'library_grid_show_details_v1': scene.details,
        });
        final settings = (await tester.runAsync(() async {
          final settings = AppSettingsNotifier();
          if (!settings.isInitialized) {
            final initialized = Completer<void>();
            void listener() {
              if (settings.isInitialized && !initialized.isCompleted) {
                initialized.complete();
              }
            }

            settings.addListener(listener);
            listener();
            await initialized.future;
            settings.removeListener(listener);
          }
          return settings;
        }))!;
        final boundary = GlobalKey();
        final captureMotion =
            motionScreenshots &&
            (motionScene == null || motionScene == scene.name);
        await tester.binding.setSurfaceSize(scene.size);
        tester.view.physicalSize = scene.size;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                brightness: scene.brightness,
                colorSchemeSeed: const Color(0xff356c88),
                fontFamily: screenshots == null ? null : 'ShelfPreview',
                extensions: const [
                  UiStyleThemeExtension(style: AppUiStyle.glass),
                ],
              ),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scene.scale)),
                  child: HomeMobileChromeScope(
                    metrics: const HomeMobileChromeMetrics(
                      systemTopInset: 44,
                      systemBottomInset: 24,
                    ),
                    child: RepaintBoundary(
                      key: boundary,
                      child: Stack(
                        children: [
                          LibraryPage(
                            key: ValueKey(scene.name),
                            controller: controller,
                            booksLoader: () async => sceneBooks,
                            foldersLoader: () async => folders,
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: ValueListenableBuilder<String?>(
                              valueListenable: controller.folderName,
                              builder: (context, name, _) => Material(
                                type: MaterialType.transparency,
                                child: HomeMobileTopBar(
                                  title: name ?? '书架',
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GlassToolbarButton(
                                        icon: Icons.search_rounded,
                                        onPressed: controller.toggleSearch,
                                      ),
                                      const SizedBox(width: 8),
                                      GlassToolbarButton(
                                        icon: Icons.add_rounded,
                                        onPressed: controller.showAddMenu,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 24,
                            child:
                                ValueListenableBuilder<
                                  LibrarySelectionSnapshot
                                >(
                                  valueListenable: controller.selection,
                                  builder: (context, selection, _) =>
                                      selection.isActive
                                      ? LibrarySelectionActions(
                                          selectedCount:
                                              selection.selectedCount,
                                          onCreateFolder: controller
                                              .createFolderFromSelected,
                                          onMove: controller.moveSelected,
                                          onDelete: controller.deleteSelected,
                                        )
                                      : const SizedBox(height: 56),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: scene.name);
        Future<void> capture(String suffix) async {
          if (screenshots == null) return;
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(screenshots).create(recursive: true);
            await File(
              '$screenshots/${scene.name}-$suffix.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('root');
        if (scene.layout == 'card' && sceneBooks.length > 1) {
          await tester.drag(
            find.byKey(PageStorageKey('folder-preview-strip-$parentId')),
            const Offset(-900, 0),
          );
          await tester.pumpAndSettle();
          expect(controller.folderName.value, isNull);
          expect(tester.takeException(), isNull, reason: scene.name);
          await capture('preview-end');
        }
        await tester.tap(
          find.byKey(const ValueKey('library-folder-$parentId')),
        );
        if (captureMotion) {
          await tester.pump();
          await capture('open-000');
          final interval = scene.name == 'phone-light' ? 16 : 80;
          final frames = scene.name == 'phone-light' ? 20 : 3;
          for (var index = 1; index <= frames; index++) {
            final frame = index * interval;
            await tester.pump(Duration(milliseconds: interval));
            await capture('open-${frame.toString().padLeft(3, '0')}');
            expect(
              tester.takeException(),
              isNull,
              reason: '${scene.name} open $frame',
            );
          }
        }
        await tester.pumpAndSettle();
        expect(controller.folderName.value, '文学与生活');
        expect(
          find.byKey(const ValueKey('library-back-to-parent')),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${scene.name} subfolder',
        );
        await capture('folder');
        controller.selectAllVisible();
        await tester.pumpAndSettle();
        expect(
          controller.selection.value.selectedCount,
          sceneBooks.where((book) => book.shelfFolderId == parentId).length,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${scene.name} selection',
        );
        await capture('selection');
        if (captureMotion) {
          controller.exitSelection();
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('library-back-to-parent')),
          );
          await tester.pump();
          await tester.pump();
          await capture('back-000');
          final interval = scene.name == 'phone-light' ? 16 : 70;
          final frames = scene.name == 'phone-light' ? 18 : 3;
          for (var index = 1; index <= frames; index++) {
            final frame = index * interval;
            await tester.pump(Duration(milliseconds: interval));
            await capture('back-${frame.toString().padLeft(3, '0')}');
            expect(
              tester.takeException(),
              isNull,
              reason: '${scene.name} back $frame',
            );
          }
          await tester.pumpAndSettle();
          expect(controller.folderName.value, isNull);
          expect(
            find.byKey(const ValueKey('library-back-to-parent')),
            findsNothing,
          );
          await capture('back-complete');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();
        settings.dispose();
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
