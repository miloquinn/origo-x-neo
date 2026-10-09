# 2026-10-08 液态玻璃默认设置

历史记录：本文描述标题日期对应的实现与交付，不作为当前待办或配置说明。当前维护入口为 [共用玻璃材质](../glass-material.md)。

默认玻璃样式改为液态玻璃，默认不透明度为 0.5（滑块中点）。`lib/utils/ui_style.dart` 定义两项共享默认值，`ThemeNotifier` 的初始状态和偏好回退、`GlassEffectConfig` 的启动状态与主题扩展都使用同一来源。已保存的开关、样式及 0 或其他不透明度保留。未新增依赖、迁移开关或第二套设置状态。

## 验证

- 新默认行为回归在修改前明确失败，修改后通过。首次偏好加载、设置页滑块中点、缺少不透明度的液态玻璃偏好、已保存毛玻璃/关闭效果/0 与 0.68 均有覆盖。
- 9 个 Flutter 测试文件在独立进程运行，共 72 项通过，包含共享按钮、搜索框、液态表面及顶栏。既有毛玻璃专用测试明确设置毛玻璃，保留原有断言。
- Python 更新日志与版本规则 17 项通过；应用内更新日志生成校验及 stateful 测试清单通过；修改文件静态分析、格式与 diff 检查通过。

## 交付

正常入口 `lib/main.dart` 的 iOS 与 Android Release 均构建成功，构建号为 `261008007`，源码提交为 `545f7d28936c2bcb2d651c7c9de29efd65653461`。继承 006 的全部共享改动。构建前后源码不变，两个包共享源码 SHA-256 为 `4d5edc3599ec6e9b3ab6f8a53e18cb831f2e5aee714fdfc620c691b4be38a00b`；745 个 Git 管理的运行输入与 iOS 快照逐一匹配，Android 原生输入另做校验。已保存的个人设置优先于新默认值。

- iOS：SloanePro / iPhone 16 Pro（`00008140-001979421E93001C`）原位安装 `com.niki.xxread / 2.7.3 / 261008007`。严格签名校验、安装版本回读、激活启动及进程 `15937` 的可执行路径通过。AOT SHA-256 为 `115622fc8b8d48cd4e349e458509919e362811d21b9d94a49098dc31c747f5a2`。收据在 `build/device-ios/glass-defaults-20261008/device-acceptance/`。
- Android：OPPO PKT110 原位更新为同版本，保留首次安装时间与数据目录。安装前旧包哈希与 006 收据一致，安装后回读 APK SHA-256 为 `2b20ea78c10bb7e5c822d74c7a765f22a5981cd2bc65f3519740ae9db3d7be35`，与交付包一致；进程 `6396` 与 ResumedActivity 已核对。AOT SHA-256 为 `45f38eecb945090bd4effe6f0c8c7d290b0bd013e2ecc36a768988f0b9c68ed1`，对应符号单独保存。收据在 `build/device-android/glass-defaults-20261008/`。
- 两个平台的 latest-unified 指向已安装且启动验证的 007。Windows 已 fast-forward 同步源码，保留未跟踪文件；本机四个用户 JPEG 未修改。

渠道为开发者直接签名 Release，独立于 TestFlight、App Store 与公开 Android 发版。安卓继续用设备既有开发证书签署优化后的非 debuggable Release 代码，避免卸载丢失数据。安卓当前电源状态为 Dozing；进程与前台活动验证不等于实体视觉验收。两台设备实际玻璃观感和用户操作体验仍待确认。
