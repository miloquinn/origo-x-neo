import 'dart:async';

import 'support/premium_account.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/networking/book_source_network_policy.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';
import 'package:xxread/utils/page_transitions.dart';

Future<AppSettingsNotifier> _loadNotifier({PremiumTestAccount? account}) async {
  final notifier = AppSettingsNotifier(account: account);
  if (notifier.isInitialized) return notifier;

  final initialized = Completer<void>();
  void listener() {
    if (notifier.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  notifier.addListener(listener);
  listener();
  await initialized.future;
  notifier.removeListener(listener);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BookSourceNetworkPolicy.preferredPrivateNetwork = false;
  });

  tearDown(() {
    BookSourceNetworkPolicy.preferredPrivateNetwork = false;
  });

  test('library defaults to a two-column cover grid', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.libraryLayoutMode, LibraryLayoutMode.grid);
    expect(notifier.libraryGridColumns, 2);
    expect(notifier.libraryGridShowDetails, isTrue);
    expect(
      notifier.libraryBookOpenAnimation,
      LibraryBookOpenAnimation.minimalFade,
    );
    expect(
      notifier.libraryBookOpenAnimationPace,
      LibraryBookOpenAnimationPace.fast,
    );
    expect(notifier.additionalSourceProtocolsEnabled, isFalse);
    expect(notifier.privateBookSourceNetworkEnabled, isFalse);
    expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
  });

  test(
    'premium protocols default on and an explicit opt-out persists',
    () async {
      final account = PremiumTestAccount();
      addTearDown(account.dispose);
      final notifier = await _loadNotifier(account: account);
      addTearDown(notifier.dispose);

      expect(notifier.additionalSourceProtocolsEnabled, isTrue);
      expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isTrue);
      await notifier.setAdditionalSourceProtocolsEnabled(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(additionalSourceProtocolsPreferenceKey), isFalse);
      expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isFalse);

      final restored = await _loadNotifier(account: account);
      addTearDown(restored.dispose);
      expect(restored.additionalSourceProtocolsEnabled, isFalse);
      account.setPremium(false);
      account.setPremium(true);
      expect(restored.additionalSourceProtocolsEnabled, isFalse);
      expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isFalse);
    },
  );

  test('premium private network defaults on and opt-out persists', () async {
    final account = PremiumTestAccount();
    addTearDown(account.dispose);
    final notifier = await _loadNotifier(account: account);
    addTearDown(notifier.dispose);

    expect(notifier.privateBookSourceNetworkEnabled, isTrue);
    expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isTrue);
    await notifier.setPrivateBookSourceNetworkEnabled(false);

    expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(privateBookSourceNetworkPreferenceKey), isFalse);

    final restored = await _loadNotifier(account: account);
    addTearDown(restored.dispose);
    expect(restored.privateBookSourceNetworkEnabled, isFalse);
    expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
    account.setPremium(false);
    account.setPremium(true);
    expect(restored.privateBookSourceNetworkEnabled, isFalse);
    expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
  });

  test(
    'upgrading enables absent preferences and revoking gates them',
    () async {
      final account = PremiumTestAccount(premium: false);
      addTearDown(account.dispose);
      final notifier = await _loadNotifier(account: account);
      addTearDown(notifier.dispose);

      expect(notifier.additionalSourceProtocolsEnabled, isFalse);
      expect(notifier.privateBookSourceNetworkEnabled, isFalse);
      account.setPremium(true);
      expect(notifier.additionalSourceProtocolsEnabled, isTrue);
      expect(notifier.privateBookSourceNetworkEnabled, isTrue);
      expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isTrue);
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isTrue);

      account.setPremium(false);
      expect(notifier.additionalSourceProtocolsEnabled, isFalse);
      expect(notifier.privateBookSourceNetworkEnabled, isFalse);
      expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isFalse);
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(additionalSourceProtocolsPreferenceKey),
        isFalse,
      );
      expect(prefs.containsKey(privateBookSourceNetworkPreferenceKey), isFalse);
    },
  );

  test(
    'saved advanced preferences require live membership and revoke immediately',
    () async {
      SharedPreferences.setMockInitialValues({
        additionalSourceProtocolsPreferenceKey: true,
        privateBookSourceNetworkPreferenceKey: true,
      });
      final account = PremiumTestAccount(premium: false);
      final notifier = await _loadNotifier(account: account);
      addTearDown(account.dispose);
      addTearDown(notifier.dispose);

      expect(notifier.advancedFeaturesUnlocked, isFalse);
      expect(notifier.additionalSourceProtocolsEnabled, isFalse);
      expect(notifier.privateBookSourceNetworkEnabled, isFalse);
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);

      account.setPremium(true);
      expect(notifier.advancedFeaturesUnlocked, isTrue);
      expect(notifier.additionalSourceProtocolsEnabled, isTrue);
      expect(notifier.privateBookSourceNetworkEnabled, isTrue);
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isTrue);

      account.setPremium(false);
      expect(notifier.additionalSourceProtocolsEnabled, isFalse);
      expect(notifier.privateBookSourceNetworkEnabled, isFalse);
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(additionalSourceProtocolsPreferenceKey), isTrue);
      expect(prefs.getBool(privateBookSourceNetworkPreferenceKey), isTrue);
    },
  );

  test(
    'nonmembers cannot enable advanced preferences through setters',
    () async {
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);
      await notifier.setAdditionalSourceProtocolsEnabled(true);
      await notifier.setPrivateBookSourceNetworkEnabled(true);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(additionalSourceProtocolsPreferenceKey),
        isNot(isTrue),
      );
      expect(
        prefs.getBool(privateBookSourceNetworkPreferenceKey),
        isNot(isTrue),
      );
      expect(BookSourceNetworkPolicy.preferredPrivateNetwork, isFalse);
    },
  );

  test('library layout and cover columns restore and persist', () async {
    SharedPreferences.setMockInitialValues({
      'library_layout_mode_v1': 'card',
      'library_grid_columns_v1': 3,
      'library_grid_show_details_v1': false,
      'library_book_open_animation_v1': 'minimalFade',
      'library_book_open_animation_pace_v1': 'fast',
    });
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.libraryLayoutMode, LibraryLayoutMode.card);
    expect(notifier.libraryGridColumns, 3);
    expect(notifier.libraryGridShowDetails, isFalse);
    expect(
      notifier.libraryBookOpenAnimation,
      LibraryBookOpenAnimation.minimalFade,
    );
    expect(
      notifier.libraryBookOpenAnimationPace,
      LibraryBookOpenAnimationPace.fast,
    );

    await notifier.setLibraryLayoutMode(LibraryLayoutMode.grid);
    await notifier.setLibraryGridColumns(2);
    await notifier.setLibraryGridShowDetails(true);
    await notifier.setLibraryBookOpenAnimation(
      LibraryBookOpenAnimation.classicCover,
    );
    await notifier.setLibraryBookOpenAnimationPace(
      LibraryBookOpenAnimationPace.elegant,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('library_layout_mode_v1'), 'grid');
    expect(prefs.getInt('library_grid_columns_v1'), 2);
    expect(prefs.getBool('library_grid_show_details_v1'), isTrue);
    expect(prefs.getString('library_book_open_animation_v1'), 'classicCover');
    expect(prefs.getString('library_book_open_animation_pace_v1'), 'elegant');
  });

  test(
    'unsupported saved layout values fall back to grid with two columns',
    () async {
      SharedPreferences.setMockInitialValues({
        'library_layout_mode_v1': 'list',
        'library_grid_columns_v1': 5,
        'library_book_open_animation_v1': 'unknown',
      });
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.libraryLayoutMode, LibraryLayoutMode.grid);
      expect(notifier.libraryGridColumns, 2);
      expect(notifier.libraryGridShowDetails, isTrue);
      expect(
        notifier.libraryBookOpenAnimation,
        LibraryBookOpenAnimation.minimalFade,
      );
      expect(
        notifier.libraryBookOpenAnimationPace,
        LibraryBookOpenAnimationPace.fast,
      );
    },
  );

  test('saved elegant animation pace remains opt-in', () async {
    SharedPreferences.setMockInitialValues({
      'library_book_open_animation_pace_v1': 'elegant',
    });
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(
      notifier.libraryBookOpenAnimationPace,
      LibraryBookOpenAnimationPace.elegant,
    );
  });

  test('removed book spread preference falls back to minimal fade', () async {
    SharedPreferences.setMockInitialValues({
      'library_book_open_animation_v1': 'bookSpread',
    });
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(
      notifier.libraryBookOpenAnimation,
      LibraryBookOpenAnimation.minimalFade,
    );
  });
}
