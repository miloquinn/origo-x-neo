// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/books/enhanced_txt_import_service.dart';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../../models/book.dart';
import '../../services/books/book_cover_edit_service.dart';
import '../../services/books/book_dao.dart';
import '../../services/books/cover_generator_service.dart';
import '../../services/books/txt_edit_service.dart';
import '../../services/books/txt_edit_reference_service.dart';
import '../../services/books/txt_content_change_bus.dart';
import '../../services/library/library_event_bus_service.dart';
import '../models/registered_book_source.dart';
import '../models/source_book_update_info.dart';
import '../protocol/book_source_protocol.dart';
import 'book_download_cancellation.dart';
import 'book_source_client.dart';
import 'book_source_reading_progress.dart';
import 'source_chapter_state.dart';
import '../caching/source_cover_cache.dart';

part 'book_source_shelf_models.dart';
part 'book_source_shelf_storage.dart';
part 'book_source_shelf_updates.dart';

class BookSourceShelfService {
  static const int _downloadBatchSize = 3;

  /// 在线书源书籍的进度编码单位：currentPage/totalPages 存储的是
  /// "章节序号 * unitsPerChapter + 章内进度"，而不是真实页码。
  /// UI 展示总量/当前值时需要除以该常量换算回章节数，避免把它当作页数显示。
  static const int unitsPerChapter = 1000;

  /// Repairs books downloaded by versions that changed `storage_type` to
  /// local but left `currentPage` in online chapter-unit encoding.
  static Book repairLegacyDownloadedProgress(Book book) {
    final normalizedProgress = book.readingProgress;
    if (book.isOnline ||
        book.format.toLowerCase() != 'txt' ||
        book.sourceId == null ||
        book.sourceBookId == null ||
        book.totalPages <= 0 ||
        book.currentPage <= 0 ||
        normalizedProgress == null ||
        (book.lastCanonicalLocator?.trim().isNotEmpty ?? false)) {
      return book;
    }
    final localEstimate = book.currentPage / book.totalPages;
    final encodedEstimate =
        book.currentPage / (book.totalPages * unitsPerChapter);
    final localDistance = (normalizedProgress - localEstimate).abs();
    final encodedDistance = (normalizedProgress - encodedEstimate).abs();
    if (encodedDistance + 0.000001 >= localDistance) return book;
    final chapterIndex = (book.currentPage ~/ unitsPerChapter).clamp(
      0,
      book.totalPages - 1,
    );
    return book.copyWith(currentPage: chapterIndex);
  }

  BookSourceShelfService({
    BookDao? bookDao,
    BookSourceClient? client,
    BookSourceClient Function()? clientFactory,
    SourceCoverCache? sourceCoverCache,
    SourceChapterStateStore? sourceChapterStateStore,
    TxtEditService? txtEditService,
    SourceTxtRevisionCommitter? sourceRevisionCommitter,
    Directory? downloadDirectory,
  }) : assert(client == null || clientFactory == null),
       _downloadDirectory = downloadDirectory,
       _bookDao = bookDao ?? BookDao(),
       _client = client ?? (clientFactory ?? BookSourceClient.new)(),
       _ownsClient = client == null,
       _sourceCoverCache = sourceCoverCache ?? SourceCoverCache.instance,
       _sourceChapterStateStore =
           sourceChapterStateStore ?? const SourceChapterStateStore(),
       _txtEditService = txtEditService ?? TxtEditService(),
       _revisionCommitter =
           sourceRevisionCommitter ??
           ((book, commit) => TxtEditReferenceService().commitRevision(
             book: book,
             commit: commit,
           ));

  final BookDao _bookDao;
  final BookSourceClient _client;
  final bool _ownsClient;
  final SourceCoverCache _sourceCoverCache;
  final SourceChapterStateStore _sourceChapterStateStore;
  final TxtEditService _txtEditService;
  final SourceTxtRevisionCommitter _revisionCommitter;
  final Directory? _downloadDirectory;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }

  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) =>
      _bookDao.getBookBySource(sourceId: sourceId, sourceBookId: sourceBookId);

  Future<Book> addOnline({
    required RegisteredBookSource source,
    required BookSourceBook book,
  }) async {
    final existing = await findShelfBook(
      sourceId: source.id,
      sourceBookId: book.id,
    );
    if (existing != null) return existing;
    final shelfBook = Book(
      title: book.title,
      author: book.author,
      filePath: '',
      format: 'source',
      storageType: 'online',
      sourceId: source.id,
      sourceBookId: book.id,
      sourceJson: jsonEncode(source.toJson()),
      sourceBookJson: jsonEncode(book.toJson()),
    );
    final id = await _bookDao.insertBook(shelfBook);
    LibraryEventBus().notifyLibraryChanged();
    final added = shelfBook.copyWith(id: id);
    // Cover retrieval must not block leaving the reader. Persist it as a
    // point update so a concurrent progress update cannot be overwritten.
    unawaited(_persistOnlineCover(source, book, id));
    return added;
  }

  Future<void> updateShelfProgress({
    required int shelfBookId,
    required int chapterIndex,
    required int chapterCount,
    required double chapterProgress,
  }) async {
    final currentUnits =
        chapterIndex * unitsPerChapter +
        (chapterProgress.clamp(0, 1) * unitsPerChapter).round();
    final totalUnits = chapterCount * unitsPerChapter;
    await _bookDao.updateBookProgress(
      shelfBookId,
      currentUnits,
      readingProgress: totalUnits <= 0 ? 0 : currentUnits / totalUnits,
    );
    await _bookDao.updateBookTotalPages(shelfBookId, totalUnits);
  }

  Future<Book> replaceOnlineSourceBinding({
    required Book shelfBook,
    required RegisteredBookSource source,
    required BookSourceBook book,
    required int chapterIndex,
    required int chapterCount,
    required double chapterProgress,
    BookSourceReadingProgress? sourceProgress,
  }) async {
    if (shelfBook.id == null) {
      throw const BookSourceProtocolException(
        'Only a saved shelf book can change source.',
      );
    }
    final currentUnits =
        chapterIndex * unitsPerChapter +
        (chapterProgress.clamp(0, 1) * unitsPerChapter).round();
    final totalUnits = chapterCount * unitsPerChapter;
    var updated = shelfBook.copyWith(
      currentPage: shelfBook.isOnline ? currentUnits : shelfBook.currentPage,
      totalPages: shelfBook.isOnline ? totalUnits : shelfBook.totalPages,
      readingProgress: shelfBook.isOnline
          ? (totalUnits <= 0 ? 0 : currentUnits / totalUnits)
          : shelfBook.readingProgress,
      sourceId: source.id,
      sourceBookId: book.id,
      sourceJson: jsonEncode(source.toJson()),
      sourceBookJson: jsonEncode({
        ...book.toJson(),
        if (!shelfBook.isOnline)
          SourceBookUpdateInfo.storageKey: SourceBookUpdateInfo(
            status: SourceBookCheckStatus.needsMapping,
            latestChapter: book.latestChapter,
            updatedAt: book.updatedAt,
          ).toJson(),
      }),
    );
    final oldState = shelfBook.isOnline
        ? null
        : await _sourceChapterStateStore.load(shelfBook);
    updated = sourceProgress == null
        ? await _bookDao.updateSourceBinding(shelfBook, updated)
        : await _bookDao.updateSourceBindingWithProgress(
            shelfBook,
            updated,
            progress: sourceProgress,
          );
    if (oldState != null) {
      try {
        await _sourceChapterStateStore.save(
          updated,
          _reboundSourceState(
            oldState,
            sourceId: source.id,
            sourceBookId: book.id,
          ),
        );
      } catch (_) {
        // The database binding is authoritative. A later sidecar read repairs
        // the stale binding idempotently from the committed shelf record.
      }
    }
    try {
      if (!shelfBook.isOnline) {
        final hash = await SourceChapterStateStore.hashFile(
          File(updated.filePath),
        );
        _notifySourceSidecarChanged(updated, hash);
      }
      LibraryEventBus().notifyLibraryChanged();
    } catch (_) {
      // The binding is already committed. Hashing and notifications are
      // non-critical follow-up work and must not report the change as failed.
    }
    if (!BookCoverEditService.hasCustomCover(shelfBook)) {
      unawaited(
        _persistReboundCover(source, book, updated.id!, updated.coverImagePath),
      );
    }
    return updated;
  }

  /// Reconciles a downloaded book's sidecar with its committed database
  /// binding. This is safe to call repeatedly and repairs a process exit or
  /// I/O failure between the database commit and the best-effort sidecar save.
  Future<SourceChapterState?> recoverDownloadedSourceBinding(
    Book shelfBook,
  ) async {
    final state = await _sourceChapterStateStore.load(shelfBook);
    if (state == null || shelfBook.isOnline) return state;
    final sourceId = shelfBook.sourceId?.trim();
    final sourceBookId = shelfBook.sourceBookId?.trim();
    if (sourceId == null ||
        sourceId.isEmpty ||
        sourceBookId == null ||
        sourceBookId.isEmpty ||
        (state.sourceId == sourceId && state.sourceBookId == sourceBookId)) {
      return state;
    }
    final repaired = _reboundSourceState(
      state,
      sourceId: sourceId,
      sourceBookId: sourceBookId,
    );
    await _sourceChapterStateStore.save(shelfBook, repaired);
    return repaired;
  }

  Future<Book> downloadToLocal({
    required RegisteredBookSource source,
    required BookSourceBook book,
    String? bookUid,
    void Function(int completed, int total)? onProgress,
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final existing = await findShelfBook(
      sourceId: source.id,
      sourceBookId: book.id,
    );
    if (existing != null &&
        !existing.isOnline &&
        existing.filePath.trim().isNotEmpty &&
        await File(existing.filePath).exists()) {
      // Re-running an initial download must never replace a user's readable
      // file. Updates require the explicit append/refresh API below.
      return existing;
    }
    final chapters = [
      ...await _client.getChaptersForDownload(
        source,
        book.id,
        sourceVariables: book.sourceVariables,
        cancellation: cancellation,
      ),
    ]..sort(compareBookSourceChapters);
    cancellation?.throwIfCancelled();
    if (chapters.isEmpty) {
      throw const BookSourceProtocolException(
        'This book source returned an empty chapter catalog.',
      );
    }

    final documents =
        _downloadDirectory ?? await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(documents.path, 'books'));
    await directory.create(recursive: true);
    final file = File(
      path.join(
        directory.path,
        '${_safeFileName(book.title)}-${_downloadIdentity(source, book)}.txt',
      ),
    );
    final temporaryFile = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.part',
    );
    IOSink? sink;
    final trackedChapters = <TrackedSourceChapter>[];
    var completed = 0;
    onProgress?.call(0, chapters.length);

    try {
      sink = temporaryFile.openWrite(mode: FileMode.write, encoding: utf8);
      for (
        var offset = 0;
        offset < chapters.length;
        offset += _downloadBatchSize
      ) {
        cancellation?.throwIfCancelled();
        final end = (offset + _downloadBatchSize).clamp(0, chapters.length);
        final batch = chapters.sublist(offset, end);
        final contents = await Future.wait(
          batch.asMap().entries.map((entry) async {
            final chapter = entry.value;
            final chapterIndex = offset + entry.key;
            final content = await _client.getChapterContentForDownload(
              source,
              bookId: book.id,
              chapterId: chapter.id,
              sourceVariables: {
                ...book.sourceVariables,
                'chapterIndex': '$chapterIndex',
                'chapterTitle': chapter.title,
                'bookName': book.title,
                'bookAuthor': book.author,
                'bookType': '${book.type}',
              },
              cancellation: cancellation,
            );
            cancellation?.throwIfCancelled();
            completed++;
            onProgress?.call(completed, chapters.length);
            return content;
          }),
        );
        cancellation?.throwIfCancelled();
        for (var index = 0; index < batch.length; index++) {
          final body = _plainText(contents[index]);
          sink
            ..writeln(batch[index].title)
            ..writeln()
            ..writeln(body)
            ..writeln()
            ..writeln();
          final bodyHash = SourceChapterStateStore.hashText(body);
          trackedChapters.add(
            TrackedSourceChapter(
              sourceChapterId: batch[index].id,
              ordinal: offset + index,
              title: batch[index].title,
              sourceMarker: batch[index].updatedAt?.toUtc().toIso8601String(),
              baselineHash: bodyHash,
              currentHash: bodyHash,
              body: body,
              userModified: false,
            ),
          );
        }
        await sink.flush();
      }
      cancellation?.throwIfCancelled();
      await sink.close();
      sink = null;
      cancellation?.throwIfCancelled();
      await _commitDownloadedFile(temporaryFile, file);
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {
        // Preserve the download error; cleanup is best effort.
      }
      try {
        if (await temporaryFile.exists()) await temporaryFile.delete();
      } catch (_) {
        // Preserve the download error; cleanup is best effort.
      }
      rethrow;
    }

    if (cancellation?.isCancelled ?? false) {
      throw const BookDownloadCancelledException();
    }

    final generatedCoverPath =
        existing?.coverImagePath ?? await _storedCoverPath(source, book);
    cancellation?.throwIfCancelled();
    if (existing != null) {
      final localChapterIndex =
          (existing.isOnline
                  ? existing.currentPage ~/ unitsPerChapter
                  : existing.currentPage)
              .clamp(0, chapters.length - 1);
      final downloaded = existing.copyWith(
        title: book.title,
        author: book.author,
        filePath: file.path,
        format: 'txt',
        currentPage: localChapterIndex,
        totalPages: chapters.length,
        storageType: 'local',
        sourceJson: jsonEncode(source.toJson()),
        sourceBookJson: jsonEncode(book.toJson()),
        coverImagePath: generatedCoverPath,
      );
      await _bookDao.updateBook(downloaded);
      await _saveInitialSourceState(
        downloaded,
        bookUid: bookUid,
        source: source,
        sourceBook: book,
        chapters: trackedChapters,
      );
      LibraryEventBus().notifyLibraryChanged();
      return downloaded;
    }

    final downloaded = Book(
      title: book.title,
      author: book.author,
      filePath: file.path,
      format: 'txt',
      totalPages: chapters.length,
      storageType: 'local',
      sourceId: source.id,
      sourceBookId: book.id,
      sourceJson: jsonEncode(source.toJson()),
      sourceBookJson: jsonEncode(book.toJson()),
      coverImagePath: generatedCoverPath,
    );
    final id = await _bookDao.insertBook(downloaded);
    final inserted = downloaded.copyWith(id: id);
    await _saveInitialSourceState(
      inserted,
      bookUid: bookUid,
      source: source,
      sourceBook: book,
      chapters: trackedChapters,
    );
    LibraryEventBus().notifyLibraryChanged();
    return inserted;
  }

  Future<SourceChapterState> establishTrackingBaseline({
    required Book shelfBook,
    required List<BookSourceChapter> sourceChapters,
    required String lastDownloadedChapterId,
    required bool mappingConfirmed,
    String? bookUid,
  }) async {
    if (!mappingConfirmed) {
      throw const BookSourceProtocolException(
        'A legacy chapter mapping must be explicitly confirmed.',
      );
    }
    final binding = bindingFrom(shelfBook);
    final boundary = sourceChapters.indexWhere(
      (chapter) => chapter.id == lastDownloadedChapterId,
    );
    if (boundary < 0) {
      throw const BookSourceProtocolException(
        'The selected chapter is not present in the current catalog.',
      );
    }
    final hash = await SourceChapterStateStore.hashFile(
      File(shelfBook.filePath),
    );
    final state = SourceChapterState(
      schemaVersion: 1,
      bookUid: _resolvedBookUid(shelfBook, bookUid),
      sourceId: binding.source.id,
      sourceBookId: binding.book.id,
      materializedContentHash: hash,
      baselineKnown: false,
      catalogChapterIds: sourceChapters
          .take(boundary + 1)
          .map((chapter) => chapter.id)
          .toList(growable: false),
      chapters: const [],
      conflicts: const [],
      revisionOrigin: SourceRevisionOrigin.sourceRebind,
    );
    await _sourceChapterStateStore.save(shelfBook, state);
    LibraryEventBus().notifyLibraryChanged();
    _notifySourceSidecarChanged(shelfBook, hash);
    return state;
  }

  Future<SourceUpdateResult> updateDownloadedBook({
    required Book shelfBook,
    required SourceUpdateMode mode,
    String? bookUid,
    void Function(int completed, int total)? onProgress,
    BookDownloadCancellation? cancellation,
  }) async {
    final binding = bindingFrom(shelfBook);
    final file = File(shelfBook.filePath);
    if (shelfBook.isOnline ||
        shelfBook.format.toLowerCase() != 'txt' ||
        !await file.exists()) {
      throw const BookSourceProtocolException(
        'Source updates require a downloaded TXT book.',
      );
    }
    var state = await recoverDownloadedSourceBinding(shelfBook);
    final actualHash = await SourceChapterStateStore.hashFile(file);
    if (state == null) {
      return SourceUpdateResult(
        book: shelfBook,
        status: SourceUpdateStatus.baselineUnknown,
        addedChapterCount: 0,
        refreshedChapterCount: 0,
        conflictCount: 0,
        materializedContentHash: actualHash,
        revisionOrigin: SourceRevisionOrigin.initialDownload,
      );
    }
    if (state.sourceId != binding.source.id ||
        state.sourceBookId != binding.book.id) {
      return SourceUpdateResult(
        book: shelfBook,
        status: SourceUpdateStatus.baselineUnknown,
        addedChapterCount: 0,
        refreshedChapterCount: 0,
        conflictCount: state.conflicts
            .where((c) => c.resolution == null)
            .length,
        materializedContentHash: actualHash,
        revisionOrigin: SourceRevisionOrigin.sourceRebind,
      );
    }
    if (actualHash != state.materializedContentHash) {
      final reconciled = _reconcileEditedContent(
        await _readSourceUpdateText(shelfBook),
        state.chapters,
      );
      if (reconciled == null) {
        return SourceUpdateResult(
          book: shelfBook,
          status: SourceUpdateStatus.baselineUnknown,
          addedChapterCount: 0,
          refreshedChapterCount: 0,
          conflictCount: state.conflicts
              .where((c) => c.resolution == null)
              .length,
          materializedContentHash: actualHash,
          revisionOrigin: SourceRevisionOrigin.userEdit,
        );
      }
      state = state.copyWith(
        chapters: reconciled,
        materializedContentHash: actualHash,
        revisionOrigin: SourceRevisionOrigin.userEdit,
      );
      await _sourceChapterStateStore.save(shelfBook, state);
    }

    cancellation?.throwIfCancelled();
    final catalog = [
      ...await _client.getChaptersForDownload(
        binding.source,
        binding.book.id,
        sourceVariables: binding.book.sourceVariables,
        cancellation: cancellation,
      ),
    ]..sort(compareBookSourceChapters);
    cancellation?.throwIfCancelled();
    if (mode == SourceUpdateMode.appendNewChapters) {
      return _appendNewChapters(
        shelfBook: shelfBook,
        binding: binding,
        state: state,
        catalog: catalog,
        onProgress: onProgress,
        cancellation: cancellation,
      );
    }
    if (!state.baselineKnown) {
      return SourceUpdateResult(
        book: shelfBook,
        status: SourceUpdateStatus.baselineUnknown,
        addedChapterCount: 0,
        refreshedChapterCount: 0,
        conflictCount: state.conflicts
            .where((c) => c.resolution == null)
            .length,
        materializedContentHash: state.materializedContentHash,
        revisionOrigin: state.revisionOrigin,
      );
    }
    return _refreshDownloadedChapters(
      shelfBook: shelfBook,
      binding: binding,
      state: state,
      catalog: catalog,
      onProgress: onProgress,
      cancellation: cancellation,
    );
  }

  Future<List<BookSourceChapter>> sourceChaptersFor(Book book) async {
    final binding = bindingFrom(book);
    return [
      ...await _client.getChaptersForDownload(
        binding.source,
        binding.book.id,
        sourceVariables: binding.book.sourceVariables,
      ),
    ]..sort(compareBookSourceChapters);
  }

  /// Downloads a readable source snapshot without changing the user's current
  /// TXT. This is the recovery path when an old or externally edited file can
  /// no longer be mapped safely to the persisted chapter baseline.
  Future<SourceStateAsset> downloadSourceCandidate({
    required Book shelfBook,
    void Function(int completed, int total)? onProgress,
    BookDownloadCancellation? cancellation,
  }) async {
    final binding = bindingFrom(shelfBook);
    final catalog = await sourceChaptersFor(shelfBook);
    final candidate = <TrackedSourceChapter>[];
    onProgress?.call(0, catalog.length);
    for (var index = 0; index < catalog.length; index++) {
      cancellation?.throwIfCancelled();
      final chapter = catalog[index];
      final value = await _client.getChapterContentForDownload(
        binding.source,
        bookId: binding.book.id,
        chapterId: chapter.id,
        sourceVariables: _chapterVariables(binding.book, chapter, index),
        cancellation: cancellation,
      );
      final body = _plainText(value);
      final hash = SourceChapterStateStore.hashText(body);
      candidate.add(
        TrackedSourceChapter(
          sourceChapterId: chapter.id,
          ordinal: index,
          title: chapter.title,
          sourceMarker: chapter.updatedAt?.toUtc().toIso8601String(),
          baselineHash: hash,
          currentHash: hash,
          body: body,
          userModified: false,
        ),
      );
      onProgress?.call(index + 1, catalog.length);
    }
    final asset = await _sourceChapterStateStore.writeBookCandidate(
      book: shelfBook,
      id: '${DateTime.now().microsecondsSinceEpoch}-${binding.source.id}',
      content: SourceChapterStateStore.materialize(candidate),
    );
    final hash = await SourceChapterStateStore.hashFile(
      File(shelfBook.filePath),
    );
    LibraryEventBus().notifyLibraryChanged();
    _notifySourceSidecarChanged(shelfBook, hash);
    return asset;
  }

  Future<SourceUpdateResult> resolveSourceConflict({
    required Book shelfBook,
    required String conflictId,
    required SourceConflictResolution resolution,
  }) async {
    final state = await recoverDownloadedSourceBinding(shelfBook);
    if (state == null) throw StateError('Source chapter state is missing');
    final conflictIndex = state.conflicts.indexWhere(
      (value) => value.id == conflictId,
    );
    if (conflictIndex < 0) throw StateError('Source conflict is missing');
    final conflict = state.conflicts[conflictIndex];
    if (conflict.resolution != null) {
      return _unchangedResult(shelfBook, state, SourceUpdateStatus.noChanges);
    }
    final chapters = [...state.chapters];
    final chapterIndex = chapters.indexWhere(
      (chapter) => chapter.sourceChapterId == conflict.sourceChapterId,
    );
    if (chapterIndex < 0) throw StateError('Conflicted chapter is missing');
    if (resolution == SourceConflictResolution.useSource) {
      final raw = await _sourceChapterStateStore.readAsset(
        shelfBook,
        conflict.sourceAsset,
      );
      final body = _bodyFromReadableChapter(raw);
      final hash = SourceChapterStateStore.hashText(body);
      chapters[chapterIndex] = chapters[chapterIndex].copyWith(
        body: body,
        baselineHash: hash,
        currentHash: hash,
        userModified: false,
        baselineAsset: conflict.sourceAsset,
      );
    } else {
      final raw = await _sourceChapterStateStore.readAsset(
        shelfBook,
        conflict.sourceAsset,
      );
      final sourceBody = _bodyFromReadableChapter(raw);
      chapters[chapterIndex] = chapters[chapterIndex].copyWith(
        baselineHash: SourceChapterStateStore.hashText(sourceBody),
        baselineAsset: conflict.sourceAsset,
        userModified: true,
      );
    }
    final conflictValues = [...state.conflicts]
      ..[conflictIndex] = conflict.copyWith(resolution: resolution);
    return _commitSourceRevision(
      shelfBook: shelfBook,
      state: state.copyWith(
        chapters: chapters,
        conflicts: conflictValues,
        revisionOrigin: SourceRevisionOrigin.conflictResolution,
      ),
      chapters: chapters,
      addedChapterCount: 0,
      refreshedChapterCount: 0,
      invalidateAllReferences: resolution == SourceConflictResolution.useSource,
    );
  }

  OnlineShelfBookBinding bindingFrom(Book book) {
    if ((book.sourceId?.trim().isEmpty ?? true) ||
        (book.sourceBookId?.trim().isEmpty ?? true)) {
      throw const OnlineShelfBookBindingException(
        'This shelf record is not bound to a book source.',
      );
    }
    try {
      final sourceJson = _storedJsonObject(book.sourceJson, 'source metadata');
      final sourceBookJson = _storedJsonObject(
        book.sourceBookJson,
        'source book metadata',
      );
      final source = RegisteredBookSource.fromJson(sourceJson);
      final sourceBook = BookSourceBook.fromJson(
        sourceBookJson,
        baseUri: source.apiBaseUrl,
      );
      final sourceId = book.sourceId?.trim() ?? '';
      if (sourceId.isEmpty || source.id != sourceId) {
        throw const BookSourceProtocolException(
          'Stored source identity does not match the shelf record.',
        );
      }
      final sourceBookId = book.sourceBookId?.trim() ?? '';
      if (sourceBookId.isEmpty || sourceBook.id != sourceBookId) {
        throw const BookSourceProtocolException(
          'Stored source-book identity does not match the shelf record.',
        );
      }
      return OnlineShelfBookBinding(source: source, book: sourceBook);
    } on OnlineShelfBookBindingException {
      rethrow;
    } catch (error) {
      throw OnlineShelfBookBindingException(
        'Stored online book data is invalid.',
        cause: error,
      );
    }
  }

  RegisteredBookSource sourceFrom(Book book) => bindingFrom(book).source;

  BookSourceBook sourceBookFrom(Book book) => bindingFrom(book).book;
}
