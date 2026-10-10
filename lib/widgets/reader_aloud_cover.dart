import 'package:flutter/material.dart';

import '../book_sources/caching/source_cover_cache.dart';
import '../core/reader/reader_aloud_controller.dart';
import '../models/book_cover_reference.dart';
import 'book_cover_image.dart';
import 'generated_book_cover.dart';

/// Renders the best available cover for the dedicated listening surface.
class ReaderAloudCover extends StatelessWidget {
  const ReaderAloudCover({
    super.key,
    required this.title,
    required this.fallbackAuthor,
    this.metadata,
    this.remoteCache,
  });

  final String title;
  final String fallbackAuthor;
  final ReaderAloudBookMetadata? metadata;

  /// Allows deterministic cache-backed rendering in widget tests.
  final SourceCoverCache? remoteCache;

  @override
  Widget build(BuildContext context) {
    final metadata = this.metadata;
    final metadataAuthor = metadata?.author.trim() ?? '';
    final fallback = GeneratedBookCover(
      title: title,
      author: metadataAuthor.isEmpty ? fallbackAuthor : metadataAuthor,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth =
            constraints.hasBoundedWidth && constraints.maxWidth > 0
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
            : null;
        return BookCoverImage(
          reference: BookCoverReference(
            localPath: metadata?.localCoverPath,
            remoteUrl: metadata?.remoteCoverUrl,
            remoteHeaders: metadata?.remoteCoverHeaders ?? const {},
          ),
          fallback: fallback,
          remoteCache: remoteCache,
          fit: BoxFit.cover,
          cacheWidth: decodeWidth,
        );
      },
    );
  }
}
