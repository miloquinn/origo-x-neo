import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  test('support endpoints reuse authenticated account transport', () async {
    final adapter = _Adapter((options) async {
      expect(options.headers['Authorization'], 'Bearer access-token');
      if (options.path.endsWith('/feedback')) {
        expect(options.data, {
          'feedback_id': 'feedback-1',
          'expected_user_id': 'account-1',
          'category': 'bug',
          'message': 'Page is slow',
        });
        return _json({'feedback_id': 'feedback-1', 'status': 'received'});
      }
      expect(options.data, {
        'expected_user_id': 'account-1',
        'reports': [
          {'report_id': 'report-1'},
        ],
      });
      return _json({
        'accepted': ['report-1'],
      });
    });
    final api = _client(adapter);

    final feedback = await api.submitFeedback({
      'feedback_id': 'feedback-1',
      'expected_user_id': 'account-1',
      'category': 'bug',
      'message': 'Page is slow',
    });
    final accepted = await api.uploadDiagnostics([
      {'report_id': 'report-1'},
    ], expectedUserId: 'account-1');

    expect(feedback['status'], 'received');
    expect(accepted, ['report-1']);
    expect(adapter.requests.map((request) => request.uri.path), [
      '/api/v1/support/feedback',
      '/api/v1/support/diagnostics',
    ]);
  });

  test('support endpoints obey the legal network gate before HTTP', () async {
    final adapter = _Adapter((_) async => _json({}));
    final api = _client(adapter)..setNetworkAllowed(false);

    await expectLater(
      api.submitFeedback({'feedback_id': 'feedback-1'}),
      throwsA(
        isA<MemberAccountException>().having(
          (error) => error.code,
          'code',
          MemberAccountException.legalConsentRequiredCode,
        ),
      ),
    );
    await expectLater(
      api.uploadDiagnostics([
        {'report_id': 'report-1'},
      ], expectedUserId: 'account-1'),
      throwsA(isA<MemberAccountException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('empty diagnostics batch does not make a request', () async {
    final adapter = _Adapter((_) async => _json({}));
    final api = _client(adapter);

    expect(
      await api.uploadDiagnostics(const [], expectedUserId: 'account-1'),
      isEmpty,
    );
    expect(adapter.requests, isEmpty);
  });
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
