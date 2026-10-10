import 'dart:typed_data';

import '../../models/theme_package.dart';

class ThemePackageStore {
  ThemePackageStore({Object? rootDirectory});

  bool get isSupported => false;

  Future<List<ThemePackage>> loadInstalled() async => const [];

  Future<ThemePackage?> findInstalled(
    String id, {
    int? version,
    bool allowVersionFallback = false,
  }) async => null;

  Future<ThemePackage> install(
    Uint8List bytes, {
    required String expectedSha256,
    required String expectedId,
    required int expectedVersion,
  }) => throw UnsupportedError('Theme packages are unavailable on web.');

  Future<void> remove(ThemePackage package) =>
      throw UnsupportedError('Theme packages are unavailable on web.');
}
