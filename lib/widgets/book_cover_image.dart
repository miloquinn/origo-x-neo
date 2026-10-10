import 'package:flutter/material.dart';

import '../book_sources/caching/source_cover_cache.dart';
import '../models/book_cover_reference.dart';
import 'book_cover_local_image.dart';
import 'source_cover_image.dart';

/// Shared local-to-remote cover fallback contract for runtime books.
class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.reference,
    required this.fallback,
    this.loadingPlaceholder,
    this.remoteCache,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.alignment = Alignment.center,
    this.gaplessPlayback = true,
  });

  final BookCoverReference reference;
  final Widget fallback;
  final Widget? loadingPlaceholder;
  final SourceCoverCache? remoteCache;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final AlignmentGeometry alignment;
  final bool gaplessPlayback;

  @override
  Widget build(BuildContext context) {
    final remote = _remoteOrFallback();
    final localPath = reference.localPath;
    if (localPath == null) return remote;
    return buildLocalBookCoverImage(
      path: localPath,
      fallback: remote,
      loadingPlaceholder: loadingPlaceholder ?? fallback,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
    );
  }

  Widget _remoteOrFallback() {
    final remoteUrl = reference.remoteUrl;
    if (remoteUrl == null) return fallback;
    return SourceCoverImage(
      url: remoteUrl,
      headers: reference.remoteHeaders,
      cache: remoteCache,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      alignment: alignment,
      fallback: fallback,
    );
  }
}
