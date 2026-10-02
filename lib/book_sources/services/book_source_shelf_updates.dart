part of 'book_source_shelf_service.dart';

extension _BookSourceShelfUpdates on BookSourceShelfService {
  Future<SourceUpdateResult> _appendNewChapters({
    required Book shelfBook,
    required OnlineShelfBookBinding binding,
    required SourceChapterState state,
    required List<BookSourceChapter> catalog,
    required void Function(int completed, int total)? onProgress,
    required BookDownloadCancellation? cancellation,
  }) async {
    final trackedIds = state.catalogChapterIds;
    if (catalog.length < trackedIds.length ||
        catalog
                .take(trackedIds.length)
                .map((c) => c.id)
                .toList()
                .join('\u0000') !=
            trackedIds.join('\u0000')) {
      return _unchangedResult(
        shelfBook,
        state,
        SourceUpdateStatus.needsConfirmation,
      );
    }
    final additions = catalog.skip(trackedIds.length).toList(growable: false);
    if (additions.isEmpty) {
      return _unchangedResult(shelfBook, state, SourceUpdateStatus.noChanges);
    }
    final added = <TrackedSourceChapter>[];
    onProgress?.call(0, additions.length);
    for (var index = 0; index < additions.length; index++) {
      cancellation?.throwIfCancelled();
      final chapter = additions[index];
      final content = await _client.getChapterContentForDownload(
        binding.source,
        bookId: binding.book.id,
        chapterId: chapter.id,
        sourceVariables: _chapterVariables(
          binding.book,
          chapter,
          trackedIds.length + index,
        ),
        cancellation: cancellation,
      );
      final body = _plainText(content);
      final hash = SourceChapterStateStore.hashText(body);
      final baselineAsset = await _sourceChapterStateStore.writeConflictAsset(
        book: shelfBook,
        conflictId: 'baseline-${trackedIds.length + index}-${chapter.id}',
        label: 'source',
        title: chapter.title,
        body: body,
      );
      added.add(
        TrackedSourceChapter(
          sourceChapterId: chapter.id,
          ordinal: trackedIds.length + index,
          title: chapter.title,
          sourceMarker: chapter.updatedAt?.toUtc().toIso8601String(),
          baselineHash: hash,
          currentHash: hash,
          body: body,
          userModified: false,
          baselineAsset: baselineAsset,
        ),
      );
      onProgress?.call(index + 1, additions.length);
    }
    final chapters = [...state.chapters, ...added];
    return _commitSourceRevision(
      shelfBook: shelfBook,
      state: state.copyWith(
        baselineKnown: state.baselineKnown,
        chapters: chapters,
        catalogChapterIds: [
          ...trackedIds,
          ...additions.map((value) => value.id),
        ],
        revisionOrigin: SourceRevisionOrigin.sourceAppend,
      ),
      chapters: chapters,
      addedChapterCount: added.length,
      refreshedChapterCount: 0,
      invalidateAllReferences: false,
    );
  }

  Future<SourceUpdateResult> _refreshDownloadedChapters({
    required Book shelfBook,
    required OnlineShelfBookBinding binding,
    required SourceChapterState state,
    required List<BookSourceChapter> catalog,
    required void Function(int completed, int total)? onProgress,
    required BookDownloadCancellation? cancellation,
  }) async {
    final byId = {for (final chapter in catalog) chapter.id: chapter};
    final next = [...state.chapters];
    final conflicts = [...state.conflicts];
    var refreshed = 0;
    onProgress?.call(0, state.chapters.length);
    for (var index = 0; index < state.chapters.length; index++) {
      cancellation?.throwIfCancelled();
      final tracked = state.chapters[index];
      final chapter = byId[tracked.sourceChapterId];
      if (chapter == null) {
        return _unchangedResult(
          shelfBook,
          state,
          SourceUpdateStatus.needsConfirmation,
        );
      }
      final content = await _client.getChapterContentForDownload(
        binding.source,
        bookId: binding.book.id,
        chapterId: chapter.id,
        sourceVariables: _chapterVariables(binding.book, chapter, index),
        cancellation: cancellation,
      );
      final sourceBody = _plainText(content);
      final sourceHash = SourceChapterStateStore.hashText(sourceBody);
      if (sourceHash != tracked.baselineHash) {
        if (tracked.userModified ||
            tracked.currentHash != tracked.baselineHash) {
          final alreadyOpen = conflicts.any(
            (value) =>
                value.sourceChapterId == tracked.sourceChapterId &&
                value.resolution == null,
          );
          if (alreadyOpen) {
            onProgress?.call(index + 1, state.chapters.length);
            continue;
          }
          final conflictId =
              '${DateTime.now().microsecondsSinceEpoch}-${tracked.sourceChapterId}';
          final baselineBody = tracked.baselineAsset == null
              ? ''
              : _bodyFromReadableChapter(
                  await _sourceChapterStateStore.readAsset(
                    shelfBook,
                    tracked.baselineAsset!,
                  ),
                );
          final baselineAsset = await _sourceChapterStateStore
              .writeConflictAsset(
                book: shelfBook,
                conflictId: conflictId,
                label: 'baseline',
                title: tracked.title,
                body: baselineBody,
              );
          final localAsset = await _sourceChapterStateStore.writeConflictAsset(
            book: shelfBook,
            conflictId: conflictId,
            label: 'local',
            title: tracked.title,
            body: tracked.body,
          );
          final sourceAsset = await _sourceChapterStateStore.writeConflictAsset(
            book: shelfBook,
            conflictId: conflictId,
            label: 'source',
            title: chapter.title,
            body: sourceBody,
          );
          conflicts.add(
            SourceContentConflict(
              id: conflictId,
              sourceChapterId: tracked.sourceChapterId,
              baselineAsset: baselineAsset,
              localAsset: localAsset,
              sourceAsset: sourceAsset,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        } else {
          final baselineAsset = await _sourceChapterStateStore
              .writeConflictAsset(
                book: shelfBook,
                conflictId: 'baseline-$index-${chapter.id}-$sourceHash',
                label: 'source',
                title: chapter.title,
                body: sourceBody,
              );
          next[index] = tracked.copyWith(
            title: chapter.title,
            sourceMarker: chapter.updatedAt?.toUtc().toIso8601String(),
            baselineHash: sourceHash,
            currentHash: sourceHash,
            body: sourceBody,
            userModified: false,
            baselineAsset: baselineAsset,
          );
          refreshed++;
        }
      }
      onProgress?.call(index + 1, state.chapters.length);
    }
    final unresolved = conflicts
        .where((conflict) => conflict.resolution == null)
        .length;
    if (refreshed == 0) {
      final nextState = state.copyWith(
        conflicts: conflicts,
        revisionOrigin: SourceRevisionOrigin.sourceRefresh,
      );
      await _sourceChapterStateStore.save(shelfBook, nextState);
      LibraryEventBus().notifyLibraryChanged();
      _notifySourceSidecarChanged(shelfBook, nextState.materializedContentHash);
      return _unchangedResult(
        shelfBook,
        nextState,
        unresolved > 0
            ? SourceUpdateStatus.conflicts
            : SourceUpdateStatus.noChanges,
      );
    }
    return _commitSourceRevision(
      shelfBook: shelfBook,
      state: state.copyWith(
        chapters: next,
        conflicts: conflicts,
        revisionOrigin: SourceRevisionOrigin.sourceRefresh,
      ),
      chapters: next,
      addedChapterCount: 0,
      refreshedChapterCount: refreshed,
      invalidateAllReferences: true,
    );
  }

  Future<SourceUpdateResult> _commitSourceRevision({
    required Book shelfBook,
    required SourceChapterState state,
    required List<TrackedSourceChapter> chapters,
    required int addedChapterCount,
    required int refreshedChapterCount,
    required bool invalidateAllReferences,
  }) async {
    // Prefix boundaries describe the file on disk, not the next revision.
    final previousState =
        await recoverDownloadedSourceBinding(shelfBook) ?? state;
    final content = await _materializeWithPreservedPrefix(
      shelfBook,
      previousState,
      chapters,
    );
    late Book updatedBook;
    late SourceChapterState committedState;
    final commit = await _txtEditService.replaceContent(
      book: shelfBook,
      content: content,
      expectedBaseContentHash: state.materializedContentHash,
      invalidateAllReferences: invalidateAllReferences,
      preserveReferenceOffsets:
          addedChapterCount > 0 && !invalidateAllReferences,
      onCommitted: (revision) async {
        committedState = state.copyWith(
          materializedContentHash: revision.contentHash,
          chapters: chapters,
        );
        await _sourceChapterStateStore.save(shelfBook, committedState);
        try {
          updatedBook = await _revisionCommitter(shelfBook, revision);
        } catch (_) {
          await _sourceChapterStateStore.save(shelfBook, previousState);
          rethrow;
        }
      },
    );
    if (addedChapterCount > 0) {
      final previousInfo = SourceBookUpdateInfo.fromBook(updatedBook);
      final sourceDates =
          chapters
              .map((chapter) => DateTime.tryParse(chapter.sourceMarker ?? ''))
              .nonNulls
              .toList()
            ..sort();
      final checkedAt = DateTime.now().toUtc();
      final info = SourceBookUpdateInfo(
        status: SourceBookCheckStatus.current,
        checkedAt: checkedAt,
        updatedAt: sourceDates.isNotEmpty
            ? sourceDates.last
            : previousInfo.updatedAt ?? checkedAt,
        chapterCount: committedState.catalogChapterIds.length,
        latestChapterId: chapters.last.sourceChapterId,
        latestChapter: chapters.last.title,
      );
      try {
        final metadata = info.encodeInto(updatedBook);
        if (await _bookDao.updateSourceBookMetadata(updatedBook, metadata)) {
          updatedBook = updatedBook.copyWith(sourceBookJson: metadata);
        }
      } catch (error) {
        // The text revision is already committed; a status write must not
        // turn a successful download into a failed task. Recheck on refresh.
        debugPrint('Persist source update status failed: $error');
      }
    }
    LibraryEventBus().notifyLibraryChanged();
    TxtContentChangeBus.instance.notify(
      TxtContentChanged(
        book: updatedBook,
        contentHash: commit.contentHash,
        modifiedAt: commit.modifiedAt,
        origin: TxtContentChangeOrigin.localEdit,
      ),
    );
    final unresolved = committedState.conflicts
        .where((c) => c.resolution == null)
        .length;
    return SourceUpdateResult(
      book: updatedBook,
      status: unresolved > 0
          ? SourceUpdateStatus.conflicts
          : SourceUpdateStatus.updated,
      addedChapterCount: addedChapterCount,
      refreshedChapterCount: refreshedChapterCount,
      conflictCount: unresolved,
      materializedContentHash: commit.contentHash,
      revisionOrigin: committedState.revisionOrigin,
    );
  }

  SourceUpdateResult _unchangedResult(
    Book book,
    SourceChapterState state,
    SourceUpdateStatus status,
  ) => SourceUpdateResult(
    book: book,
    status: status,
    addedChapterCount: 0,
    refreshedChapterCount: 0,
    conflictCount: state.conflicts.where((c) => c.resolution == null).length,
    materializedContentHash: state.materializedContentHash,
    revisionOrigin: state.revisionOrigin,
  );

  List<TrackedSourceChapter>? _reconcileEditedContent(
    String content,
    List<TrackedSourceChapter> chapters,
  ) {
    if (chapters.isEmpty) return null;
    final bodies = <String>[];
    final firstHeader = '${chapters.first.title}\n\n';
    final firstStart = content.indexOf(firstHeader);
    // Untracked text must never disappear when a source revision is rebuilt.
    if (firstStart != 0) return null;
    var bodyStart = firstStart + firstHeader.length;
    for (var index = 0; index < chapters.length; index++) {
      final end = index + 1 == chapters.length
          ? content.length
          : content.indexOf(
              '\n\n\n${chapters[index + 1].title}\n\n',
              bodyStart,
            );
      if (end < 0) return null;
      if (index + 1 < chapters.length) {
        final separator = '\n\n\n${chapters[index + 1].title}\n\n';
        if (content.indexOf(separator, end + separator.length) >= 0) {
          return null;
        }
      }
      bodies.add(
        content.substring(bodyStart, end).replaceFirst(RegExp(r'\n\n\n$'), ''),
      );
      if (index + 1 < chapters.length) {
        bodyStart = end + '\n\n\n${chapters[index + 1].title}\n\n'.length;
      }
    }
    final reconciled = chapters
        .asMap()
        .entries
        .map((entry) {
          final body = bodies[entry.key].replaceFirst(RegExp(r'\n+$'), '');
          final hash = SourceChapterStateStore.hashText(body);
          return entry.value.copyWith(
            body: body,
            currentHash: hash,
            userModified: hash != entry.value.baselineHash,
          );
        })
        .toList(growable: false);
    // Accept a mapping only when it reconstructs every character exactly.
    return SourceChapterStateStore.materialize(reconciled) == content
        ? reconciled
        : null;
  }

  Future<String> _materializeWithPreservedPrefix(
    Book book,
    SourceChapterState previous,
    List<TrackedSourceChapter> chapters,
  ) async {
    final untrackedCount =
        previous.catalogChapterIds.length - previous.chapters.length;
    if (untrackedCount <= 0) {
      return SourceChapterStateStore.materialize(chapters);
    }
    final current = await _readSourceUpdateText(book);
    String prefix;
    if (previous.chapters.isEmpty) {
      prefix = current;
    } else {
      final trackedSuffix = SourceChapterStateStore.materialize(
        previous.chapters,
      );
      if (!current.endsWith(trackedSuffix)) {
        throw const BookSourceProtocolException(
          'Downloaded chapter boundaries no longer match the local text.',
        );
      }
      prefix = current.substring(0, current.length - trackedSuffix.length);
    }
    final separator = prefix.endsWith('\n\n\n') ? '' : '\n\n\n';
    return '$prefix$separator${SourceChapterStateStore.materialize(chapters)}';
  }

  Map<String, String> _chapterVariables(
    BookSourceBook book,
    BookSourceChapter chapter,
    int chapterIndex,
  ) => {
    ...book.sourceVariables,
    'chapterIndex': '$chapterIndex',
    'chapterTitle': chapter.title,
    'bookName': book.title,
    'bookAuthor': book.author,
    'bookType': '${book.type}',
  };

  String _bodyFromReadableChapter(String value) {
    final separator = value.indexOf('\n\n');
    return (separator < 0 ? value : value.substring(separator + 2)).trimRight();
  }

  String _resolvedBookUid(Book book, String? explicit) {
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
    if (book.id != null) return 'local-book-${book.id}';
    return sha256.convert(utf8.encode(book.filePath)).toString();
  }

  void _notifySourceSidecarChanged(Book book, String contentHash) {
    final modified = File(book.filePath).lastModifiedSync();
    TxtContentChangeBus.instance.notify(
      TxtContentChanged(
        book: book,
        contentHash: contentHash,
        modifiedAt: modified,
        origin: TxtContentChangeOrigin.localEdit,
      ),
    );
  }
}
