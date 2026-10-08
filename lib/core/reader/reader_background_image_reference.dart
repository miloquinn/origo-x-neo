import 'package:path/path.dart' as path;

/// Stable references for images owned by the custom reader theme library.
class ReaderBackgroundImageReference {
  static const directoryName = 'reader_theme_backgrounds';

  static String? managedReference(String value) {
    final context = value.contains('\\') ? path.windows : path.posix;
    final segments = context.split(value);
    if (segments.any((segment) => segment == '..' || segment == '.')) {
      return null;
    }
    final normalized = context.normalize(value);
    final parent = context.dirname(normalized);
    if (context.basename(parent) != directoryName) return null;
    if (!context.isAbsolute(value) && parent != directoryName) return null;
    final filename = context.basename(normalized);
    if (filename.isEmpty || filename == directoryName) return null;
    return '$directoryName/$filename';
  }

  static String normalize(String value) => managedReference(value) ?? value;

  static bool sameImage(String? first, String? second) =>
      (first == null ? null : normalize(first)) ==
      (second == null ? null : normalize(second));
}
