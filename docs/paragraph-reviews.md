# 书源段评维护

从 [维护入口](README.md) 进入；书源所有权与协议边界见 [书源架构](../lib/book_sources/README.md)，缓存身份见 [阅读缓存](reading-cache.md)。

## 兼容范围

兼容导入的 Legado 书源正文中带有 `style: "text"` 与非空 `click` 的图片动作：`<img src="图片地址,{...}">`。图片地址可为 HTTP(S) 或内嵌 data image，JSON 支持实体编码、引号和嵌套内容。动作保留完整 `src` 作为脚本的 `result`。普通图片没有点击脚本时不会产生段评气泡；没有提供段评的书源不显示气泡。

这是通用正文动作兼容，不按书源名或域名特判。当前上游的 `ruleReview` 消费链未启用，本实现没有把这个字段当作段评接口，也没有新增平台自建评论服务。ORSP 章节动作明确返回不支持。TXT、EPUB 和没有动作的章节沿用原有文字排版与正文宽度。

## 正文、净化与位置

`book_source_chapter_text.dart` 同时投影 canonical 正文和 `BookSourceParagraphAction`，动作身份为书籍/章节/原始标记序号。正文不包含气泡标签、图片数据或脚本；TTS、搜索、批注和进度继续使用正文 UTF-16 offset。

净化通过 `ReplaceRuleService.applyBatchAsync(ranges:)` 对每次实际 literal/regex 替换以及逐行 trim 同步映射段落区间，不用相似文字搜索，也不按长度比例猜位置。整段删除时删除动作；局部替换移动锚点；合并、拆分后仍保留各个原始动作与原始段落摘要。两个气泡在同一行或过于紧密时，共享选择弹层列出各个原始评论入口，防止互相遮挡。净化只改变展示文本，不改写原始章节或 `click` 脚本中的上游段号。

正文与动作一起进入阅读器的有界章节内存缓存。目录重排、净化规则改变、章节刷新和内存裁剪同步清理或重建动作。磁盘仍保存原始 `BookSourceChapterContent`，已有缓存可以重新投影，导入书源和已有书籍无需数据迁移。

## 排版与共享外观

分页和连续阅读统一使用 `ReaderAnnotatedTextPage`、`ReaderParagraphActionLayer`。有动作的章节预留 36pt 侧栏，分页测量与实际绘制使用同一正文宽度，宽度进入现有分页 fingerprint；无动作章节不预留。气泡只出现在拥有段落最后一个字符的页面，使用实际 `RenderParagraph` glyph boxes 定位，并消耗翻页/听书跳读的同一点击。动作身份和位置进入卷页快照的内容 revision。

气泡、合并选择列表、段评弹层分别复用 `GlassIconButton`、`AppSkinIcon` 与 `showGlassBottomSheet`；阅读配色通过 `ReaderThemePalette.toThemeData(parentTheme:)` 继承应用材质设置。实底、毛玻璃、液态玻璃与明暗模式共用同一组件链，圆角、宽度上限、安全区域与动画由共享底部菜单负责。网页内容由书源提供，应用负责弹层外壳。

`ReaderParagraphReviewPresentation` 读取 Legado `config` 的安全展示子集：`heightPercentage` 是 0–1 比例，限制在 0.25–0.95；`dismissOnTouchOutside` 和 `isDraggable` 控制关闭交互。源端 Android 窗口标志、自定义圆角与背景不覆盖共享外观。

## 点击与网页会话

`BookSourceClient.executeChapterAction → ReadingSourceChapterActionBackendPort → SourceRuntimeChapterActions` 只在用户点击时运行。它恢复源库、书籍、章节和变量，复用现有网络、Cookie、localStorage、持久缓存与脚本能力，并完整传递 `showBrowser(url, html, preloadJs, config)`。相对 URL 在运行时解析为绝对 URL。常规登录流程保持 `standard`，章节动作标记为 `reading` 并交给阅读器独立 handler。

`SourceBrowserContentView` 在 Android、iOS、macOS 中嵌入原生 WebView，视图各有独立 MethodChannel。Cookie 和 localStorage 继续按源和 origin 隔离；关闭、返回、点击遮罩和下拉关闭尽量先捕获会话，捕获超时保留最近可用快照。关闭弹层取消其网页回调，外层动作仍可接收捕获会话；退出阅读器、目录或净化刷新取消整个动作，过期回调不写回。

现代 Legado 网页的全局 `run()` 和 `*Await` 桥接通过同一运行时执行，保持上游字符串返回语义，网络 Await 返回正文、响应或 headers 的对应字符串。 网页回调携带当前 interaction 的 live evaluator，固定回到外层执行 Zone，共用原有书籍/章节变量并支持上游变量删除。会话用字段归属和独立 mutation revision 处理取消回滚与并发保存，保护同时发生的合法登录、缓存和 browser 更新。这个保证覆盖受控正常关闭/取消后的最终状态，不提供进程强杀时的事务隔离。桥接不暴露原生反射。网页 `refreshContent` 在外层动作结束后调用窄能力 `refreshChapterContent`，只强制刷新当前章节，越过正文缓存并使用最新请求令牌阻止旧响应覆盖，不清登录或全源缓存。

## 已知边界与验证

- 旧网页直接同步调用 `java.ajax/get/post` 等原生 Java 接口的方式尚未完整兼容；当前 Flutter 网页桥接支持现代 Promise/Await 路径。`webViewGetSourceAwait`、`createSignHexAwait`、`importScriptAwait` 当前明确返回不支持。依赖 JVM、Android 原生插件或上游未实现脚本能力的源不能据此声明全部兼容。
- Windows、Linux、Web 暂没有嵌入评论 WebView 的同等能力，显示明确的加载反馈；正文阅读仍可继续。
- 评论服务、源端登录与真实源的发布/点赞等行为属于源端接口；fixture、组件截图和本地构建不能替代真实书源/账号的端到端验收。

主要回归入口：

- `book_source_chapter_text_test.dart`：动作解析、HTML 实体、原始脚本与标题清理。
- `replace_rule_executor_test.dart` / `replace_rule_service_test.dart`：删除、重复段落、合并、拆分、Unicode、逐行 trim、超时回滚与 isolate。
- `source_runtime_chapter_actions_test.dart`：上下文、延迟点击、嵌套网页回调、字符串返回、会话代次和取消；`book_source_client_facade_test.dart`：窄能力路由。
- `book_source_chapter_cache_test.dart` / `reading_source_chapter_cache_test.dart`：强制单章刷新与旧响应保护。
- `reader_paragraph_action_layer_test.dart`：真实 glyph 定位、跨页、合并选择、正文宽度、点击优先级；`book_source_reader_paragraph_actions_test.dart`：阅读器净化和点击闭环。
- `reader_paragraph_review_sheet_test.dart`：三种材质、明暗模式、返回/遮罩/取消和 config；`source_browser_content_view_test.dart`：嵌入视图控制与快照。

具有进程全局状态的 Flutter widget 文件分别运行；同一 checkout 的 Flutter 任务还可能竞争 macOS native assets 的生成和签名，先单独复现再判断产品是否存在问题。

### 2026-10-10 验证记录

段落投影、净化映射、章节刷新、运行时上下文/取消/并发会话保存，以及阅读器三种阅读模式的定向回归均已通过。阅读器批注、气泡、弹层和嵌入视图的 widget 文件分别运行通过；全库静态分析没有 error 或 warning，仍有 6 条与本次功能无关的 info 提示。日志保存在 `build/paragraph-comments/final-regressions/`、`runtime-verification.log` 和 `analyze-final.log`。

iOS 模拟器中通过真实 `SourceRuntime.executeChapterAction` 打开共享弹层与原生 WKWebView；网页 `run()` 读取当前书名和章节，关闭时捕获 URL、HTML 和 localStorage，外层脚本随后正常结束。实底与液态玻璃暗色两次运行均记录 `SOURCE_BROWSER_SHEET_SMOKE=PASS`，日志为 `build/paragraph-comments/source-browser-sheet-{solid,liquid}.log`。三种材质的明暗组件截图也已检查。Android Kotlin 编译、macOS Runner 构建及 iOS Swift SDK 类型检查通过。

上述原生网页是受控 fixture，不访问真实评论服务。SloanePro 更新由共享 checkout 的统一安装任务负责，安装与真实书源/账号的段评验收需要各自的回执；本记录不表示已完成这两项。
