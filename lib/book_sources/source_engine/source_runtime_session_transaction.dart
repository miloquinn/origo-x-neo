part of 'source_runtime_login.dart';

enum _SourceSessionField {
  loginInfo,
  loginHeaders,
  sourceVariable,
  scriptCache,
  browserSession,
}

final Object _sourceSessionTransactionZoneKey = Object();
final Expando<Map<String, Map<_SourceSessionField, _SourceSessionTransaction>>>
_sourceSessionOwners = Expando('source session transaction owners');
final Expando<Map<String, int>> _sourceSessionMutationRevisions = Expando(
  'source session mutation revisions',
);

class _SourceSessionTransaction {
  _SourceSessionTransaction({
    required this.manager,
    required this.sourceId,
    required this.revision,
    required this.previous,
    required this.previousBrowser,
    required this.wasDirty,
    this.parent,
  });

  final SourceRuntimeSessionManager manager;
  final String sourceId;
  final int revision;
  final SourceLoginSession previous;
  final SourceBrowserSession previousBrowser;
  final bool wasDirty;
  final _SourceSessionTransaction? parent;
  final Set<_SourceSessionField> touched = {};
  final Map<_SourceSessionField, _SourceSessionTransaction?> previousOwners =
      {};
  final Map<_SourceSessionField, SourceLoginSession> rollbackSessions = {};
  final Map<_SourceSessionField, SourceBrowserSession> rollbackBrowsers = {};
}

extension _SourceRuntimeSessionTransactionMethods
    on SourceRuntimeSessionManager {
  Map<String, Map<_SourceSessionField, _SourceSessionTransaction>>
  get _transactionOwners => _sourceSessionOwners[this] ??= {};

  Map<String, int> get _transactionMutationRevisions =>
      _sourceSessionMutationRevisions[this] ??= {};

  int _transactionMutationRevision(String id) =>
      _transactionMutationRevisions[id] ?? 0;

  void _markTransactionField(String id, _SourceSessionField field) {
    _transactionMutationRevisions[id] = _transactionMutationRevision(id) + 1;
    final transaction = Zone.current[_sourceSessionTransactionZoneKey];
    if (transaction is! _SourceSessionTransaction ||
        !identical(transaction.manager, this) ||
        transaction.sourceId != id) {
      _transactionOwners[id]?.remove(field);
      return;
    }
    final owner = _transactionOwners[id]?[field];
    if (!identical(owner, transaction)) {
      transaction.previousOwners[field] = owner;
      transaction.rollbackSessions[field] =
          _sessions[id] ?? const SourceLoginSession();
      if (field == _SourceSessionField.browserSession) {
        transaction.rollbackBrowsers[field] =
            _browserTransport?.browserSession(id) ??
            transaction.rollbackSessions[field]!.browserSession;
      }
    }
    transaction.touched.add(field);
    (_transactionOwners[id] ??= {})[field] = transaction;
  }
}

Future<T> _runSourceSessionTransaction<T>(
  SourceRuntimeSessionManager manager,
  ReadingSourceConfig source, {
  required Future<T> Function() action,
  void Function()? cancellationCheck,
}) async {
  cancellationCheck?.call();
  final id = source.stableId;
  final parent = switch (Zone.current[_sourceSessionTransactionZoneKey]) {
    final _SourceSessionTransaction value
        when identical(value.manager, manager) && value.sourceId == id =>
      value,
    _ => null,
  };
  final transaction = _SourceSessionTransaction(
    manager: manager,
    sourceId: id,
    revision: manager.generation(source),
    previous: manager.current(source),
    previousBrowser:
        manager._browserTransport?.browserSession(id) ??
        manager.current(source).browserSession,
    wasDirty: manager._dirty.contains(id),
    parent: parent,
  );
  try {
    final value = await runZoned(
      action,
      zoneValues: {_sourceSessionTransactionZoneKey: transaction},
    );
    cancellationCheck?.call();
    if (manager.generation(source) != transaction.revision) {
      throw const SourceBrowserCancelled();
    }
    _commitSourceSessionTransaction(manager, transaction);
    return value;
  } on Object {
    if (manager.generation(source) == transaction.revision) {
      await _rollbackSourceSessionTransaction(manager, transaction);
    }
    rethrow;
  }
}

void _commitSourceSessionTransaction(
  SourceRuntimeSessionManager manager,
  _SourceSessionTransaction transaction,
) {
  final owners = manager._transactionOwners[transaction.sourceId];
  for (final field in transaction.touched) {
    if (!identical(owners?[field], transaction)) continue;
    final parent = transaction.parent;
    if (parent == null) {
      owners?.remove(field);
    } else {
      parent.previousOwners.putIfAbsent(
        field,
        () => transaction.previousOwners[field],
      );
      parent.rollbackSessions.putIfAbsent(
        field,
        () => transaction.rollbackSessions[field]!,
      );
      if (transaction.rollbackBrowsers[field] case final previous?) {
        parent.rollbackBrowsers.putIfAbsent(field, () => previous);
      }
      parent.touched.add(field);
      owners?[field] = parent;
    }
  }
  if (owners?.isEmpty == true) {
    manager._transactionOwners.remove(transaction.sourceId);
  }
}

Future<void> _rollbackSourceSessionTransaction(
  SourceRuntimeSessionManager manager,
  _SourceSessionTransaction transaction,
) async {
  final id = transaction.sourceId;
  final owners = manager._transactionOwners[id];
  var current = manager._sessions[id] ?? const SourceLoginSession();
  var restoreBrowserTransport = false;
  for (final field in transaction.touched) {
    if (!identical(owners?[field], transaction)) continue;
    current = _restoreSourceSessionField(
      current,
      transaction.rollbackSessions[field] ?? transaction.previous,
      field,
    );
    restoreBrowserTransport |= field == _SourceSessionField.browserSession;
    final previousOwner = transaction.previousOwners[field];
    if (previousOwner == null) {
      owners?.remove(field);
    } else {
      owners?[field] = previousOwner;
    }
  }
  manager._sessions[id] = current;
  if (restoreBrowserTransport) {
    manager._browserTransport?.restoreBrowserSession(
      id,
      transaction.rollbackBrowsers[_SourceSessionField.browserSession] ??
          transaction.previousBrowser,
    );
  }
  if (owners?.isEmpty == true) manager._transactionOwners.remove(id);
  manager._dirty.add(id);
  final persistedRevision = manager._transactionMutationRevision(id);
  try {
    await manager._persist(id, () => manager._store.write(id, current));
    if (manager._transactionMutationRevision(id) == persistedRevision) {
      manager._dirty.remove(id);
    }
  } on MissingPluginException {
    if (transaction.wasDirty || transaction.touched.isNotEmpty) {
      manager._dirty.add(id);
    }
  }
}

SourceLoginSession _restoreSourceSessionField(
  SourceLoginSession current,
  SourceLoginSession previous,
  _SourceSessionField field,
) => SourceLoginSession(
  loginInfo: field == _SourceSessionField.loginInfo
      ? previous.loginInfo
      : current.loginInfo,
  loginHeaders: field == _SourceSessionField.loginHeaders
      ? previous.loginHeaders
      : current.loginHeaders,
  rawLoginHeader: field == _SourceSessionField.loginHeaders
      ? previous.rawLoginHeader
      : current.rawLoginHeader,
  sourceVariable: field == _SourceSessionField.sourceVariable
      ? previous.sourceVariable
      : current.sourceVariable,
  scriptCache: field == _SourceSessionField.scriptCache
      ? previous.scriptCache
      : current.scriptCache,
  browserSession: field == _SourceSessionField.browserSession
      ? previous.browserSession
      : current.browserSession,
);
