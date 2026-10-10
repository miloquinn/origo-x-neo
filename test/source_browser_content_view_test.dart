import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_browser_session.dart';
import 'package:xxread/widgets/source_browser_content_view.dart';

void main() {
  test('embedded browser channel is scoped to the platform view', () {
    expect(
      sourceBrowserContentChannelName(42),
      'com.niki.xxread/source_browser_content/42',
    );
  });

  test('platform snapshot becomes an active browser result', () {
    final result = SourceBrowserResult.fromPlatformMap({
      'body': '<html>comments</html>',
      'finalUrl': 'https://reader.example/comments',
      'session': {
        'cookies': [
          {'name': 'sid', 'value': 'abc', 'domain': 'reader.example'},
        ],
        'localStorage': {
          'https://reader.example': {'token': 'value'},
        },
      },
    });

    expect(result.body, contains('comments'));
    expect(result.finalUri.host, 'reader.example');
    expect(result.session.active, isTrue);
    expect(
      result.session.localStorage['https://reader.example']?['token'],
      'value',
    );
  });

  test('controller requires an attached native view for commands', () {
    final controller = SourceBrowserContentController();
    expect(controller.latestResult, isNull);
    expect(controller.reload, throwsStateError);
  });

  testWidgets('unsupported platforms delegate the failure to their parent', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    bool? loading;
    String? error;

    await tester.pumpWidget(
      MaterialApp(
        home: SourceBrowserContentView(
          sourceId: 'source-id',
          sourceUrl: 'https://source.example',
          url: Uri.parse('https://comments.example'),
          headers: const {},
          session: const SourceBrowserSession(),
          onLoadingChanged: (value) => loading = value,
          onError: (value) => error = value,
        ),
      ),
    );
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;

    expect(loading, isFalse);
    expect(error, contains('unavailable'));
    expect(find.byType(Text), findsNothing);
  });

  test('native views expose the modern Legado async bridge globals', () {
    const files = [
      'android/app/src/main/kotlin/com/niki/xxread/SourceBrowserSessionBridge.kt',
      'ios/Runner/SourceBrowserSessionBridge.swift',
      'macos/Runner/SourceBrowserSessionBridge.swift',
    ];
    const globals = [
      'window.run',
      'ajaxAwait',
      'connectAwait',
      'getAwait',
      'headAwait',
      'postAwait',
      'webViewAwait',
      'webViewGetSourceAwait',
      'decryptStrAwait',
      'encryptBase64Await',
      'encryptHexAwait',
      'createSignHexAwait',
      'getStringAwait',
      'importScriptAwait',
      'methodName',
      'refreshContent',
      'closeRequested',
      'closeBottomView',
      'sourceUrl',
      "==='run'",
      r'Await$',
      'Unsupported source page method',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      for (final global in globals) {
        expect(source, contains(global), reason: '$path must expose $global');
      }
    }
  });
}
