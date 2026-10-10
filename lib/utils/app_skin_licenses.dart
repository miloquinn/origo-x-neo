// 文件说明：向 Flutter 许可证页注册应用皮肤所用的第三方素材。
// 技术要点：许可文本随包离线读取，并通过幂等入口避免重复注册。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _appSkinLicensesRegistered = false;

void registerAppSkinLicenses() {
  if (_appSkinLicensesRegistered) return;
  _appSkinLicensesRegistered = true;

  LicenseRegistry.addLicense(() async* {
    final credits = await rootBundle.loadString('assets/skins/APP_CREDITS.txt');
    final twemojiLicense = await rootBundle.loadString(
      'assets/skins/LICENSE-TWEMOJI-CC-BY-4.0.txt',
    );

    yield LicenseEntryWithLineBreaks(const ['App skin artwork'], credits);
    yield LicenseEntryWithLineBreaks(
      const ['Twemoji graphics'],
      '''
Twemoji graphics, version 14.0.2, by Twitter, Inc. and other contributors.
Source: https://github.com/twitter/twemoji/tree/v14.0.2
Changes: selected SVG graphics were rasterized to transparent 128 x 128 PNG files, stripped of metadata and reduced to 8-bit RGBA. The artwork itself was not redrawn.

$twemojiLicense
''',
    );
  });
}
