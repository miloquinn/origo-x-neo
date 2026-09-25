import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:xxread/services/books/kindle_native_cache.dart';

void main() {
  late Directory sandbox;
  late Directory cache;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('kindle-native-cache-');
    cache = Directory(path.join(sandbox.path, 'book'));
  });

  tearDown(() {
    sandbox.deleteSync(recursive: true);
  });

  Map<String, dynamic> arguments() => <String, dynamic>{
    'cacheDirectory': cache.path,
    'sourceSize': 1024,
    'sourceModifiedMicros': 123456,
  };

  test('reopens chapter catalog and loads only requested rich chapter', () {
    final parsed = <String, dynamic>{
      'chapters': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'kindle-0',
          'title': 'First',
          'depth': 0,
          'plainText': 'Hello',
          'blocks': <Map<String, String>>[
            <String, String>{'type': 'text', 'content': 'Hello'},
            <String, String>{'type': 'image', 'content': 'cover.jpg'},
          ],
        },
        <String, dynamic>{
          'id': 'kindle-1',
          'title': 'Second',
          'depth': 1,
          'plainText': 'World',
          'blocks': <Map<String, String>>[
            <String, String>{'type': 'text', 'content': 'World'},
          ],
        },
      ],
      'images': <String, Uint8List>{
        'cover.jpg': Uint8List.fromList(<int>[1, 2, 3]),
      },
      'fonts': <String, Uint8List>{
        'kindle_test_font': Uint8List.fromList(<int>[4, 5, 6]),
      },
    };
    writeKindleNativeCache(<String, dynamic>{...arguments(), 'parsed': parsed});

    final index = readKindleNativeIndex(arguments())!;
    final descriptors = (index['chapters'] as List).cast<Map>();
    expect(descriptors, hasLength(2));
    expect(descriptors.first['title'], 'First');
    expect(descriptors.last['depth'], 1);
    expect(index.toString(), isNot(contains('Hello')));
    final fontPath = (index['fonts'] as Map)['kindle_test_font'] as String;
    expect(File(fontPath).readAsBytesSync(), <int>[4, 5, 6]);

    final chapters = loadKindleNativeChapters(<String, dynamic>{
      'cacheDirectory': cache.path,
      'chapters': <Map>[descriptors.first],
    })!;
    expect(chapters, hasLength(1));
    expect(chapters.first['plainText'], 'Hello');
    final image = (chapters.first['blocks'] as List).last as Map;
    expect(File(image['imagePath'] as String).readAsBytesSync(), <int>[
      1,
      2,
      3,
    ]);
    File(fontPath).deleteSync();
    expect(readKindleNativeIndex(arguments()), isNull);
  });

  test('source revision invalidates the index', () {
    writeKindleNativeCache(<String, dynamic>{
      ...arguments(),
      'parsed': <String, dynamic>{
        'chapters': <Map<String, dynamic>>[],
        'images': <String, Uint8List>{},
      },
    });
    expect(readKindleNativeIndex(arguments()), isNotNull);
    expect(
      readKindleNativeIndex(<String, dynamic>{
        ...arguments(),
        'sourceSize': 1025,
      }),
      isNull,
    );
  });

  test('missing chapter signals rebuild instead of serving partial data', () {
    final index = writeKindleNativeCache(<String, dynamic>{
      ...arguments(),
      'parsed': <String, dynamic>{
        'chapters': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'kindle-0',
            'title': 'First',
            'plainText': 'Hello',
            'blocks': <Map<String, String>>[],
          },
        ],
        'images': <String, Uint8List>{},
      },
    });
    final descriptor = (index['chapters'] as List).first as Map;
    File(descriptor['cachePath'] as String).deleteSync();
    expect(
      loadKindleNativeChapters(<String, dynamic>{
        'cacheDirectory': cache.path,
        'chapters': <Map>[descriptor],
      }),
      isNull,
    );
  });

  test('relocates cached chapter, image and font paths', () {
    writeKindleNativeCache(<String, dynamic>{
      ...arguments(),
      'parsed': <String, dynamic>{
        'chapters': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'kindle-0',
            'title': 'First',
            'plainText': '',
            'blocks': <Map<String, String>>[
              <String, String>{'type': 'image', 'content': 'cover.jpg'},
            ],
          },
        ],
        'images': <String, Uint8List>{
          'cover.jpg': Uint8List.fromList(<int>[4, 5, 6]),
        },
        'fonts': <String, Uint8List>{
          'kindle_test_font': Uint8List.fromList(<int>[7, 8, 9]),
        },
      },
    });
    final moved = Directory(path.join(sandbox.path, 'moved-book'));
    cache.renameSync(moved.path);
    final index = readKindleNativeIndex(<String, dynamic>{
      ...arguments(),
      'cacheDirectory': moved.path,
    })!;
    final fontPath = (index['fonts'] as Map)['kindle_test_font'] as String;
    expect(path.isWithin(moved.path, fontPath), isTrue);
    expect(File(fontPath).readAsBytesSync(), <int>[7, 8, 9]);
    final chapter = loadKindleNativeChapters(<String, dynamic>{
      'cacheDirectory': moved.path,
      'chapters': index['chapters'],
    })!.single;
    final image = (chapter['blocks'] as List).single as Map;
    expect(path.isWithin(moved.path, image['imagePath'] as String), isTrue);
    expect(File(image['imagePath'] as String).readAsBytesSync(), <int>[
      4,
      5,
      6,
    ]);
  });
}
