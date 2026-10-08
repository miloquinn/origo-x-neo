import 'dart:convert';

import '../../models/book.dart';
import '../../services/books/book_dao.dart';
import '../../services/library/library_event_bus_service.dart';
import '../models/source_book_update_info.dart';
import '../protocol/book_source_protocol.dart';
import 'book_source_shelf_service.dart';
import 'book_download_cancellation.dart';
import 'source_chapter_state.dart';

/// Checks catalogs only. Downloading/merging local text remains an explicit
/// operation in the download queue, with its existing conflict protection.
class SourceBookUpdateService {
  SourceBookUpdateService({
    BookDao? bookDao,
    BookSourceShelfService Function()? shelfServiceFactory,
    SourceChapterStateStore? stateStore,
    DateTime Function()? now,
  }) : _dao = bookDao ?? BookDao(),
       _createShelf = shelfServiceFactory ?? BookSourceShelfService.new,
       _store = stateStore ?? const SourceChapterStateStore(),
       _now = now ?? DateTime.now;

  final BookDao _dao;
  final BookSourceShelfService Function() _createShelf;
  final SourceChapterStateStore _store;
  final DateTime Function() _now;
  static final Map<(int, String?, String?, Object), _PendingBookCheck>
  _pending = {};
  static const automaticInterval = Duration(minutes: 30);

  Future<Book> check(
    Book book, {
    bool force = true,
    BookDownloadCancellation? cancellation,
  }) {
    cancellation?.throwIfCancelled();
    if (!book.hasSourceBinding || book.id == null) return Future.value(book);
    // A hidden shelf can stop its automatic pass without cancelling a manual
    // check owned by another page. Unscoped manual callers still share a flight.
    final key = (
      book.id!,
      book.sourceId,
      book.sourceBookId,
      cancellation ?? '#shared',
    );
    final running = _pending[key];
    if (running != null) {
      running.force = running.force || force;
      return running.result;
    }
    final pending = _PendingBookCheck(force);
    _pending[key] = pending;
    pending.result = () async {
      try {
        return await _check(book, pending: pending, cancellation: cancellation);
      } finally {
        _pending.remove(key);
      }
    }();
    return pending.result;
  }

  Future<Book> _check(
    Book snapshot, {
    required _PendingBookCheck pending,
    BookDownloadCancellation? cancellation,
  }) async {
    final book = await _dao.getBookById(snapshot.id!);
    cancellation?.throwIfCancelled();
    if (book == null || !book.hasSourceBinding) return snapshot;
    if (book.sourceId != snapshot.sourceId ||
        book.sourceBookId != snapshot.sourceBookId) {
      return book;
    }
    final old = SourceBookUpdateInfo.fromBook(book);
    final now = _now().toUtc();
    final localRevisionChanged =
        !book.isOnline &&
        book.fileModifiedTime != null &&
        (old.checkedAt == null ||
            book.fileModifiedTime! > old.checkedAt!.millisecondsSinceEpoch);
    if (!pending.force &&
        !localRevisionChanged &&
        old.checkedAt != null &&
        now.difference(old.checkedAt!) < automaticInterval) {
      return book;
    }
    final shelf = _createShelf();
    late SourceBookUpdateInfo info;
    try {
      final catalog = await shelf
          .sourceChaptersFor(book, cancellation: cancellation)
          .timeout(const Duration(seconds: 45));
      cancellation?.throwIfCancelled();
      if (catalog.isEmpty ||
          catalog.map((c) => c.id).toSet().length != catalog.length) {
        throw const BookSourceProtocolException('Invalid update catalog');
      }
      final state = book.isOnline ? null : await _store.load(book);
      cancellation?.throwIfCancelled();
      info = compareCatalog(
        book: book,
        previous: old,
        catalog: catalog,
        localState: state,
        checkedAt: now,
      );
    } on BookDownloadCancelledException {
      rethrow;
    } catch (_) {
      cancellation?.throwIfCancelled();
      info = SourceBookUpdateInfo(
        status: SourceBookCheckStatus.failed,
        checkedAt: now,
        updatedAt: old.updatedAt,
        chapterCount: old.chapterCount,
        latestChapterId: old.latestChapterId,
        latestChapter: old.latestChapter,
        hasUnacknowledgedUpdate: old.hasNewChapters,
        newChapterCount: old.newChapterCount,
      );
    } finally {
      shelf.close();
    }
    cancellation?.throwIfCancelled();
    final encoded = info.encodeInto(book);
    // A source change, download, or another metadata revision wins over this
    // stale network response. Progress and covers are never part of this write.
    if (await _dao.updateSourceBookMetadata(book, encoded)) {
      LibraryEventBus().notifySourceMetadataChanged(book, encoded);
    }
    return await _dao.getBookById(book.id!) ?? book;
  }

  static SourceBookUpdateInfo compareCatalog({
    required Book book,
    required SourceBookUpdateInfo previous,
    required List<BookSourceChapter> catalog,
    required DateTime checkedAt,
    SourceChapterState? localState,
  }) {
    var status = SourceBookCheckStatus.current;
    var additions = 0;
    if (!book.isOnline) {
      final tracked = localState?.catalogChapterIds ?? const <String>[];
      if (localState?.sourceId != book.sourceId ||
          localState?.sourceBookId != book.sourceBookId ||
          tracked.isEmpty ||
          tracked.length > catalog.length ||
          tracked.indexed.any((entry) => catalog[entry.$1].id != entry.$2)) {
        status = SourceBookCheckStatus.needsMapping;
      } else {
        additions = catalog.length - tracked.length;
      }
    } else {
      final previousCount = previous.newChapterCount;
      final hadUnread = previous.hasNewChapters;
      final countUnknown = hadUnread && previousCount == 0;
      bool hasReliableBoundary(int boundary) =>
          previous.chapterCount == 0 || boundary == previous.chapterCount - 1;
      if (countUnknown) {
        status = SourceBookCheckStatus.available;
      } else if (previous.latestChapterId != null) {
        final boundaries = catalog.indexed
            .where((entry) => entry.$2.id == previous.latestChapterId)
            .map((entry) => entry.$1)
            .toList();
        if (boundaries.length == 1 && hasReliableBoundary(boundaries.single)) {
          additions =
              catalog.length -
              boundaries.single -
              1 +
              (hadUnread ? previousCount : 0);
        } else {
          status = SourceBookCheckStatus.available;
        }
      } else if (previous.latestChapter?.trim().isNotEmpty == true) {
        final boundaries = catalog.indexed
            .where((entry) => entry.$2.title == previous.latestChapter)
            .map((entry) => entry.$1)
            .toList();
        if (boundaries.length == 1 && hasReliableBoundary(boundaries.single)) {
          additions =
              catalog.length -
              boundaries.single -
              1 +
              (hadUnread ? previousCount : 0);
        } else {
          status = SourceBookCheckStatus.available;
        }
      } else if (hadUnread) {
        status = SourceBookCheckStatus.available;
      }
    }
    if (additions > 0) status = SourceBookCheckStatus.available;
    final sourceDates = catalog.map((c) => c.updatedAt).nonNulls.toList()
      ..sort();
    final changed =
        additions > previous.newChapterCount &&
        (previous.latestChapterId == null ||
            previous.latestChapterId != catalog.last.id);
    return SourceBookUpdateInfo(
      status: status,
      checkedAt: checkedAt,
      updatedAt: sourceDates.isNotEmpty
          ? sourceDates.last
          : changed
          ? checkedAt
          : previous.updatedAt,
      chapterCount: catalog.length,
      latestChapterId: catalog.last.id,
      latestChapter: catalog.last.title,
      hasUnacknowledgedUpdate: status == SourceBookCheckStatus.available,
      newChapterCount: additions,
    );
  }

  Future<void> markOnlineOpened(
    Book book, {
    required String latestChapterId,
  }) async {
    if (!book.isOnline || book.id == null) return;
    final current = await _dao.getBookById(book.id!);
    if (current == null ||
        current.sourceId != book.sourceId ||
        current.sourceBookId != book.sourceBookId) {
      return;
    }
    final json = jsonDecode(current.sourceBookJson!) as Map<String, dynamic>;
    final info = SourceBookUpdateInfo.fromBook(current);
    if (!info.hasNewChapters || info.latestChapterId != latestChapterId) {
      return;
    }
    json[SourceBookUpdateInfo.storageKey] = {
      ...info.toJson(),
      'status': SourceBookCheckStatus.current.name,
      'hasUnacknowledgedUpdate': false,
      'newChapterCount': 0,
    };
    final encoded = jsonEncode(json);
    if (await _dao.updateSourceBookMetadata(current, encoded)) {
      LibraryEventBus().notifySourceMetadataChanged(current, encoded);
    }
  }
}

class _PendingBookCheck {
  _PendingBookCheck(this.force);
  bool force;
  late Future<Book> result;
}
