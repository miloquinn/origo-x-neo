import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_search_sheet.dart';
import 'package:xxread/widgets/reader_selection_toolbar.dart';

const _backAsset = 'assets/test-skins/reader-back.png';
const _bookmarkAsset = 'assets/test-skins/reader-bookmark.png';
const _bookmarkSelectedAsset = 'assets/test-skins/reader-bookmark-selected.png';
const _moreAsset = 'assets/test-skins/reader-more.png';

final class _ReaderSkinBundle extends CachingAssetBundle {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgaGj4DwADhAIAV8n6LgAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{
        _backAsset: <Object>[
          <String, Object>{'asset': _backAsset},
        ],
        _bookmarkAsset: <Object>[
          <String, Object>{'asset': _bookmarkAsset},
        ],
        _bookmarkSelectedAsset: <Object>[
          <String, Object>{'asset': _bookmarkSelectedAsset},
        ],
        _moreAsset: <Object>[
          <String, Object>{'asset': _moreAsset},
        ],
      })!;
    }
    if (key == _backAsset ||
        key == _bookmarkAsset ||
        key == _bookmarkSelectedAsset ||
        key == _moreAsset) {
      return ByteData.sublistView(_png);
    }
    throw FlutterError('Missing test asset: $key');
  }
}

AppSkin get _readerSkin => AppSkin(
  id: 'reader-test',
  icons: {
    AppSkinIconSlot.back: AppSkinIconAssets(
      normal: AppSkinImage(asset: _backAsset),
    ),
    AppSkinIconSlot.bookmark: AppSkinIconAssets(
      normal: AppSkinImage(asset: _bookmarkAsset),
      selected: AppSkinImage(asset: _bookmarkSelectedAsset),
    ),
    AppSkinIconSlot.more: AppSkinIconAssets(
      normal: AppSkinImage(asset: _moreAsset),
    ),
  },
);

Widget _host({required Widget child, AppSkin? skin, double textScale = 1}) =>
    DefaultAssetBundle(
      bundle: _ReaderSkinBundle(),
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            AppSkinTheme(skin: skin ?? AppSkin.original),
          ],
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 640),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  tearDown(() {
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  testWidgets('reader control skin keeps its 44px target and callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        skin: _readerSkin,
        child: Center(
          child: ReaderControlIconButton(
            palette: ReaderThemes.day,
            onPressed: () => taps++,
            tooltip: 'Bookmark',
            icon: Icons.bookmark_rounded,
            selected: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final target = find.byType(ReaderControlIconButton);
    expect(tester.getSize(target), const Size.square(44));
    final image = tester.widget<Image>(
      find.descendant(of: target, matching: find.byType(Image)),
    );
    expect((image.image as AssetImage).assetName, _bookmarkSelectedAsset);
    expect(find.byTooltip('Bookmark'), findsOneWidget);

    await tester.tap(target);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('original reader control preserves the exact fallback icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: Center(
          child: ReaderControlIconButton(
            palette: ReaderThemes.day,
            onPressed: () {},
            tooltip: 'Back',
            icon: Icons.arrow_back_rounded,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded));
    expect(icon.size, 22);
    expect(
      tester.getSize(find.byType(ReaderControlIconButton)),
      const Size.square(44),
    );
  });

  testWidgets('selection toolbar skins overflow action at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        skin: _readerSkin,
        textScale: 2,
        child: ReaderSelectionToolbar(
          palette: ReaderThemes.day,
          anchors: const TextSelectionToolbarAnchors(
            primaryAnchor: Offset(160, 240),
          ),
          onHighlight: () {},
          onNote: () {},
          onCopy: () {},
          onSearch: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final more = find.byKey(const ValueKey('reader-selection-more'));
    expect(more, findsOneWidget);
    expect(
      find.descendant(of: more, matching: find.byType(RawImage)),
      findsOneWidget,
    );
    expect(tester.getRect(more).width, 44);
    expect(tester.takeException(), isNull);

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-selection-search')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader search sheet skins back action and still closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        skin: _readerSkin,
        textScale: 2,
        child: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showReaderSearchSheet(
                context,
                palette: ReaderThemes.day,
                loadDocuments: () => const Stream<ReaderSearchDocument>.empty(),
                documentCount: 0,
              ),
              child: const Text('Open search'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();
    final back = find.byTooltip(
      MaterialLocalizations.of(
        tester.element(find.byType(IconButton).first),
      ).closeButtonTooltip,
    );
    expect(back, findsOneWidget);
    final image = tester.widget<Image>(
      find.descendant(of: back, matching: find.byType(Image)),
    );
    expect((image.image as AssetImage).assetName, _backAsset);
    expect(tester.takeException(), isNull);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-full-text-search-field')),
      findsNothing,
    );
  });
}
