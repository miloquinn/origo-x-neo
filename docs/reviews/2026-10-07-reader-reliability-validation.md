# 阅读跳章、重试和缓存恢复验证

## 结果与范围

修复公共章节加载与 ReadingSource 目录状态恢复；沿用当前工作区已有的失败目标、
load serial、catalog generation 和一次缺章恢复机制。没有增加依赖或书源名称分支。
版本号保持 `2.7.2+261005001`；本次不涉及发布或设备安装。

## Reader 修复与证据

- 后台章节失败只在该章仍占当前阅读窗口时提升为前台错误，防止读到第三章后被第二章迟到失败打断。
- 短末章至少占一个正文视口，使重试成功后的目标章节可以顶对齐，避免滚动中心把进度回写到上一章。
- 新章节加载接管时清理旧位置恢复状态；错误界面不产生新的阅读进度。
- 同一套加载/恢复链路用于普通切章、上下翻页目录跳转和 Retry。失败目标保持可重试，404 只自动恢复一次。

新增回归的失败证据保存在 `build/reader-reliability-20261007/reader-before.log`
与 `retry-before.log`；修复后 `reader-after.log` 的 17 项全部通过。
覆盖瞬时翻页、上下逐章、上下整书、重复 403 Retry、失败退出重开、成功重试后的进度重开、
目录插入及章节 ID 改变、迟到响应和不可见章节失败。

Reader 完整回归 `reader-page-after.log`：67 项通过，包括原有目录跳转、四种 saved anchor、
自然正文高度、缓存/分页/预取、自动翻页和横向跨章。朗读跨章回归 `reader-aloud-after.log`：10 项通过。

## ReadingSource 修复

仅在未缓存正文需要 runtime 时恢复完整目录解析状态，已缓存正文保持离线读取。
cache revision 从工作区已有的 5 升至 6，绕过旧语义下可能包含跨章正文的缓存。
目录/正文 HTTP 错误保留 statusCode，404 可进入既有缺章恢复，403 保持明确失败。

共同目录初始化按 runtime、source revision、book 去重；调用者独立取消，强刷按请求顺序执行。
目录身份排除 reader 注入的章内上下文变量，保留自定义书源变量，防止每章重复加载全目录。

已完成的 future 不再作为永久初始化依据。成功状态由 runtime 中有界的 marker 验证，
并检查目标章节边界、book context 和实际需要的 rule state；内存淘汰或清理后会重新初始化。
末章的 `nextChapterUrl` 为空字符串仍是有效边界。

新增 `reading_source_cached_catalog_boundary_test.dart` 的 13 项全部通过：
内存/磁盘目录重开、链尾 404、完整脚本状态、相邻 reader 变量去重、自定义变量切换、
共享初始化、失败重试、取消首调用者、取消 follower、强刷顺序、结构化 404 与低容量状态淘汰后重开。
原冷目录正式复现修改前 5 项均失败，现均为正确行为断言。

| 独立 Source suite | 通过项数 |
| --- | ---: |
| cached catalog boundary | 13 |
| chapter cache | 4 |
| rule revision | 4 |
| xpath cache revision | 3 |
| runtime components | 3 |
| login invalidation | 7 |
| pagination | 14 |
| format contract | 13 |
| HTTP transport | 29 |

Source 共 90 项，Reader 共 94 项，合计 **12 个独立 suite、184 项通过**。
Reader 8 个检查项及 Source 8 个检查项的 Flutter 静态分析均为 `No issues found`；
`git diff --check` 通过。独立代码复审中的并发与生命周期问题已修复并复审通过。
证据集中保存在 `build/reader-reliability-20261007/`。

## 测试隔离修复

当前工作区初始化先查询书架，原 widget fixture 会调用真实全局数据库并卡在假时钟中。
使用共用 `NoShelfBookSourceService` 隔离该依赖；没有增加超时或跳过断言。
`_pumpUntilFound` 超时现在明确失败，修正了旧测试期待已经不存在的 instant surface key、
在无标题页情况下先滚过短正文，以及未落到边界却声称覆盖延迟跨章的刺激。
延迟横向跨章测试现在驱动 PageController 到边界，并在释放正文前断言已到该页。

每个 Flutter suite 在独立进程运行。为避开原 checkout 的外置 build symlink 与
`install_name_tool` 冲突，使用真实临时 build 目录和指向本 checkout 的源码。
这些隔离不修改产品行为。

## 改动文件

- `lib/pages/reader/book_source/book_source_reader_chapter_loading.dart`
- `lib/pages/reader/book_source/book_source_reader_catalog_loading.dart`
- `lib/pages/reader/book_source/book_source_reader_vertical_paging.dart`
- `lib/book_sources/protocol/reading_source/reading_source_backend.dart`
- `lib/book_sources/source_engine/source_runtime.dart`
- `lib/book_sources/source_engine/source_runtime_state.dart`
- `lib/book_sources/source_engine/source_runtime_catalog_reading.dart`
- `lib/book_sources/source_engine/source_http_transport.dart`
- `test/book_source_reader_recovery_test.dart`
- `test/book_source_reader_page_test.dart`
- `test/book_source_reader_aloud_transition_test.dart`
- `test/support/no_shelf_book_source_service.dart`
- `test/reading_source_cached_catalog_boundary_test.dart`
- `test/reading_source_rule_revision_test.dart`
- `test/source_http_transport_test.dart`
- 本计划、诊断与验证记录。

## 证据边界

受控回归确认上述客户端缺陷已修；当前 Mac 实站访问篱笆好文学仍得到地区拦截 HTTP 403。
客户端不能使上游持续拒绝访问、断网或不存在的正文变成成功加载。
此次没有用户原手机错误日志，不能确定其实际使用哪个书源，也未完成该手机或全部书源实测。
旧缓存失效后需联网重新取得受影响正文。未 commit、push 或发布。
