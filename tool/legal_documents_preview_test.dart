import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/pages/legal/legal_document_page.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const outputDirectory = 'docs/previews/legal-documents-20261008';

  testWidgets('capture legal document responsive previews', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('LegalPreview')
        ..addFont(
          File(
            '/System/Library/Fonts/STHeiti Medium.ttc',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '/Users/xiaoyuan/flutter/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await iconLoader.load();
    });
    final document = _previewDocument();

    await _captureScenario(
      tester,
      document: document,
      size: const Size(390, 844),
      textScale: 1,
      brightness: Brightness.light,
      path: '$outputDirectory/privacy-mobile-light.png',
    );
    await _captureScenario(
      tester,
      document: document,
      size: const Size(320, 640),
      textScale: 1.6,
      brightness: Brightness.light,
      path: '$outputDirectory/privacy-narrow-large-text.png',
    );
    await _captureScenario(
      tester,
      document: document,
      size: const Size(390, 844),
      textScale: 1,
      brightness: Brightness.dark,
      path: '$outputDirectory/privacy-mobile-dark.png',
    );
  });
}

LegalDocument _previewDocument() => LegalDocument(
  id: 'privacy',
  locale: 'zh-CN',
  title: '隐私政策',
  summary: '说明开元阅读在本地阅读、账号服务、同步与购买场景中如何处理信息。',
  revision: '2026-10-08.1',
  consentVersion: '2026-10-08.1',
  effectiveDate: '2026-10-08',
  updatedAt: '2026-10-08',
  changeSummary: const ['统一说明本地数据、可选联网功能与用户选择。', '补充账号阅读统计和第三方服务边界。'],
  canonicalUrl: Uri.parse('https://open.xxread.top/privacy?lang=zh-CN'),
  requiresAcceptance: true,
  sections: const [
    LegalSection(
      id: 'local-first',
      title: '本地优先与书籍数据',
      paragraphs: [
        '阅读记录、书架与本地书籍默认保存在你的设备上。开元阅读不会仅因为你打开一本书就上传正文。',
        '当你主动使用 WebDAV、账号同步或在线服务时，应用只处理完成该功能所需的信息。',
      ],
      bullets: ['不上传本地书籍正文。', '同步范围由你主动选择。'],
    ),
    LegalSection(
      id: 'network',
      title: '联网功能与账号服务',
      paragraphs: ['登录、会员验证、检查更新和在线内容会访问对应服务。我们会在功能界面中说明用途，并提供可用的关闭或删除选项。'],
    ),
    LegalSection(
      id: 'rights',
      title: '你的选择与权利',
      paragraphs: ['你可以查看、更正或删除账号信息，也可以关闭可选的云端统计与公开排行功能。'],
    ),
  ],
);

Future<void> _captureScenario(
  WidgetTester tester, {
  required LegalDocument document,
  required Size size,
  required double textScale,
  required Brightness brightness,
  required String path,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final boundaryKey = GlobalKey();
  final baseTheme =
      ThemeData(
        brightness: brightness,
        colorSchemeSeed: const Color(0xFF396E56),
        useMaterial3: true,
      ).copyWith(
        textTheme: ThemeData(
          brightness: brightness,
        ).textTheme.apply(fontFamily: 'LegalPreview'),
      );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: baseTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(
          key: boundaryKey,
          child: LegalDocumentPage(
            document: document,
            source: LegalContentSource.bundled,
            checkForUpdates: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull);
  await _capture(tester, boundaryKey, path);
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.reset();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
