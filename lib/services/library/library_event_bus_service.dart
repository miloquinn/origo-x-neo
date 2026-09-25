// 文件说明：书库事件总线，用于在不同页面之间广播书库刷新事件。
// 技术要点：服务层。

import 'dart:async';

import '../../models/book.dart';

/// A catalog check changed one book's source metadata without changing the
/// library's membership, order, or reading progress.
class LibrarySourceMetadataChange {
  const LibrarySourceMetadataChange({
    required this.previous,
    required this.sourceBookJson,
  });

  final Book previous;
  final String sourceBookJson;
}

class LibraryEventBus {
  static final LibraryEventBus _instance = LibraryEventBus._internal();
  factory LibraryEventBus() => _instance;
  LibraryEventBus._internal();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  final StreamController<LibrarySourceMetadataChange>
  _sourceMetadataController =
      StreamController<LibrarySourceMetadataChange>.broadcast();

  Stream<void> get stream => _controller.stream;
  Stream<LibrarySourceMetadataChange> get sourceMetadataStream =>
      _sourceMetadataController.stream;

  void notifyLibraryChanged() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void notifySourceMetadataChanged(Book previous, String sourceBookJson) {
    if (!_sourceMetadataController.isClosed) {
      _sourceMetadataController.add(
        LibrarySourceMetadataChange(
          previous: previous,
          sourceBookJson: sourceBookJson,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _controller.close();
    await _sourceMetadataController.close();
  }
}
