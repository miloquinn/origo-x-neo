import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_distribution.dart';

/// Upgrade-only protection for existing free readers, never a Premium grant.
/// Record both true and false before the current agreement screen is shown.
/// The member_ prefix excludes this device-local record from app backups.
class LegacyReaderAccess {
  LegacyReaderAccess._();

  static const storageKey = 'member_legacy_store_reader_v1';
  static bool _allowed = false;
  static bool get allowed => AppDistribution.isStore && _allowed;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getBool(storageKey);
    if (existing != null) {
      _allowed = existing;
      return;
    }
    _allowed =
        AppDistribution.isStore &&
        preferences.getBool('userAgreementAccepted') == true;
    if (!await preferences.setBool(storageKey, _allowed)) {
      throw StateError('Could not persist reader access migration');
    }
  }

  @visibleForTesting
  static void debugReset() => _allowed = false;
}
