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

## 合并交付独立核验

统一安装负责人恢复设备连接后，已使用 `direct` 渠道的本地开发签名 Release 原地更新。此次独立核验确认：

- 构建前、构建后与安装前的三份源码清单都包含本次 `home_mobile_chrome.dart`，SHA-256 为 `7b51811f63543bcddec6acaef577047f5ba5739f0d97f1847d22b4cfedd2da64`，合并产品输入摘要保持一致；构建提交 `d9c6ef03` 包含本次源码提交 `7d0a3d86`。
- 手机实时读回 `com.niki.xxread`、版本 `2.7.3`、构建 `261010004`。统一安装和启动收据均成功；本聊天再次读取实时进程，确认 PID `30010` 的可执行文件属于同一安装路径。
- 共享构建/签名收据为 `build/theme-market/signed-build.json`，本范围独立收据为 `build/ios-navigation-position/delivery-verification.json`。协调条目已更新为 `installedAndLaunched`。

此版本已包含导航下移改动；物理导航位置与触感尚未得到用户验收。未上传 TestFlight / App Store，本聊天没有重复安装。主题聊天继续负责下一版共享构建和安装，当前 `261010004` 的验证结论保留为该版本证据。
