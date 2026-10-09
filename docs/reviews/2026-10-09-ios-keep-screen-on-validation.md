# 2026-10-09 iOS 阅读常亮修复验证

当前维护入口：[阅读屏幕常亮](../reader-keep-screen-on.md)。这是本次修复的验证记录，不是公开发布收据。

## 原因与修改

原共享控制器只在 Android 调用 `setKeepScreenOn`，iOS 的同名通道也未处理该方法，导致偏好能保存但未禁用系统自动锁屏。新回归在修改 Dart 前验证 Android 六项通过、iOS 六项全部失败（没有原生调用），日志 `build/validation/keep-screen-on-261009003/before.log`。

`lib/core/reader/reader_keep_screen_on.dart` 将 iOS 纳入原有同步路径；`ios/Runner/AppDelegate.swift` 在既有通道内验证 `{enabled: bool}` 并设置 `UIApplication.shared.isIdleTimerDisabled`。保留既有偏好、对象身份登记、Android 窗口标记、多阅读器释放及失败后重试；未增加依赖。通道使用默认主线程处理器。

## 已完成验证

- 三个独立 Flutter 进程全部通过：常亮控制器 12 项（Android/iOS 各六项）、设置偏好 3 项、分页图片阅读器 10 项，共 25 项。
- 覆盖开启旧偏好、阅读中切换、最后阅读器退出、强制重同步、阅读器外开启和平台失败后重试。
- Swift 语法解析通过；修改的 Dart 格式与局部静态分析通过，diff 检查通过。
- 全库分析无错误或警告；运行时有三处此前的无关 info，以及另一聊天正在修改的协议回归一处 info。全库分析包含共享工作树当时状态，局部分析验证本修复无问题。
- 只读复核未发现阻断问题。测试验证状态机及通道调用，不等同于系统自动锁屏等待验收。

日志保存在忽略目录 `build/validation/keep-screen-on-261009003/`。

## 设备交付

已识别 SloanePro 为物理 iPhone 16 Pro，UDID `00008140-001979421E93001C`；安装前读回 bundle `com.niki.xxread`、版本 `2.7.3`、构建 `261009001`。本聊天负责合并最新共享 checkout 后的开发签名 Release 安装；其他聊天保留独立功能验证和提交责任。安装/启动结果将在构建完成后补充。

设备收据目录：`build/device-ios/keep-screen-on-261009003/`。不卸载或清除数据。TestFlight/App Store 公开发布与本地开发验收分开。阅读页面中保持无触摸超过自动锁屏时间、关闭开关恢复锁屏及前后台返回的实际 UI 验收仍需独立证据。

Windows `192.168.1.10:22` 本次连接超时，尚未同步；当前主机就是 `sloane.local`，本地提交推送后直接核对 live remote HEAD。四张用户预览 JPEG 保留。
