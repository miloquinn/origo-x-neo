import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/core/app_distribution.dart';

const _configuredDistributionChannel = String.fromEnvironment(
  'ORIGO_DISTRIBUTION_CHANNEL',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.niki.xxread/app_distribution');

  setUp(AppDistribution.debugReset);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    AppDistribution.debugReset();
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS always uses Apple billing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AppDistribution.channel, AppDistributionChannel.appleStore);
    expect(AppDistribution.usesAppleBilling, isTrue);
    expect(AppDistribution.usesGoogleBilling, isFalse);
    expect(AppDistribution.usesStoreBilling, isTrue);
    expect(AppDistribution.isStore, isTrue);
    expect(AppDistribution.allowsExternalSupport, isFalse);
    expect(AppDistribution.readerLicenseRequired, isFalse);
    expect(AppDistribution.suppressesExternalUpdates, isFalse);
  });

  test('Android defaults to direct distribution', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppDistribution.channel, AppDistributionChannel.direct);
    expect(AppDistribution.usesAppleBilling, isFalse);
    expect(AppDistribution.usesGoogleBilling, isFalse);
    expect(AppDistribution.usesStoreBilling, isFalse);
    expect(AppDistribution.isStore, isFalse);
    expect(AppDistribution.allowsExternalSupport, isTrue);
    expect(AppDistribution.readerLicenseRequired, isFalse);
    expect(AppDistribution.suppressesExternalUpdates, isFalse);
  });

  test('Google Play builds use Google billing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);

    expect(AppDistribution.channel, AppDistributionChannel.googlePlay);
    expect(AppDistribution.usesAppleBilling, isFalse);
    expect(AppDistribution.usesGoogleBilling, isTrue);
    expect(AppDistribution.usesStoreBilling, isTrue);
    expect(AppDistribution.isStore, isTrue);
    expect(AppDistribution.allowsExternalSupport, isFalse);
    expect(AppDistribution.readerLicenseRequired, isFalse);
    expect(AppDistribution.suppressesExternalUpdates, isTrue);
  });

  test(
    'compile-time Google Play channel selects Google billing',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppDistribution.channel, AppDistributionChannel.googlePlay);
      expect(AppDistribution.usesGoogleBilling, isTrue);
      expect(AppDistribution.readerLicenseRequired, isFalse);
    },
    skip: _configuredDistributionChannel == 'googlePlay'
        ? false
        : 'requires the Google Play release dart-define',
  );

  test('reader licensing only applies to store builds when enabled', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );
    expect(AppDistribution.readerLicenseRequired, isTrue);

    AppDistribution.debugOverride(
      channel: AppDistributionChannel.direct,
      readerLicenseRequired: true,
    );
    expect(AppDistribution.readerLicenseRequired, isFalse);
  });

  test('unknown configured channels fail closed', () {
    expect(
      () => AppDistribution.debugResolveChannel(
        configuredChannel: 'play',
        platform: TargetPlatform.android,
      ),
      throwsStateError,
    );
  });

  test('configured channels must match their platform', () {
    expect(
      () => AppDistribution.debugResolveChannel(
        configuredChannel: 'direct',
        platform: TargetPlatform.iOS,
      ),
      throwsStateError,
    );
    expect(
      () => AppDistribution.debugResolveChannel(
        configuredChannel: 'appleStore',
        platform: TargetPlatform.android,
      ),
      throwsStateError,
    );
    expect(
      () => AppDistribution.debugResolveChannel(
        configuredChannel: 'googlePlay',
        platform: TargetPlatform.macOS,
      ),
      throwsStateError,
    );
    expect(
      () => AppDistribution.debugResolveChannel(
        configuredChannel: 'direct',
        platform: TargetPlatform.macOS,
        macAppStore: true,
      ),
      throwsStateError,
    );
  });

  test('legacy unspecified channels preserve platform behavior', () {
    expect(
      AppDistribution.debugResolveChannel(
        configuredChannel: '',
        platform: TargetPlatform.iOS,
      ),
      AppDistributionChannel.appleStore,
    );
    expect(
      AppDistribution.debugResolveChannel(
        configuredChannel: '',
        platform: TargetPlatform.android,
      ),
      AppDistributionChannel.direct,
    );
  });

  test('macOS defaults to website billing before a receipt probe', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(AppDistribution.channel, AppDistributionChannel.direct);
    expect(AppDistribution.usesAppleBilling, isFalse);
    expect(AppDistribution.allowsExternalSupport, isTrue);
    expect(AppDistribution.suppressesExternalUpdates, isFalse);
  });

  test('macOS website builds keep redemption and external updates', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    AppDistribution.debugOverride(usesAppleBilling: false);
    expect(AppDistribution.channel, AppDistributionChannel.direct);
    expect(AppDistribution.usesAppleBilling, isFalse);
    expect(AppDistribution.suppressesExternalUpdates, isFalse);
  });

  test('macOS App Store builds use Apple billing and hide website updates', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    AppDistribution.debugOverride(usesAppleBilling: true);
    expect(AppDistribution.channel, AppDistributionChannel.appleStore);
    expect(AppDistribution.usesAppleBilling, isTrue);
    expect(AppDistribution.allowsExternalSupport, isFalse);
    expect(AppDistribution.suppressesExternalUpdates, isTrue);
  });

  test('macOS receipt probe enables App Store billing at runtime', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'isMacAppStore');
          return true;
        });

    await AppDistribution.initialize();

    expect(AppDistribution.usesAppleBilling, isTrue);
    expect(AppDistribution.suppressesExternalUpdates, isTrue);
  });

  test(
    'macOS website builds stay on redemption when no receipt exists',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'isMacAppStore');
            return false;
          });

      await AppDistribution.initialize();

      expect(AppDistribution.usesAppleBilling, isFalse);
      expect(AppDistribution.suppressesExternalUpdates, isFalse);
    },
  );
}
