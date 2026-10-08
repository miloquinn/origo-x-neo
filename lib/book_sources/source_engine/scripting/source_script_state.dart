import '../source_login_session.dart';

export '../source_login_session.dart' show SourceScriptCacheEntry;

class SourceScriptState {
  String variable = '';
  Map<String, String> values = {};
  Map<String, String> loginInfo = {};
  Map<String, String> loginHeaders = {};
  String? rawLoginHeader;
  Map<String, Object?> javaState = {};
  final Map<String, SourceScriptCacheEntry> cache = {};
  final Map<String, Object?> memoryCache = {};

  Object? readCache(String key, DateTime now) {
    final entry = cache[key];
    if (entry == null) return null;
    if (entry.expiresAt?.isBefore(now) ?? false) {
      cache.remove(key);
      return null;
    }
    return sourceScriptJsonSafe(entry.value);
  }

  void deleteCache(String key) {
    cache.remove(key);
    memoryCache.remove(key);
  }
}

Object? sourceScriptJsonSafe(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry('$key', sourceScriptJsonSafe(item)),
    );
  }
  if (value is Iterable) {
    return value.map(sourceScriptJsonSafe).toList(growable: false);
  }
  return '$value';
}

// Embedded in the bootstrap invocation scope; shares its payload and host bridge.
// Owns source/session cache aliases and origin-scoped browser storage adapters.
const sourceScriptStateAdapters =
    r'''  const __state = Object.assign({}, __payload.state || {});
  const __sourceValues = Object.assign({}, __payload.sourceValues || {});
  const __ruleValues = Object.assign({}, __payload.variables || {});
  let __loginInfo = Object.assign({}, __payload.loginInfo || {});
  let __loginHeaders = Object.assign({}, __payload.loginHeaders || {});
  let __rawLoginHeader = __payload.rawLoginHeader || '';
  const __sourceVariableCacheKey = 'sourceVariable_' + __payload.sourceKey;
  const __loginInfoCacheKey = 'userInfo_' + __payload.sourceKey;
  const __loginHeaderCacheKey = 'loginHeader_' + __payload.sourceKey;
  const __sourceValueCacheKey = (name) =>
    'v_' + __payload.sourceKey + '_' + String(name);
  const __expiringCacheKeys = new Set(__payload.persistentCacheExpiringKeys || []);
  let __sourceVariableExpires = __expiringCacheKeys.has(__sourceVariableCacheKey);
  let __loginInfoExpires = __expiringCacheKeys.has(__loginInfoCacheKey);
  let __loginHeaderExpires = __expiringCacheKeys.has(__loginHeaderCacheKey);
  const __messages = [];
  const __browserLocalStorage = Object.assign(Object.create(null), __payload.browserLocalStorage || {});
  const __storageOrigin = __payload.storageOrigin;
  const __clearedStorageOrigins = new Set();
  function __storage(origin) {
    const key = origin == null ? __storageOrigin : String(origin);
    if (!Object.prototype.hasOwnProperty.call(__browserLocalStorage, key)) {
      __browserLocalStorage[key] = Object.create(null);
    }
    return __browserLocalStorage[key];
  }
  globalThis.localStorage = {
    getItem: (key) => Object.prototype.hasOwnProperty.call(__storage(), String(key))
      ? String(__storage()[String(key)]) : null,
    setItem: (key, value) => { Object.defineProperty(__storage(), String(key), {
      value: String(value), writable: true, enumerable: true, configurable: true
    }); },
    removeItem: (key) => { delete __storage()[String(key)]; },
    clear: () => { __browserLocalStorage[__storageOrigin] = Object.create(null); __clearedStorageOrigins.add(__storageOrigin); },
    key: (index) => Object.keys(__storage())[Number(index)] ?? null,
    get length() { return Object.keys(__storage()).length; }
  };
  let __sourceVariable = __payload.sourceVariable || '';
  function __setLoginInfo(value) {
    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value);
        __loginInfo = parsed && typeof parsed === 'object' && !Array.isArray(parsed)
          ? Object.assign({}, parsed) : {};
      } catch (_) { __loginInfo = {}; }
    } else {
      __loginInfo = value && typeof value === 'object' && !Array.isArray(value)
        ? Object.assign({}, value) : {};
    }
  }
  function __setLoginHeader(value) {
    __rawLoginHeader = typeof value === 'string'
      ? value : value == null ? '' : JSON.stringify(value);
    let parsed;
    try { parsed = JSON.parse(__rawLoginHeader); } catch (_) {}
    __loginHeaders = parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? Object.assign({}, parsed) : {};
  }
  function __loginCryptoKey() {
    return String(__host('androidId', []) || '').substring(0, 16);
  }
  function __encryptedLoginInfo() {
    if (!Object.keys(__loginInfo).length) return null;
    return __host('symmetricCrypto', [
      'encryptBase64', 'AES', __loginCryptoKey(), '', JSON.stringify(__loginInfo)
    ]);
  }
  function __readEncryptedLoginInfo(value) {
    const decoded = __host('symmetricCrypto', [
      'decryptString', 'AES', __loginCryptoKey(), '', String(value == null ? '' : value)
    ]);
    __setLoginInfo(
      String(decoded == null ? '' : decoded).split(String.fromCharCode(0)).join('')
    );
  }
  function __cachePut(name, value, seconds) {
    const cacheKey = String(name);
    const expires = Number(seconds || 0) > 0;
    if (cacheKey === __sourceVariableCacheKey) {
      __sourceVariable = value == null ? '' : String(value);
      __sourceVariableExpires = expires;
    } else if (cacheKey === __loginInfoCacheKey) {
      __readEncryptedLoginInfo(value);
      __loginInfoExpires = expires;
    } else if (cacheKey === __loginHeaderCacheKey) {
      __setLoginHeader(value);
      __loginHeaderExpires = expires;
    }
    return __host('cachePut', [cacheKey, value, Number(seconds || 0)]);
  }
  function __cacheGet(name) {
    const cacheKey = String(name);
    const cached = __host('cacheGet', [cacheKey]);
    if (cached != null) {
      if (cacheKey === __sourceVariableCacheKey) {
        __sourceVariable = String(cached);
      } else if (cacheKey === __loginInfoCacheKey) {
        __readEncryptedLoginInfo(cached);
      } else if (cacheKey === __loginHeaderCacheKey) {
        __setLoginHeader(cached);
      }
      return cached;
    }
    if (cacheKey === __sourceVariableCacheKey && __sourceVariableExpires) {
      __sourceVariable = '';
      __sourceVariableExpires = false;
      return null;
    }
    if (cacheKey === __loginInfoCacheKey && __loginInfoExpires) {
      __loginInfo = {};
      __loginInfoExpires = false;
      return null;
    }
    if (cacheKey === __loginHeaderCacheKey && __loginHeaderExpires) {
      __loginHeaders = {};
      __rawLoginHeader = '';
      __loginHeaderExpires = false;
      return null;
    }
    if (cacheKey === __sourceVariableCacheKey) {
      return __sourceVariable === '' ? null : __sourceVariable;
    }
    if (cacheKey === __loginInfoCacheKey) return __encryptedLoginInfo();
    if (cacheKey === __loginHeaderCacheKey) {
      return __rawLoginHeader === '' ? null : __rawLoginHeader;
    }
    return null;
  }
  function __cacheDelete(name) {
    const cacheKey = String(name);
    if (cacheKey === __sourceVariableCacheKey) {
      __sourceVariable = '';
      __sourceVariableExpires = false;
    } else if (cacheKey === __loginInfoCacheKey) {
      __loginInfo = {};
      __loginInfoExpires = false;
    } else if (cacheKey === __loginHeaderCacheKey) {
      __loginHeaders = {};
      __rawLoginHeader = '';
      __loginHeaderExpires = false;
    }
    return __host('cacheDelete', [cacheKey]);
  }
  globalThis.result = __payload.result;
  globalThis.baseUrl = __payload.baseUrl;
  globalThis.key = (__payload.variables || {}).key || '';
  globalThis.page = Number((__payload.variables || {}).page || 1);
  globalThis.source = {
    bookSourceName: __payload.sourceName || '',
    bookSourceType: Number(__payload.sourceType || 0),
    bookSourceUrl: __payload.sourceUrl,
    bookSourceComment: __payload.sourceComment || '',
    bookSourceGroup: __payload.sourceGroup || '',
    lastUpdateTime: Number(__payload.sourceLastUpdateTime || 0),
    exploreUrl: __payload.sourceExploreUrl || '',
    loginUrl: __payload.sourceLoginUrl || '',
    ruleSearch: __payload.sourceRules.ruleSearch || {},
    ruleExplore: __payload.sourceRules.ruleExplore || {},
    ruleBookInfo: __payload.sourceRules.ruleBookInfo || {},
    ruleToc: __payload.sourceRules.ruleToc || {},
    ruleContent: __payload.sourceRules.ruleContent || {},
    header: __javaMap(__payload.sourceHeader || {}),
    key: __payload.sourceKey,
    getKey: () => __payload.sourceKey,
    getVariable: () => {
      const value = __cacheGet(__sourceVariableCacheKey);
      return value == null ? '' : String(value);
    },
    setVariable: (value) => {
      __sourceVariable = value == null ? '' : String(value);
      if (__sourceVariable === '') __cacheDelete(__sourceVariableCacheKey);
      else __cachePut(__sourceVariableCacheKey, __sourceVariable, 0);
      return value;
    },
    putVariable: (value) => globalThis.source.setVariable(value),
    put: (name, value) => {
      const key = String(name);
      delete __sourceValues[key];
      __cachePut(__sourceValueCacheKey(key), value == null ? '' : String(value), 0);
      return value;
    },
    get: (name) => {
      const key = String(name);
      const value = __cacheGet(__sourceValueCacheKey(key));
      return value == null ? (__sourceValues[key] || '') : String(value);
    },
    getHeaderMap: () => __javaMap(__payload.sourceHeader || {}),
    getLoginHeader: () => {
      __cacheGet(__loginHeaderCacheKey);
      return __rawLoginHeader;
    },
    getLoginHeaderMap: () => {
      __cacheGet(__loginHeaderCacheKey);
      return __javaMap(__loginHeaders);
    },
    putLoginHeader: (value) => {
      __setLoginHeader(value);
      if (__rawLoginHeader === '') __cacheDelete(__loginHeaderCacheKey);
      else __cachePut(__loginHeaderCacheKey, __rawLoginHeader, 0);
      return value;
    },
    removeLoginHeader: () => __cacheDelete(__loginHeaderCacheKey),
    getLocalStorage: (origin) => __javaMap(__storage(origin)),
    getLoginInfo: () => {
      __cacheGet(__loginInfoCacheKey);
      return JSON.stringify(__loginInfo);
    },
    getLoginInfoMap: () => {
      __cacheGet(__loginInfoCacheKey);
      return __javaMap(__loginInfo);
    },
    putLoginInfo: (value) => {
      __setLoginInfo(value);
      if (Object.keys(__loginInfo).length) {
        __cachePut(__loginInfoCacheKey, __encryptedLoginInfo(), 0);
      } else {
        __cacheDelete(__loginInfoCacheKey);
      }
      return true;
    },
    removeLoginInfo: () => { __cacheDelete(__loginInfoCacheKey); return true; }
  };
  Object.defineProperty(globalThis.source, 'variable', {
    get: () => globalThis.source.getVariable(),
    set: (value) => { globalThis.source.setVariable(value); }
  });
  globalThis.cache = {
    put: (name, value, seconds) => __cachePut(name, value, seconds),
    get: (name) => __cacheGet(name),
    delete: (name) => __cacheDelete(name),
    putMemory: (name, value) => __host('cachePutMemory', [String(name), value]),
    getFromMemory: (name) => __host('cacheGetMemory', [String(name)]) ?? null,
    deleteMemory: (name) => __host('cacheDeleteMemory', [String(name)]),
    putFile: (name, value, seconds) => __cachePut(name, value, seconds),
    getFile: (name) => __cacheGet(name)
  };''';
