// 文件说明：向 Flutter 许可证页注册应用皮肤所用的第三方素材。
// 技术要点：许可文本随包离线读取，并通过幂等入口避免重复注册。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'provider_asset_licenses.dart';

bool _appSkinLicensesRegistered = false;

void registerAppSkinLicenses() {
  registerProviderAssetLicenses();
  if (_appSkinLicensesRegistered) return;
  _appSkinLicensesRegistered = true;

  LicenseRegistry.addLicense(() async* {
    final credits = await rootBundle.loadString('assets/skins/APP_CREDITS.txt');
    final iconParkLicense = await rootBundle.loadString(
      'assets/skins/LICENSE-ICONPARK-APACHE-2.0.txt',
    );

    yield LicenseEntryWithLineBreaks(const ['App skin artwork'], credits);
    yield LicenseEntryWithLineBreaks(
      const ['IconPark graphics'],
      '''
IconPark graphics, version 1.4.2, by ByteDance and contributors.
Source: https://github.com/bytedance/IconPark/tree/v1.4.2
Changes: selected vector geometry was recolored, composed into coordinated themes and rasterized to transparent PNG images.

$iconParkLicense
''',
    );
  });
}
