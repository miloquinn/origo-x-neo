# 应用配色与素材主题

主题入口位于“我的”首页和“偏好设置”的“主题与外观”卡片。主题页提供两类可自由组合的选择：6 套协调配色，以及原始外观和 3 套图片皮肤。主题切换即时预览，不改变明暗模式、玻璃材质、阅读纸张、字体或阅读背景图。

## 配色、入口与持久化

- `lib/utils/app_themes.dart`：`AppThemes.colorPresets` 定义稳定 ID `blue`、`forest`、`amber`、`rose`、`violet`、`graphite`，各自提供浅色/深色主色、辅助色和第三色的完整 Material 3 角色（含 fixed 角色）。默认蓝保持旧方案。
- `lib/services/core/theme_notifier.dart`：`setColorPreset(id)` 保存 `appColorPresetIdV1`，同时维护兼容键 `appAccentColorV2`。新用户及旧默认蓝绑定 `blue`；历史非默认任意强调色保持原值，在主题页以“原有配色”展示，直到用户主动选择套餐。失效 ID 清理后保留旧颜色。旧自由色盘、名称表和翻译适配器已删除，旧色值读取/备份契约保留。
- `lib/pages/settings/app_theme_page.dart`：配色/贴图两类卡片，使用真实渲染器的预览，手机大字体单列与平板双栏布局，选中语义和素材致谢入口。每类选择有操作版本与当前值校验，早期失败不能重试覆盖较新选择。
- `lib/widgets/app_theme_summary_card.dart` 和设置页 `parts/settings_hub_part.dart`：统一摘要入口，沿用设置页懒构建。显示效果与字体/布局分组独立，避免把玻璃参数混入主题套餐。

配色与皮肤各自按选择顺序写入并恢复。保存失败保持即时视觉选择，通过包含原始错误与堆栈的日志和“重试”提示暴露；后续选择可以继续保存，同一选择可重试。阅读偏好与玻璃开关/样式/不透明度始终使用各自原有键。

## 所有权与切换链

```mermaid
flowchart TD
    Catalog[AppSkinCatalog：随包素材目录] --> State[ThemeNotifier：选中皮肤 ID]
    State --> Theme[AppSkinTheme：ThemeData 扩展]
    Theme --> Icons[AppSkinIcon：语义图标]
    Theme --> Pages[PageStyleHelper：页面底图]
    Theme --> Artwork[AppSkinArtwork：导航底图]
    Artwork --> Glass[GlassSurface：现有玻璃材质]
    Glass --> Navigation[导航内容、选中透镜与交互]
    Settings[独立玻璃偏好] --> Glass
```

- `lib/models/app_skin.dart`：不可变素材、语义槽位及目录。构造时校验 ID、随包资源路径和重复定义，不允许覆盖 `original`。
- `lib/services/core/theme_notifier.dart`：恢复与保存 `appSkinIdV1`，通过 `setSkin(id)` 通知现有主题树。连续选择按顺序写入；恢复已移除的 ID 会返回原始皮肤并清理旧键。未知的新选择明确报错。
- `lib/utils/app_skin_theme.dart`：只承载当前已解析的皮肤，不承载目录、控制器或解码缓存。浅色、深色主题由 `lib/main.dart` 注入同一皮肤描述；图片切换采用离散插值。
- `lib/widgets/app_skin_icon.dart`：按语义槽位和选中状态解析图片，沿用原图标尺寸、标签和调用方动画；彩色贴图不被强调色染色。公共返回、搜索、更多入口通过同一适配器解析已有标准图标，其他图标保持原样。
- `lib/utils/page_style_helper.dart` 的 `backgroundDecoration`：背景所有者在现有渐变或颜色上混合底图（浅色 35%、深色 24%），保留文字可读性，不改变布局和命中。首页、书库、书源、AI、设置和普通二级页接入此入口。
- `lib/widgets/app_skin_artwork.dart`：只把导航装饰以浅色 22%、深色 16% 绘制在玻璃下面，裁切装饰本身。它不裁切导航内容，不新增模糊，不修改玻璃参数。

## 随包素材与素材定义

当前 `AppSkinCatalog.builtIn` 包含 `original`、`tidal`（海边来信）、`botanical`（花园漫读）、`celestial`（星际漫游）。后 3 套提供页面/导航底图及 5 个主要导航贴图，公共返回、搜索、更多保持标准图标。素材清单、来源与维护规则见[素材目录](app-skin-assets.md)，随包授权通过 `registerAppSkinLicenses()` 注入应用许可证页。

`AppSkinIconSlot` 包含首页、书库、发现、AI、个人页、返回、搜索和更多。首页槽位从 `HomeNavigationDestination` 映射，不从索引、译文或图标形状推导，因此导航重排与隐藏不会串图。

`AppSkinArtworkSlot.pageBackground` 是共用页面底图，`navigation` 是悬浮导航底图。公共页面 wrapper 在有皮肤底图时把背景交给实际页面所有者；rail 外壳保留自己的渐变，避免再绘制整页贴图。书库转场的临时面板使用同一解析结果，避免转场时闪回默认背景。

每张 `AppSkinImage` 支持 `asset` 和可选 `darkAsset`；缺少深色图时使用普通图。图标的 `AppSkinIconAssets` 支持 `normal` 和可选 `selected`，选中图缺省时复用普通图。当前支持 PNG、WebP、JPEG，资源路径必须在 `assets/` 下；SVG 需在制作阶段导出为支持的图片格式。

新增皮肤先在 Flutter `pubspec.yaml` 声明实际素材目录，再加入 `AppSkinCatalog.builtIn` 的静态定义。例如：

```dart
AppSkin(
  id: 'ocean',
  icons: {
    AppSkinIconSlot.library: AppSkinIconAssets(
      normal: AppSkinImage(asset: 'assets/skins/ocean/library.png'),
      selected: AppSkinImage(asset: 'assets/skins/ocean/library-selected.png'),
    ),
  },
  artwork: {
    AppSkinArtworkSlot.pageBackground:
        AppSkinImage(asset: 'assets/skins/ocean/background.webp'),
    AppSkinArtworkSlot.navigation:
        AppSkinImage(asset: 'assets/skins/ocean/navigation.png'),
  },
)
```

素材作者和授权文件随素材保留。先以统一语义槽试用部分图片，缺少的槽位沿用原图标/背景，不需要复制页面、导航组件或建立皮肤专属条件分支。

## 玻璃、阅读器及异常边界

皮肤不包含材质模式、玻璃样式、模糊数值、颜色或阅读偏好字段。毛玻璃、液态玻璃、关闭效果和 Material 3 继续遵循[共用玻璃材质](glass-material.md)的策略。实底策略可以遮住导航底图，这是可读性策略；高对比模式关闭页面底图和导航装饰。

导航图片仍处于原有的两层选择淡入淡出之内，标签、点击热区、弹性透镜和安全区由原组件负责。背景和装饰不接收点击、不增加无障碍节点。不要把整条导航裁切或为每套皮肤重新做一份玻璃滤镜。

图片加载失败通过 Flutter 错误报告保留路径和错误证据；图标返回原 `Icon`，背景保留原渐变，导航保留原玻璃。缺少槽位是正常的部分皮肤契约，与损坏资源的错误报告区别处理。

`ReaderThemePalette.toThemeData(parentTheme: ...)` 继承皮肤扩展和玻璃扩展，同时保留自己的纸张颜色和背景图；阅读画布不调用应用底图解析器。皮肤的缓存由 Flutter 的 AssetImage/ImageCache 管理，不引入第二份磁盘缓存或静态图片控制器。

## 验证入口与当前限制

- `test/app_color_presets_test.dart`：6 套浅/深配色、完整角色来源、文字对比度和默认蓝兼容。
- `test/app_color_preset_state_test.dart`：默认/旧色迁移、失效 ID、顺序保存、失败重试和偏好隔离。
- `test/app_theme_page_test.dart`：选择、真实素材、失败重试/快速选择竞态、选中语义、点击区域、大字体/长文案/平板与无障碍策略。
- `test/settings_theme_entry_test.dart`：设置摘要入口和自由色盘移除。
- `test/app_skin_assets_test.dart`：实际随包素材解码及许可证注册。
- `test/app_skin_test.dart`：目录、路径、不可变集合、明暗/选中解析及主题插值。
- `test/app_skin_state_test.dart`：选择恢复、连续持久化、旧 ID 清理、玻璃/强调色/明暗/阅读偏好隔离。
- `test/app_skin_rendering_test.dart`：真实导航和背景接入、图片失败、点击/标签/尺寸、高对比、玻璃策略及阅读器继承。
- 原有 `home_bounce_navigation_item`、`elastic_pill_navigation_bar`、`tablet_home_shell`、`home_shell_system_bar`、`floating_subpage_scaffold`、`shared_glass_background`、`glass_material_consumers`、`reader_theme_glass_policy` 套件独立进程执行。
- `tool/preview_theme_gallery.dart`：真实 iOS Flutter 的配色页、浅/深贴图页、1024 平板、大字体和偏好设置预览。桌面模拟器载体用 FittedBox 承载完整设计尺寸，截图取内部 RepaintBoundary。本次原生渲染截图见 [2026-10-10 主题预览](previews/theme-gallery-20261010/)，它不等同于用户真机视觉验收。
- `tool/preview_app_skin.dart`：真实 Flutter 渲染的原始/贴图毛玻璃/液态/深色/实底/高对比预览，仅复用已有随包图片验证架构，不注册为生产皮肤。

当前不包含皮肤商店、下载/import、运行时 JSON manifest、动画贴图或手机桌面图标切换。后续下载功能需要独立的安装、授权、版本和校验边界，先验证 manifest 再解析成运行时模型；不要把文件 IO 或不可信解析混入 ThemeExtension。
