import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../book_sources/services/book_download_cancellation.dart';
import '../book_sources/source_engine/scripting/source_script_contract.dart';
import '../book_sources/source_engine/source_browser_session.dart';
import '../utils/localization_extension.dart';
import '../utils/glass_material.dart';
import '../utils/reader_themes.dart';
import 'glass_bottom_sheet.dart';
import 'glass_buttons.dart';
import 'side_toast.dart';
import 'source_browser_content_view.dart';

/// The reader owns the panel and its appearance; the source owns its comments.
Future<SourceBrowserResult> showReaderParagraphReviewSheet(
  BuildContext context, {
  required ReaderThemePalette palette,
  required String sourceId,
  required String sourceName,
  String? sourceUrl,
  required SourceScriptInteractionRequest request,
  required BookDownloadCancellation cancellation,
  required SourceBrowserScriptRequestCallback onScriptRequest,
  ValueChanged<String>? onRefreshContent,
  VoidCallback? onClosing,
  WidgetBuilder? contentBuilder,
}) async {
  final controller = SourceBrowserContentController();
  final presentation = ReaderParagraphReviewPresentation.fromConfig(
    request.config,
  );
  final fallback = SourceBrowserResult(
    body: request.html ?? '',
    finalUri: Uri.parse(request.url),
    session: request.browserSession,
  );
  final result = await showGlassBottomSheet<SourceBrowserResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: presentation.dismissOnTouchOutside,
    enableDrag: presentation.isDraggable,
    backgroundColor: palette.surface,
    theme: palette.toThemeData(parentTheme: Theme.of(context)),
    builder: (_) => ReaderParagraphReviewSheet(
      palette: palette,
      sourceId: sourceId,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      request: request,
      controller: controller,
      cancellation: cancellation,
      onScriptRequest: onScriptRequest,
      onRefreshContent: onRefreshContent,
      onClosing: onClosing,
      presentation: presentation,
      contentBuilder: contentBuilder,
    ),
  );
  if (result != null) return result;
  // Barrier and drag dismissal can finish before native view disposal. Capture
  // while it is attached; otherwise keep the last source-scoped snapshot.
  if (controller.isAttached) {
    try {
      return await controller.captureSession().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      // Closing comments must never discard the latest available session.
    }
  }
  return controller.latestResult ?? fallback;
}

class ReaderParagraphReviewSheet extends StatefulWidget {
  const ReaderParagraphReviewSheet({
    super.key,
    required this.palette,
    required this.sourceId,
    required this.sourceName,
    this.sourceUrl,
    required this.request,
    required this.controller,
    required this.cancellation,
    required this.onScriptRequest,
    this.onRefreshContent,
    this.contentBuilder,
    this.onClosing,
    this.presentation = const ReaderParagraphReviewPresentation(),
  });

  final ReaderThemePalette palette;
  final String sourceId;
  final String sourceName;
  final String? sourceUrl;
  final SourceScriptInteractionRequest request;
  final SourceBrowserContentController controller;
  final BookDownloadCancellation cancellation;
  final SourceBrowserScriptRequestCallback onScriptRequest;
  final ValueChanged<String>? onRefreshContent;
  final WidgetBuilder? contentBuilder;
  final VoidCallback? onClosing;
  final ReaderParagraphReviewPresentation presentation;

  @override
  State<ReaderParagraphReviewSheet> createState() =>
      _ReaderParagraphReviewSheetState();
}

class _ReaderParagraphReviewSheetState
    extends State<ReaderParagraphReviewSheet> {
  bool _loading = true;
  bool _failed = false;
  bool _closing = false;
  bool _allowPop = false;
  bool _notifiedClosing = false;

  void _notifyClosing() {
    if (_notifiedClosing) return;
    _notifiedClosing = true;
    widget.onClosing?.call();
  }

  @override
  void initState() {
    super.initState();
    widget.cancellation.addListener(_cancel);
  }

  @override
  void dispose() {
    _notifyClosing();
    widget.cancellation.removeListener(_cancel);
    super.dispose();
  }

  void _cancel() {
    if (!mounted) return;
    scheduleMicrotask(() {
      if (mounted) unawaited(_close());
    });
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _notifyClosing();
    SourceBrowserResult? result;
    if (widget.controller.isAttached) {
      try {
        result = await widget.controller.close().timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {
        result = widget.controller.latestResult;
      }
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(result);
  }

  Future<void> _reload() async {
    if (_closing || !widget.controller.isAttached) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await widget.controller.reload();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final material = GlassMaterial.resolve(
      context,
      role: GlassSurfaceRole.panel,
      color: palette.surface,
      brightness: palette.brightness,
    );
    final height = math.max(
      0.0,
      MediaQuery.sizeOf(context).height * widget.presentation.heightFraction -
          MediaQuery.viewInsetsOf(context).bottom,
    );
    return PopScope<SourceBrowserResult>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _notifyClosing();
        if (!didPop) unawaited(_close());
      },
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.readerParagraphReviews,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    key: const ValueKey('paragraph-reviews-reload'),
                    tooltip: context.l10n.bookSourcesRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    color: palette.controlBar,
                    foregroundColor: palette.text,
                    brightness: palette.brightness,
                    onPressed: _reload,
                  ),
                  const SizedBox(width: 6),
                  GlassIconButton(
                    key: const ValueKey('paragraph-reviews-close'),
                    tooltip: context.l10n.bookSourcesClose,
                    icon: const Icon(Icons.close_rounded),
                    color: palette.controlBar,
                    foregroundColor: palette.text,
                    brightness: palette.brightness,
                    onPressed: _close,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.contentBuilder?.call(context) ??
                      SourceBrowserContentView(
                        sourceId: widget.sourceId,
                        sourceUrl: widget.sourceUrl,
                        url: Uri.parse(widget.request.url),
                        html: widget.request.html,
                        preloadJs: widget.request.preloadJs,
                        headers: widget.request.headers,
                        session: widget.request.browserSession,
                        isDark: palette.brightness == Brightness.dark,
                        backgroundColor:
                            material.mode == GlassMaterialMode.solid
                            ? palette.surface
                            : Colors.transparent,
                        textColor: palette.text,
                        controller: widget.controller,
                        onLoadingChanged: (value) {
                          if (mounted) setState(() => _loading = value);
                        },
                        onError: (_) {
                          if (mounted) {
                            setState(() {
                              _loading = false;
                              _failed = true;
                            });
                          }
                        },
                        onCloseRequested: () => unawaited(_close()),
                        onRefreshContent: widget.onRefreshContent,
                        onScriptRequest: widget.onScriptRequest,
                        onToast: (message) => showSideToast(context, message),
                      ),
                  if (_loading && widget.contentBuilder == null)
                    const Center(child: CircularProgressIndicator()),
                  if (_failed)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.readerParagraphReviewFailed,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Source geometry is bounded by the app's shared shell and safe areas.
/// Android-only corner colors, radii and window flags are intentionally absent.
class ReaderParagraphReviewPresentation {
  const ReaderParagraphReviewPresentation({
    this.heightFraction = 0.78,
    this.dismissOnTouchOutside = true,
    this.isDraggable = true,
  });

  final double heightFraction;
  final bool dismissOnTouchOutside;
  final bool isDraggable;

  factory ReaderParagraphReviewPresentation.fromConfig(String? config) {
    Object? value;
    try {
      value = config == null ? null : jsonDecode(config);
    } catch (_) {}
    if (value is! Map) return const ReaderParagraphReviewPresentation();
    final percentage = value['heightPercentage'];
    final fraction =
        percentage is num &&
            percentage.isFinite &&
            percentage >= 0 &&
            percentage <= 1
        ? percentage.toDouble().clamp(0.25, 0.95)
        : 0.78;
    return ReaderParagraphReviewPresentation(
      heightFraction: fraction,
      dismissOnTouchOutside: value['dismissOnTouchOutside'] != false,
      isDraggable: value['isDraggable'] != false,
    );
  }
}
