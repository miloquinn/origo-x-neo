import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/themes/theme_market_item.dart';

Map<String, dynamic> _item({int size = 3}) => {
  'id': 'paper-garden',
  'version': 2,
  'name': 'Paper Garden',
  'description': '',
  'author': 'Maker',
  'license': 'CC0',
  'sha256': 'a' * 64,
  'size': size,
  'downloadUrl': 'https://untrusted.test/package.zip',
};

void main() {
  test('public metadata uses only official exact-version paths', () async {
    final adapter = _Adapter((options) async {
      expect(options.headers['Authorization'], isNull);
      return _json({
        'themes': [_item()],
      });
    });
    final api = _client(adapter);
    final theme = (await api.approvedThemes()).single;
    expect(
      theme.downloadPath,
      '/api/v1/themes/paper-garden/download?version=2',
    );
    expect(theme.previewPath, '/api/v1/themes/paper-garden/preview?version=2');
    expect(adapter.requests.single.uri.host, 'example.test');
    expect(
      () => ThemeMarketItem.fromJson({..._item(), 'id': 'bad_id'}),
      throwsFormatException,
    );
  });

  test('market listing and download obey legal consent before HTTP', () async {
    final adapter = _Adapter((_) async => _json({}));
    final api = _client(adapter)..setNetworkAllowed(false);
    await expectLater(
      api.approvedThemes(),
      throwsA(isA<MemberAccountException>()),
    );
    await expectLater(
      api.downloadTheme(ThemeMarketItem.fromJson(_item())),
      throwsA(isA<MemberAccountException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('streamed packages enforce exact size and disallow redirects', () async {
    final adapter = _Adapter((options) async {
      expect(options.followRedirects, false);
      expect(options.uri.queryParameters['version'], '2');
      return ResponseBody(Stream.value(Uint8List.fromList([1, 2, 3])), 200);
    });
    final api = _client(adapter);
    expect(await api.downloadTheme(ThemeMarketItem.fromJson(_item())), [
      1,
      2,
      3,
    ]);
    await expectLater(
      api.downloadTheme(ThemeMarketItem.fromJson(_item(size: 2))),
      throwsA(isA<MemberAccountException>()),
    );
    await expectLater(
      api.downloadTheme(ThemeMarketItem.fromJson(_item(size: 4))),
      throwsA(isA<MemberAccountException>()),
    );
  });

  test(
    'revoking consent during a download prevents returning its bytes',
    () async {
      late MemberAccountApiClient api;
      final adapter = _Adapter(
        (_) async => ResponseBody(
          Stream<Uint8List>.multi((controller) {
            controller.add(Uint8List.fromList([1]));
            api.setNetworkAllowed(false);
            controller.add(Uint8List.fromList([2, 3]));
            controller.close();
          }),
          200,
        ),
      );
      api = _client(adapter);
      await expectLater(
        api.downloadTheme(ThemeMarketItem.fromJson(_item())),
        throwsA(isA<MemberAccountException>()),
      );
    },
  );
}

MemberAccountApiClient _client(_Adapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return MemberAccountApiClient(
    dio: dio,
    tokenStore: _Tokens(accessToken: 'access-token'),
    baseUri: Uri.parse('https://example.test'),
  );
}

ResponseBody _json(Map<String, Object?> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }
}

class _Tokens implements MemberTokenStore {
  _Tokens({this.accessToken});

  String? accessToken;

  @override
  Future<void> clear() async => accessToken = null;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<bool> readMfaPending() async => false;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async => this.accessToken = accessToken;
}
