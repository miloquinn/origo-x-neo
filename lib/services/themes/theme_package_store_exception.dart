class ThemePackageStoreException implements Exception {
  const ThemePackageStoreException(this.message);

  final String message;

  @override
  String toString() => 'ThemePackageStoreException: $message';
}
