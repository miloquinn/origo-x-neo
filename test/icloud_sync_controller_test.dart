import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/icloud/icloud_sync_controller.dart';
import 'package:xxread/services/icloud/icloud_sync_models.dart';
import 'package:xxread/services/icloud/icloud_sync_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  late SharedPreferences preferences;
  late _FakeStore store;
  late _FakeTransport transport;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('icloud-controller-');
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = _FakeStore();
    transport = _FakeTransport();
  });

  tearDown(() async {
    await documents.delete(recursive: true);
  });

  ICloudSyncController controller({bool networkAllowed = true}) =>
      ICloudSyncController(
        store: store,
        transport: transport,
        documents: documents,
        preferences: preferences,
        supported: true,
        networkAllowed: networkAllowed,
      );

  test('starts disabled and never auto-enables', () async {
    store.values['setting:theme'] = {'name': 'dark'};
    final sync = controller();
    await sync.initialize();

    expect(sync.enabled, isFalse);
    expect(sync.status, 'disabled');
    expect(transport.files, isEmpty);
    sync.dispose();
  });

  test('publishes local revisions and durable tombstones', () async {
    store.values['book:one'] = {'title': 'One'};
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    var records = _ownRecords(transport);
    expect(records.single.value, {'title': 'One'});
    store.values.remove('book:one');
    await sync.synchronize();
    records = _ownRecords(transport);
    expect(records.single.value, isNull);
    expect(records.single.clock.values.single, 2);
    sync.dispose();
  });

  test('missing remote manifests do not delete local data', () async {
    store.values['book:local'] = {'title': 'Kept'};
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);
    transport.files.removeWhere(
      (path, _) => path.startsWith('sync-v1/devices/'),
    );

    await sync.synchronize();
    expect(store.values['book:local'], {'title': 'Kept'});
    expect(store.applied, isEmpty);
    sync.dispose();
  });

  test(
    'concurrent device revisions conflict until explicit resolution',
    () async {
      store.values['progress:book'] = {'page': 4, 'label': 'This device'};
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);
      final local = _ownRecords(transport).single;
      final other = ICloudRecord(
        key: local.key,
        value: {'page': 9, 'label': 'Other device'},
        clock: const {'device-b': 1},
        device: 'device-b',
        modifiedAt: 2,
      );
      transport.putManifest('device-b', [other]);

      await sync.synchronize();
      expect(sync.conflicts, hasLength(1));
      expect(store.values['progress:book']!['page'], 4);

      await sync.resolveConflict(local.key, other);
      expect(store.values['progress:book']!['page'], 9);
      final resolved = _ownRecords(transport).single;
      expect(resolved.clock['device-b'], 1);
      final localVectorDevice = local.clock.keys.single;
      expect(
        resolved.clock[localVectorDevice],
        greaterThan(local.clock[localVectorDevice]!),
      );
      expect(sync.conflicts, isEmpty);
      sync.dispose();
    },
  );

  test('account change pauses and requires explicit re-enable', () async {
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);
    transport.accountId = 'account-b';

    await sync.synchronize();
    expect(sync.enabled, isFalse);
    expect(sync.status, 'accountChanged');
    expect(sync.error, 'accountChanged');

    await sync.setEnabled(true);
    expect(sync.enabled, isTrue);
    expect(preferences.getString('icloud_sync_account_v1'), 'account-b');
    sync.dispose();
  });

  test(
    'network revocation cancels an in-flight manifest application',
    () async {
      final remote = ICloudRecord(
        key: 'setting:font',
        value: const {'size': 24},
        clock: const {'device-b': 1},
        device: 'device-b',
        modifiedAt: 1,
      );
      transport.putManifest('device-b', [remote]);
      transport.pauseReads = true;
      final sync = controller();
      await sync.initialize();
      final enabling = sync.setEnabled(true);
      await transport.readStarted.future;
      sync.setNetworkAllowed(false);
      transport.releaseReads.complete();
      await enabling;

      expect(store.values, isEmpty);
      expect(store.applied, isEmpty);
      sync.dispose();
    },
  );

  test('pending native upload does not advance lastSync', () async {
    store.values['setting:theme'] = {'name': 'dark'};
    transport.uploaded = false;
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(sync.status, 'pendingUpload');
    expect(sync.lastSync, isNull);
    sync.dispose();
  });

  test('idempotent store apply returning false is still successful', () async {
    final remote = ICloudRecord(
      key: 'setting:font',
      value: const {'size': 24},
      clock: const {'device-b': 1},
      device: 'Other device',
      modifiedAt: 1,
    );
    transport.putManifest('device-b', [remote]);
    store.applyResult = false;
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(sync.error, isNull);
    expect(store.values['setting:font'], {'size': 24});
    final applyCount = store.applied.length;
    await sync.synchronize();
    expect(store.applied, hasLength(applyCount));
    sync.dispose();
  });

  test('queues every missing asset before withholding the manifest', () async {
    final first = File('${documents.path}/first.bin');
    final second = File('${documents.path}/second.bin');
    await first.writeAsString('first');
    await second.writeAsString('second');
    final firstHash = (await sha256.bind(first.openRead()).first).toString();
    final secondHash = (await sha256.bind(second.openRead()).first).toString();
    store.values['book:one'] = {
      'kind': 'book',
      'label': 'One',
      'uid': 'one',
      'row': <String, Object?>{},
      'file': firstHash,
      'cover': secondHash,
    };
    store.assets.addAll({firstHash: first.path, secondHash: second.path});
    transport.uploaded = false;
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(
      transport.writeCalls.where((path) => path.startsWith('sync-v1/assets/')),
      hasLength(2),
    );
    expect(
      transport.writeCalls.where((path) => path.startsWith('sync-v1/devices/')),
      isEmpty,
    );
    expect(sync.status, 'pendingUpload');
    sync.dispose();
  });

  test('64-hex metadata is not interpreted as a file asset', () async {
    final metadataHash = 'a' * 64;
    transport.putManifest('device-b', [
      ICloudRecord(
        key: 'progress:one',
        value: {
          'kind': 'progress',
          'label': 'One',
          'uid': 'one',
          'row': {'content_hash': metadataHash},
        },
        clock: const {'device-b': 1},
        device: 'Other',
        modifiedAt: 1,
      ),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(
      transport.readCalls.where((path) => path.contains('/assets/')),
      isEmpty,
    );
    expect(sync.error, isNull);
    sync.dispose();
  });

  test(
    'referenced book assets require cloud or verified local bytes',
    () async {
      final missingHash = 'b' * 64;
      store.values['book:one'] = {
        'kind': 'book',
        'label': 'One',
        'uid': 'one',
        'row': <String, Object?>{},
        'file': missingHash,
      };
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);

      expect(sync.status, 'error');
      expect(sync.error, 'missingAsset');
      expect(
        transport.writeCalls.where(
          (path) => path.startsWith('sync-v1/devices/'),
        ),
        isEmpty,
      );
      sync.dispose();
    },
  );

  test('corrupt cached assets are downloaded again', () async {
    final bytes = utf8.encode('verified body');
    final hash = sha256.convert(bytes).toString();
    final corrupt = File('${documents.path}/corrupt.bin')
      ..writeAsStringSync('bad');
    store.assets[hash] = corrupt.path;
    transport.files['sync-v1/assets/$hash'] = bytes;
    transport.putManifest('device-b', [
      ICloudRecord(
        key: 'book:one',
        value: {
          'kind': 'book',
          'label': 'One',
          'uid': 'one',
          'row': <String, Object?>{},
          'file': hash,
        },
        clock: const {'device-b': 1},
        device: 'Other',
        modifiedAt: 1,
      ),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(transport.readCalls, contains('sync-v1/assets/$hash'));
    expect(store.values, contains('book:one'));
    sync.dispose();
  });

  test(
    'upload errors retry available assets and fail manifest writes',
    () async {
      final body = File('${documents.path}/body.bin')
        ..writeAsStringSync('body');
      final hash = (await sha256.bind(body.openRead()).first).toString();
      store.values['book:one'] = {
        'kind': 'book',
        'label': 'One',
        'uid': 'one',
        'row': <String, Object?>{},
        'file': hash,
      };
      store.assets[hash] = body.path;
      transport.files['sync-v1/assets/$hash'] = utf8.encode('body');
      transport.uploadErrors['sync-v1/assets/$hash'] = 'network';
      transport.manifestUploadError = 'quota';
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);

      expect(transport.writeCalls, contains('sync-v1/assets/$hash'));
      expect(sync.status, 'error');
      expect(sync.error, 'manifestUploadFailed');
      sync.dispose();
    },
  );

  test(
    'book deletion waits for concurrent progress bookmark and note choice',
    () async {
      const uid = 'one';
      ICloudRecord remote(
        String key,
        Map<String, Object?>? value,
        Map<String, int> clock,
        String writer,
        int modified,
      ) => ICloudRecord(
        key: key,
        value: value,
        clock: clock,
        device: writer,
        writer: writer,
        modifiedAt: modified,
      );
      final book = {
        'kind': 'book',
        'label': 'One',
        'uid': uid,
        'row': <String, Object?>{},
      };
      final progress = {
        'kind': 'progress',
        'label': 'One',
        'uid': uid,
        'row': {'currentPage': 9},
      };
      final bookmark = {
        'kind': 'bookmark',
        'label': 'Bookmark',
        'uid': uid,
        'bookmarkId': 'mark',
        'row': <String, Object?>{},
      };
      final note = {
        'kind': 'note',
        'label': 'Note',
        'uid': uid,
        'annotationId': 'note',
        'row': <String, Object?>{},
      };
      transport.putManifest('delete', [
        remote('book:$uid', null, {'base': 1, 'delete': 1}, 'delete', 2),
        remote('progress:$uid', null, {'base': 1, 'delete': 1}, 'delete', 2),
      ]);
      transport.putManifest('keep', [
        remote('book:$uid', book, {'base': 1, 'keep': 1}, 'keep', 3),
        remote('progress:$uid', progress, {'base': 1, 'keep': 1}, 'keep', 3),
        remote('bookmark:$uid:mark', bookmark, {'keep': 1}, 'keep', 3),
        remote('note:note', note, {'keep': 1}, 'keep', 3),
        remote(
          'setting:reader_theme_mode',
          {
            'kind': 'setting',
            'label': 'Theme',
            'key': 'reader_theme_mode',
            'value': 'dark',
          },
          {'keep': 1},
          'keep',
          3,
        ),
      ]);
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);

      expect(sync.status, 'conflicts');
      expect(sync.error, 'dependentConflict');
      expect(store.values, contains('setting:reader_theme_mode'));
      expect(store.values.containsKey('book:$uid'), isFalse);
      expect(store.values.containsKey('progress:$uid'), isFalse);
      final aggregate = sync.conflicts.singleWhere(
        (item) => item.key == 'book:$uid',
      );
      final keep = aggregate.versions.singleWhere((item) => item.value != null);
      await sync.resolveConflict(aggregate.key, keep);

      expect(
        store.values.keys,
        containsAll([
          'book:$uid',
          'progress:$uid',
          'bookmark:$uid:mark',
          'note:note',
        ]),
      );
      expect(sync.conflicts, isEmpty);
      sync.dispose();
    },
  );

  test('aggregate delete tombstones concurrent book children', () async {
    final book = <String, Object?>{
      'kind': 'book',
      'label': 'One',
      'uid': 'one',
      'row': <String, Object?>{},
    };
    final progress = <String, Object?>{
      'kind': 'progress',
      'label': 'One',
      'uid': 'one',
      'row': <String, Object?>{'currentPage': 3},
    };
    transport.putManifest('delete', [
      _remote('book:one', null, {'base': 1, 'd': 1}, 'd', 2),
      _remote('progress:one', null, {'base': 1, 'd': 1}, 'd', 2),
    ]);
    transport.putManifest('keep', [
      _remote('book:one', book, {'base': 1, 'k': 1}, 'k', 3),
      _remote('progress:one', progress, {'base': 1, 'k': 1}, 'k', 3),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);
    final conflict = sync.conflicts.singleWhere(
      (item) => item.key == 'book:one',
    );
    await sync.resolveConflict(
      conflict.key,
      conflict.versions.singleWhere((item) => item.value == null),
    );

    expect(store.applied.last['book:one']!.value, isNull);
    expect(store.applied.last['progress:one']!.value, isNull);
    sync.dispose();
  });

  test('aggregate exposes every concurrent live parent choice', () async {
    Map<String, Object?> book(String label) => {
      'kind': 'book',
      'label': label,
      'uid': 'one',
      'row': <String, Object?>{'title': label},
    };
    Map<String, Object?> progress(int page) => {
      'kind': 'progress',
      'label': 'One',
      'uid': 'one',
      'row': <String, Object?>{'currentPage': page},
    };
    transport.putManifest('delete', [
      _remote('book:one', null, {'base': 1, 'a': 1}, 'a', 2),
      _remote('progress:one', null, {'base': 1, 'a': 1}, 'a', 2),
    ]);
    transport.putManifest('device-b', [
      _remote('book:one', book('B'), {'base': 1, 'b': 1}, 'b', 3),
      _remote('progress:one', progress(8), {'base': 1, 'b': 1}, 'b', 3),
    ]);
    transport.putManifest('device-c', [
      _remote('book:one', book('C'), {'base': 1, 'c': 1}, 'c', 4),
      _remote('progress:one', progress(12), {'base': 1, 'c': 1}, 'c', 4),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    final conflict = sync.conflicts.singleWhere(
      (item) => item.key == 'book:one',
    );
    expect(conflict.versions, hasLength(3));
    expect(
      conflict.versions.map((item) => item.value?['label']).whereType<String>(),
      containsAll(['B', 'C']),
    );
    final chooseC = conflict.versions.singleWhere(
      (item) => item.value?['label'] == 'C',
    );
    await sync.resolveConflict(conflict.key, chooseC);

    expect(store.values['book:one']!['label'], 'C');
    expect((store.values['progress:one']!['row'] as Map)['currentPage'], 12);
    sync.dispose();
  });

  test(
    'aggregate keeps dependent-only device choices with identical parent',
    () async {
      final book = <String, Object?>{
        'kind': 'book',
        'label': 'Same book',
        'uid': 'one',
        'row': <String, Object?>{'title': 'Same book'},
      };
      Map<String, Object?> progress(int page) => {
        'kind': 'progress',
        'label': 'Same book',
        'uid': 'one',
        'row': <String, Object?>{'currentPage': page},
      };
      transport.putManifest('delete', [
        _remote('book:one', null, {'base': 1, 'a': 1}, 'a', 2),
        _remote('progress:one', null, {'base': 1, 'a': 1}, 'a', 2),
      ]);
      transport.putManifest('device-b', [
        _remote('book:one', book, {'base': 1}, 'b', 1),
        _remote('progress:one', progress(8), {'base': 1, 'b': 1}, 'b', 3),
      ]);
      transport.putManifest('device-c', [
        _remote('book:one', book, {'base': 1}, 'c', 1),
        _remote('progress:one', progress(12), {'base': 1, 'c': 1}, 'c', 4),
      ]);
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);

      final conflict = sync.conflicts.singleWhere(
        (item) => item.key == 'book:one',
      );
      expect(conflict.versions, hasLength(3));
      expect(
        conflict.versions
            .where((item) => item.value != null)
            .map((item) => item.writerId),
        containsAll(['b', 'c']),
      );
      await sync.resolveConflict(
        conflict.key,
        conflict.versions.singleWhere((item) => item.writerId == 'c'),
      );
      expect((store.values['progress:one']!['row'] as Map)['currentPage'], 12);
      sync.dispose();
    },
  );

  test(
    'aggregate keep leaves unrelated dependent writers as a conflict',
    () async {
      final book = <String, Object?>{
        'kind': 'book',
        'label': 'Same book',
        'uid': 'one',
        'row': <String, Object?>{'title': 'Same book'},
      };
      Map<String, Object?> progress(int page) => {
        'kind': 'progress',
        'label': 'Same book',
        'uid': 'one',
        'row': <String, Object?>{'currentPage': page},
      };
      Map<String, Object?> note(String text) => {
        'kind': 'note',
        'label': text,
        'uid': 'one',
        'annotationId': 'note',
        'row': <String, Object?>{'text': text},
      };
      transport.putManifest('delete', [
        _remote('book:one', null, {'base': 1, 'a': 1}, 'a', 2),
        _remote('progress:one', null, {'base': 1, 'a': 1}, 'a', 2),
      ]);
      transport.putManifest('device-b', [
        _remote('book:one', book, {'base': 1}, 'b', 1),
        _remote('progress:one', progress(8), {'base': 1, 'b': 1}, 'b', 3),
      ]);
      transport.putManifest('device-c', [
        _remote('book:one', book, {'base': 1}, 'c', 1),
        _remote('progress:one', progress(12), {'base': 1, 'c': 1}, 'c', 4),
        _remote('note:note', note('C'), {'c': 1}, 'c', 4),
      ]);
      transport.putManifest('device-d', [
        _remote('book:one', book, {'base': 1}, 'd', 1),
        _remote('note:note', note('D'), {'d': 1}, 'd', 5),
      ]);
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);

      final aggregate = sync.conflicts.singleWhere(
        (item) => item.key == 'book:one',
      );
      await sync.resolveConflict(
        aggregate.key,
        aggregate.versions.singleWhere((item) => item.writerId == 'b'),
      );

      expect((store.values['progress:one']!['row'] as Map)['currentPage'], 8);
      final noteConflict = sync.conflicts.singleWhere(
        (item) => item.key == 'note:note',
      );
      expect(
        noteConflict.versions.map((item) => item.writerId),
        containsAll(['c', 'd']),
      );
      sync.dispose();
    },
  );

  test(
    'folder delete promotes children and books to its prior parent',
    () async {
      final bodyBytes = utf8.encode('folder child book');
      final bodyHash = sha256.convert(bodyBytes).toString();
      transport.files['sync-v1/assets/$bodyHash'] = bodyBytes;
      final parent = <String, Object?>{
        'kind': 'folder',
        'label': 'Parent',
        'id': 'parent',
        'row': {
          'id': 'parent',
          'name': 'Parent',
          'parent_id': 'grand',
          'created_at': 1,
        },
      };
      final child = <String, Object?>{
        'kind': 'folder',
        'label': 'Child',
        'id': 'child',
        'row': {
          'id': 'child',
          'name': 'Child',
          'parent_id': 'parent',
          'created_at': 2,
        },
      };
      final book = <String, Object?>{
        'kind': 'book',
        'label': 'One',
        'uid': 'one',
        'row': {'shelf_folder_id': 'parent'},
        'file': bodyHash,
      };
      transport.putManifest('delete', [
        _remote('folder:parent', null, {'base': 1, 'd': 1}, 'd', 2),
      ]);
      transport.putManifest('keep', [
        _remote('folder:parent', parent, {'base': 1, 'k': 1}, 'k', 3),
        _remote('folder:child', child, {'base': 1, 'k': 1}, 'k', 3),
        _remote('book:one', book, {'base': 1, 'k': 1}, 'k', 3),
      ]);
      final sync = controller();
      await sync.initialize();
      await sync.setEnabled(true);
      final conflict = sync.conflicts.singleWhere(
        (item) => item.key == 'folder:parent',
      );
      await sync.resolveConflict(
        conflict.key,
        conflict.versions.singleWhere((item) => item.value == null),
      );

      final applied = store.applied.last;
      expect(
        (applied['folder:child']!.value!['row'] as Map)['parent_id'],
        'grand',
      );
      expect(
        (applied['book:one']!.value!['row'] as Map)['shelf_folder_id'],
        'grand',
      );
      expect(transport.readCalls, contains('sync-v1/assets/$bodyHash'));
      sync.dispose();
    },
  );

  test('folder delete preserves unmatched promoted child choices', () async {
    final parent = <String, Object?>{
      'kind': 'folder',
      'label': 'Parent',
      'id': 'parent',
      'row': {
        'id': 'parent',
        'name': 'Parent',
        'parent_id': 'grand',
        'created_at': 1,
      },
    };
    Map<String, Object?> child(String name) => {
      'kind': 'folder',
      'label': name,
      'id': 'child',
      'row': {
        'id': 'child',
        'name': name,
        'parent_id': 'parent',
        'created_at': 2,
      },
    };
    transport.putManifest('delete', [
      _remote('folder:parent', null, {'base': 1, 'a': 1}, 'a', 2),
    ]);
    transport.putManifest('device-c', [
      _remote('folder:parent', parent, {'base': 1}, 'c', 1),
      _remote('folder:child', child('C'), {'c': 1}, 'c', 3),
    ]);
    transport.putManifest('device-d', [
      _remote('folder:parent', parent, {'base': 1}, 'd', 1),
      _remote('folder:child', child('D'), {'d': 1}, 'd', 4),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    final aggregate = sync.conflicts.singleWhere(
      (item) => item.key == 'folder:parent',
    );
    await sync.resolveConflict(
      aggregate.key,
      aggregate.versions.singleWhere((item) => item.value == null),
    );

    final childConflict = sync.conflicts.singleWhere(
      (item) => item.key == 'folder:child',
    );
    expect(childConflict.versions.map((item) => item.writerId), ['c', 'd']);
    for (final version in childConflict.versions) {
      expect((version.value!['row'] as Map)['parent_id'], 'grand');
    }
    await sync.resolveConflict(
      childConflict.key,
      childConflict.versions.singleWhere((item) => item.writerId == 'c'),
    );
    expect((store.values['folder:child']!['row'] as Map)['parent_id'], 'grand');
    expect(sync.conflicts, isEmpty);
    sync.dispose();
  });

  test('folder parent conflict tolerates already deleted dependents', () async {
    final parent = <String, Object?>{
      'kind': 'folder',
      'label': 'Renamed',
      'id': 'parent',
      'row': {
        'id': 'parent',
        'name': 'Renamed',
        'parent_id': null,
        'created_at': 1,
      },
    };
    final child = <String, Object?>{
      'kind': 'folder',
      'label': 'Child',
      'id': 'child',
      'row': {
        'id': 'child',
        'name': 'Child',
        'parent_id': 'parent',
        'created_at': 2,
      },
    };
    transport.putManifest('delete', [
      _remote('folder:parent', null, {'base': 1, 'd': 1}, 'd', 3),
      _remote('folder:child', null, {'child': 1, 'd': 1}, 'd', 2),
    ]);
    transport.putManifest('rename', [
      _remote('folder:parent', parent, {'base': 1, 'k': 1}, 'k', 3),
      _remote('folder:child', child, {'child': 1}, 'k', 1),
    ]);
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);

    expect(sync.status, 'conflicts');
    expect(sync.error, 'dependentConflict');
    final conflict = sync.conflicts.singleWhere(
      (item) => item.key == 'folder:parent',
    );
    await sync.resolveConflict(
      conflict.key,
      conflict.versions.singleWhere((item) => item.value != null),
    );
    expect(store.applied.last['folder:child']!.value, isNull);
    sync.dispose();
  });

  test('first availability completes a pending user enable', () async {
    transport.available = false;
    final sync = controller();
    await sync.initialize();
    await sync.setEnabled(true);
    expect(sync.enabled, isTrue);
    expect(preferences.getString('icloud_sync_account_v1'), isNull);

    transport.available = true;
    await sync.synchronize();
    expect(sync.enabled, isTrue);
    expect(preferences.getString('icloud_sync_account_v1'), 'account-a');
    expect(sync.error, isNull);
    sync.dispose();
  });

  test(
    'publishes local changes without receiving while apply is deferred',
    () async {
      transport.putManifest('device-b', [
        ICloudRecord(
          key: 'setting:remote',
          value: const {'value': true},
          clock: const {'device-b': 1},
          device: 'Other device',
          modifiedAt: 1,
        ),
      ]);
      store.values['setting:local'] = {'value': true};
      final sync = controller();
      sync.canApply = () => false;
      await sync.initialize();
      await sync.setEnabled(true);

      expect(transport.readCalls, isEmpty);
      expect(store.values.containsKey('setting:remote'), isFalse);
      expect(
        transport.writeCalls.where(
          (path) => path.startsWith('sync-v1/devices/'),
        ),
        hasLength(1),
      );
      sync.dispose();
    },
  );
}

List<ICloudRecord> _ownRecords(_FakeTransport transport) {
  final entry = transport.files.entries.singleWhere(
    (item) =>
        item.key.startsWith('sync-v1/devices/') &&
        !item.key.endsWith('device-b.json'),
  );
  final manifest = jsonDecode(utf8.decode(entry.value)) as Map<String, dynamic>;
  return (manifest['records'] as List)
      .map(
        (item) => ICloudRecord.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
}

ICloudRecord _remote(
  String key,
  Map<String, Object?>? value,
  Map<String, int> clock,
  String writer,
  int modifiedAt,
) => ICloudRecord(
  key: key,
  value: value,
  clock: clock,
  device: writer,
  writer: writer,
  modifiedAt: modifiedAt,
);

class _FakeStore implements ICloudSyncStore {
  final values = <String, Map<String, Object?>>{};
  final assets = <String, String>{};
  final applied = <Map<String, ICloudRecord>>[];
  bool applyResult = true;

  @override
  Future<ICloudLocalSnapshot> capture() async => ICloudLocalSnapshot(
    Map<String, Map<String, Object?>>.from(values),
    Map<String, String>.from(assets),
  );

  @override
  Future<bool> apply(
    Map<String, ICloudRecord> records,
    Map<String, String> assets,
  ) async {
    applied.add(Map<String, ICloudRecord>.from(records));
    for (final entry in records.entries) {
      final value = entry.value.value;
      if (value == null) {
        values.remove(entry.key);
      } else {
        values[entry.key] = Map<String, Object?>.from(value);
      }
    }
    return applyResult;
  }
}

class _FakeTransport implements ICloudSyncTransport {
  String accountId = 'account-a';
  bool available = true;
  bool uploaded = true;
  bool pauseReads = false;
  String? installationIdentity = 'install-a';
  final files = <String, List<int>>{};
  final writeCalls = <String>[];
  final readCalls = <String>[];
  final uploadErrors = <String, String>{};
  String? manifestUploadError;
  final readStarted = Completer<void>();
  final releaseReads = Completer<void>();

  void putManifest(String device, List<ICloudRecord> records) {
    files['sync-v1/devices/$device.json'] = utf8.encode(
      jsonEncode({
        'version': 1,
        'deviceId': device,
        'records': records.map((item) => item.toJson()).toList(),
      }),
    );
  }

  @override
  Future<ICloudTransportStatus> status() async => ICloudTransportStatus(
    available: available,
    accountId: available ? accountId : null,
    deviceName: 'Test device',
    installationIdentity: installationIdentity,
  );

  @override
  Future<List<ICloudRemoteFile>> list({required String accountId}) async =>
      files.entries
          .map(
            (entry) => ICloudRemoteFile(
              path: entry.key,
              bytes: entry.value.length,
              uploaded: !uploadErrors.containsKey(entry.key),
              uploadError: uploadErrors[entry.key],
            ),
          )
          .toList();

  @override
  Future<String> read({
    required String path,
    required String destinationPath,
    required String accountId,
  }) async {
    readCalls.add(path);
    if (pauseReads) {
      if (!readStarted.isCompleted) readStarted.complete();
      await releaseReads.future;
    }
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(files[path]!, flush: true);
    return destination.path;
  }

  @override
  Future<ICloudWriteResult> write({
    required String path,
    required String sourcePath,
    required String accountId,
  }) async {
    writeCalls.add(path);
    files[path] = await File(sourcePath).readAsBytes();
    if (path.startsWith('sync-v1/assets/')) uploadErrors.remove(path);
    final error = path.startsWith('sync-v1/devices/')
        ? manifestUploadError
        : null;
    return ICloudWriteResult(
      uploaded: error == null && uploaded,
      uploadError: error,
    );
  }
}
