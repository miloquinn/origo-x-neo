import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/ai/global_ai_reading_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  Future<Directory> useTemporaryDocumentsDirectory() async {
    final directory = await Directory.systemTemp.createTemp(
      'origo-x-global-ai-test-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => directory.path,
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    return directory;
  }

  test(
    'summary persistence round-trips and preserves existing memory',
    () async {
      final documents = await useTemporaryDocumentsDirectory();
      final memoryFile = File(
        '${documents.path}/ai_knowledge/books/7/memory.json',
      );
      await memoryFile.parent.create(recursive: true);
      await memoryFile.writeAsString(
        jsonEncode({'existingFact': 'keep-me'}),
        flush: true,
      );
      final service = GlobalAIReadingService.forTesting();

      await service.saveBookSummary(bookId: '7', summary: '# Complete summary');

      expect(await service.loadBookSummary('7'), '# Complete summary');
      final memory = await service.loadBookMemory('7');
      expect(memory?['existingFact'], 'keep-me');
      expect(memory?['summaryCreatedAt'], isA<String>());
      expect(memory?['updatedAt'], isA<String>());
      expect(memory?['summaryCreatedAt'], memory?['updatedAt']);
    },
  );

  test('real filesystem write failure is surfaced to the caller', () async {
    final documents = await useTemporaryDocumentsDirectory();
    final memoryPath = '${documents.path}/ai_knowledge/books/9/memory.json';
    await Directory(memoryPath).create(recursive: true);
    final service = GlobalAIReadingService.forTesting();

    await expectLater(
      service.saveBookSummary(bookId: '9', summary: '# Must not succeed'),
      throwsA(isA<FileSystemException>()),
    );
  });
}
