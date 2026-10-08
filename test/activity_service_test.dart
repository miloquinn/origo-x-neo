import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/activities/activity.dart';
import 'package:xxread/services/activities/activity_browser.dart';

import 'support/activity_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'public catalogue requests the selected channel without account tokens',
    () async {
      final adapter = _Adapter({
        'activities': [activityFixture()],
      });
      final api = MemberAccountApiClient(
        baseUri: Uri.parse('https://example.test'),
        dio: Dio()..httpClientAdapter = adapter,
        tokenStore: _ForbiddenTokenStore(),
      );
      final result = await api.activities(channel: 'official');
      expect(result.single.id, 'referral');
      expect(adapter.request!.uri.path, '/api/v1/activities');
      expect(adapter.request!.uri.queryParameters, {'channel': 'official'});
      expect(adapter.request!.headers.containsKey('Authorization'), false);
    },
  );

  test(
    'store client filters referral metadata even if a server includes it',
    () async {
      final api = MemberAccountApiClient(
        dio: Dio()
          ..httpClientAdapter = _Adapter({
            'activities': [
              activityFixture(channels: ['official', 'store']),
              activityFixture(
                id: 'news',
                kind: 'announcement',
                channels: ['store'],
              ),
            ],
          }),
      );
      final result = await api.activities(channel: 'store');
      expect(result.map((item) => item.id), ['news']);
    },
  );

  test(
    'malformed catalogue fails rather than falling back to old activities',
    () async {
      final api = MemberAccountApiClient(
        dio: Dio()
          ..httpClientAdapter = _Adapter({
            'activities': [activityFixture()..['id'] = '../../login'],
          }),
      );
      await expectLater(
        api.activities(channel: 'official'),
        throwsA(isA<MemberAccountException>()),
      );
    },
  );

  test('detail URL keeps trusted origin, revision, theme and locale only', () {
    final activity = AppActivity.fromJson(activityFixture());
    final uri = activity.detailUri(
      Uri.parse('https://example.test:8443/api?token=old#secret'),
      channel: 'official',
      locale: 'zh-TW',
      dark: true,
    );
    expect(
      uri.toString(),
      'https://example.test:8443/zh-TW/activities/referral?channel=official&v=3&embedded=1&theme=dark',
    );
    expect(
      activity
          .detailUri(
            Uri.parse('https://example.test'),
            channel: 'official',
            locale: 'fr',
          )
          .path,
      '/en/activities/referral',
    );
    expect(
      () => activity.detailUri(
        Uri.parse('https://user:secret@example.test'),
        channel: 'official',
      ),
      throwsFormatException,
    );
    expect(
      () => activity.detailUri(
        Uri.parse('http://example.test'),
        channel: 'official',
      ),
      throwsFormatException,
    );
    expect(
      () => activity.detailUri(
        Uri.parse('https://example.test'),
        channel: 'store',
      ),
      throwsFormatException,
    );
    expect(
      activity
          .detailUri(Uri.parse('http://localhost:3000'), channel: 'official')
          .host,
      'localhost',
    );
  });

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    test('activity browser mode for $platform', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final previous = UrlLauncherPlatform.instance;
      final launcher = _Launcher();
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = previous);
      final uri = Uri.parse('https://example.test/activities/news');
      expect(await openActivityDetail(uri), isTrue);
      expect(launcher.url, uri.toString());
      expect(
        launcher.options!.mode,
        platform == TargetPlatform.android || platform == TargetPlatform.iOS
            ? PreferredLaunchMode.inAppBrowserView
            : PreferredLaunchMode.externalApplication,
      );
    });
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response);
  final Map<String, dynamic> response;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ForbiddenTokenStore implements MemberTokenStore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Public activities must not touch account tokens');
}

class _Launcher extends UrlLauncherPlatform {
  @override
  get linkDelegate => null;
  String? url;
  LaunchOptions? options;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return true;
  }
}
