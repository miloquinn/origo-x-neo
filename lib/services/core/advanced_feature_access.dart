import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/account_api_client.dart';

const String additionalSourceProtocolsPreferenceKey =
    'additional_source_protocols_v1';
const String privateBookSourceNetworkPreferenceKey =
    'private_book_source_network_v1';

/// Shared runtime gate for consumers outside the widget/provider tree.
/// AppSettingsNotifier keeps this in sync with verified account membership.
/// Persistence is owned by the account controller and restored only after the
/// cached membership is matched to the authenticated account.
@immutable
class AdvancedFeatureAccessSnapshot {
  const AdvancedFeatureAccessSnapshot({
    required this.readerFeaturesUnlocked,
    required this.premiumUnlocked,
  });

  final bool readerFeaturesUnlocked;
  final bool premiumUnlocked;

  @override
  bool operator ==(Object other) =>
      other is AdvancedFeatureAccessSnapshot &&
      readerFeaturesUnlocked == other.readerFeaturesUnlocked &&
      premiumUnlocked == other.premiumUnlocked;

  @override
  int get hashCode => Object.hash(readerFeaturesUnlocked, premiumUnlocked);
}

class AdvancedFeatureAccess {
  static bool _readerUnlocked = false;
  static final ValueNotifier<AdvancedFeatureAccessSnapshot> _access =
      ValueNotifier(
        const AdvancedFeatureAccessSnapshot(
          readerFeaturesUnlocked: false,
          premiumUnlocked: false,
        ),
      );
  static final ValueNotifier<bool> _premiumAccess = ValueNotifier(false);

  static ValueListenable<AdvancedFeatureAccessSnapshot> get accessChanges =>
      _access;

  static ValueListenable<bool> get premiumAccessChanges => _premiumAccess;

  static bool get readerFeaturesUnlocked =>
      _access.value.readerFeaturesUnlocked;

  static bool get premiumUnlocked => _access.value.premiumUnlocked;

  /// Compatibility bridge for callers that have not moved to [update] yet.
  static set premiumUnlocked(bool value) =>
      update(readerUnlocked: _readerUnlocked, premiumUnlocked: value);

  static void update({
    required bool readerUnlocked,
    required bool premiumUnlocked,
  }) {
    _readerUnlocked = readerUnlocked;
    _access.value = AdvancedFeatureAccessSnapshot(
      readerFeaturesUnlocked: readerUnlocked || premiumUnlocked,
      premiumUnlocked: premiumUnlocked,
    );
    _premiumAccess.value = premiumUnlocked;
  }

  static void requireReaderFeatures() {
    if (readerFeaturesUnlocked) return;
    throw const MemberAccountException('此功能需要 Origo 开卷或 Origo 探元权益');
  }

  static Future<bool> additionalProtocolsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(additionalSourceProtocolsPreferenceKey) != false;
  }
}
