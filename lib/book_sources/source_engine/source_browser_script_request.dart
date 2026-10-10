import 'dart:convert';

/// Builds the source-runtime callback used by Legado-compatible browser pages.
///
/// Legado's asynchronous web bridge resolves callback values as strings. Keep
/// that boundary here instead of exposing runtime-native JavaScript values to
/// the page, which would turn numbers and booleans into different JS types.
abstract final class SourceBrowserScriptRequestEvaluator {
  static final RegExp _methodPattern = RegExp(
    r'^(java|source|cache)\.[A-Za-z][A-Za-z0-9_]*$',
  );

  static String scriptFor(String method, List<Object?> arguments) {
    if (method == 'eval' || method == 'run') {
      if (arguments.isEmpty || arguments.first is! String) {
        throw ArgumentError('A source script is required.');
      }
      return 'String(eval(${jsonEncode(arguments.first)}))';
    }
    if (const {'decryptStr', 'encryptBase64', 'encryptHex'}.contains(method)) {
      if (arguments.length < 4) {
        throw ArgumentError(
          '$method requires transformation, key, iv, and data.',
        );
      }
      final cryptoArguments = arguments.take(3).map(jsonEncode).join(',');
      return 'String(java.createSymmetricCrypto($cryptoArguments).$method('
          '${jsonEncode(arguments[3])}))';
    }
    if (!_methodPattern.hasMatch(method)) {
      throw UnsupportedError('Unsupported source page method: $method');
    }
    final parameters = arguments.map(jsonEncode).join(',');
    return switch (method) {
      // The native WebJsExtensions bridge exposes the response representation
      // for connectAwait, while getAwait/postAwait resolve the response body
      // and headAwait resolves the response headers as JSON.
      'java.connect' => 'JSON.stringify(java.connect($parameters))',
      'java.get' => _getScript(arguments),
      'java.post' => 'String(java.post($parameters).body())',
      'java.head' => 'JSON.stringify(java.head($parameters).headers())',
      _ => 'String($method($parameters))',
    };
  }

  static String resultFrom(String value) => value;

  static String _getScript(List<Object?> arguments) {
    final compatible = arguments.length > 1
        ? arguments
        : <Object?>[...arguments, null];
    final parameters = compatible.map(jsonEncode).join(',');
    return 'String(java.get($parameters).body())';
  }
}
