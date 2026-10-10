import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';

class _MemoryAISettingsStore implements AISettingsStore {
  AIProviderSettings _settings = AIProviderSettings.defaults(
    AIProviderType.minimax,
  );

  @override
  Future<AIProviderSettings> load([AIProviderType? provider]) async {
    if (provider == null || provider == _settings.provider) return _settings;
    return AIProviderSettings.defaults(provider);
  }

  @override
  Future<void> save(AIProviderSettings settings) async {
    _settings = settings.normalized();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderHttpAIService.fetchAvailableModels', () {
    test('parses OpenAI-compatible model data', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [
                      {'id': 'model-b'},
                      {'id': 'model-a'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(
        dio: dio,
        settingsStore: _MemoryAISettingsStore(),
      );

      final models = await service.fetchAvailableModels(
        const AIProviderSettings(
          provider: AIProviderType.openai,
          apiKey: 'test-key',
          baseUrl: 'https://example.com/v1',
          model: 'model-a',
          temperature: 0.7,
        ),
      );

      expect(models, ['model-a', 'model-b']);
    });

    test('accepts successful business code with model data', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'code': 200,
                    'data': [
                      {'id': 'glm-5.3'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(dio: dio);

      final models = await service.fetchAvailableModels(
        const AIProviderSettings(
          provider: AIProviderType.glm,
          apiKey: 'valid-key',
          baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
          model: '',
          temperature: 0.7,
        ),
      );

      expect(models, ['glm-5.3']);
    });

    test(
      'maps HTTP 200 business authentication failures without secrets',
      () async {
        const secret = 'must-not-appear-api-key';
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'code': 401, 'message': 'Invalid API key: $secret'},
                  ),
                );
              },
            ),
          );
        final service = ReaderHttpAIService(dio: dio);

        await expectLater(
          service.fetchAvailableModels(
            const AIProviderSettings(
              provider: AIProviderType.glm,
              apiKey: secret,
              baseUrl: 'https://open.bigmodel.cn/api/anthropic',
              model: 'glm-5.3',
              temperature: 0.7,
            ),
          ),
          throwsA(
            isA<AIServiceException>()
                .having(
                  (error) => error.code,
                  'code',
                  'request_failed_provider_mismatch_hint',
                )
                .having((error) => error.status, 'status', '401')
                .having((error) => error.text, 'text', isNull)
                .having((error) => error.error, 'error', isNull)
                .having((error) => error.snippet, 'snippet', isNull),
          ),
        );
      },
    );

    test('maps HTTP 200 error objects before list parsing', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'error': {'code': 403, 'message': 'Unauthorized'},
                  },
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(dio: dio);

      await expectLater(
        service.fetchAvailableModels(
          const AIProviderSettings(
            provider: AIProviderType.openai,
            apiKey: 'bad-key',
            baseUrl: 'https://example.com/v1',
            model: '',
            temperature: 0.7,
          ),
        ),
        throwsA(
          isA<AIServiceException>()
              .having(
                (error) => error.code,
                'code',
                'request_failed_provider_mismatch_hint',
              )
              .having((error) => error.status, 'status', '403'),
        ),
      );
    });

    test('parses and normalizes Gemini model names', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'models': [
                      {
                        'name': 'models/gemini-2.5-flash',
                        'supportedGenerationMethods': ['generateContent'],
                      },
                      {'name': 'models/gemini-2.5-pro'},
                      {
                        'name': 'models/text-embedding-004',
                        'supportedGenerationMethods': ['embedContent'],
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(dio: dio);

      final models = await service.fetchAvailableModels(
        const AIProviderSettings(
          provider: AIProviderType.gemini,
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          model: 'gemini-2.5-flash',
          temperature: 0.7,
        ),
      );

      expect(models, ['gemini-2.5-flash', 'gemini-2.5-pro']);
    });

    test('follows Gemini page tokens on the same endpoint', () async {
      final queries = <Map<String, dynamic>>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              queries.add(Map<String, dynamic>.from(options.queryParameters));
              final isSecond = options.queryParameters['pageToken'] == 'next';
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: isSecond
                      ? {
                          'models': [
                            {'name': 'models/gemini-second'},
                          ],
                        }
                      : {
                          'models': [
                            {'name': 'models/gemini-first'},
                          ],
                          'nextPageToken': 'next',
                        },
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(dio: dio);

      final models = await service.fetchAvailableModels(
        const AIProviderSettings(
          provider: AIProviderType.gemini,
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          model: 'gemini-first',
          temperature: 0.7,
        ),
      );

      expect(models, ['gemini-first', 'gemini-second']);
      expect(queries, [
        {},
        {'pageToken': 'next'},
      ]);
    });

    for (final protocol in [AIProtocolType.openai, AIProtocolType.anthropic]) {
      test('follows ${protocol.value} cursor pagination', () async {
        final queries = <Map<String, dynamic>>[];
        final cursorKey = protocol == AIProtocolType.anthropic
            ? 'after_id'
            : 'after';
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                queries.add(Map<String, dynamic>.from(options.queryParameters));
                final isSecond = options.queryParameters[cursorKey] == 'one';
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: isSecond
                        ? {
                            'data': [
                              {'id': 'two'},
                            ],
                            'has_more': false,
                          }
                        : {
                            'data': [
                              {'id': 'one'},
                            ],
                            'has_more': true,
                          },
                  ),
                );
              },
            ),
          );
        final service = ReaderHttpAIService(dio: dio);

        final models = await service.fetchAvailableModels(
          AIProviderSettings(
            provider: AIProviderType.custom,
            protocol: protocol,
            apiKey: 'test-key',
            baseUrl: 'https://models.example.com',
            model: '',
            temperature: 0.7,
          ),
        );

        expect(models, ['one', 'two']);
        expect(queries, [
          {},
          {cursorKey: 'one'},
        ]);
      });
    }

    test(
      'uses Anthropic model endpoint and headers for custom provider',
      () async {
        late RequestOptions captured;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                captured = options;
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'data': [
                        {'id': 'custom-claude-model'},
                      ],
                    },
                  ),
                );
              },
            ),
          );
        final service = ReaderHttpAIService(dio: dio);

        final models = await service.fetchAvailableModels(
          const AIProviderSettings(
            provider: AIProviderType.custom,
            protocol: AIProtocolType.anthropic,
            apiKey: 'anthropic-key',
            baseUrl: 'https://gateway.example.com',
            model: 'custom-claude-model',
            temperature: 0.7,
          ),
        );

        expect(models, ['custom-claude-model']);
        expect(
          captured.uri.toString(),
          'https://gateway.example.com/v1/models',
        );
        expect(captured.headers['x-api-key'], 'anthropic-key');
        expect(captured.headers['anthropic-version'], '2023-06-01');
        expect(captured.headers, isNot(contains('Authorization')));
      },
    );

    test(
      'reports manual entry when GLM model endpoint is unsupported',
      () async {
        late RequestOptions captured;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                captured = options;
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
            ),
          );
        final service = ReaderHttpAIService(dio: dio);

        await expectLater(
          service.fetchAvailableModels(
            const AIProviderSettings(
              provider: AIProviderType.glm,
              apiKey: 'glm-key',
              baseUrl: 'https://open.bigmodel.cn/api/anthropic',
              model: 'glm-5.3',
              temperature: 0.7,
            ),
          ),
          throwsA(
            isA<AIServiceException>()
                .having(
                  (error) => error.code,
                  'code',
                  'model_list_unsupported_manual_entry',
                )
                .having((error) => error.status, 'status', '404'),
          ),
        );

        expect(captured.uri.host, 'open.bigmodel.cn');
        expect(captured.uri.path, '/api/anthropic/v1/models');
        expect(captured.headers['x-api-key'], 'glm-key');
      },
    );

    test('does not hide GLM authentication errors behind fallback', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 401,
                    data: {
                      'error': {'message': 'Invalid API key'},
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(dio: dio);

      await expectLater(
        service.fetchAvailableModels(
          const AIProviderSettings(
            provider: AIProviderType.glm,
            apiKey: 'bad-key',
            baseUrl: 'https://open.bigmodel.cn/api/anthropic',
            model: 'glm-5.3',
            temperature: 0.7,
          ),
        ),
        throwsA(
          isA<AIServiceException>()
              .having(
                (error) => error.code,
                'code',
                'request_failed_provider_mismatch_hint',
              )
              .having((error) => error.status, 'status', '401'),
        ),
      );
    });
  });

  group('custom AI provider protocol settings', () {
    test('OpenAI-compatible URL keeps v1 and strips full chat endpoint', () {
      final settings = const AIProviderSettings(
        provider: AIProviderType.custom,
        protocol: AIProtocolType.openai,
        apiKey: 'key',
        baseUrl: 'https://gateway.example.com/v1/chat/completions',
        model: 'reader-model',
        temperature: 1.2,
      ).normalized();

      expect(settings.baseUrl, 'https://gateway.example.com/v1');
      expect(settings.effectiveProtocol, AIProtocolType.openai);
      expect(validateAIProviderSettings(settings), isNull);
    });

    test(
      'Anthropic protocol accepts custom model names and limits temperature',
      () {
        final settings = const AIProviderSettings(
          provider: AIProviderType.custom,
          protocol: AIProtocolType.anthropic,
          apiKey: 'key',
          baseUrl: 'https://gateway.example.com/v1/messages',
          model: 'vendor-private-model',
          temperature: 1.2,
        ).normalized();

        expect(settings.baseUrl, 'https://gateway.example.com/v1');
        expect(validateAIProviderSettings(settings), 'temp_error_out_of_range');
      },
    );

    test('custom Anthropic chat uses messages endpoint and payload', () async {
      late RequestOptions captured;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              captured = options;
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 200,
                  data: jsonEncode({
                    'content': [
                      {'type': 'text', 'text': '自定义协议已生效'},
                    ],
                  }),
                ),
              );
            },
          ),
        );
      final service = ReaderHttpAIService(
        dio: dio,
        settingsStore: _MemoryAISettingsStore(),
      );
      await service.saveSettings(
        const AIProviderSettings(
          provider: AIProviderType.custom,
          protocol: AIProtocolType.anthropic,
          apiKey: 'anthropic-key',
          baseUrl: 'https://gateway.example.com',
          model: 'private-reader-model',
          temperature: 0.7,
        ),
      );

      final answer = await service.chat(
        history: const [AIChatMessage(role: 'user', content: '解释这段文本')],
        pageText: '当前阅读页',
        meta: const AIRequestMeta(bookId: 'book', chapterId: 'chapter'),
      );

      expect(answer, '自定义协议已生效');
      expect(
        captured.uri.toString(),
        'https://gateway.example.com/v1/messages',
      );
      expect(captured.headers['x-api-key'], 'anthropic-key');
      final payload = captured.data as Map<String, dynamic>;
      expect(payload['model'], 'private-reader-model');
      expect(payload['system'], contains('中文阅读助手'));
      expect(payload['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '解释这段文本'},
          ],
        },
      ]);
    });
  });

  group('ReaderHttpAIService.chat transport errors', () {
    Future<ReaderHttpAIService> serviceFor(
      void Function(RequestOptions, RequestInterceptorHandler) respond,
    ) async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => respond(options, handler),
          ),
        );
      final service = ReaderHttpAIService(
        dio: dio,
        settingsStore: _MemoryAISettingsStore(),
      );
      await service.saveSettings(
        const AIProviderSettings(
          provider: AIProviderType.custom,
          protocol: AIProtocolType.openai,
          apiKey: 'test-key',
          baseUrl: 'https://gateway.example.com/v1',
          model: 'reader-model',
          temperature: 0.7,
        ),
      );
      return service;
    }

    Future<String> chat(ReaderHttpAIService service) => service.chat(
      history: const [AIChatMessage(role: 'user', content: '测试')],
      pageText: '正文',
      meta: const AIRequestMeta(bookId: 'book', chapterId: 'chapter'),
    );

    test('preserves empty response diagnostics', () async {
      final service = await serviceFor(
        (options, handler) => handler.resolve(
          Response<String>(requestOptions: options, statusCode: 200, data: ''),
        ),
      );

      await expectLater(
        chat(service),
        throwsA(
          isA<AIServiceException>().having(
            (error) => error.code,
            'code',
            'empty_response_error',
          ),
        ),
      );
    });

    test('preserves invalid JSON diagnostics', () async {
      final service = await serviceFor(
        (options, handler) => handler.resolve(
          Response<String>(
            requestOptions: options,
            statusCode: 200,
            data: '<html>gateway failure</html>',
          ),
        ),
      );

      await expectLater(
        chat(service),
        throwsA(
          isA<AIServiceException>()
              .having((error) => error.code, 'code', 'invalid_json_error')
              .having(
                (error) => error.snippet,
                'snippet',
                '<html>gateway failure</html>',
              ),
        ),
      );
    });

    test('preserves semantic empty assistant responses', () async {
      final service = await serviceFor(
        (options, handler) => handler.resolve(
          Response<String>(
            requestOptions: options,
            statusCode: 200,
            data: jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': ''},
                },
              ],
            }),
          ),
        ),
      );

      await expectLater(
        chat(service),
        throwsA(
          isA<AIServiceException>().having(
            (error) => error.code,
            'code',
            'empty_response',
          ),
        ),
      );
    });

    test('keeps provider HTTP errors on the shared translator path', () async {
      final service = await serviceFor((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 401,
              data: {
                'error': {'message': 'Invalid API key'},
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      });

      await expectLater(
        chat(service),
        throwsA(
          isA<AIServiceException>()
              .having(
                (error) => error.code,
                'code',
                'request_failed_provider_mismatch_hint',
              )
              .having((error) => error.status, 'status', '401'),
        ),
      );
    });
  });
}
