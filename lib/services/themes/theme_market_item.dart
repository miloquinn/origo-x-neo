import 'dart:convert';

import '../../models/theme_package.dart';

/// Public metadata identifies one approved, immutable downloadable version.
class ThemeMarketItem {
  ThemeMarketItem.fromJson(Map<String, dynamic> json)
    : schemaVersion = (json['schemaVersion'] ?? 1) as int,
      id = json['id'] as String,
      version = json['version'] as int,
      name = json['name'] as String,
      description = json['description'] as String,
      author = json['author'] as String,
      license = json['license'] as String,
      sha256 = json['sha256'] as String,
      size = json['size'] as int {
    if (schemaVersion != ThemePackage.currentSchemaVersion ||
        !RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id) ||
        id.length > 48 ||
        version < 1 ||
        name.isEmpty ||
        name.length > 60 ||
        description.length > 300 ||
        author.isEmpty ||
        author.length > 60 ||
        license.isEmpty ||
        license.length > 120 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) ||
        size <= 0 ||
        size > maxPackageBytes) {
      throw const FormatException('Invalid approved theme metadata');
    }
  }

  static const maxPackageBytes = 10 * 1024 * 1024;
  final int schemaVersion;
  final String id;
  final int version;
  final String name;
  final String description;
  final String author;
  final String license;
  final String sha256;
  final int size;

  // URLs are derived from validated identity, never taken from package input.
  String get downloadPath =>
      '/api/v1/themes/${Uri.encodeComponent(id)}/download?version=$version';
  String get previewPath =>
      '/api/v1/themes/${Uri.encodeComponent(id)}/preview?version=$version';

  @override
  String toString() => jsonEncode({'id': id, 'version': version});
}
