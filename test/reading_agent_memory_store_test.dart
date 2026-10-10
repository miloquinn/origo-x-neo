import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/ai/reading_agent_memory_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test(
    'new store keeps agent and proactive recommendations disabled',
    () async {
      final store = ReadingAgentMemoryStore();
      addTearDown(store.dispose);

      await store.ensureLoaded();

      expect(store.permissions.enabled, isFalse);
      expect(store.permissions.proactive, isFalse);
      expect(store.memories, isEmpty);
      expect(store.feedback, isEmpty);
    },
  );

  test('confirmed memory edits and recommendation feedback persist', () async {
    final store = ReadingAgentMemoryStore();
    addTearDown(store.dispose);
    await store.saveMemory(text: ' 喜欢历史推理 ', origin: 'agent_suggestion');
    final id = store.memories.single.id;
    await store.saveMemory(text: '喜欢历史小说', id: id);
    await store.recordFeedback(
      title: '长安十二时辰',
      author: '马伯庸',
      interested: false,
    );

    final restored = ReadingAgentMemoryStore();
    addTearDown(restored.dispose);
    await restored.ensureLoaded();

    expect(restored.memories.single.id, id);
    expect(restored.memories.single.text, '喜欢历史小说');
    expect(restored.feedback.single, {
      'title': '长安十二时辰',
      'author': '马伯庸',
      'value': 'not_interested',
    });

    await restored.deleteMemory(id);
    expect(restored.memories, isEmpty);
  });

  test('unconfirmed inferred preferences are ignored when loading', () async {
    SharedPreferences.setMockInitialValues({
      ReadingAgentMemoryStore.prefsKey: jsonEncode({
        'version': 1,
        'permissions': {'enabled': false, 'proactive': false},
        'memories': [
          {
            'id': 'inferred',
            'text': '读得久，所以一定喜欢长篇小说',
            'confirmedByUser': false,
            'createdAt': '2026-10-10T00:00:00.000Z',
            'updatedAt': '2026-10-10T00:00:00.000Z',
          },
          {
            'id': 'confirmed',
            'text': '用户明确说喜欢科幻',
            'confirmedByUser': true,
            'createdAt': '2026-10-10T00:00:00.000Z',
            'updatedAt': '2026-10-10T00:00:00.000Z',
          },
        ],
      }),
    });
    final store = ReadingAgentMemoryStore();
    addTearDown(store.dispose);

    await store.ensureLoaded();

    expect(store.memories.map((memory) => memory.id), ['confirmed']);
  });

  test('concurrent saves serialize without losing either preference', () async {
    final store = ReadingAgentMemoryStore();
    addTearDown(store.dispose);

    await Future.wait([
      store.saveMemory(text: '喜欢科幻'),
      store.saveMemory(text: '避开剧透'),
    ]);

    expect(store.memories.map((memory) => memory.text).toSet(), {
      '喜欢科幻',
      '避开剧透',
    });
    final restored = ReadingAgentMemoryStore();
    addTearDown(restored.dispose);
    await restored.ensureLoaded();
    expect(restored.memories, hasLength(2));
  });

  test(
    'failed save rolls back state and does not poison later mutations',
    () async {
      final preferences = await SharedPreferences.getInstance();
      var calls = 0;
      final store = ReadingAgentMemoryStore(
        preferences: () async {
          calls++;
          if (calls == 2) throw StateError('disk unavailable');
          return preferences;
        },
      );
      addTearDown(store.dispose);
      await store.ensureLoaded();

      await expectLater(
        store.saveMemory(text: 'must roll back'),
        throwsA(isA<StateError>()),
      );
      expect(store.memories, isEmpty);

      await store.saveMemory(text: 'later save succeeds');
      expect(store.memories.single.text, 'later save succeeds');
    },
  );
}
