# 2026-10-09 朗读正文排版验证

这是构建 `2.7.3+261009002` 的历史验证记录；当前维护入口见 [听书维护](../tts-jump-reading-design.md)。产品源码已推送，两端 Release 构建通过；设备连接中断，002 尚未安装或完成实机验收。此构建未公开发布至 GitHub Release、TestFlight 或 Google Play。

## 修复范围

产品源码提交：`4dc5b33584aee0ded12c5ef018a1460bf8923f2d`。朗读正文此前继承应用界面字体，未采用当前书籍的阅读排版。现在提供可选的阅读展示合同，正文复用阅读字体及书内样式分段，高亮仅改变颜色；保留字号、行距、字距、字重、fallback 与变量字体参数。按钮和标题继续使用界面字体。

主要文件：`lib/core/reader/reader_aloud_controller.dart`、`lib/widgets/reader_aloud_transcript.dart`、`lib/pages/reader/native/native_reader_controls.dart`、`lib/pages/reader/native/native_reader_chapter.dart`、`lib/pages/reader/book_source/book_source_reader_aloud_actions.dart`、`lib/pages/reader/book_source/book_source_reader_settings.dart`。原有正文范围样式提取为共用处理，没有新增字体解析器或依赖；章节 callback 捕获准确文字版本和不可变 blocks，避免关闭原阅读页后读取已销毁的 State。

EPUB 书内、系统、自定义字体选择遵循已有阅读器优先级。重新打开播放器刷新展示 source，保留同书播放会话、位置与休眠计时。构建包含此前自定义背景图升级修复和会员启动缓存改动；未修改服务端。

## 回归及视觉验证

八个独立 Flutter 进程，共 107 项测试全部通过：

| 套件 | 项数 | 覆盖 |
| --- | ---: | --- |
| `reader_aloud_typography_test.dart` | 3 | 活动及非活动句、混合字体、字重与 fallback、应用字体隔离 |
| `reader_aloud_panel_test.dart` | 30 | 既有播放器交互与设置 |
| `reader_aloud_controller_test.dart` | 40 | 连续播放、跳读、source 刷新与休眠状态 |
| `reader_font_profile_test.dart` | 6 | 字体模式优先级 |
| `native_reader_epub_chapter_transition_test.dart` | 12 | EPUB 延迟加载及章节切换 |
| `book_source_reader_aloud_transition_test.dart` | 11 | 书源朗读章节切换 |
| `reader_aloud_navigation_guard_test.dart` | 4 | 导航保护 |
| `native_reader_aloud_typography_test.dart` | 1 | 真实阅读页进入播放器、三种字体选择、远章节与关闭原阅读页后的快照 |

新增阅读页回归使用合成八章 EPUB，验证书内字体、系统覆盖及显式自定义字体，并验证第八章延迟加载、字号/行距/字距/字重和原阅读页销毁后的正文展示。测试使用现有内存缓存 DAO，排空阅读缓存后关闭规则服务；所有断言保留，状态型 Widget 套件分进程运行。

实际 `ReaderAloudTranscript` 另以本地 Georgia 阅读字体及 Courier 界面字体渲染合成捷克语文字，截图核对正文字体一致、高亮不改字重。预览：`build/validation/aloud-font-261009002/aloud-font-preview.png`。这是合成内容的组件视觉证据，不能代替用户原书或实机验证。

全量静态分析无错误或警告，仅保留此前三处无关 info：`source_chapter_state.dart:313`、`source_cookie_utils.dart:32`、`offline_reader_license_refresh_test.dart:9`。修改的 Dart 文件格式和 diff 检查通过；当前指南的源码、测试与文档链接已核对。

日志与汇总：`build/validation/aloud-font-261009002/`，包括 `test-results.json`、`verification.json`、`analyze.log` 与视觉判定。这些本地材料位于忽略的构建目录。

## 构建及签名

iOS 和 Android 正常 Release 产品构建、独立签名验证均通过。两端入口均为 `lib/main.dart`，构建前后产品源码指纹一致：`5147295264f0573fdd4bb8c7fbdd36d095d333d5323d42aebd670931039842c8`。文档收据提交不改变此指纹。

- iOS：bundle `com.niki.xxread`，build `261009002`，Apple Store 渠道配置的开发签名 Release；这是本地验收包，不是 TestFlight。AOT SHA-256：`e9c68be95a499a98ecee52b45db3390df7eca63d8db28d5f90e78282528e9d86`。收据：`build/device-ios/aloud-font-261009002/signed-build.json`。
- Android：同一 bundle，共享构建号 `261009002`，arm64 包的实际 versionCode `261011002`。正式签名包及与设备原安装证书兼容的本地验收包已分别保留；验收包签名验证通过，证书 SHA-256 `919daa4cde1cca0fdb7e989f6a6a29cf913a45fad93991660f9e28b5ad42edd2`。收据：`build/device-android/aloud-font-261009002/signed-build.json`。

| 本地产物 | SHA-256 |
| --- | --- |
| Android 正式签名 APK | `ee53c32e61e36a6908b06dfbf8abe69807539846d9e25d7f020c27e1cdb8270b` |
| Android 设备兼容签名 APK | `97c547f6673fdaff76a5e5da6f8eec3879037961839b9dc1c9273b18b895422d` |
| Android AOT | `ff237370b5256ec5cdf9434a2fc3987044515411d68d993cb5a8f9e58aaaa9a0` |

这些散列标识本地构建，不是公开 Release 下载清单。

## 设备交付与剩余边界

- SloanePro 已核对为物理 iPhone 16 Pro、UDID `00008140-001979421E93001C`。本次安装前查询应用被 CoreDevice 4016 阻止，设备状态 `unavailable`；最后再次列举仍不可用。安装命令尚未执行，002 未安装，也未验证启动。此次阻塞是连接不可用，不能沿用上一构建的 `Locked` 作为当前诊断。证据：`build/device-ios/aloud-font-261009002/device-acceptance/` 中的 `apps-before.log`、`details.json`、`devices-final.json`。
- Android PKT110 的无线 ADB 连接消失；最后 `adb devices -l` 和 `adb mdns services` 均无设备。002 未安装。连接恢复后按原地升级流程保留数据，核对原安装版本、证书、数据目录及首次安装时间，再验证 APK 散列和前台启动。
- 已请求连接设备。上一构建的安装事实见 [背景图修复记录](2026-10-09-reader-background-upgrade-validation.md)，不能视为 002 的交付证明。本次未卸载、清除应用或改变真实用户字体设置。
- 未打开用户私有书籍，未取得截图中原书的字体文件，也未验证真实 TTS 音频及两端实机字体显示。缺失字体或缺字仍沿用阅读器回退。
- 源码已推送并核对 live `origin/main`。当前主机为 sloane，无需 SSH 到自身；Windows `192.168.1.10:22` 连接超时，未完成 Git 同步。四张无关未跟踪预览 JPEG 保持原状。
