import 'dart:async';

import 'package:flutter/foundation.dart';

import '../account/account_api_client.dart';
import '../account/member_account_controller.dart';
import 'reading_account_scope.dart';
import 'reading_cloud_store.dart';

class ReadingCloudController extends ChangeNotifier {
  ReadingCloudController({
    required this.account,
    ReadingCloudStore? store,
    ReadingAccountScope? scope,
    bool automatic = true,
    bool? networkAllowed,
  }) : _store = store ?? ReadingCloudStore(),
       _scope = scope ?? ReadingAccountScope.instance,
       _networkAllowed = networkAllowed ?? true {
    _owner = _scope.owner;
    _scope.addListener(_ownerChanged);
    account.addListener(_accountChanged);
    if (automatic) {
      _timer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => unawaited(synchronize()),
      );
      unawaited(initialize());
    }
  }

  final MemberAccountController account;
  final ReadingCloudStore _store;
  final ReadingAccountScope _scope;
  Timer? _timer;
  bool _disposed = false;
  int _generation = 0;
  String? _owner;
  String? get owner => _owner;
  Map<String, dynamic>? summary;
  Map<String, dynamic>? week;
  Map<String, dynamic>? month;
  String? updatedAt;
  String? error;
  int guestSeconds = 0;
  int pendingCount = 0;
  int rejectedCount = 0;
  bool busy = false;
  bool savingPreference = false;
  Future<void>? _sync;
  int _syncGeneration = -1;
  bool _networkAllowed;

  bool get networkAllowed => _networkAllowed;

  bool _current(int generation) => !_disposed && generation == _generation;
  bool _networkCurrent(int generation) =>
      _networkAllowed && _current(generation);

  /// Changes the transport permission without starting a synchronization.
  ///
  /// Changing either direction invalidates every in-flight operation. The
  /// caller explicitly decides whether to initialize or synchronize after
  /// enabling access.
  void setNetworkAllowed(bool value) {
    if (_disposed || value == _networkAllowed) return;
    _networkAllowed = value;
    _generation++;
    _sync = null;
    _syncGeneration = -1;
    busy = false;
    savingPreference = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    final generation = _generation;
    final owner = _owner;
    try {
      final cached = owner == null ? null : await _store.cached(owner);
      final guest = await _store.guestSeconds();
      if (!_current(generation)) return;
      if (cached != null && summary == null) _apply(cached);
      guestSeconds = guest;
      notifyListeners();
      if (_networkCurrent(generation)) await synchronize();
    } catch (_) {
      if (_current(generation)) {
        error = '无法读取本地阅读数据，请重试';
        notifyListeners();
      }
    }
  }

  void _ownerChanged() {
    _generation++;
    _owner = _scope.owner;
    summary = week = month = null;
    updatedAt = error = null;
    pendingCount = rejectedCount = 0;
    busy = savingPreference = false;
    notifyListeners();
    unawaited(initialize());
  }

  void _accountChanged() {
    if (!account.loading && account.user?.id == _owner && _owner != null) {
      if (_networkAllowed) {
        unawaited(synchronize());
      } else {
        unawaited(_refreshLocalCounts(_generation));
      }
    }
  }

  Future<void> synchronize() {
    if (_disposed) return Future<void>.value();
    if (!_networkAllowed) return _refreshLocalCounts(_generation);
    if (savingPreference) return _sync ?? Future<void>.value();
    if (_sync != null && _syncGeneration == _generation) return _sync!;
    final owner = _owner;
    if (owner == null || account.user?.id != owner || account.loading) {
      return _refreshLocalCounts(_generation);
    }
    final generation = _generation;
    _syncGeneration = generation;
    final operation = _synchronize(owner, generation);
    _sync = operation;
    return operation.whenComplete(() {
      if (identical(_sync, operation)) _sync = null;
    });
  }

  Future<void> _refreshLocalCounts(int generation) async {
    final owner = _owner;
    try {
      final guest = await _store.guestSeconds();
      final counts = owner == null ? null : await _store.counts(owner);
      if (!_current(generation)) return;
      guestSeconds = guest;
      pendingCount = counts?.pending ?? 0;
      rejectedCount = counts?.rejected ?? 0;
      notifyListeners();
    } catch (_) {
      if (_current(generation)) {
        error = '无法读取本地阅读数据，请重试';
        notifyListeners();
      }
    }
  }

  Future<void> _synchronize(String owner, int generation) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      // Use the account controller's serialized lifecycle to refresh expired
      // credentials before uploading. Reading HTTP calls themselves never
      // refresh tokens and cannot overwrite a newly signed-in account.
      if (!_networkCurrent(generation)) return;
      await account.synchronize();
      if (!_networkCurrent(generation) || account.user?.id != owner) return;
      while (_networkCurrent(generation)) {
        final rows = await _store.pending(owner);
        if (!_networkCurrent(generation)) return;
        if (rows.isEmpty) break;
        if (!_networkCurrent(generation)) return;
        final result = await account.readingApi.readingRequest(
          'POST',
          'events',
          owner,
          data: {'events': rows.map(_store.payload).toList()},
        );
        if (!_networkCurrent(generation)) return;
        _checkOwner(result, owner);
        final expected = rows.map((row) => row['event_id']).toSet();
        final acknowledged = {
          ...result['accepted'] as List,
          ...(result['rejected'] as List).map((item) => item['event_id']),
        };
        if (!setEquals(expected, acknowledged)) {
          throw const MemberAccountException('阅读同步回执不完整，请重试');
        }
        // Updating the captured owner's queue is safe even after a switch.
        await _store.acknowledge(owner, result);
        if (!_networkCurrent(generation)) return;
      }
      if (!_networkCurrent(generation)) return;
      final responses = <Map<String, dynamic>>[];
      for (final request in <Future<Map<String, dynamic>> Function()>[
        () => account.readingApi.readingRequest('GET', 'summary', owner),
        () => account.readingApi.readingRequest(
          'GET',
          'leaderboard',
          owner,
          period: 'week',
        ),
        () => account.readingApi.readingRequest(
          'GET',
          'leaderboard',
          owner,
          period: 'month',
        ),
      ]) {
        if (!_networkCurrent(generation)) return;
        final response = await request();
        if (!_networkCurrent(generation)) return;
        responses.add(response);
      }
      for (final response in responses) {
        _checkOwner(response, owner);
      }
      final cached = <String, dynamic>{
        'summary': responses[0],
        'week': responses[1],
        'month': responses[2],
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _store.cache(owner, cached);
      if (_networkCurrent(generation)) _apply(cached);
    } catch (exception) {
      if (_current(generation)) {
        error = exception is MemberAccountException
            ? exception.statusCode == 404
                  ? '服务器尚未开放阅读云同步，请稍后重试'
                  : exception.message
            : '阅读同步失败，数据已保留在本机，可稍后重试';
      }
    } finally {
      if (_current(generation)) {
        busy = false;
        await _refreshLocalCounts(generation);
      }
    }
  }

  void _checkOwner(Map<String, dynamic> response, String owner) {
    if (response['user_id'] != owner) {
      throw const MemberAccountException('阅读数据账号不匹配，请重新登录');
    }
  }

  void _apply(Map<String, dynamic> value) {
    summary = (value['summary'] as Map).cast<String, dynamic>();
    week = (value['week'] as Map).cast<String, dynamic>();
    month = (value['month'] as Map).cast<String, dynamic>();
    updatedAt = value['updated_at'] as String?;
  }

  Future<void> claimGuest() async {
    final owner = _owner;
    if (!_networkAllowed || owner == null || account.user?.id != owner) return;
    final generation = _generation;
    await _store.claimGuest(owner);
    if (!_networkCurrent(generation)) return;
    await _refreshLocalCounts(generation);
    if (!_networkCurrent(generation)) return;
    await synchronize();
  }

  Future<void> setPublic(bool value) async {
    final owner = _owner;
    if (!_networkAllowed ||
        owner == null ||
        account.user?.id != owner ||
        savingPreference) {
      return;
    }
    final generation = _generation;
    savingPreference = true;
    notifyListeners();
    try {
      final active = _sync;
      if (active != null) await active;
      if (!_networkCurrent(generation)) return;
      final response = await account.readingApi.readingRequest(
        'PUT',
        'preferences',
        owner,
        data: {'public': value},
      );
      if (!_networkCurrent(generation)) return;
      _checkOwner(response, owner);
      if (!_networkCurrent(generation)) return;
      if (summary != null) summary = {...summary!, 'public': value};
      if (!value) {
        Map<String, dynamic>? withoutMe(Map<String, dynamic>? board) =>
            board == null
            ? null
            : {
                ...board,
                'me': null,
                'items': (board['items'] as List)
                    .where((item) => item['user_id'] != owner)
                    .toList(),
              };
        week = withoutMe(week);
        month = withoutMe(month);
      }
      // A successful opt-out must survive a failed subsequent board refresh.
      // Otherwise a restart could show a stale privacy preference.
      if (summary != null && week != null && month != null) {
        await _store.cache(owner, {
          'summary': summary,
          'week': week,
          'month': month,
          'updated_at': updatedAt,
        });
      }
      if (!_networkCurrent(generation)) return;
      savingPreference = false;
      notifyListeners();
      if (!_networkCurrent(generation)) return;
      await synchronize();
    } catch (exception) {
      if (_current(generation)) {
        error = exception is MemberAccountException
            ? exception.message
            : '设置未保存，请重试';
      }
    } finally {
      if (_current(generation)) {
        savingPreference = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _scope.removeListener(_ownerChanged);
    account.removeListener(_accountChanged);
    super.dispose();
  }
}
