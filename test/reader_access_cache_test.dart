import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('installation credential is stable and has 32 random bytes', () async {
    const store = ReaderInstallationCredentialStore();
    final first = await store.getOrCreate();
    final second = await store.getOrCreate();
    expect(first.value, second.value);
    expect(first.value.length, greaterThanOrEqualTo(43));
    expect(first.hash, hasLength(64));
  });

  test(
    'offline attestation is bound to installation, channel and validity',
    () async {
      const credentials = ReaderInstallationCredentialStore();
      const cache = ReaderAccessCache();
      final credential = await credentials.getOrCreate();
      final now = DateTime.utc(2026, 9, 26);
      final attestation = ReaderOfflineAttestation(
        version: 1,
        issuedAt: now,
        validUntil: now.add(const Duration(days: 30)),
        readerUnlocked: true,
        installationKeyHash: credential.hash,
        channel: 'google_play',
        signature: 'opaque-server-signature',
      );
      await cache.save(attestation);

      expect(
        await cache.load(
          credential: credential,
          channel: 'google_play',
          now: now.add(const Duration(days: 1)),
        ),
        isNotNull,
      );
      expect(
        await cache.load(credential: credential, channel: 'apple', now: now),
        isNull,
      );
      expect(
        await cache.load(
          credential: credential,
          channel: 'google_play',
          now: now.add(const Duration(days: 31)),
        ),
        isNull,
      );
    },
  );

  test(
    'logout storage cleanup does not erase anonymous reader state',
    () async {
      const credentials = ReaderInstallationCredentialStore();
      const readerCache = ReaderAccessCache();
      const oldAccountLicense = OfflineReaderLicenseStore();
      final credential = await credentials.getOrCreate();
      final now = DateTime.now();
      await readerCache.save(
        ReaderOfflineAttestation(
          version: 1,
          issuedAt: now,
          validUntil: now.add(const Duration(days: 30)),
          readerUnlocked: true,
          installationKeyHash: credential.hash,
          channel: 'google_play',
          signature: 'opaque',
        ),
      );

      await oldAccountLicense.clear();

      expect((await credentials.getOrCreate()).value, credential.value);
      expect(
        await readerCache.load(credential: credential, channel: 'google_play'),
        isNotNull,
      );
    },
  );
}
