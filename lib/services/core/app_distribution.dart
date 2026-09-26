import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppDistributionChannel { direct, googlePlay, appleStore }

/// Distinguishes store commerce from website / GitHub distribution.
///
/// iOS always uses StoreKit. macOS uses StoreKit only for Mac App Store
/// builds, identified by `--dart-define=OPEN_READING_MACOS_APP_STORE=true`
/// or a live `_MASReceipt`. Direct Developer ID / notarized builds keep the
/// website redemption-code flow. Android defaults to direct distribution;
/// Google Play bundles must explicitly set
/// `--dart-define=ORIGO_DISTRIBUTION_CHANNEL=googlePlay`.
class AppDistribution {
  AppDistribution._();

  static const _channelName = 'com.niki.xxread/app_distribution';
  static const _macosAppStoreDefine = bool.fromEnvironment(
    'OPEN_READING_MACOS_APP_STORE',
  );
  static const _distributionChannelDefine = String.fromEnvironment(
    'ORIGO_DISTRIBUTION_CHANNEL',
  );
  static const _storeReaderLicenseRequiredDefine = bool.fromEnvironment(
    'ORIGO_STORE_READER_LICENSE_REQUIRED',
  );

  static const MethodChannel _channel = MethodChannel(_channelName);

  static AppDistributionChannel? _debugOverrideChannel;
  static bool? _debugOverrideReaderLicenseRequired;
  static bool? _runtimeMacAppStore;

  /// Test-only override. `null` restores production detection.
  @visibleForTesting
  static void debugOverride({
    AppDistributionChannel? channel,
    bool? usesAppleBilling,
    bool? readerLicenseRequired,
  }) {
    assert(channel == null || usesAppleBilling == null);
    _debugOverrideChannel =
        channel ??
        switch (usesAppleBilling) {
          true => AppDistributionChannel.appleStore,
          false => AppDistributionChannel.direct,
          null => null,
        };
    _debugOverrideReaderLicenseRequired = readerLicenseRequired;
  }

  @visibleForTesting
  static void debugReset() {
    _debugOverrideChannel = null;
    _debugOverrideReaderLicenseRequired = null;
    _runtimeMacAppStore = null;
  }

  static AppDistributionChannel get channel {
    if (_debugOverrideChannel != null) return _debugOverrideChannel!;
    return _resolveChannel(
      configuredChannel: _distributionChannelDefine,
      platform: defaultTargetPlatform,
      isWeb: kIsWeb,
      macAppStore: _macosAppStoreDefine || (_runtimeMacAppStore ?? false),
    );
  }

  @visibleForTesting
  static AppDistributionChannel debugResolveChannel({
    required String configuredChannel,
    required TargetPlatform platform,
    bool isWeb = false,
    bool macAppStore = false,
  }) => _resolveChannel(
    configuredChannel: configuredChannel,
    platform: platform,
    isWeb: isWeb,
    macAppStore: macAppStore,
  );

  static AppDistributionChannel _resolveChannel({
    required String configuredChannel,
    required TargetPlatform platform,
    required bool isWeb,
    required bool macAppStore,
  }) {
    final configured = switch (configuredChannel) {
      '' => null,
      'direct' => AppDistributionChannel.direct,
      'googlePlay' => AppDistributionChannel.googlePlay,
      'appleStore' => AppDistributionChannel.appleStore,
      _ => throw StateError(
        'Unknown ORIGO_DISTRIBUTION_CHANNEL: $configuredChannel',
      ),
    };

    if (isWeb) {
      if (configured == null || configured == AppDistributionChannel.direct) {
        return AppDistributionChannel.direct;
      }
      throw StateError('$configuredChannel is not valid for web builds');
    }

    return switch (platform) {
      TargetPlatform.iOS => switch (configured) {
        null ||
        AppDistributionChannel.appleStore => AppDistributionChannel.appleStore,
        _ => throw StateError('$configuredChannel is not valid for iOS'),
      },
      TargetPlatform.macOS => switch (configured) {
        AppDistributionChannel.googlePlay => throw StateError(
          'googlePlay is not valid for macOS',
        ),
        AppDistributionChannel.direct when macAppStore => throw StateError(
          'direct conflicts with the Mac App Store receipt',
        ),
        AppDistributionChannel.direct => AppDistributionChannel.direct,
        AppDistributionChannel.appleStore => AppDistributionChannel.appleStore,
        null =>
          macAppStore
              ? AppDistributionChannel.appleStore
              : AppDistributionChannel.direct,
      },
      TargetPlatform.android => switch (configured) {
        null || AppDistributionChannel.direct => AppDistributionChannel.direct,
        AppDistributionChannel.googlePlay => AppDistributionChannel.googlePlay,
        AppDistributionChannel.appleStore => throw StateError(
          'appleStore is not valid for Android',
        ),
      },
      _ => switch (configured) {
        null || AppDistributionChannel.direct => AppDistributionChannel.direct,
        _ => throw StateError('$configuredChannel is not valid for $platform'),
      },
    };
  }

  static bool get usesAppleBilling =>
      channel == AppDistributionChannel.appleStore;

  static bool get usesGoogleBilling =>
      channel == AppDistributionChannel.googlePlay;

  static bool get usesStoreBilling => usesAppleBilling || usesGoogleBilling;

  static bool get isStore => usesStoreBilling;

  /// Store builds must not expose QR codes or links for external payments.
  static bool get allowsExternalSupport => !isStore;

  /// Whether this store build requires a trial or permanent purchase to read.
  ///
  /// Store release scripts explicitly enable this. Local developer builds may
  /// leave it disabled while testing unrelated reading features.
  static bool get readerLicenseRequired =>
      isStore &&
      (_debugOverrideReaderLicenseRequired ??
          _storeReaderLicenseRequiredDefine);

  /// Store-distributed desktop and Android builds use their store update path.
  static bool get suppressesExternalUpdates =>
      usesGoogleBilling ||
      (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.macOS &&
          usesAppleBilling);

  static void _validateConfiguredChannel() {
    switch (channel) {
      case AppDistributionChannel.direct:
      case AppDistributionChannel.googlePlay:
      case AppDistributionChannel.appleStore:
        return;
    }
  }

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      _runtimeMacAppStore = false;
      _validateConfiguredChannel();
      return;
    }
    if (_macosAppStoreDefine) {
      _runtimeMacAppStore = true;
      _validateConfiguredChannel();
      return;
    }
    try {
      final value = await _channel.invokeMethod<bool>('isMacAppStore');
      _runtimeMacAppStore = value == true;
    } on MissingPluginException {
      _runtimeMacAppStore = false;
    } on PlatformException {
      _runtimeMacAppStore = false;
    }
    _validateConfiguredChannel();
  }
}
