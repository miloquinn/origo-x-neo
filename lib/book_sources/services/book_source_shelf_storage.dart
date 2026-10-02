part of 'book_source_shelf_service.dart';

extension _BookSourceShelfStorage on BookSourceShelfService {
  Future<void> _persistOnlineCover(
    RegisteredBookSource source,
    BookSourceBook book,
    int shelfBookId,
  ) async {
    try {
      final coverPath = await _storedCoverPath(source, book);
      if (coverPath == null) return;
      await _bookDao.updateBookCoverPath(shelfBookId, coverPath);
      LibraryEventBus().notifyLibraryChanged();
    } catch (_) {
      // Cover persistence is best effort and must not affect shelf creation.
    }
  }

  SourceChapterState _reboundSourceState(
    SourceChapterState state, {
    required String sourceId,
    required String sourceBookId,
  }) => state.copyWith(
    sourceId: sourceId,
    sourceBookId: sourceBookId,
    baselineKnown: false,
    chapters: const [],
    catalogChapterIds: const [],
    conflicts: const [],
    revisionOrigin: SourceRevisionOrigin.sourceRebind,
  );

  Future<void> _persistReboundCover(
    RegisteredBookSource source,
    BookSourceBook book,
    int shelfBookId,
    String? expectedCoverImagePath,
  ) async {
    try {
      final coverPath = await _storedCoverPath(source, book);
      if (coverPath == null) return;
      final applied = await _bookDao.updateBookCoverPathIfSource(
        bookId: shelfBookId,
        sourceId: source.id,
        sourceBookId: book.id,
        expectedCoverImagePath: expectedCoverImagePath,
        coverImagePath: coverPath,
      );
      if (applied) LibraryEventBus().notifyLibraryChanged();
    } catch (_) {
      // A source change is complete even when its non-critical cover fails.
    }
  }

  Future<void> _saveInitialSourceState(
    Book downloaded, {
    required String? bookUid,
    required RegisteredBookSource source,
    required BookSourceBook sourceBook,
    required List<TrackedSourceChapter> chapters,
  }) async {
    final withAssets = <TrackedSourceChapter>[];
    for (final chapter in chapters) {
      final asset = await _sourceChapterStateStore.writeConflictAsset(
        book: downloaded,
        conflictId: 'baseline-${chapter.ordinal}-${chapter.sourceChapterId}',
        label: 'source',
        title: chapter.title,
        body: chapter.body,
      );
      withAssets.add(chapter.copyWith(baselineAsset: asset));
    }
    final hash = await SourceChapterStateStore.hashFile(
      File(downloaded.filePath),
    );
    await _sourceChapterStateStore.save(
      downloaded,
      SourceChapterState(
        schemaVersion: 1,
        bookUid: _resolvedBookUid(downloaded, bookUid),
        sourceId: source.id,
        sourceBookId: sourceBook.id,
        materializedContentHash: hash,
        baselineKnown: true,
        chapters: withAssets,
        catalogChapterIds: withAssets
            .map((chapter) => chapter.sourceChapterId)
            .toList(growable: false),
        conflicts: const [],
        revisionOrigin: SourceRevisionOrigin.initialDownload,
      ),
    );
    _notifySourceSidecarChanged(downloaded, hash);
  }

  /// Establishes an explicit catalog boundary for a legacy local download.
  /// The readable text is retained byte-for-byte. Existing chapters have no
  /// trusted source baseline, so a later refresh produces candidates instead
  /// of replacing them; chapters after [lastDownloadedChapterId] may be safely
  /// appended.

  Map<String, dynamic> _storedJsonObject(String? raw, String label) {
    if (raw == null || raw.trim().isEmpty) {
      throw BookSourceProtocolException(
        'Stored online book is missing $label.',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw BookSourceProtocolException(
        'Stored online book $label must be a JSON object.',
      );
    }
    return decoded.map((key, value) => MapEntry('$key', value));
  }

  String _safeFileName(String value) {
    final safe = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return safe.isEmpty ? 'book' : safe.substring(0, safe.length.clamp(0, 80));
  }

  String _downloadIdentity(RegisteredBookSource source, BookSourceBook book) =>
      sha256
          .convert(utf8.encode('${source.id}\u0000${book.id}'))
          .toString()
          .substring(0, 20);

  Future<void> _commitDownloadedFile(File temporary, File destination) async {
    final backup = File('${destination.path}.backup');
    final hadDestination = await destination.exists();
    if (await backup.exists()) await backup.delete();
    try {
      if (hadDestination) await destination.rename(backup.path);
      await temporary.rename(destination.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await destination.exists() && await backup.exists()) {
        await backup.rename(destination.path);
      }
      rethrow;
    }
  }

  String _plainText(BookSourceChapterContent content) {
    if (content.contentType != 'text/html') return content.content.trim();
    final fragment = html_parser.parseFragment(content.content);
    final paragraphs = <String>[];

    void visit(dom.Node node) {
      if (node is dom.Element &&
          const {'p', 'div', 'li', 'blockquote'}.contains(node.localName)) {
        final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isNotEmpty) paragraphs.add(text);
        return;
      }
      for (final child in node.nodes) {
        visit(child);
      }
    }

    for (final node in fragment.nodes) {
      visit(node);
    }
    return paragraphs.isEmpty
        ? (fragment.text ?? '').trim()
        : paragraphs.join('\n');
  }

  Future<String?> _storedCoverPath(
    RegisteredBookSource source,
    BookSourceBook book,
  ) async {
    try {
      final documents =
          _downloadDirectory ?? await getApplicationDocumentsDirectory();
      if (book.coverUrl != null) {
        final bytes = await _sourceCoverCache.load(
          book.coverUrl!,
          headers: book.coverHeaders,
        );
        return await CoverGenerator.saveCover(
          bytes,
          '${source.id}_${book.id}',
          documentsDirectory: documents,
          fileTag: 'source',
          fileExtension: 'img',
        );
      }
      final bytes = await CoverGenerator.generateTextCover(
        title: book.title,
        author: book.author,
      );
      return await CoverGenerator.saveCover(
        bytes,
        '${source.id}_${book.id}.png',
        documentsDirectory: documents,
      );
    } catch (_) {
      // 持久化失败不应阻止用户加入书架；UI 会继续使用同一绘制器实时兜底。
      return null;
    }
  }
}
