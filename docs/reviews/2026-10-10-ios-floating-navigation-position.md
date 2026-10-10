# iOS 首页悬浮导航位置 — 2026-10-10

这是本次用户反馈的历史验证记录，当前布局契约见[共用玻璃材质](../glass-material.md#组件边界)。

## 调整与源码

- `lib/pages/home/home_mobile_chrome.dart`：在带 Home Indicator 的 iPhone 上，把完整系统安全区外的间距由 10 点减为 2 点，导航下移 8 个逻辑点。统一指标同时驱动内容留白、悬浮按钮和书库多选操作栏，无需为各页面补位置偏移。
- `test/home_mobile_chrome_metrics_test.dart`：显式指定 iOS / Android，覆盖安全区、键盘、自定义导航高度和无 Home Indicator 的 iPhone。
- `test/home_shell_system_bar_test.dart`：运行真实首页壳层，核对 iPhone 与 Android 的导航矩形、内容及悬浮按钮避让。
- `docs/glass-material.md`：记录安全区与导航位置的所有权和回归入口。

Android 和无 Home Indicator 的 iPhone 保留 10 点间距；平板顶置导航、玻璃材质和用户自定义尺寸保持原契约。没有新增依赖、存储项或机型专属偏移。

## 验证

两个独立 Flutter 测试进程全部通过，共 18 项：尺寸指标 11 项、首页壳层 7 项。真实首页 widget 的 402 × 874 逻辑点视口中，iOS 导航高 60 点，底边为 838，距离屏幕底边 36 点（34 点系统安全区 + 2 点间距）；Android 使用同样安全区时仍距底边 44 点。

三份 Dart 源码/测试的静态分析无问题，Dart 格式与 `git diff --check` 通过。测试不等于物理触感或视觉验收。

## 交付边界

SloanePro 已实时识别为物理 iPhone 16 Pro，UDID `00008140-001979421E93001C`，当时状态为 available (paired)。当前有主题市场等并行 APP 改动；统一安装负责人为主题聊天 `01a123b2-b368-7680-af66-6d2a6ba66c03`，本次来源和文件哈希登记在忽略的 `build/device-ios/coordination.json` 的 `iosFloatingNavigationPosition` 条目，等待其最新共享 checkout 合并构建与原地安装。此次没有另装较旧快照，也没有卸载或清除数据。最终构建、签名、安装身份与启动以合并交付收据为准，真机位置验收仍待完成。

当前主机为 `sloane.local`。本次 Windows 的 `knbook` 和 `milo-pc.local` SSH 均连接超时，未更改远端工作树。
