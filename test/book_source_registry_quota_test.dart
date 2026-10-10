import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      additionalSourceProtocolsPreferenceKey: true,
    });
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
    await BookSourceRegistry.resetForTesting();
  });

  tearDown(() async {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
    await BookSourceRegistry.resetForTesting();
  });

  test('ORSP sources stay unlimited for a basic account', () async {
    final registry = BookSourceRegistry(storage: _MemoryStorage());

    for (var index = 0; index < 5; index++) {
      await registry.upsert(_orsp('orsp-$index'));
    }

    expect(await registry.load(), hasLength(5));
  });

  test('reader entitlement still limits other protocols to two', () async {
    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: false);
    final registry = BookSourceRegistry(storage: _MemoryStorage());

    await registry.upsert(_reading('one'));
    await registry.upsert(_reading('two'));

    await expectLater(
      registry.upsert(_reading('three')),
      throwsA(isA<BookSourceQuotaExceededException>()),
    );
    expect(await registry.load(), hasLength(2));
  });

  test('premium account has no other-protocol quota', () async {
    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: true);
    final registry = BookSourceRegistry(storage: _MemoryStorage());

    for (var index = 0; index < 5; index++) {
      await registry.upsert(_reading('reading-$index'));
    }

    expect(await registry.load(), hasLength(5));
  });

  test(
    'batch updates identities first and partially accepts in input order',
    () async {
      final registry = BookSourceRegistry(storage: _MemoryStorage());
      await registry.upsert(_reading('existing', name: 'Old name'));
      final stored = (await registry.load()).single;
      final refreshed = _reading(
        'existing',
        id: 'renamed-id',
        name: 'New name',
      );
      expect(stored.manifestUrl.host, refreshed.manifestUrl.host);
      expect(stored.apiBaseUrl.host, refreshed.apiBaseUrl.host);
      expect(stored.sourceProtocol, refreshed.sourceProtocol);

      final result = await registry.upsertAll([
        refreshed,
        _reading('second'),
        _reading('third'),
        _orsp('orsp'),
      ]);

      expect(result.quotaRejected.map((source) => source.name), ['third']);
      expect(result.conflicted.map((source) => source.name), isEmpty);
      expect(
        result.sources.map((source) => source.id),
        contains('existing-id'),
      );
      expect(result.sources.map((source) => source.id), contains('second-id'));
      expect(result.sources.map((source) => source.id), contains('orsp'));
      expect(
        result.sources.map((source) => source.id),
        isNot(contains('third-id')),
      );
      expect(
        result.sources.singleWhere((source) => source.id == 'existing-id').name,
        'New name',
      );
    },
  );

  test('serialized concurrent mutations cannot exceed the quota', () async {
    final storage = _MemoryStorage();
    final first = BookSourceRegistry(storage: storage);
    final second = BookSourceRegistry(storage: storage);

    final results = await Future.wait(
      [
        first.upsert(_reading('one')),
        second.upsert(_reading('two')),
        first.upsert(_reading('three')),
      ].map((future) async {
        try {
          await future;
          return true;
        } on BookSourceQuotaExceededException {
          return false;
        }
      }),
    );

    expect(results.where((accepted) => accepted), hasLength(2));
    expect(await first.load(), hasLength(2));
  });

  test(
    'legacy excess remains runnable and editable but blocks new sources',
    () async {
      AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: true);
      final storage = _MemoryStorage();
      final registry = BookSourceRegistry(storage: storage);
      await registry.upsertAll([
        _reading('one'),
        _reading('two'),
        _reading('three'),
      ]);
      AdvancedFeatureAccess.update(
        readerUnlocked: true,
        premiumUnlocked: false,
      );

      expect(await registry.loadRunnable(), hasLength(3));
      await registry.updateReadingSource('one-id', {
        ...?_reading('one').sourceConfig,
        'bookSourceName': 'Edited source',
      });
      expect(
        (await registry.load())
            .singleWhere((source) => source.id == 'one-id')
            .name,
        'Edited source',
      );
      await expectLater(
        registry.upsert(_reading('four')),
        throwsA(isA<BookSourceQuotaExceededException>()),
      );
      expect(await registry.load(), hasLength(3));
    },
  );

  test(
    'sync updates existing records but rejects a new source over quota',
    () async {
      final registry = BookSourceRegistry(storage: _MemoryStorage());
      await registry.upsertAll([_reading('one'), _reading('two')]);

      await registry.applySynced(
        _reading('one', id: 'remote-one-id', name: 'Synced name'),
      );
      await expectLater(
        registry.applySynced(_reading('three')),
        throwsA(isA<BookSourceQuotaExceededException>()),
      );

      final sources = await registry.load();
      expect(sources, hasLength(2));
      expect(
        sources.singleWhere((source) => source.id == 'one-id').name,
        'Synced name',
      );
    },
  );

  test('an ORSP id cannot transition to another protocol over quota', () async {
    for (final apply in <Future<void> Function(BookSourceRegistry)>[
      (registry) async {
        await registry.upsert(_reading('shared', id: 'shared'));
      },
      (registry) async {
        await registry.applySynced(_reading('shared', id: 'shared'));
      },
    ]) {
      final registry = BookSourceRegistry(storage: _MemoryStorage());
      await registry.upsertAll([
        _orsp('shared'),
        _reading('one'),
        _reading('two'),
      ]);

      await expectLater(
        apply(registry),
        throwsA(isA<BookSourceQuotaExceededException>()),
      );
      expect(
        (await registry.load())
            .singleWhere((source) => source.id == 'shared')
            .sourceProtocol,
        BookSourceProtocolKind.orsp,
      );
    }
  });

  test(
    'replacement preflight reports identities and rechecks under mutation lock',
    () async {
      final storage = _MemoryStorage();
      final registry = BookSourceRegistry(storage: storage);
      await registry.upsertAll([_reading('one'), _reading('two')]);
      final replacement = _storedSources([
        _reading('one', name: 'Updated'),
        _reading('two'),
        _reading('three'),
      ]);

      final preflight = await registry.preflightReplacement(replacement);
      expect(preflight.limit, 2);
      expect(preflight.existingAdditionalCount, 2);
      expect(preflight.newAdditionalSourceIds, ['three-id']);
      expect(preflight.rejectedSourceIds, ['three-id']);
      expect(preflight.allowed, isFalse);

      var applied = false;
      await expectLater(
        registry.runWithValidatedReplacement(
          replacement,
          () async => applied = true,
        ),
        throwsA(
          isA<BookSourceQuotaExceededException>().having(
            (error) => error.rejectedSourceIds,
            'rejectedSourceIds',
            ['three-id'],
          ),
        ),
      );
      expect(applied, isFalse);
      expect(await registry.load(), hasLength(2));
    },
  );

  test(
    'replacement may reuse slots released by the same atomic restore',
    () async {
      final registry = BookSourceRegistry(storage: _MemoryStorage());
      await registry.upsertAll([_reading('local-one'), _reading('local-two')]);
      final replacement = _storedSources([
        _reading('backup-one'),
        _reading('backup-two'),
      ]);

      final preflight = await registry.preflightReplacement(replacement);

      expect(preflight.existingAdditionalCount, 2);
      expect(preflight.newAdditionalSourceIds, [
        'backup-one-id',
        'backup-two-id',
      ]);
      expect(preflight.rejectedSourceIds, isEmpty);
      expect(preflight.allowed, isTrue);
    },
  );

  test(
    'replacement counts duplicate identities as stored source records',
    () async {
      final storage = _MemoryStorage();
      final registry = BookSourceRegistry(storage: storage);
      final duplicateSources = [
        for (var index = 0; index < 3; index++)
          _reading('same', id: 'id-$index'),
      ];
      final replacement = _storedSources(duplicateSources);
      final preflight = await registry.preflightReplacement(replacement);
      expect(preflight.allowed, isFalse);
      expect(preflight.rejectedSourceIds, ['id-2']);
      var wrote = false;
      await expectLater(
        registry.runWithValidatedReplacement(
          replacement,
          () async => wrote = true,
        ),
        throwsA(isA<BookSourceQuotaExceededException>()),
      );
      expect(wrote, isFalse);
      // An existing legacy multiplicity is retained, but cannot grow further.
      storage.raw = replacement;
      expect(
        (await registry.preflightReplacement(replacement)).allowed,
        isTrue,
      );
      final expanded = _storedSources([
        ...duplicateSources,
        _reading('same', id: 'extra'),
      ]);
      expect(
        (await registry.preflightReplacement(expanded)).rejectedSourceIds,
        ['extra'],
      );
    },
  );
}

String _storedSources(Iterable<RegisteredBookSource> sources) => jsonEncode({
  'version': 2,
  'sources': sources.map((source) => source.toJson()).toList(),
  'groups': <String>[],
});

RegisteredBookSource _orsp(String id) => RegisteredBookSource(
  id: id,
  name: id,
  description: '',
  manifestUrl: Uri.parse('https://$id.example/manifest.json'),
  apiBaseUrl: Uri.parse('https://$id.example/api'),
  protocolVersion: '1.4',
  languages: const ['zh-CN'],
  capabilities: const {'search', 'detail', 'catalog', 'content'},
  enabled: true,
  addedAt: DateTime(2026),
);

RegisteredBookSource _reading(String identity, {String? id, String? name}) =>
    RegisteredBookSource(
      id: id ?? '$identity-id',
      name: name ?? identity,
      description: '',
      manifestUrl: Uri.parse('https://$identity.example'),
      apiBaseUrl: Uri.parse('https://$identity.example'),
      protocolVersion: '1.0',
      languages: const ['zh-CN'],
      capabilities: const {'search'},
      enabled: true,
      addedAt: DateTime(2026),
      sourceProtocol: BookSourceProtocolKind.readingSource,
      sourceConfig: {
        'bookSourceName': name ?? identity,
        'bookSourceUrl': 'https://$identity.example',
        'searchUrl': '/search?key={{key}}',
        'ruleSearch': {'bookList': 'body', 'name': 'text', 'bookUrl': 'href'},
      },
    );

class _MemoryStorage implements BookSourceRegistryStorage {
  String? raw;

  @override
  Future<String?> read() async => raw;

  @override
  Future<bool> write(String value) async {
    raw = value;
    return true;
  }
}
