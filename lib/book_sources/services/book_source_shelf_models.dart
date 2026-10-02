part of 'book_source_shelf_service.dart';

class OnlineShelfBookBinding {
  const OnlineShelfBookBinding({required this.source, required this.book});

  final RegisteredBookSource source;
  final BookSourceBook book;
}

class OnlineShelfBookBindingException implements Exception {
  const OnlineShelfBookBindingException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

enum SourceUpdateMode { appendNewChapters, refreshDownloadedChapters }

enum SourceUpdateStatus {
  noChanges,
  updated,
  baselineUnknown,
  needsConfirmation,
  conflicts,
}

class SourceUpdateResult {
  const SourceUpdateResult({
    required this.book,
    required this.status,
    required this.addedChapterCount,
    required this.refreshedChapterCount,
    required this.conflictCount,
    required this.materializedContentHash,
    required this.revisionOrigin,
  });

  final Book book;
  final SourceUpdateStatus status;
  final int addedChapterCount;
  final int refreshedChapterCount;
  final int conflictCount;
  final String materializedContentHash;
  final SourceRevisionOrigin revisionOrigin;
}

typedef SourceTxtRevisionCommitter =
    Future<Book> Function(Book book, TxtEditCommit commit);

Future<String> _readSourceUpdateText(Book book) async => compute(
  _decodeSourceUpdateText,
  (await File(book.filePath).readAsBytes(), book.textEncoding),
);

String _decodeSourceUpdateText((Uint8List, String?) input) {
  // Prefer lossless UTF-8, including files converted during a prior append.
  final encoding = EnhancedTxtImportService.normalizeEncoding(input.$2);
  if (!encoding.startsWith('utf16')) {
    try {
      return utf8.decode(input.$1);
    } on FormatException {
      /* Legacy TXT. */
    }
  }
  final result = EnhancedTxtImportService().decodeWithResult(
    input.$1,
    encodingOverride: input.$2,
  );
  if (result.content.contains('\uFFFD')) {
    throw const FormatException(
      'Local TXT encoding must be resolved before updating.',
    );
  }
  return result.content;
}
