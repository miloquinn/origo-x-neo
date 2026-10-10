import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/icloud/icloud_sync_models.dart';

void main() {
  ICloudRecord record(
    String value,
    Map<String, int> clock, {
    String device = 'device-a',
  }) => ICloudRecord(
    key: 'book:1',
    value: {'value': value},
    clock: clock,
    device: device,
    modifiedAt: 1,
  );

  test('vector frontier removes causal ancestors and retains concurrency', () {
    final ancestor = record('old', {'device-a': 1});
    final successor = record('new', {'device-a': 2});
    final concurrent = record('other', {'device-b': 1}, device: 'device-b');

    expect(syncFrontier([ancestor, successor]), [successor]);
    expect(syncFrontier([ancestor, successor, concurrent]), {
      successor,
      concurrent,
    });
  });

  test('clock joins take every device maximum', () {
    expect(
      joinSyncClocks([
        record('a', {'a': 3, 'b': 1}),
        record('b', {'a': 2, 'b': 4}),
      ]),
      {'a': 3, 'b': 4},
    );
  });

  test('record decoding rejects malformed and non-JSON values', () {
    Map<String, Object?> valid() => {
      'key': 'setting:theme',
      'value': {'name': 'dark'},
      'clock': {'device-a': 1},
      'device': 'device-a',
      'modifiedAt': 1,
    };

    expect(
      ICloudRecord.fromJson(Map<String, dynamic>.from(valid())).key,
      'setting:theme',
    );
    expect(
      () => ICloudRecord.fromJson(
        Map<String, dynamic>.from(valid()..['clock'] = {'device-a': 0}),
      ),
      throwsFormatException,
    );
    expect(
      () => ICloudRecord.fromJson(
        Map<String, dynamic>.from(valid()..['value'] = {'bad': Object()}),
      ),
      throwsFormatException,
    );
    expect(
      () => ICloudRecord.fromJson(
        Map<String, dynamic>.from(valid()..['modifiedAt'] = -1),
      ),
      throwsFormatException,
    );
  });

  test('canonical JSON ignores map insertion order', () {
    expect(
      syncCanonicalJson({
        'b': 2,
        'a': {'d': 4, 'c': 3},
      }),
      syncCanonicalJson({
        'a': {'c': 3, 'd': 4},
        'b': 2,
      }),
    );
  });
}
