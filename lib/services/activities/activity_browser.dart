import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile uses the platform's browser sheet. Desktop and web use their normal
/// browser. There is no JavaScript bridge into the account or purchase APIs.
Future<bool> openActivityDetail(Uri uri) => launchUrl(
  uri,
  mode:
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
      ? LaunchMode.inAppBrowserView
      : LaunchMode.externalApplication,
  browserConfiguration: const BrowserConfiguration(showTitle: true),
);
