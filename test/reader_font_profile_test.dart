import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_font_profile.dart';
import 'package:xxread/utils/font_catalog_helper.dart';

void main() {
  test('EPUB book font and system font have distinct pagination contracts', () {
    final embedded = resolveReaderFontProfile(
      selection: FontCatalog.bookEmbeddedFont,
      platform: TargetPlatform.android,
      isWeb: false,
    );
    final system = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.android,
      isWeb: false,
    );

    expect(embedded.preservesBookFont, isTrue);
    expect(system.preservesBookFont, isFalse);
    expect(embedded.fontFamily, system.fontFamily);
    expect(embedded.cacheSignature, isNot(system.cacheSignature));
    expect(embedded.preservesParsedFontFor('epub'), isTrue);
    expect(system.preservesParsedFontFor('epub'), isFalse);
    expect(system.preservesParsedFontFor('azw3'), isTrue);
    expect(system.preservesParsedFontFor('mobi'), isTrue);
    expect(
      resolveReaderFontProfile(
        selection: FontCatalog.sourceHanSerif,
        platform: TargetPlatform.android,
        isWeb: false,
      ).preservesParsedFontFor('azw3'),
      isFalse,
    );
  });

  test('Android platform default uses generic sans-serif', () {
    final profile = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.android,
      locale: const Locale('zh', 'CN'),
      isWeb: false,
    );

    expect(profile.fontFamily, 'sans-serif');
    expect(profile.fontFamilyFallback, isEmpty);
    expect(profile.isPlatformDefault, isTrue);
    expect(profile.cacheSignature, contains('android-generic-sans'));
  });

  test('Apple platform default resolves PingFang by Chinese script', () {
    final simplified = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.iOS,
      locale: const Locale('zh', 'CN'),
      isWeb: false,
    );
    final traditional = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.macOS,
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      isWeb: false,
    );

    expect(simplified.fontFamily, 'PingFang SC');
    expect(simplified.fontFamilyFallback, <String>['PingFang TC']);
    expect(traditional.fontFamily, 'PingFang TC');
    expect(traditional.fontFamilyFallback, <String>['PingFang SC']);
    expect(simplified.cacheSignature, isNot(traditional.cacheSignature));
  });

  test('Windows platform default resolves Microsoft YaHei chain', () {
    final profile = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.windows,
      locale: const Locale('zh', 'CN'),
      isWeb: false,
    );

    expect(profile.fontFamily, 'Microsoft YaHei');
    expect(profile.fontFamilyFallback, <String>[
      'Microsoft YaHei UI',
      'Segoe UI',
      'Arial',
    ]);
  });

  test('explicit catalog font remains platform independent', () {
    final android = resolveReaderFontProfile(
      selection: FontCatalog.sourceHanSerif,
      platform: TargetPlatform.android,
      locale: const Locale('zh', 'CN'),
      isWeb: false,
    );
    final windows = resolveReaderFontProfile(
      selection: FontCatalog.sourceHanSerif,
      platform: TargetPlatform.windows,
      locale: const Locale('zh', 'CN'),
      isWeb: false,
    );

    expect(android.fontFamily, 'SourceHanSerifCN');
    expect(android.fontFamilyFallback, <String>['SourceHanSansCN']);
    expect(android.cacheSignature, windows.cacheSignature);
    expect(android.isPlatformDefault, isFalse);
  });

  test('web system selection remains browser managed', () {
    final profile = resolveReaderFontProfile(
      selection: FontCatalog.systemFont,
      platform: TargetPlatform.android,
      locale: const Locale('zh', 'CN'),
      isWeb: true,
    );

    expect(profile.fontFamily, isNull);
    expect(profile.fontFamilyFallback, isEmpty);
  });
}
