# 阅读屏幕常亮

## 开关与所有权

`lib/core/reader/reader_keep_screen_on.dart` 是 Android/iOS 共用的控制入口。保留已有 `keepScreenOn` 偏好，默认关闭。只有偏好开启且至少一个阅读器已登记时才启用常亮；最后一个阅读器退出时解除。设置页开启开关只保存偏好，进入阅读页后才阻止自动锁屏。

设置页调用 `setPreference` 即时更新已有阅读器。原生文字阅读、书源文字阅读、分页图片阅读及连续图片阅读在初始化/销毁时分别调用 `activate`/`deactivate`。文字阅读页恢复前台调用 `reapply`，重新读取偏好并强制同步；平台调用失败不记为已应用，后续同步可以重试。图片阅读器保持登记期间的系统常亮状态，未单独实现恢复回调。

## 平台合同

共用 `com.niki.xxread/fullscreen` 通道，方法 `setKeepScreenOn`，参数 `{enabled: bool}`。Android 在 `android/app/src/main/kotlin/com/niki/xxread/MainActivity.kt` 设置/清除窗口 `FLAG_KEEP_SCREEN_ON`；iOS 在 `ios/Runner/AppDelegate.swift` 的通道处理器设置 `UIApplication.shared.isIdleTimerDisabled`。保留现有插件注册和主线程调用方式，不新增依赖。其他平台不发送此原生方法。

常亮用于阅读期间的系统自动锁屏；不阻止用户主动锁屏，也不保证系统中断期间屏幕持续点亮。阅读器登记采用对象身份集合，叠加或切换阅读器不会由旧页面单独解除新页面所需的常亮。

## 回归与验收

`test/reader_keep_screen_on_test.dart` 对 Android 与 iOS 分别验证：读取旧偏好、实时切换、最后一个阅读器释放、前台强制重同步、阅读器外开启、原生错误后重试。`test/settings_page_preferences_test.dart` 覆盖设置快照；`test/paged_image_reader_test.dart` 覆盖阅读器设置面板的即时持久化。状态型 Widget 测试单独运行。

真机验收需进入阅读页，开启常亮，保持无触摸超过设备当前自动锁屏时间，核对不会自动锁屏；关闭开关或退出阅读后核对恢复自动锁屏，再验证切到后台后返回阅读。安装与成功启动不能替代这项等待验收。2026-10-09 修复及设备收据见 [验证记录](reviews/2026-10-09-ios-keep-screen-on-validation.md)。
