# 听书跳读与设置整理验证

## 实现

- `lib/core/reader/reader_aloud_controller.dart`：显式跳读定位句首，暂停时点击开播，当前句重听；章节加载与页面定位仅采纳最新操作；准备音频期间不伪造高亮；页面重绑保留播放状态和睡眠定时。
- `lib/widgets/reader_aloud_panel.dart`、`reader_aloud_transcript.dart`：保留封面并增加正文；虚拟列表支持点句跳读，手动浏览暂停自动跟随，可回到正在朗读；设置按播放方式、声音、定时组织。
- `lib/widgets/reader_annotated_text_page.dart`、`reader_tap_observer.dart`、`reader_text_page_content.dart`：点击实际字形映射到原文，处理跨页和生成缩进；空白点击、长按选字、滑动、已有批注继续使用原交互。
- `lib/pages/reader/native/`、`lib/pages/reader/book_source/`：两类阅读器接入同书会话跳读，页面定位取消检查贯穿异步加载和延迟布局恢复。
- `lib/services/reader_aloud_service.dart`、`reader_aloud_providers.dart`：保存点句跳读设置；首句优先，前瞻四句，合成请求最多两路；相邻句复用音频会话；支持取消实际 HTTP 请求及响应流，丢弃失效预取。

## 验证

独立 Flutter 测试进程通过：

| 测试文件 | 用例数 |
| --- | ---: |
| reader_aloud_controller_test | 36 |
| reader_aloud_cloud_service_test | 27 |
| reader_aloud_bytes_player_test | 8 |
| reader_aloud_provider_test | 10 |
| reader_aloud_panel_test | 30 |
| reader_annotated_text_page_test | 12 |
| reader_tap_observer_test | 3 |
| reader_aloud_locate_test | 3 |
| reader_text_layout_mapping_test | 13 |
| reader_text_flow_test | 12 |
| native_reader_paragraph_normalization_test | 3 |
| reader_aloud_navigation_guard_test | 3 |

以上 160 个专项用例通过。真实书源阅读器覆盖延迟定位后停止、快速新目标、关闭再重开同书；重开断言控制器身份不变、10 分钟定时保留、未重复启动音频，随后跳到新章并拒绝旧定位。两类阅读器的重绑接线经过最终只读复核，无剩余必要修正。

原生阅读器初始进度测试的两个隔离用例通过：超大 TXT 的拆章偏移恢复，EPUB 横向阅读首帧页码恢复。全文件运行在第一例之后出现缓存释放超时，后续等待阅读器状态超时；上述用例各自单独运行通过，保留断言并记录为测试进程状态清理问题。

Flutter 中文字体截图人工检查通过：手机正文、手机设置、窄屏大字体设置；修复窄横屏准备状态遮盖正文、返回当前句操作覆盖正文。截图来自组件测试，未代表真机触摸验收。

最终 `flutter analyze --no-pub --no-fatal-infos` 无 error / warning，保留其它任务范围内原有的三条 info（source_chapter_state、source_cookie_utils、offline_reader_license_refresh_test）。本次修改的目标文件分析通过，`git diff --check` 通过。没有新依赖；设置复用现有组件，导航复用原加载与恢复流程。

## 验证边界

- 当前云端接口没有真实句时间戳，继续逐句合成并优化缓冲，没有启用整页合成或按字数估算音频时间。
- 未进行真实云端服务和 iOS / Android 设备试听；模拟测试证明有界预取、取消和状态顺序，不证明实际音频衔接无缝。
- 原生阅读器重开同书尚无独立路由集成用例；已有控制器重绑单测、原生接线复核和隔离初始进度回归。
- 未提交代码、打包或发布；工作区其它任务的改动保留。

## 2026-10-05 截图反馈复核

截图中的云端预加载和点击正文恢复朗读，已由当前未发布实现覆盖。本次复用实现，没有重复添加播放器、开关或依赖。

- 云端首句优先，最多预取后续四句、同时两路合成；暂停、停止和跳读取消旧请求。相邻句复用音频会话。
- 阅读页在听书会话中启用「点句跳读」后，点击正文从该句句首播放。本地书和书源均接入；「手动翻页改变朗读位置」是独立设置，误翻页场景可保持关闭。
- `test/reader_aloud_navigation_guard_test.dart` 新增真实书源页面回归：用页边点击翻到下一章再返回，确认未重启朗读；点击第二句中间字形，确认从第二句句首播放且控制器身份不变。复用现有测试服务，原有三个导航用例的数据保持不变。
- 八个测试文件分别独立执行通过：cloud service 27、controller 36、bytes player 8、provider 10、panel 30、annotated text page 12、tap observer 3、navigation guard 4，共 130 项。
- 听书控制器、服务、正文组件、两类阅读器及新增测试的定向 `flutter analyze --no-pub --no-fatal-infos` 无问题；`dart format` 与 `git diff --check` 通过。

仍需区分缓冲与实际无缝播放：控制器按同章约 1800 字分批，下一批和下一章首句仍需合成；播放器仍逐句提交音频。未访问真实硅基流动服务，未测量 CosyVoice2-0.5B 延迟或进行手机试听。本次没有提交、打包或发布。
