import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/pages/book_sources/controllers/book_source_management_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('HTML form sources appear in the existing login filter', () {
    final source = _source().toRegisteredSource();
    final controller = BookSourceManagementController();
    addTearDown(controller.dispose);
    controller.replaceSources([source]);
    controller.setFilter(BookSourceManagementFilter.requiresLogin);
    expect(sourceRequiresLogin(source), isTrue);
    expect(controller.state.visibleSources, [source]);
  });

  test(
    'HTML login uses the shared secure session and restores fields',
    () async {
      final config = _source();
      final store = _SessionStore();
      store.sessions[config.stableId] = const SourceLoginSession(
        loginInfo: {'Email': 'saved@example.test'},
        loginHeaders: {'Authorization': 'existing-session'},
      );
      final source = config.toRegisteredSource();
      var runtime = SourceRuntime(loginSessionStore: store);
      addTearDown(() => runtime.close());

      final fields = await runtime.loadLoginFields(source);
      expect(fields.map((field) => field.name), [
        'Email',
        'Password',
        'Sign in',
      ]);
      expect(fields.first.defaultValue, 'saved@example.test');
      expect(fields.last.action, 'login(true)');

      final message = await runtime.login(source, {
        'Email': 'next@example.test',
        'Password': 'fixture-password',
      }, action: fields.last.action);
      expect(message, 'Signed in as next@example.test');
      final saved = store.sessions[config.stableId]!;
      expect(saved.loginInfo['Email'], 'next@example.test');
      expect(saved.loginInfo['Password'], 'fixture-password');
      expect(saved.loginInfo['confirmed'], 'yes');
      expect(saved.loginHeaders, {'Authorization': 'existing-session'});

      // Form values and source-side updates survive a new runtime. The special
      // LoginInfo bridge key must not become an ordinary preferences cache item.
      runtime.close();
      runtime = SourceRuntime(loginSessionStore: store);
      final restored = await runtime.loadLoginFields(source);
      expect(restored.first.defaultValue, 'next@example.test');
      final preferences = await SharedPreferences.getInstance();
      for (final key in preferences.getKeys()) {
        expect('${preferences.get(key)}', isNot(contains('fixture-password')));
      }
      await runtime.clearLoginSession(source);
      expect(
        (await runtime.loadLoginFields(source)).first.defaultValue,
        isNull,
      );
    },
  );
}

ReadingSourceConfig _source() => ReadingSourceConfig.fromJson({
  'bookSourceName': 'HTML login contract',
  'bookSourceUrl': 'https://login-contract.test',
  'html':
      '''<script>
async function getloginurl() {
  return ${jsonEncode(jsonEncode([
        {'name': 'Email', 'type': 'text'},
        {'name': 'Password', 'type': 'password'},
        {'name': 'Sign in', 'type': 'button', 'action': 'login(true)'},
      ]))};
}
async function login(flag) {
  const bridge = window.flutter_inappwebview;
  const info = JSON.parse(await bridge.callHandler('cache.get', 'LoginInfo'));
  if (!flag || !info.Email || !info.Password) throw new Error('Missing login input');
  info.confirmed = 'yes';
  await bridge.callHandler('cache.set', 'LoginInfo', JSON.stringify(info));
  await bridge.callHandler('showToast', 'Signed in as ' + info.Email);
  return true;
}
</script>''',
});

class _SessionStore implements SourceLoginSessionStore {
  final sessions = <String, SourceLoginSession>{};

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      sessions[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    sessions[sourceId] = session;
  }

  @override
  Future<void> clear(String sourceId) async => sessions.remove(sourceId);
}
