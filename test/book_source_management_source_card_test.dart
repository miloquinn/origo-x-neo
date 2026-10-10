import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/book_sources/widgets/book_source_management_source_card.dart';
import 'package:xxread/widgets/app_menu.dart';

void main() {
  testWidgets('long source content stays readable at supported narrow widths', (
    tester,
  ) async {
    for (final variant in <({double width, double textScale})>[
      (width: 320, textScale: 1),
      (width: 390, textScale: 1.4),
      (width: 320, textScale: 2),
    ]) {
      await _pumpCard(
        tester,
        source: _denseSource(),
        width: variant.width,
        textScale: variant.textScale,
      );

      expect(find.text(_longName), findsOneWidget);
      expect(find.text(_longDescription), findsOneWidget);
      expect(find.text(_longGroup), findsOneWidget);
      expect(find.text('部分失效'), findsOneWidget);
      expect(tester.widget<Text>(find.text(_longName)).maxLines, 2);
      expect(tester.widget<Text>(find.text(_longGroup)).maxLines, 2);
      expect(tester.widget<Text>(find.text(_longDescription)).maxLines, 2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('favorite switch and menu keep their existing behavior', (
    tester,
  ) async {
    var favoriteTaps = 0;
    var enabledValue = true;
    final actions = <BookSourceManagementSourceAction>[];
    await _pumpCard(
      tester,
      source: _denseSource().copyWith(enabled: false),
      width: 320,
      textScale: 1,
      onEnabledChanged: (value) => enabledValue = value,
      onAction: (action) {
        actions.add(action);
        if (action == BookSourceManagementSourceAction.favorite) {
          favoriteTaps++;
        }
      },
    );

    await tester.tap(find.byKey(const ValueKey('bookSourceFavorite-dense')));
    await tester.tap(find.byType(Switch));
    expect(favoriteTaps, 1);
    expect(enabledValue, isTrue);

    await tester.tap(find.byType(AppPopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑书源'));
    await tester.pumpAndSettle();
    expect(actions, contains(BookSourceManagementSourceAction.edit));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection mode preserves the summary alignment and selection', (
    tester,
  ) async {
    var selectionTaps = 0;
    await _pumpCard(tester, source: _denseSource(), width: 320, textScale: 2);
    final normalNameLeft = tester.getTopLeft(find.text(_longName)).dx;
    await _pumpCard(
      tester,
      source: _denseSource(),
      width: 320,
      textScale: 2,
      selectionMode: true,
      selected: true,
      onToggleSelection: () => selectionTaps++,
    );

    final nameLeft = tester.getTopLeft(find.text(_longName)).dx;
    expect(find.byType(AppPopupMenuButton<String>), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(nameLeft, normalNameLeft);
    await tester.tap(find.byType(Checkbox));
    expect(selectionTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('regular cards share one compact metadata and action row', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      source: _compactSource(groups: const ['常用']),
      width: 390,
      textScale: 1,
    );

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('bookSourceCard-compact')),
    );
    final metadataRect = tester.getRect(
      find.byKey(const ValueKey('bookSourceMetadata-compact')),
    );
    final actionsRect = tester.getRect(
      find.byKey(const ValueKey('bookSourceActions-compact')),
    );
    final favoriteSize = tester.getSize(
      find.byKey(const ValueKey('bookSourceFavorite-compact')),
    );

    expect(cardRect.height, lessThan(130));
    expect((metadataRect.center.dy - actionsRect.center.dy).abs(), lessThan(1));
    expect(favoriteSize.width, greaterThanOrEqualTo(44));
    expect(favoriteSize.height, greaterThanOrEqualTo(44));
    expect(
      tester.getSize(find.byType(Switch)).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sources without metadata stay compact and readable', (
    tester,
  ) async {
    await _pumpCard(tester, source: _compactSource(), width: 390, textScale: 1);

    expect(find.text('简短书源'), findsOneWidget);
    expect(find.text('compact.example'), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('bookSourceCard-compact')))
          .height,
      lessThan(130),
    );
    expect(find.byKey(const ValueKey('bookSourceActions-compact')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login health and long groups keep ordinary cards compact', (
    tester,
  ) async {
    for (final variant in [
      (width: 320.0, scale: 1.0),
      (width: 390.0, scale: 1.2),
    ]) {
      await _pumpCard(
        tester,
        source: _denseSource(),
        width: variant.width,
        textScale: variant.scale,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('bookSourceCard-dense')))
            .height,
        lessThanOrEqualTo(200),
      );
      expect(find.text('部分失效'), findsOneWidget);
      expect(find.text(_longGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('locked additional protocols cannot be enabled', (tester) async {
    var enabledChanges = 0;
    await _pumpCard(
      tester,
      source: _denseSource().copyWith(enabled: false),
      width: 390,
      textScale: 1,
      additionalProtocolsEnabled: false,
      onEnabledChanged: (_) => enabledChanges++,
    );

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.onChanged, isNull);
    await tester.tap(find.byType(Switch));
    expect(enabledChanges, 0);
    expect(tester.takeException(), isNull);
  });
}

const _longName = 'E小说网6 与一个非常非常长但仍然需要辨认的书源名称';
const _longDescription =
    'm.ecc6.com / Error: Timeout while validating the complete reading chain';
const _longGroup = '整理检验与一个名称特别长仍然不能撑破卡片的自定义分组';

RegisteredBookSource _denseSource() {
  final source = RegisteredBookSource(
    id: 'dense',
    name: _longName,
    description: _longDescription,
    manifestUrl: Uri.parse('https://m.ecc6.com/source.json'),
    apiBaseUrl: Uri.parse('https://m.ecc6.com'),
    protocolVersion: 'reading-source-1',
    languages: const ['zh'],
    capabilities: const {'search', 'detail', 'catalog', 'content'},
    enabled: true,
    groups: const ['源仓库', _longGroup],
    addedAt: DateTime.utc(2026, 9, 12),
    sourceProtocol: BookSourceProtocolKind.readingSource,
    sourceConfig: const {
      'loginUrl': 'https://m.ecc6.com/login',
      '_openReadingHealthCheck': {
        'checked': ['search', 'info', 'catalog', 'content'],
        'failed': ['content'],
        'checkedAt': '2026-09-12T00:00:00Z',
      },
    },
  );
  return source;
}

RegisteredBookSource _compactSource({List<String> groups = const []}) {
  return RegisteredBookSource(
    id: 'compact',
    name: '简短书源',
    description: '',
    manifestUrl: Uri.parse('https://compact.example/source.json'),
    apiBaseUrl: Uri.parse('https://compact.example'),
    protocolVersion: '1',
    languages: const ['zh'],
    capabilities: const {'search'},
    enabled: true,
    groups: groups,
    addedAt: DateTime.utc(2026, 10, 10),
    sourceProtocol: BookSourceProtocolKind.orsp,
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required RegisteredBookSource source,
  required double width,
  required double textScale,
  bool selectionMode = false,
  bool selected = false,
  bool additionalProtocolsEnabled = true,
  VoidCallback? onToggleSelection,
  ValueChanged<bool>? onEnabledChanged,
  ValueChanged<BookSourceManagementSourceAction>? onAction,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BookSourceManagementSourceCard(
                source: source,
                selectionMode: selectionMode,
                selected: selected,
                additionalProtocolsEnabled: additionalProtocolsEnabled,
                onToggleSelection: onToggleSelection ?? () {},
                onEnabledChanged: onEnabledChanged ?? (_) {},
                onAction: onAction ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
