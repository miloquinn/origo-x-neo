import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/utils/book_open_transition.dart';

class DesktopWindowService {
  DesktopWindowService._();

  static const closeReaderToLibraryPreferenceKey =
      'desktop_close_reader_to_library';
  static const MethodChannel _channel = MethodChannel(
    'com.niki.xxread/desktop_window',
  );

  static GlobalKey<NavigatorState>? _navigatorKey;

  static bool get isDesktopPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    if (!isDesktopPlatform) return;
    _navigatorKey = navigatorKey;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'requestClose') {
      throw MissingPluginException('Unknown desktop window method');
    }
    return handleCloseRequest(
      navigator: _navigatorKey?.currentState,
      preferences: await SharedPreferences.getInstance(),
    );
  }

  @visibleForTesting
  static Future<bool> handleCloseRequest({
    required NavigatorState? navigator,
    required SharedPreferences preferences,
  }) async {
    if ((preferences.getBool(closeReaderToLibraryPreferenceKey) ?? true) !=
            true ||
        !BookOpenTransition.hasActiveReaderActivity ||
        navigator == null ||
        !navigator.canPop()) {
      return false;
    }
    try {
      // Reader routes intentionally veto the first pop while they flush the
      // final reading position, then finish the pop themselves. Reaching the
      // route is therefore a handled close request even when maybePop returns
      // false.
      await navigator.maybePop();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Desktop close request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static void dispose() {
    _navigatorKey = null;
    _channel.setMethodCallHandler(null);
  }
}
