import 'package:flutter/foundation.dart';

import '../books/book_dao.dart';

/// Records one successful reading event for a reader or listening session.
/// Trial reading retains its original time until a library identity is bound.
class ReadingActivityRecorder {
  ReadingActivityRecorder({BookDao? bookDao, DateTime Function()? now})
    : _bookDao = bookDao ?? BookDao(),
      _now = now ?? DateTime.now;

  final BookDao _bookDao;
  final DateTime Function() _now;
  int? _bookId;
  DateTime? _firstReadAt;
  bool _saved = false;
  Future<void>? _saving;

  Future<void> markContentReady({int? bookId}) {
    if (bookId != null) _bookId = bookId;
    _firstReadAt ??= _now().toUtc();
    return _save();
  }

  Future<void> bindBook(int? bookId) {
    _bookId = bookId;
    return _save();
  }

  Future<void> _save() {
    final pending = _saving;
    if (pending != null) return pending;
    final bookId = _bookId;
    final at = _firstReadAt;
    if (_saved || bookId == null || at == null) return Future<void>.value();
    return _saving = Future<void>.sync(() => _bookDao.markRead(bookId, at: at))
        .then<void>((_) {
          _saved = true;
        })
        .catchError((Object error) {
          debugPrint('Save recent reading activity failed: $error');
        })
        .whenComplete(() => _saving = null);
  }
}
