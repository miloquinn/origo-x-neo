# 阅读跳章与后续章节加载失败诊断

> 历史诊断，记录 2026-10-07 修复前及调查阶段的复现。下文“当前”“HEAD”“未修复”仅指当时快照，不是今天的待办。修复结果见 [阅读可靠性验证](2026-10-07-reader-reliability-validation.md)，后续启动优化见 [在线加载验证](2026-10-08-online-book-loading-validation.md)。维护以 [阅读缓存](../reading-cache.md) 和现有源码/测试为准。

调查日期：2026-10-07。基线为 `main` 的 `b8e81a85` 及当前已有未提交改动。
本次调查没有修改应用代码，没有发布版本。第一轮截图没有提供版本、书源、书名、阅读模式或日志。
后续已提供《重生日常修仙》、“上下翻页”、失败后重试无用，以及两个书源的导出；后续结论见文末。

## 已复现：目录缓存没有恢复正文所需的运行状态

影响 ReadingSource / Legado 兼容书源。触发条件是目录已缓存、新建 runtime 打开书籍、正文尚未缓存，且 `nextContentUrl` 会选到下一章的链接。

1. `lib/book_sources/protocol/reading_source/reading_source_backend.dart:211` 的
   `getChapters()` 可直接返回内存或磁盘目录；默认 30 分钟内不执行 loader。
2. `lib/book_sources/source_engine/source_runtime_catalog_reading.dart:203` 在真实解析目录时
   才给每章写入 `nextChapterUrl`、index、title 等运行状态。
3. `lib/book_sources/source_engine/source_runtime_state.dart:13` 的状态只有内存 Map。
   目录缓存只保存章节模型，没有保存或恢复这些状态。
4. `lib/book_sources/source_engine/source_runtime_reading.dart:83` 在新 runtime 中取不到
   `nextChapterUrl`；229 行用于阻止跨章的边界检查因而失效。
5. 后续章节被当成本章分页继续下载并拼接。请求成功时，错误正文会按原 chapterId
   被缓存；12 小时内可直接复用，单独刷新目录不会使正文缓存失效。

使用真实 `ReadingSourceBackend`、`SourceRuntime` 和受控 transport 复现：

| 场景 | 实际请求 | 实际结果 |
| --- | --- | --- |
| 首次加载目录再读第 1 章 | chapter/1 | 只有第 1 章正文 |
| 新 runtime 命中缓存目录，再读第 1 章 | chapter/1、2、3 | 三章被拼进第 1 章 |
| 此后只刷新目录、再次读取相同缓存键 | 无正文请求 | 仍返回拼错的缓存正文 |
| 缓存目录重开，误跟随的链尾返回 404 | chapter/2、3、4 | 原本有效的第 2 章也加载失败 |
| 在同一 backend/runtime 内强制刷新目录 | 只请求 chapter/2 | 第 2 章恢复正常 |
| 清除静态内存、只保留磁盘目录，再用真实 reader 参数读未缓存正文 | chapter/2、3 | 第 3 章仍被拼进第 2 章 |

这证明了公共链路缺陷；还不能证明截图里的“跳章”一定指正文混章。

## 已复现：兼容书源 404 无法触发已有自动恢复

`lib/book_sources/source_engine/source_runtime_catalog_reading.dart:311` 和
`lib/book_sources/source_engine/source_http_transport.dart:631` 将 HTTP 状态写进文字消息，
没有设置异常的 `statusCode` 或章节错误 `code`。

`lib/pages/reader/book_source/book_source_reader_chapter_loading.dart:100` 只对
`isMissingChapter` 刷新目录并重试。受控 404 的 `statusCode == null`、
`isMissingChapter == false` 已在复现测试中断言。因此 ReadingSource 的缺章响应不会
进入这条恢复路径；当前未提交的 ORSP 修复不能视为已经修复兼容书源。

reader 每次成功加载章节都会预取下一章，再预取前一章和后两章。
`book_source_reader_chapter_loading.dart:302` 吞掉后台预取错误，前台翻章再重试。
没有证据表明预取会固定在“几章”后停止；更可能是后续请求失败而表现为缓存没有继续。

## 代码确认的另一条跳章风险

HEAD 的 `book_source_reader_chapter_loading.dart:409`，`_jumpToVerticalChapter()`
等待正文后只检查 mounted。连续滚动中若 B、C 两次跳转重叠，C 先返回、B 后返回，
较旧的 B 请求仍能覆盖当前章节，并排队保存错误进度；再次打开会恢复到 B。

当前工作区 593 行起已有复用 `_loadChapter` 及 serial/generation 检查的改动。
不能把已有未提交改动等同于已发布或验证完成的修复。

另一个需要实际目录才能判断的分支：初始化时若保存的 chapterId 不在当前目录，
`book_source_reader_catalog_loading.dart:46` 回退到旧 chapterIndex。若网站更换 ID
并插入、删除或重排目录，旧索引可能对应另一章。

## “手动更新后恢复”的限定

上述恢复复现使用同一 backend/runtime。真实“检查更新”界面通过
`SourceBookUpdateService` 新建并关闭另一套 client/runtime；它不会直接补回在线
reader 的运行状态。因此不能把同实例强刷的结果直接归因到截图里的手动操作。

如果用户读的是下载的本地 TXT，“继续更新”会实际下载新增章节并写入本地文件，
属于另一条路径。需要确认在线/本地、具体按钮和更新后的操作。

## 验证与证据

- 4 项受控诊断测试通过：正常边界、缓存重开混章与缓存污染、404 失败及同实例强刷恢复、
  磁盘目录冷启动混章。测试断言保留了 404 无结构化恢复信号的事实。
- `test/source_runtime_pagination_test.dart` 独立运行，14 项通过。
  原测试覆盖先真实解析目录再读取正文，未覆盖缓存目录重开的组合。
- 当前未提交工作区的 `vertical source reopens at the saved text anchor` 四个 widget case
  独立运行仍出现 `pumpAndSettle timed out`；这是现有改动的验证缺口，不能据此宣称
  用户现场故障已复现。干净 HEAD 的同组四项通过。
- 原工作区测试受外置卷 build 符号链接的 `install_name_tool` 错误阻塞。
  诊断使用独立临时构建目录，lib/test/assets 指向当前工作区，应用源码未复制成旧版本。
- 磁盘复现的一次重跑碰到异步正文写盘与临时目录删除竞争；诊断改为只持久化目录，
  保留全部正文断言后重跑。这个测试清理问题与用户故障无关。

本地证据保存在忽略的 `build/reader-chapter-diagnosis-20261007/`：
`cached_catalog_boundary_probe_test.dart`、`boundary-probe.log`、`vertical-reopen.log`。

## 修复方向与待确认信息

兼容书源应在首次读取未缓存正文前确保当前 runtime 已初始化完整目录/规则状态；
缓存命中不能冒充 runtime 已解析目录。修复后需使旧的跨章正文缓存失效。
同时应保留 HTTP 状态并用既有有界恢复机制处理缺章。
垂直跳转应统一使用请求序号保护状态应用及进度保存。

待确认：反馈者的版本、书名、书源及在线/本地模式；“跳章”是章节编号变化还是正文混章；
使用的翻页模式；所谓“更新书”具体是哪一个操作。

## 后续实查：具体书源、上下翻页、重试无效

用户补充书名为《重生日常修仙》，使用“上下翻页”，部分章节加载失败后点击重试无效。
`pageTurningScroll` 的产品文案“上下翻页”对应 `ReaderPageMode.verticalScroll`。
导出文件包含两个启用的书源：书旗小说（ORSP 适配）、篱笆好文学（ReadingSource）。
用户不知道具体使用哪一个，继续通过实际接口与阅读器代码核对，不重复索要确认。

### 确定复现：全屏重试回到上一成功章节

在干净的已提交基线 `b8e81a85` 上运行受控 widget probe：

1. 显示第 1 章，令第 2 章正文返回临时错误。
2. 前台打开第 2 章，出现全屏错误和 Retry。
3. 恢复受控第 2 章响应，让再次请求可以成功。
4. 点击 Retry，界面实际显示回第 1 章，未显示第 2 章。

根因：HEAD `book_source_reader_chapter_loading.dart:35-41` 在 catch 中清空
`_requestedChapterIndex`；HEAD `book_source_reader_shell.dart:105-109` 的重试只用
仍然指向上一成功章的 `_chapterIndex`，所以重试目标丢失。

两次独立 probe 均通过其缺陷复现断言：

- 即时翻页：`head_retry_target_probe_test.dart` / `head_retry_target_probe.log`。
- 上下翻页并启用逐章滚动、从目录选择第 2 章：
  `head_vertical_retry_probe_test.dart` / `head_vertical_retry_probe.log`。

共同关键输出：`firstFailedTarget=second retryVisibleChapter=old`。
重新应用第 1 章后又会后台预取第 2 章，所以最后一条网络请求可能仍是 second；
验证使用实际渲染章节，避免把预取误当成前台重试。

当前已有未提交改动保留失败目标并优先重试它，本次没有重复修改这些代码。
这证明公共全屏重试缺陷，也证明它适用于上下翻页的逐章分支；尚不知道反馈者是否启用逐章滚动。

整书连续上下翻页的内嵌重试是另一路径：失败 future 已在 whenComplete 移除，按钮触发重建后
重新请求同一章节。没有“失败 future 永久卡住”的代码证据。如果原 URL/书源响应持续失败，
重试也会持续失败。失败占位没有成功内容，位置监听器不会将其保存为当前章，重开会回到
最后成功章；这可以造成用户所说的“跳回”。

### 实站结果：两个源不能混为同一个故障

| 书源 | 本次实际结果 | 能得出的结论 |
| --- | --- | --- |
| 书旗小说 ORSP | 搜到精确书名，bookId=9162987；目录共 1069 章；第 13 章“第13章 道个歉吧”；第 10、13、14 章均 HTTP 200、正文非空且响应身份一致；重复两次前 100 章 IDs 稳定 | 本次没有复现这些章节的书旗服务故障，不能排除用户旧目录/旧版本或先前服务状态 |
| 篱笆好文学 | 原导出请求头的搜索/书籍入口返回 HTTP 403；HTML 明确“地区拦截”“你的区域被禁止访问”；项目真实 SourceRuntime 同样在搜索阶段失败 | 当前 Mac 出口被站点地区策略拒绝，普通重试不会改变出口或访问许可 |

篱笆请求的 DNS 地址落在 fake-IP 测试网段，Mac 当前流量经过透明代理/TUN。
403 只说明本次出口被拒绝，不能据此声称反馈者手机当时也是 403。
未改变系统网络、代理配置或任何书源。

篱笆导出的规则是 `nextContentUrl=text.下一页@href`。此前冷目录缓存混章的复现
要求这条规则选中下一章链接；当前站点被地区策略挡住，无法读取真实第 13 章分页 HTML，
因此尚未把此前混章缺陷归因到这个实际书源。

新增本地证据位于同一 ignored 诊断目录：`actual-orsp-catalog.json`、
`actual-orsp-summary.json`、`actual-libahao-runtime.log`、`search.headers`、`search.html`，
以及两组 HEAD 重试探针及日志。实站检查没有保存整章正文。

本轮剩余未知：设备 App 版本、实际选择的源、逐章滚动开关、失败时的错误消息。
目前最直接且已复现的客户端缺陷是全屏 Retry 丢失目标；具体的最初网络失败仍不能唯一归因。
