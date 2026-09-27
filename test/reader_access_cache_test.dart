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
    'account cache requires the same session, account, device and TTL',
    () async {
      const cache = ReaderAccessCache();
      final credential = await const ReaderInstallationCredentialStore()
          .getOrCreate();
      final now = DateTime.utc(2026, 9, 27);
      final license = ReaderOfflineAttestation(
        version: 2,
        accountId: 'account-a',
        subjectType: 'account',
        issuedAt: now,
        validUntil: now.add(const Duration(days: 30)),
        readerUnlocked: true,
        installationKeyHash: credential.hash,
        channel: 'account',
        signature: 'opaque-server-attestation',
      );
      await cache.saveAccount(license, sessionBinding: 'session-a');
      Future<ReaderOfflineAttestation?> read({
        String? session = 'session-a',
        String? account = 'account-a',
        DateTime? at,
        ReaderInstallationCredential? device,
      }) => cache.loadAccount(
        credential: device ?? credential,
        sessionBinding: session,
        accountId: account,
        now: at ?? now,
      );
      expect((await read())?.accountId, 'account-a');
      expect(await read(session: null), isNull);
      expect(await read(session: 'session-b'), isNull);
      expect(await read(account: 'account-b'), isNull);
      expect(await read(at: now.add(const Duration(days: 30))), isNull);
      expect(
        await read(device: const ReaderInstallationCredential('different')),
        isNull,
      );
      // A device license must not be interpreted as an account license.
      await cache.saveAccount(
        ReaderOfflineAttestation(
          version: 1,
          issuedAt: now,
          validUntil: now.add(const Duration(days: 30)),
          readerUnlocked: true,
          installationKeyHash: credential.hash,
          channel: 'google_play',
          signature: 'old-license',
        ),
        sessionBinding: 'session-a',
      );
      expect(await read(), isNull);
      await cache.saveAccount(license, sessionBinding: 'session-a');
      await cache.clearAccount();
      expect(await read(), isNull);
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
