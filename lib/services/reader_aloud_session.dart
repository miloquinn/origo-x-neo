import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/reader/reader_aloud_controller.dart';
import 'reading/reading_activity_recorder.dart';

/// App-scoped ownership for the active read-aloud controller.
///
/// A reader page may subscribe to this controller for highlighting, but it
/// must not own its lifetime: routes are routinely disposed while a user is
/// still listening from the notification, lock screen, or another app.
class ReaderAloudSession extends ChangeNotifier {
  ReaderAloudController? _controller;
  String? _sourceId;
  ReadingActivityRecorder? _readingActivity;

  ReaderAloudController? get controller => _controller;
  String? get sourceId => _sourceId;
  bool get isActive => _controller?.isActive ?? false;

  ReaderAloudController acquire({
    required String sourceId,
    required ReaderAloudController Function() create,
    int? shelfBookId,
    ReadingActivityRecorder? readingActivity,
  }) {
    final existing = _controller;
    if (existing != null && _sourceId == sourceId) {
      if (shelfBookId != null) {
        unawaited(_readingActivity?.bindBook(shelfBookId));
      }
      return existing;
    }

    if (existing != null) {
      existing.removeListener(_relayChange);
      // Switching books is an explicit replacement of the listening session.
      // Stopping first also clears the native media notification.
      unawaited(existing.stop());
      existing.dispose();
    }

    final controller = create();
    _controller = controller;
    _sourceId = sourceId;
    _readingActivity = readingActivity ?? ReadingActivityRecorder();
    unawaited(_readingActivity!.bindBook(shelfBookId));
    controller.addListener(_relayChange);
    notifyListeners();
    return controller;
  }

  Future<void> stop() async {
    await _controller?.stop();
  }

  void _relayChange() {
    final controller = _controller;
    if (controller?.state == ReaderAloudPlaybackState.playing &&
        controller!.engine.isPlaying) {
      unawaited(_readingActivity?.markContentReady());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    _sourceId = null;
    if (controller != null) {
      controller.removeListener(_relayChange);
      controller.dispose();
    }
    super.dispose();
  }
}
