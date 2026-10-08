import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/book_source_response_cache.dart';
import 'package:xxread/book_sources/networking/book_source_network_policy.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/protocol/orsp/orsp_http_pipeline.dart';

void main() {
  group('ORSP chapter error mapping', () {
    test('marks structured CHAPTER_NOT_FOUND as a missing chapter', () async {
      final exception = await _mappedException(
        statusCode: HttpStatus.notFound,
        body: const {
          'error': {
            'code': 'CHAPTER_NOT_FOUND',
            'message': 'upstream reference expired',
          },
        },
      );

      expect(exception.message, 'upstream reference expired (HTTP 404)');
      expect(exception.code, 'CHAPTER_NOT_FOUND');
      expect(exception.statusCode, HttpStatus.notFound);
      expect(exception.isMissingChapter, isTrue);
    });

    test('marks code-less HTTP 404 as a missing chapter', () async {
      final exception = await _mappedException(
        statusCode: HttpStatus.notFound,
        body: const {
          'error': {'message': 'opaque response'},
        },
      );

      expect(exception.message, 'opaque response (HTTP 404)');
      expect(exception.code, isNull);
      expect(exception.statusCode, HttpStatus.notFound);
      expect(exception.isMissingChapter, isTrue);
    });

    test('accepts CHAPTER_NOT_FOUND when no HTTP status is available', () {
      const exception = BookSourceProtocolException(
        'chapter unavailable',
        code: 'CHAPTER_NOT_FOUND',
      );

      expect(exception.statusCode, isNull);
      expect(exception.isMissingChapter, isTrue);
    });

    for (final testCase in <({int status, String? code})>[
      (status: HttpStatus.notFound, code: 'BOOK_NOT_FOUND'),
      (status: HttpStatus.notFound, code: 'ROUTE_NOT_FOUND'),
      (status: HttpStatus.unauthorized, code: null),
      (status: HttpStatus.tooManyRequests, code: null),
      (status: HttpStatus.internalServerError, code: null),
      (status: HttpStatus.unauthorized, code: 'CHAPTER_NOT_FOUND'),
      (status: HttpStatus.tooManyRequests, code: 'CHAPTER_NOT_FOUND'),
      (status: HttpStatus.internalServerError, code: 'CHAPTER_NOT_FOUND'),
    ]) {
      test(
        'does not mark HTTP ${testCase.status} ${testCase.code ?? 'without a code'} '
        'as a missing chapter',
        () async {
          final exception = await _mappedException(
            statusCode: testCase.status,
            body: {
              'error': {
                if (testCase.code != null) 'code': testCase.code,
                'message': 'request failed',
              },
            },
          );

          expect(exception.code, testCase.code);
          expect(exception.statusCode, testCase.status);
          expect(exception.isMissingChapter, isFalse);
        },
      );
    }
  });
}

Future<BookSourceProtocolException> _mappedException({
  required int statusCode,
  required Map<String, Object?> body,
}) async {
  final dio = Dio()..httpClientAdapter = _ReplyAdapter(statusCode, body);
  addTearDown(() => dio.close(force: true));
  final pipeline = OrspHttpPipeline(
    dio,
    BookSourceNetworkPolicy(
      lookup: (_) async => [InternetAddress('93.184.216.34')],
    ),
    BookSourceResponseCache(),
    systemDio: dio,
  );

  try {
    await pipeline.getBounded(Uri.parse('https://example.org/chapter'));
  } on DioException catch (error) {
    return pipeline.mapDioException(error);
  }
  throw StateError('Expected the ORSP request to fail.');
}

class _ReplyAdapter implements HttpClientAdapter {
  _ReplyAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
