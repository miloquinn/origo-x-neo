import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

/// Copyright permission and third-party brand rights are separate notices.
/// Both are bundled offline and exposed to every LicenseRegistry consumer.
void registerProviderAssetLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Lobe Icons',
    ], await rootBundle.loadString('assets/ai_providers/LICENSE-MIT.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Third-party service marks',
    ], await rootBundle.loadString('assets/ai_providers/BRAND-NOTICE.txt'));
  });
}
