# 玻璃样式与液态材质验收

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
