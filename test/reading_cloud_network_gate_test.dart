import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/services/account/account_api_client.dart';
import 'package:xxread/services/account/account_models.dart';
import 'package:xxread/services/account/member_account_controller.dart';
import 'package:xxread/services/reading/reading_account_scope.dart';
import 'package:xxread/services/reading/reading_cloud_controller.dart';
import 'package:xxread/services/reading/reading_cloud_store.dart';

const _owner = '00000000-0000-4000-8000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'networkAllowed false keeps initialize and listeners local-only',
    () async {
      final scope = ReadingAccountScope();
      await scope.setOwner(_owner);
      final store = _Store()..hasPending = true;
      final api = _Api();
      final account = _Account(api);
      final cloud = ReadingCloudController(
        account: account,
        store: store,
        scope: scope,
        automatic: false,
        networkAllowed: false,
      );

      await cloud.initialize();
      await cloud.synchronize();
      await cloud.setPublic(true);
      await cloud.claimGuest();
      account.emit();
      await Future<void>.delayed(Duration.zero);

      expect(account.synchronizeCalls, 0);
      expect(api.calls, isEmpty);
      expect(store.claimCalls, 0);
      expect(store.localReads, greaterThan(0));
      expect(cloud.summary?['user_id'], _owner);

      cloud.dispose();
      account.dispose();
      scope.dispose();
    },
  );

  test(
    'default true performs the normal account and reading requests',
    () async {
      final scope = ReadingAccountScope();
      await scope.setOwner(_owner);
      final store = _Store();
      final api = _Api();
      final account = _Account(api);
      final cloud = ReadingCloudController(
        account: account,
        store: store,
        scope: scope,
        automatic: false,
      );

      await cloud.synchronize();

      expect(account.synchronizeCalls, 1);
      expect(api.calls, [
        'GET summary',
        'GET leaderboard:week',
        'GET leaderboard:month',
      ]);
      expect(cloud.summary?['user_id'], _owner);

      cloud.dispose();
      account.dispose();
      scope.dispose();
    },
  );

  test(
    'revoking permission invalidates in-flight upload before later requests',
    () async {
      final scope = ReadingAccountScope();
      await scope.setOwner(_owner);
      final store = _Store()..hasPending = true;
      final api = _Api()..holdEventUpload = true;
      final account = _Account(api);
      final cloud = ReadingCloudController(
        account: account,
        store: store,
        scope: scope,
        automatic: false,
      );

      final operation = cloud.synchronize();
      await api.eventRequested.future;
      cloud.setNetworkAllowed(false);
      api.releaseEvent.complete();
      await operation;

      expect(api.calls, ['POST events']);
      expect(store.acknowledgeCalls, 0);
      expect(cloud.networkAllowed, isFalse);
      expect(cloud.busy, isFalse);

      cloud.setNetworkAllowed(true);
      await cloud.synchronize();
      expect(
        api.calls,
        containsAllInOrder([
          'POST events',
          'POST events',
          'GET summary',
          'GET leaderboard:week',
          'GET leaderboard:month',
        ]),
      );
      expect(store.acknowledgeCalls, 1);

      cloud.dispose();
      account.dispose();
      scope.dispose();
    },
  );
}

class _Store extends ReadingCloudStore {
  bool hasPending = false;
  int localReads = 0;
  int claimCalls = 0;
  int acknowledgeCalls = 0;

  @override
  Future<Map<String, dynamic>?> cached(String owner) async {
    localReads++;
    return {
      'summary': {'user_id': owner, 'public': false},
      'week': {'user_id': owner, 'items': [], 'me': null},
      'month': {'user_id': owner, 'items': [], 'me': null},
      'updated_at': '2026-10-08T00:00:00Z',
    };
  }

  @override
  Future<int> guestSeconds() async {
    localReads++;
    return 45;
  }

  @override
  Future<({int pending, int rejected})> counts(String owner) async {
    localReads++;
    return (pending: hasPending ? 1 : 0, rejected: 0);
  }

  @override
  Future<List<Map<String, Object?>>> pending(String owner) async => hasPending
      ? [
          {
            'event_id': 'event-1',
            'start_ms': 1,
            'end_ms': 1001,
            'seconds': 1,
            'kind': 'reading',
          },
        ]
      : const [];

  @override
  Future<void> acknowledge(String owner, Map<String, dynamic> result) async {
    acknowledgeCalls++;
    hasPending = false;
  }

  @override
  Future<void> claimGuest(String owner) async {
    claimCalls++;
    hasPending = true;
  }

  @override
  Future<void> cache(String owner, Map<String, dynamic> payload) async {}
}

class _Api extends MemberAccountApiClient {
  final calls = <String>[];
  bool holdEventUpload = false;
  final eventRequested = Completer<void>();
  final releaseEvent = Completer<void>();

  @override
  Future<Map<String, dynamic>> readingRequest(
    String method,
    String endpoint,
    String owner, {
    Map<String, Object?>? data,
    String? period,
  }) async {
    calls.add('$method $endpoint${period == null ? '' : ':$period'}');
    if (endpoint == 'events') {
      if (!eventRequested.isCompleted) eventRequested.complete();
      if (holdEventUpload) {
        holdEventUpload = false;
        await releaseEvent.future;
      }
      return {
        'user_id': owner,
        'accepted': ['event-1'],
        'rejected': [],
      };
    }
    if (endpoint == 'summary') {
      return {'user_id': owner, 'public': false};
    }
    if (endpoint == 'preferences') {
      return {'user_id': owner, 'public': data!['public']};
    }
    return {'user_id': owner, 'items': [], 'me': null};
  }
}

class _Account extends MemberAccountController {
  _Account(this.api);

  final _Api api;
  int synchronizeCalls = 0;

  @override
  MemberAccountApiClient get readingApi => api;

  @override
  MemberUser get user => MemberUser(
    id: _owner,
    email: 'reader@example.test',
    emailVerified: true,
    username: 'reader',
    effectiveName: 'Reader',
    authMethods: const [],
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<void> synchronize() async {
    synchronizeCalls++;
  }

  void emit() => notifyListeners();
}
