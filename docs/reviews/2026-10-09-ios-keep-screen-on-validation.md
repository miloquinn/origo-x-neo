# 2026-10-09 iOS 阅读常亮修复验证

当前维护入口：[阅读屏幕常亮](../reader-keep-screen-on.md)。这是本次修复的验证记录，不是公开发布收据。

## 原因与修改

原共享控制器只在 Android 调用 `setKeepScreenOn`，iOS 的同名通道也未处理该方法，导致偏好能保存但未禁用系统自动锁屏。新回归在修改 Dart 前验证 Android 六项通过、iOS 六项全部失败（没有原生调用），日志 `build/validation/keep-screen-on-261009003/before.log`。

`lib/core/reader/reader_keep_screen_on.dart` 将 iOS 纳入原有同步路径；`ios/Runner/AppDelegate.swift` 在既有通道内验证 `{enabled: bool}` 并设置 `UIApplication.shared.isIdleTimerDisabled`。保留既有偏好、对象身份登记、Android 窗口标记、多阅读器释放及失败后重试；未增加依赖。通道使用默认主线程处理器。

常亮源码提交：`d47ebd9f71539a258b724f3f976b40e60d3e618e`，已推送。

## 已完成验证

- 三个独立 Flutter 进程全部通过：常亮控制器 12 项（Android/iOS 各六项）、设置偏好 3 项、分页图片阅读器 10 项，共 25 项。
- 覆盖开启旧偏好、阅读中切换、最后阅读器退出、强制重同步、阅读器外开启和平台失败后重试。
- Swift 语法解析通过；修改的 Dart 格式与局部静态分析通过，diff 检查通过。
- 全库分析无错误或警告；运行时有三处此前的无关 info，以及另一聊天正在修改的协议回归一处 info。全库分析包含共享工作树当时状态，局部分析验证本修复无问题。
- 最终合并代码再次全库分析，无错误或警告，仅剩三条此前的无关 info，日志 `combined-analyze.log`。
- 只读复核未发现阻断问题。测试验证状态机及通道调用，不等同于系统自动锁屏等待验收。

日志保存在忽略目录 `build/validation/keep-screen-on-261009003/`。

## 设备交付

首轮正常 iOS Release 构建和 `codesign --verify --deep --strict` 均通过，bundle `com.niki.xxread`、版本 `2.7.3`、构建 `261009003`。构建期间其他聊天修改阅读源码，构建前后指纹不一致，因此保留为 `precombined-Runner.app`，未安装；不能视为最终合并包。收据：`build/device-ios/keep-screen-on-261009003/precombined-build.json`。

最终合并正常 iOS Release 构建（入口 `lib/main.dart`）与签名检查均通过，已包含常亮、登录协议恢复、iOS 上下翻页位置及选中工具栏的完成源码。构建前、构建后及交付后产品源码指纹一致：`a3eb344b5051b695d093dd64309101f0d2b21abd40ef58d8cb778dcaa183db92`。构建时基线 `be472090` 加已完成但尚未提交的上下翻页修改；交付后提交 `b972ecf3` 包含该修改。完整文件指纹用于核对实际构建输入，不能仅将基线 commit 视为包的全部来源。

已识别 SloanePro 为物理 iPhone 16 Pro，UDID `00008140-001979421E93001C`；安装前读回 bundle `com.niki.xxread`、版本 `2.7.3`、构建 `261009001`。本聊天统一原地安装后读回 `2.7.3` / `261009003`，成功激活启动，PID `21528`，后续进程查询确认运行。没有卸载或清除数据，其他聊天没有重复安装旧快照。

交付渠道：Apple Store 渠道配置的开发签名 Release，本地验收，未上传 TestFlight/App Store。AOT SHA-256：`e4041db1c57f56da3c4c68a113ba730dd0bbdff843d1feab7fa856351d46deae`。最终收据 `build/device-ios/keep-screen-on-261009003/signed-build.json`；安装、版本读回、启动与进程证据见同目录 `device-acceptance/`。

设备收据目录：`build/device-ios/keep-screen-on-261009003/`。不卸载或清除数据。TestFlight/App Store 公开发布与本地开发验收分开。阅读页面中保持无触摸超过自动锁屏时间、关闭开关恢复锁屏及前后台返回的实际 UI 验收仍需独立证据。

尝试用 LLDB 读取原生 idle timer 布尔值时，设备调试连接未取得可求值的停止进程，未能读取状态；这不是产品构建或启动失败。没有通过调试器修改用户偏好或常亮状态，不据此宣称自动锁屏等待验收通过。

补充检查时初始 PID 已不在进程列表，原因未确认；设备可读的 Runner 系统报告只有 2026-09-10 的历史磁盘写入记录。重新启动被 iOS 明确以 `Locked` 拒绝；用户在本聊天确认解锁后，正常重新启动成功，PID `21578`，30 秒后进程查询仍确认运行、设备未锁定。收据见 `launch-unlocked.json`、`processes-unlocked.json` 和 `lock-state-after-unlock.json`。用户阅读静置复测结果尚未记录，未将这一运行检查等同于无触摸自动锁屏验收。

Windows `192.168.1.10:22` 本次连接超时，尚未同步；当前主机就是 `sloane.local`，本地提交推送后直接核对 live remote HEAD。四张用户预览 JPEG 保留。
