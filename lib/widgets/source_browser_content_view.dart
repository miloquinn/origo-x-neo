import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../book_sources/source_engine/source_browser_session.dart';

typedef SourceBrowserScriptRequestCallback =
    FutureOr<Object?> Function(String method, List<Object?> arguments);

String sourceBrowserContentChannelName(int viewId) =>
    'com.niki.xxread/source_browser_content/$viewId';

class SourceBrowserContentController {
  _SourceBrowserContentState? _state;
  SourceBrowserResult? _latestResult;

  bool get isAttached => _state != null;
  SourceBrowserResult? get latestResult => _latestResult;

  Future<void> reload() => _requireState().reload();

  Future<SourceBrowserResult> captureSession() =>
      _requireState().captureSession();

  Future<SourceBrowserResult> close() => _requireState().close();

  _SourceBrowserContentState _requireState() {
    final state = _state;
    if (state == null) {
      throw StateError('SourceBrowserContentController is not attached.');
    }
    return state;
  }
}

class SourceBrowserContentView extends StatefulWidget {
  const SourceBrowserContentView({
    super.key,
    required this.sourceId,
    required this.url,
    required this.headers,
    required this.session,
    this.sourceUrl,
    this.html,
    this.preloadJs,
    this.isDark = false,
    this.backgroundColor,
    this.textColor,
    this.controller,
    this.onLoadingChanged,
    this.onError,
    this.onCloseRequested,
    this.onRefreshContent,
    this.onToast,
    this.onScriptRequest,
  });

  static const viewType = 'com.niki.xxread/source_browser_content';

  final String sourceId;
  final Uri url;
  final Map<String, String> headers;
  final SourceBrowserSession session;
  final String? sourceUrl;
  final String? html;
  final String? preloadJs;
  final bool isDark;
  final Color? backgroundColor;
  final Color? textColor;
  final SourceBrowserContentController? controller;
  final ValueChanged<bool>? onLoadingChanged;
  final ValueChanged<String>? onError;
  final VoidCallback? onCloseRequested;
  final ValueChanged<String>? onRefreshContent;
  final ValueChanged<String>? onToast;
  final SourceBrowserScriptRequestCallback? onScriptRequest;

  @override
  State<SourceBrowserContentView> createState() => _SourceBrowserContentState();
}

class _SourceBrowserContentState extends State<SourceBrowserContentView> {
  MethodChannel? _channel;
  late SourceBrowserResult _latestResult;
  bool _unsupportedReported = false;

  Map<String, Object?> get _creationParams => {
    'sourceId': widget.sourceId,
    'sourceUrl': widget.sourceUrl ?? widget.url.origin,
    'url': widget.url.toString(),
    'headers': widget.headers,
    'session': widget.session.toJson(),
    'html': widget.html,
    'preloadJs': widget.preloadJs,
    'isDark': widget.isDark,
    'backgroundColor': widget.backgroundColor?.toARGB32(),
    'textColor': widget.textColor?.toARGB32(),
  };

  @override
  void initState() {
    super.initState();
    _latestResult = SourceBrowserResult(
      body: widget.html ?? '',
      finalUri: widget.url,
      session: widget.session,
    );
    widget.controller?._latestResult = _latestResult;
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant SourceBrowserContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._latestResult = _latestResult;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    final controller = widget.controller;
    if (controller?._state == this) controller?._state = null;
    final channel = _channel;
    if (channel != null) {
      unawaited(
        channel
            .invokeMethod<Object?>('close')
            .then((value) {
              final captured = SourceBrowserResult.fromPlatformMap(value);
              controller?._latestResult = captured;
            })
            .timeout(const Duration(seconds: 2))
            .catchError((Object _) => null),
      );
    }
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _unsupported();
    const codec = StandardMessageCodec();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: SourceBrowserContentView.viewType,
          creationParams: _creationParams,
          creationParamsCodec: codec,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: SourceBrowserContentView.viewType,
          creationParams: _creationParams,
          creationParamsCodec: codec,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.macOS:
        return AppKitView(
          viewType: SourceBrowserContentView.viewType,
          creationParams: _creationParams,
          creationParamsCodec: codec,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _unsupported();
    }
  }

  Widget _unsupported() {
    if (!_unsupportedReported) {
      _unsupportedReported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onLoadingChanged?.call(false);
        widget.onError?.call(
          'Embedded source browser is unavailable on this platform.',
        );
      });
    }
    return const SizedBox.shrink();
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel(sourceBrowserContentChannelName(id));
    _channel = channel;
    channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<Object?> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'loading':
        widget.onLoadingChanged?.call(call.arguments == true);
      case 'error':
        widget.onError?.call('${call.arguments ?? ''}');
      case 'closeRequested':
        widget.onCloseRequested?.call();
      case 'refreshContent':
        widget.onRefreshContent?.call('${call.arguments ?? ''}');
      case 'toast':
        widget.onToast?.call('${call.arguments ?? ''}');
      case 'copy':
        await Clipboard.setData(ClipboardData(text: '${call.arguments ?? ''}'));
      case 'sessionSnapshot':
        _cacheResult(SourceBrowserResult.fromPlatformMap(call.arguments));
      case 'scriptRequest':
        final raw = call.arguments;
        if (raw is! Map || widget.onScriptRequest == null) return null;
        final id = '${raw['id'] ?? ''}';
        final method = '${raw['methodName'] ?? raw['method'] ?? ''}';
        final arguments = raw['arguments'] is List
            ? List<Object?>.from(raw['arguments'] as List)
            : const <Object?>[];
        try {
          final result = await widget.onScriptRequest!(method, arguments);
          await _channel?.invokeMethod<void>('completeScriptRequest', {
            'id': id,
            'value': result,
          });
        } catch (error) {
          await _channel?.invokeMethod<void>('completeScriptRequest', {
            'id': id,
            'error': '$error',
          });
        }
    }
    return null;
  }

  Future<void> reload() async => _invoke<void>('reload');

  Future<SourceBrowserResult> captureSession() => _capture('capture');

  Future<SourceBrowserResult> close() => _capture('close');

  Future<SourceBrowserResult> _capture(String method) async {
    try {
      final captured = SourceBrowserResult.fromPlatformMap(
        await _invoke<Object?>(method).timeout(const Duration(seconds: 2)),
      );
      _cacheResult(captured);
      return captured;
    } catch (_) {
      return _latestResult;
    }
  }

  void _cacheResult(SourceBrowserResult result) {
    _latestResult = result;
    widget.controller?._latestResult = result;
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('The source browser view is not ready.');
    }
    return channel.invokeMethod<T>(method, arguments);
  }
}
