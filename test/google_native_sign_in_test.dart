import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  test(
    'initializes the Google SDK once and authenticates interactively',
    () async {
      final sdk = _FakeGoogleNativeSdk()..tokens.addAll(['token-1', 'token-2']);
      final service = GoogleNativeSignInService(sdk: sdk);
      const config = GoogleNativeAuthConfig(
        enabled: true,
        serverClientId: 'server.apps.googleusercontent.com',
        iosClientId: 'ios.apps.googleusercontent.com',
      );

      expect(
        await service.authenticate(config, platform: TargetPlatform.iOS),
        'token-1',
      );
      expect(
        await service.authenticate(config, platform: TargetPlatform.iOS),
        'token-2',
      );

      expect(sdk.initializeCalls, 1);
      expect(sdk.clientId, config.iosClientId);
      expect(sdk.serverClientId, config.serverClientId);
      expect(sdk.signOutCalls, 2);
      expect(sdk.authenticateCalls, 2);
    },
  );

  test('a canceled account chooser is silent and can be retried', () async {
    final sdk = _FakeGoogleNativeSdk()
      ..errors.add(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      )
      ..tokens.add('token-after-cancel');
    final service = GoogleNativeSignInService(sdk: sdk);
    const config = GoogleNativeAuthConfig(
      enabled: true,
      serverClientId: 'server.apps.googleusercontent.com',
    );

    expect(
      await service.authenticate(config, platform: TargetPlatform.android),
      isNull,
    );
    expect(
      await service.authenticate(config, platform: TargetPlatform.android),
      'token-after-cancel',
    );
    expect(sdk.initializeCalls, 1);
    expect(sdk.authenticateCalls, 2);
  });

  test('missing identity token is a visible login error', () async {
    final service = GoogleNativeSignInService(sdk: _FakeGoogleNativeSdk());

    await expectLater(
      service.authenticate(
        const GoogleNativeAuthConfig(
          enabled: true,
          serverClientId: 'server.apps.googleusercontent.com',
        ),
        platform: TargetPlatform.android,
      ),
      throwsA(
        isA<MemberAccountException>().having(
          (error) => error.message,
          'message',
          contains('身份令牌'),
        ),
      ),
    );
  });

  test(
    'does not reinitialize the singleton with changed OAuth config',
    () async {
      final sdk = _FakeGoogleNativeSdk()..tokens.add('token-1');
      final service = GoogleNativeSignInService(sdk: sdk);

      await service.authenticate(
        const GoogleNativeAuthConfig(
          enabled: true,
          serverClientId: 'server-1.apps.googleusercontent.com',
        ),
        platform: TargetPlatform.android,
      );

      await expectLater(
        service.authenticate(
          const GoogleNativeAuthConfig(
            enabled: true,
            serverClientId: 'server-2.apps.googleusercontent.com',
          ),
          platform: TargetPlatform.android,
        ),
        throwsA(
          isA<MemberAccountException>().having(
            (error) => error.message,
            'message',
            contains('重启'),
          ),
        ),
      );
      expect(sdk.initializeCalls, 1);
    },
  );
}

class _FakeGoogleNativeSdk implements GoogleNativeSignInSdk {
  final List<String?> tokens = [];
  final List<Object> errors = [];
  int initializeCalls = 0;
  int signOutCalls = 0;
  int authenticateCalls = 0;
  String? clientId;
  String? serverClientId;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    initializeCalls++;
    this.clientId = clientId;
    this.serverClientId = serverClientId;
  }

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<String?> authenticate() async {
    authenticateCalls++;
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return tokens.isEmpty ? null : tokens.removeAt(0);
  }
}
