# 听书跳读与连续播放

这是听书展示、跳读与连续播放的当前维护入口。早期跳读验证见 [2026-10-03 记录](reviews/2026-10-03-tts-jump-reading-validation.md)，2026-10-09 增加阅读排版共用合同。

## 交互合同

- 共用 ReaderAloudController；全文位置用章节 ID 与原文字偏移，点击始终归到句首。
- 专门听书页保留封面，支持切换正文。正文单击从句首播放，暂停时点击也播放；点击当前句重听。浏览正文不改变播放位置，暂停自动跟随，并提供回到正在朗读。
- 阅读页新增「点句跳读」，默认关闭，持久化。只在当前书的听书会话启用；打开后正文短点优先跳读，滑动翻页、长按选字与批注继续工作。空白不吸附到正文。
- 快速连续跳读只保留最新目标；等待音频有准备状态，不伪造已播放的句子进度。定时停止不因跳读重置。
- 「手动翻页改变朗读位置」保持独立设置、默认关闭。其原有保存值不迁移。

## 正文排版

朗读播放器的正文沿用当前书籍的阅读排版；按钮、标题和设置仍使用应用界面字体。不要用整个 APP 的 ThemeData 替换阅读字体，也不要用单一字体覆盖书内混合字体。

- `lib/core/reader/reader_aloud_controller.dart`：`ReaderAloudTextSource` 是可选展示合同，保存阅读 `TextStyle` 和书内字体保留选择。`ReaderAloudChapter.buildTextSpan` 描述该章精确文字版本的样式分段，不参与音频合成或改变原文偏移。
- `lib/pages/reader/native/native_reader_controls.dart`：取 `_readerTextStyle` 和 `_preserveDocumentFont`，读取章节时通过 `_loadIndexedChapter` 共用延迟加载、字体注册与替换准备，捕获文字及不可变 blocks。`native_reader_chapter.dart` 的正文和朗读均委托 `_styledSpanForNativeTextRange`，使用原有字体、fallback、变量字重、字号比例和粗斜体规则。
- `lib/pages/reader/book_source/book_source_reader_settings.dart`：书源朗读提供 `_bodyTextStyle`。书源无 EPUB 分段字体，不另写书籍字体推断。
- 两个阅读器每次打开播放器刷新展示 source，保留同一本书的 controller、播放位置和休眠状态。关闭原阅读页后，当前章的样式 callback 只读取已捕获的文本与 blocks，不访问已销毁的 State 或卸载章节。
- `lib/widgets/reader_aloud_transcript.dart`：只对活动句设置高亮颜色；保留阅读字体、字号、行距、字距和字重。正文 `Text.rich` 及 base style 显式 `inherit:false`，即使 family 为 null 也不继承应用装饰字体。加载提示等界面文本继续使用应用主题。

EPUB 仅“书籍内置”保留书内字体；系统与自定义选择按已有 `ReaderFontProfile.preservesParsedFontFor` 规则覆盖。Kindle 的默认与显式字体同样沿用该规则。缺失字体或缺字沿用阅读器回退，不能保证每本书的所有字形均由嵌入字体提供。

回归入口：`test/reader_aloud_typography_test.dart` 验证活动/非活动句、fallback、变量字重、混合字体和应用字体隔离；`test/native_reader_aloud_typography_test.dart` 从合成 EPUB 的真实阅读页进入播放器，验证书内/系统/自定义字体、远章节和原阅读页关闭后的快照；原有 `reader_aloud_panel_test.dart`、`reader_aloud_controller_test.dart`、`reader_font_profile_test.dart`、`native_reader_epub_chapter_transition_test.dart` 保留控制、会话与字体优先级回归。状态型 Widget 套件分进程运行。

## 设置整理计划

1. 先运行既有听书面板回归，保留播放暂停、停止、模式选择、语速、音色与云端设置入口。
2. 复用既有组件，按播放方式、声音、定时组织；听书展示方式采用明确的互斥选项，行为开关说明动作方向。
3. 常用点句跳读在简易听书控制栏可达；云端服务的 API 参数仍留在云端设置页。
4. 验证窄屏、横屏、大字体和中英日文，不增加依赖。

## 云端边界

- 当前引擎只返回音频字节，没有真实句时间戳。保留句级高亮，不用字数比例冒充大段语音对齐。
- 当前阶段扩大有界前瞻缓冲，减少逐句播放器初始化，保证首句尽快启动；预取失败只在该句轮到播放时报告。
- 停止、暂停、跳读、切音色或语速后旧任务不得发声。请求与缓存有界，优先用户最新目标。
- 将来取得准确句时间信息后，可自然段批量合成并按句时间 seek，不绑定屏幕分页。

## 验收

- 本地文本与书源共用点击坐标到原文偏移；生成缩进、空行、跨页句子不破坏定位。
- 跳读句首、暂停跳读、快速跳读、跨章、停止后旧请求完成、定时停止有回归。
- 正文浏览与回到朗读、两种听书展示、设置持久化有组件回归。
- 云端预取比原来提前一句更充分，有界并发，取消后不播放，错误延后展示。
- 测试与静态检查通过；云端真实音频间隔和设备触摸手感需实机验证，不能以模拟测试宣称无缝。
