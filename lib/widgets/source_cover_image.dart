import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../book_sources/caching/source_cover_cache.dart';
import 'image_decode_retry_controller.dart';

class SourceCoverImage extends StatefulWidget {
  const SourceCoverImage({
    super.key,
    required this.url,
    required this.fallback,
    this.cache,
    this.headers = const {},
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.alignment = Alignment.center,
  });

  final Uri url;
  final Widget fallback;
  final SourceCoverCache? cache;
  final Map<String, String> headers;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final AlignmentGeometry alignment;

  @override
  State<SourceCoverImage> createState() => _SourceCoverImageState();
}

class _SourceCoverImageState extends State<SourceCoverImage> {
  late Future<Uint8List> _bytes;
  final _decodeRetry = ImageDecodeRetryController();

  SourceCoverCache get _cache => widget.cache ?? SourceCoverCache.instance;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant SourceCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.cache != widget.cache ||
        !mapEquals(oldWidget.headers, widget.headers)) {
      _decodeRetry.reset();
      _bytes = _load();
    }
  }

  Future<Uint8List> _load() {
    final cached = _cache.peek(widget.url, headers: widget.headers);
    // A memory-cache hit resolves synchronously so the first frame paints the
    // cover instead of flashing the placeholder for one frame. Awaiting the
    // same bytes through the cache's future always costs that frame.
    if (cached != null) return SynchronousFuture<Uint8List>(cached);
    return _cache.load(widget.url, headers: widget.headers);
  }

  void _retryAfterDecodeFailure() {
    _decodeRetry.schedule(
      isMounted: () => mounted,
      evict: () => _cache.evict(widget.url, headers: widget.headers),
      reload: () {
        setState(() {
          _bytes = _load();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            // Bytes arriving is not the same as a decoded frame arriving.
            // Keep the placeholder underneath until the image can paint, then
            // fade the image in once without fading the placeholder out first.
            return Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(child: widget.fallback),
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ],
            );
          },
          errorBuilder: (_, _, _) {
            _retryAfterDecodeFailure();
            return widget.fallback;
          },
        );
      },
    );
  }
}
