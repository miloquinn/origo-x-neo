// 文件说明：把当前应用皮肤挂入 Flutter ThemeData 扩展树。
// 技术要点：ThemeExtension、离散主题切换、默认皮肤回退。

import 'package:flutter/material.dart';

import 'package:xxread/models/app_skin.dart';

@immutable
class AppSkinTheme extends ThemeExtension<AppSkinTheme> {
  const AppSkinTheme({required this.skin});

  final AppSkin skin;

  static AppSkinTheme of(BuildContext context) =>
      Theme.of(context).extension<AppSkinTheme>() ??
      AppSkinTheme(skin: AppSkin.original);

  @override
  AppSkinTheme copyWith({AppSkin? skin}) =>
      AppSkinTheme(skin: skin ?? this.skin);

  @override
  AppSkinTheme lerp(covariant ThemeExtension<AppSkinTheme>? other, double t) {
    if (other is! AppSkinTheme) return this;
    return t < 0.5 ? this : other;
  }
}
