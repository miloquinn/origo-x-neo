# 玻璃样式与液态材质验收

历史记录：本文描述标题日期对应的实现与交付，不作为当前待办或配置说明。当前维护入口为 [共用玻璃材质](../glass-material.md)。

2026-10-08。先将共享工作区保存为基线 `43cfb4ee` 并推送到 `origin/main`，随后实现独立的玻璃样式实验。

## 最终行为

- 设置 → 偏好设置 → 玻璃效果；开启后下方显示「玻璃样式」，可选择毛玻璃或液态玻璃。旧用户默认毛玻璃，关闭后保留选择，重启仍恢复。
- 首页/统计浮动导航、共享玻璃按钮、阅读控制栏复用液态 renderer：实时背景折射、轻透明主题基底和同形边缘高光。顶部渐进模糊保持原有衰减规则，液态模式减轻强度。
- 毛玻璃保留原分支；总开关关闭使用原实色分支。已有 `blurBackground:false` 的嵌套控件继续不叠加滤镜。不支持 shader 的后端使用轻模糊与高光；高对比设置使用更实基底。
- 不新增依赖或主动连续动画；复用现有弹性导航和触控。shader 在场景合成时刷新局部坐标，缓存的前景不需要每帧重新绘制。

## 修正与审查

- 发现液态按钮内部命中区域较毛玻璃大 2px，补回旧边框占据的内边距；模式切换后尺寸与触控回归通过。
- 发现首页 `AnimatedSlide` + 内层 `RepaintBoundary` 会复用旧绘制，造成仅 paint 时刷新的 shader 坐标滞后。将坐标刷新移到 `ContainerLayer.addToScene`，通过 `alwaysNeedsAddToScene` 传播合成需求，保留原 RepaintBoundary 和前景缓存。独立审查对照当前 Flutter layer/Impeller 源码确认该合同成立。
- 保留 1×1 sampler seed：它为引擎替换的实时 backdrop 配置线性采样；shader 和 seed 随组件销毁释放。

## 回归证据

有全局状态的 widget 文件逐个启动独立 Flutter 进程，未跳过断言。以下共 88 项通过：

| 文件 | 数量 |
| --- | ---: |
| `ui_style_test.dart` | 3 |
| `glass_config_test.dart` | 4 |
| `glass_control_surface_test.dart` | 4 |
| `reader_control_chrome_test.dart` | 5 |
| `gradient_top_backdrop_test.dart` | 11 |
| `home_shell_system_bar_test.dart` | 4 |
| `book_source_glass_controls_test.dart` | 2 |
| `book_source_pill_test.dart` | 10 |
| `app_menu_test.dart` | 17 |
| `settings_performance_test.dart` | 14 |
| `app_theme_accent_test.dart` | 7 |
| `settings_glass_style_test.dart` | 3 |
| `liquid_glass_surface_test.dart` | 4 |

- 本次相关文件 `flutter analyze --no-pub` 无问题。
- 全仓 `flutter analyze --no-pub --no-fatal-infos` 返回 0；保留 3 条既有 info（`source_chapter_state.dart`、`source_cookie_utils.dart`、`offline_reader_license_refresh_test.dart`），这些文件本次未改。
- `git diff --check` 通过。
- 本地忽略目录 `build/validation/liquid-glass/` 保留主要既有回归日志。

## 实际渲染

- iOS 27 Simulator、iPhone 18 Pro Max，Flutter 3.44.7，VM service 确认 Impeller enabled，预览中 shader supported。
- `tool/preview_liquid_glass.dart` 使用共享真实组件与线条/文本 fixture，原生 `RenderRepaintBoundary.toImage` 保存 1320×2868、DPR 3 截图；它不依赖账户或网络。
- 深浅主题各捕获毛玻璃、液态、关闭及导航平移 20px + RepaintBoundary，共 8 张。观察到液态边缘折射实时线条和文字，前景保持清晰；平移后轮廓和折射一同移动。
- 截图在 `docs/previews/liquid-glass-20261008/`，`navigation-comparison.png` 仅裁切并并排展示真实浅色截图，没有生成或替换 UI。

## 交付边界

- 完整应用 `flutter build ios --release --no-pub --target lib/main.dart --dart-define=ORIGO_DISTRIBUTION_CHANNEL=direct --dart-define=ORIGO_STORE_READER_LICENSE_REQUIRED=false` 成功，Xcode 115.3 秒；产物 58.6 MB。deep/strict 代码签名检查通过，打包后的液态 shader 为 3768 字节。
- 构建前采集 657 个 Dart/shader/资产/pubspec 文件摘要，构建结束逐个比对无漂移。清单 SHA-256：`8541a8e3199e0fbb1a11e2256197b2d9899c5e6929d497a44c0694bf73e26369`。该清单用于本次源码稳定性检查，不包含原生工具链配置。
- AOT `App.framework/App` SHA-256：`a6173a8df77ab5673e4f7c595b61da136cfe8834702e5ce42fb7ee276da12bc8`。
- SloanePro 身份核实为 iPhone 16 Pro，使用 `devicectl device install app` 覆盖安装，未卸载/清空数据。回读 `com.niki.xxread` / `2.7.3` / `261008001`，`builtByDeveloper=true`；版本号沿用当前开发验收包，代码摘要和安装收据区分本次包。
- 前台启动成功，PID `12728`；后续进程回读的路径与本次安装收据一致。本次仍默认毛玻璃，用户在「设置 → 偏好设置 → 玻璃效果 → 玻璃样式」选择液态即可尝试。
- 来源、构建、覆盖安装、身份回读、启动与进程存活 JSON 在本地忽略目录 `build/device-ios/liquid-glass-20261008/`。这是本地 direct 渠道开发签名交付，没有上传 TestFlight/App Store。

这是跨平台液态材质实验，保留毛玻璃作为默认选择。模拟器截图与单元测试不替代用户的物理视觉接受、滑动手感及 GPU 帧时间验收。Android/桌面真实 shader 路径和商店发布本次未验证。

## 选中导航透镜适配

用户的真机截图显示外层导航已经透明折射，但选中的书架按钮仍是一整块不透明的浅色。根因是共享弹性导航的 `ShapeDecoration` 仍使用 alpha=1 的主题 surface 混色，遮住外层的实时背景。

- `lib/widgets/elastic_pill_navigation_bar.dart`：液态模式的共享选中透镜改用已有 `LiquidGlassSurface`，保持超椭圆 clip、独立主题 tint、边缘高光；选中图标在滤镜之后绘制。保留原定位、弹簧、拖动、RTL 与 IgnorePointer。
- `lib/pages/home/widgets/home_bounce_navigation_item.dart`：独立选中指示器使用同一材质，使浮动导航设置预览一致。毛玻璃、关闭玻璃与 Material 3 继续原实色分支。
- `lib/widgets/liquid_glass_surface.dart` 与 `shaders/liquid_glass.frag`：新增 visibility，底色、高光、边缘折射、中心放大及五采样偏移一起连续渐隐；0 时不创建 filter/rim，保留 child 和布局。直接更新材质参数，不给背景滤镜套 Opacity/saveLayer。奇异变换的轻模糊 fallback 也随 visibility 缩放。
- `tool/preview_liquid_glass.dart`：用真实共享导航与按钮替代原来的静态图标 fixture，并加入独立选中按钮，避免预览遗漏这条实际绘制路径。

本次逐文件独立回归共 42 项通过：`elastic_pill_navigation_bar_test` 9、`home_bounce_navigation_item_test` 9、`liquid_glass_surface_test` 5、`detailed_stats_page_test` 1、`settings_navigation_and_layout_pages_test` 2、`home_shell_system_bar_test` 4、`glass_control_surface_test` 4、`reader_control_chrome_test` 5、`settings_glass_style_test` 3。全仓 analyze 返回 0，仍为上述 3 条既有 info。

独立审查确认 uniform 写入范围为 2–13，visibility 对边缘、中心及轻柔采样各乘一次，没有平方衰减。两层滤镜按外壳、选中透镜、前景图标的顺序绘制。Widget 测试仅覆盖 fallback 和交互合同；实际 shader 的视觉结果另以 Impeller 截图验证。嵌套选中透镜增加一个小范围 backdrop pass，真机帧时间仍需另行测量。

实际 iOS Simulator Impeller 捕获 `selected-light.png`、`selected-dark.png` 与对应 `selected-*-moving.png`，均为 1320×2868。真实共享透镜与独立指示器可透背景，选中前景保持锐利；平移 20px 的截图中高光和折射同步移动，没有观察到错位或残影。截图保存在同一预览目录。

首次真机构建与模拟器的 `xcodebuild clean build` 并行，共用 DerivedData 时出现 Swift 中间文件消失；停止并行构建后串行重建成功（105.4 秒，58.6 MB）。这是构建目录竞争，未修改产品代码来绕过。deep/strict 签名检查通过，shader 打包为 3888 字节。构建前后 670 个 lib/shader/资产/pubspec 文件无漂移；清单 SHA-256 为 `755bf738974c4915aef1d41506b89290ad4a2e774138a67ea9028b7fbcc1a290`，AOT SHA-256 为 `9aefd71088bae26eabe1744c07221cb6d32624be4785364542785bc6f4732856`。

已对 SloanePro（iPhone 16 Pro）覆盖安装本次 direct 开发签名包，未卸载/清空数据。回读 `com.niki.xxread / 2.7.3 / 261008001`，前台启动成功，PID `12985` 与本次安装目录一致。收据保存在 `build/device-ios/liquid-glass-selection-20261008/`。用户随后认可液态玻璃视觉并要求在此基础上增加不透明度调节；这不构成 GPU 帧时间测量或商店分发验收。

## 连续不透明度调节

按用户要求先保存选中态修复为 `4206f660` 并推送，再增加调节功能。参考用户提供的苹果设置截图及 [Apple 官方操作说明](https://support.apple.com/en-lamr/guide/iphone/iphd6804774e/ios)：向右增加 tint，向左更通透。

- 设置选择液态玻璃后，在玻璃样式下面展开「液态玻璃不透明度」连续滑杆，物理左端保留当前视觉，右端更不透明；标题与说明按用户语言排列，滑杆方向固定为用户要求的左到右增加。仅玻璃开启且液态选中时可见。
- `ThemeNotifier` 保存归一化的 `liquid_glass_opacity`（0–1）。0 表示在当前最通透基线之上不增加 tint，并非原始 alpha=0。缺失、非数值、非有限值和越界值安全归一；关开玻璃或切换毛玻璃不丢失选择。
- 拖动先即时更新状态，松手后保存，避免每帧写入偏好。同值最终保存仍执行；当前 SharedPreferences 单例、同步 cache 更新及 platform channel FIFO 保证最后值落盘。`UiStyleThemeExtension` 连续插值 opacity 并传给所有页面。
- `LiquidGlassSurface` 统一把浅色 `.32/.18`、深色 `.26/.18` 基底向两端 `.88` 插值，0 精确保留原材质，最大档接近不透明。高对比保持 `.94`；visibility 继续控制选中淡出。折射 shader、轮廓和 rim 强度不改。
- `GradientTopBackdrop` 仅在液态、不透明度大于 0 时叠加一次主题底色，并在 clear tail 前渐变至透明；0 保留纯 blur，毛玻璃/关闭/Material 3 不受影响。没有修改共用毛玻璃的 `chromeOpacityFor`，避免重复调色。
- 改动文件包括设置 appearance/layout/hub、ThemeNotifier/main/UiStyleThemeExtension、共享 renderer/顶部 backdrop、10 个 locale 及生成文件，以及相关测试/真实组件预览；没有新增依赖。

本轮共 79 项独立进程回归通过：

| 文件 | 数量 |
| --- | ---: |
| `app_theme_accent_test.dart` | 11 |
| `ui_style_test.dart` | 6 |
| `glass_config_test.dart` | 5 |
| `liquid_glass_surface_test.dart` | 7 |
| `gradient_top_backdrop_test.dart` | 13 |
| `settings_glass_style_test.dart` | 6 |
| `elastic_pill_navigation_bar_test.dart` | 9 |
| `home_bounce_navigation_item_test.dart` | 9 |
| `reader_control_chrome_test.dart` | 5 |
| `glass_control_surface_test.dart` | 4 |
| `home_shell_system_bar_test.dart` | 4 |

日志保存在 `build/validation/liquid-glass-opacity/`。全仓 analyze 返回 0，仍为 3 条既有 info。独立只读审查未发现阻断问题。

iOS Simulator Impeller 的浅/深主题各捕获 0、0.5、1 三档，共六张 `opacity-{light,dark}-{0,0.5,1}.png`。背景折射与前景锐度保持，底色单调加浓，顶部渐变正常；最大档导航外壳和镜片一同加浓，选中通过主题色和 rim 保持区分。外壳与选中镜片最大档叠色接近不透明是刻意的右端效果；连续滑杆可保留中间通透程度。

完整 iOS release/direct 包串行构建成功（93.4 秒，58.7 MB），deep/strict 签名检查通过。670 个 lib/shader/资产/pubspec 文件构建前后无漂移；清单 SHA-256 `f3236de86fe506e181652a56528a340e99f3b731186755a3702e4c3cd167afbf`，AOT SHA-256 `a737452d1faeefde1fe22659d8a4eadcb706116594ae695b0be26bc46c4cd8ae`。

SloanePro（iPhone 16 Pro）已覆盖安装并前台启动，保留原数据。回读 `com.niki.xxread / 2.7.3 / 261008001`，PID `13228` 与本次安装目录一致。收据在 `build/device-ios/liquid-glass-opacity-20261008/`。这是本地 direct 开发签名交付，未上传 TestFlight/App Store；默认仍为原通透程度，用户可用新滑杆选择中间或更浓的效果。真机滑杆触感/视觉接受与 GPU 帧时间仍由实际验收确认。
