import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/reader/reader_background_image_reference.dart';

class ReaderThemeBackgroundService {
  ReaderThemeBackgroundService({
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectoryProvider;

  static const int maxImageBytes = 20 * 1024 * 1024;
  static const String _directoryName =
      ReaderBackgroundImageReference.directoryName;
  static const Set<String> _extensions = {'.jpg', '.jpeg', '.png', '.webp'};

  bool get isSupported => true;

  Future<String?> pickAndStore() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    final extension = path.extension(selected.name).toLowerCase();
    if (!_extensions.contains(extension)) {
      throw const ReaderThemeBackgroundException(
        ReaderThemeBackgroundError.unsupportedFormat,
      );
    }
    final bytes = selected.bytes ?? await _readSelectedFile(selected.path);
    if (bytes == null || bytes.isEmpty) {
      throw const ReaderThemeBackgroundException(
        ReaderThemeBackgroundError.readFailed,
      );
    }
    if (bytes.length > maxImageBytes) {
      throw const ReaderThemeBackgroundException(
        ReaderThemeBackgroundError.fileTooLarge,
      );
    }
    final support = await _supportDirectoryProvider();
    final directory = Directory(path.join(support.path, _directoryName));
    await directory.create(recursive: true);
    final destination = File(
      path.join(directory.path, '${const Uuid().v4()}$extension'),
    );
    try {
      await destination.writeAsBytes(bytes, flush: true);
      return '$_directoryName/${path.basename(destination.path)}';
    } catch (error) {
      if (await destination.exists()) await destination.delete();
      throw ReaderThemeBackgroundException(
        ReaderThemeBackgroundError.storageFailed,
        error,
      );
    }
  }

  Future<String> resolvePath(String imagePath) async {
    final reference = ReaderBackgroundImageReference.managedReference(
      imagePath,
    );
    if (reference == null) return imagePath;
    final support = await _supportDirectoryProvider();
    return path.joinAll([support.path, ...reference.split('/')]);
  }

  Future<void> delete(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    if (ReaderBackgroundImageReference.managedReference(imagePath) == null) {
      return;
    }
    try {
      final candidate = await resolvePath(imagePath);
      final file = File(candidate);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A missing background should never prevent theme deletion or editing.
    }
  }

  Future<Uint8List?> _readSelectedFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    return File(filePath).readAsBytes();
  }
}

enum ReaderThemeBackgroundError {
  unsupportedFormat,
  fileTooLarge,
  readFailed,
  storageFailed,
}

class ReaderThemeBackgroundException implements Exception {
  const ReaderThemeBackgroundException(this.code, [this.cause]);

  final ReaderThemeBackgroundError code;
  final Object? cause;
}
