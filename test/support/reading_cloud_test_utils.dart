import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/services/core/database_service.dart';

Database? _readingDatabase;

Future<void> prepareReadingCloudTestDatabase() async {
  _readingDatabase ??= await DatabaseService().database;
}

/// Waits for reader-owned cloud and statistics writes before fakeAsync checks
/// for pending sqflite lock timers.
Future<int> drainReadingCloudWrites(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    var drained = false;
    var eventCount = 0;
    Object? failure;
    StackTrace? failureStack;
    final completion = () async {
      try {
        await Future<void>.delayed(Duration.zero);
        final database = _readingDatabase ??= await DatabaseService().database;
        await database.transaction((transaction) async {
          await transaction.rawQuery('SELECT 1');
        });
        final rows = await database.rawQuery(
          'SELECT COUNT(*) AS count FROM reading_cloud_events',
        );
        eventCount = (rows.single['count'] as num).toInt();
      } catch (error, stackTrace) {
        failure = error;
        failureStack = stackTrace;
      } finally {
        drained = true;
      }
    }();
    for (var attempt = 0; attempt < 200 && !drained; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
    expect(
      drained,
      isTrue,
      reason: 'reading cloud writes must finish before leaving fakeAsync',
    );
    await completion;
    if (failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
    return eventCount;
  }))!;
}

Future<void> closeReadingCloudTestDatabase() async {
  final database = _readingDatabase;
  _readingDatabase = null;
  await database?.close();
}
