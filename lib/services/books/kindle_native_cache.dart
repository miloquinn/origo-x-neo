import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const int kindleNativeCacheVersion = 2;

/// Reads only the chapter catalog. Chapter bodies and images stay on disk until
/// the reader asks for a small window around the current position.
Map<String, dynamic>? readKindleNativeIndex(Map<String, dynamic> arguments) {
  try {
    final directory = arguments['cacheDirectory'] as String;
    final file = File(path.join(directory, 'index.json'));
    if (!file.existsSync()) return null;
    final index = jsonDecode(file.readAsStringSync());
    if (index is! Map<String, dynamic> ||
        index['version'] != kindleNativeCacheVersion ||
        index['sourceSize'] != arguments['sourceSize'] ||
        index['sourceModifiedMicros'] != arguments['sourceModifiedMicros'] ||
        index['chapters'] is! List ||
        index['fonts'] is! Map) {
      return null;
    }
    final fonts = <String, String>{};
    for (final entry in (index['fonts'] as Map).entries) {
      final fontPath = path.join(
        directory,
        'fonts',
        path.basename(entry.value as String),
      );
      if (!File(fontPath).existsSync()) return null;
      fonts[entry.key as String] = fontPath;
    }
    index['fonts'] = fonts;
    final chapters = index['chapters'] as List;
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i] is! Map) return null;
      (chapters[i] as Map)['cachePath'] = _chapterPath(directory, i);
    }
    return index;
  } catch (_) {
    return null;
  }
}

/// Persists a fully parsed Kindle book. The index is written last so an
/// interrupted write can never look like a complete cache on the next open.
Map<String, dynamic> writeKindleNativeCache(Map<String, dynamic> arguments) {
  final directory = arguments['cacheDirectory'] as String;
  final parsed = Map<String, dynamic>.from(arguments['parsed'] as Map);
  final chapters = (parsed['chapters'] as List).cast<Map>();
  final images = Map<String, Uint8List>.from(parsed['images'] as Map);
  final fonts = Map<String, Uint8List>.from(
    parsed['fonts'] as Map? ?? const <String, Uint8List>{},
  );
  final root = Directory(directory)..createSync(recursive: true);
  final imagesDirectory = Directory(path.join(directory, 'images'))
    ..createSync(recursive: true);
  Directory(path.join(directory, 'chapters')).createSync(recursive: true);
  final fontsDirectory = Directory(path.join(directory, 'fonts'))
    ..createSync(recursive: true);
  final fontPaths = <String, String>{};
  for (final entry in fonts.entries) {
    final filename = '${sha1.convert(utf8.encode(entry.key))}.font';
    File(
      path.join(fontsDirectory.path, filename),
    ).writeAsBytesSync(entry.value, flush: true);
    fontPaths[entry.key] = filename;
  }
  final imagePaths = <String, String>{};
  for (final entry in images.entries) {
    final name = sha1.convert(utf8.encode(entry.key)).toString();
    final imagePath = path.join(imagesDirectory.path, '$name.image');
    File(imagePath).writeAsBytesSync(entry.value, flush: true);
    imagePaths[entry.key] = imagePath;
  }

  final descriptors = <Map<String, dynamic>>[];
  for (var i = 0; i < chapters.length; i++) {
    final chapter = Map<String, dynamic>.from(chapters[i]);
    final blocks = (chapter['blocks'] as List).cast<Map>();
    for (final block in blocks) {
      if (block['type'] != 'image') continue;
      final imagePath = imagePaths[block['content']];
      if (imagePath != null) block['imagePath'] = imagePath;
    }
    _writeJsonAtomically(File(_chapterPath(directory, i)), chapter);
    descriptors.add(<String, dynamic>{
      'id': chapter['id'] as String? ?? 'kindle-$i',
      'title': chapter['title'] as String? ?? '',
      'depth': chapter['depth'] as int? ?? 0,
      'cachePath': _chapterPath(directory, i),
    });
  }
  final index = <String, dynamic>{
    'version': kindleNativeCacheVersion,
    'sourceSize': arguments['sourceSize'],
    'sourceModifiedMicros': arguments['sourceModifiedMicros'],
    'chapters': descriptors,
    'fonts': fontPaths,
  };
  _writeJsonAtomically(File(path.join(root.path, 'index.json')), index);
  return <String, dynamic>{
    ...index,
    'fonts': <String, String>{
      for (final entry in fontPaths.entries)
        entry.key: path.join(fontsDirectory.path, entry.value),
    },
  };
}

/// Returns chapter maps in request order without opening the Kindle source.
/// A missing body invalidates the index so the caller can rebuild the cache.
List<Map<String, dynamic>>? loadKindleNativeChapters(
  Map<String, dynamic> arguments,
) {
  try {
    final directory = arguments['cacheDirectory'] as String;
    final chapters = (arguments['chapters'] as List).cast<Map>();
    final results = <Map<String, dynamic>>[];
    for (final descriptor in chapters) {
      final chapterPath = descriptor['cachePath'] as String;
      final decoded = jsonDecode(File(chapterPath).readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['blocks'] is! List) {
        return null;
      }
      for (final block in decoded['blocks'] as List) {
        if (block is! Map || block['type'] != 'image') continue;
        final imagePath = block['imagePath'] as String?;
        if (imagePath == null) continue;
        final relocated = path.join(
          directory,
          'images',
          path.basename(imagePath),
        );
        if (!File(relocated).existsSync()) return null;
        block['imagePath'] = relocated;
      }
      results.add(decoded);
    }
    return results;
  } catch (_) {
    return null;
  }
}

String _chapterPath(String directory, int index) => path.join(
  directory,
  'chapters',
  'chapter-${index.toString().padLeft(6, '0')}.json',
);

void _writeJsonAtomically(File target, Map<String, dynamic> value) {
  final temporary = File('${target.path}.tmp');
  temporary.writeAsStringSync(jsonEncode(value), flush: true);
  if (target.existsSync()) target.deleteSync();
  temporary.renameSync(target.path);
}
