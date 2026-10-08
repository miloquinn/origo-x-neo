# 本地 EPUB 目录跳转验证记录

## 用户场景与根因

用户确认本地 EPUB、左右滑动翻页。后部章节从目录跳向前部时正文空白，来回跳才恢复；
章节切换约等待 1–2 秒。

新测试在修改生产代码前复现：手机实际视口没有正文，替换控制器的页号为 65607，
其 initialPage 为 65602；双页平板旧号 65604、目标号 65601。
原因是 PageController 默认 keepPage=true、PageView 没有代次 key，PageStorage
恢复旧页号后，把新章节映射到虚拟空白页。目录路径还先等待目标 ±3 章，再经临时
Bookmark 重复等待窗口；较早的请求可在较新的请求之后取得 serial，覆盖新选择。

## 最终实现

- chapter/page 是阅读位置来源；跳章控制器 keepPage=false，PageView 按代次隔离，
  通知和页号回调验证控制器身份及代次。
- 目录、书签、搜索共享 `_setChapter` 导航事务，首次 await 前取得 serial。
  EPUB fragment/精确锚点在目标就绪后计算并原子提交，offset 0 保留独立标题页。
- 横向跳转前台只准备目标章，首帧只排目标窗口。冷前章在后台准备好后通过已有
  backward expansion 抵消新增页数；同一控制器和可见位置保持不动。物理滑动边界
  限制到有效 origin，前章未就绪时不能进入虚拟空白前缀。
- 冷目标加载时保留原正文并显示进度提示。邻章复用现有解析、替换与分页缓存。
  已解析但尚未完成替换的内容不提前发布；淘汰保护当前及待显示目标的邻近内容，
  并保护仍在解析或替换的章节。旧请求不能覆盖新目标。
- 位置对齐仅用于本次有效锚点恢复；普通滑动重建不会挂起一个迟到的对齐跳页。
  其他模式保留原章节窗口，加载期间切换模式时按提交时的模式处理。

## 清理范围

生产文件均位于 `lib/pages/reader/native/`：

| 文件 | 本次职责 |
| --- | --- |
| native_reader_navigation.dart | 删除目录预加载、临时书签转换及重复恢复流程 |
| native_reader_interaction.dart | 统一请求顺序、目标优先、锚点提交与加载提示状态 |
| native_reader_loading.dart | 复用单章/批量准备，按当前/待显示目标集中保留内容 |
| native_reader_horizontal_paging.dart | 控制器代次、目标首窗口、有效滑动边界 |
| native_reader_horizontal_window.dart | 后台单章准备、稳定前插，删除日常高频日志 |
| native_reader_page_cache.dart | 后台只准备所需单章，忽略过远的预热任务 |
| native_reader_scaffold.dart | 禁用旧页号继承、有效锚点对齐、加载进度提示 |
| native_reader_page.dart | 统一待显示目标状态，删除两项延后遮罩状态 |
| native_reader_chapter.dart | 明确可排版状态，保护待完成替换 |
| native_reader_auto_page_turn.dart | 沿用统一加载状态，移除旧保留参数 |

相对任务开始的 reader 快照，生产代码新增 254 行、删除 281 行，净减少 27 行。
没有新增依赖、书名/章节号特例、另建导航/缓存层；可验证的重复旧实现直接删除。
既有非本次改动的 WIP 保留，在线阅读器未修改。

测试文件：`test/native_reader_epub_chapter_transition_test.dart` 补远跳、代次、最后意图、
慢前章和滑动边界；`test/native_reader_initial_progress_test.dart` 为既有净化后全文搜索
用例显式启用该 EPUB 的净化。原用例未开启 EPUB 默认关闭的净化，失败发生在搜索结果
出现前；任务开始快照中的默认策略相同。所有搜索正文/位置断言保留。

## 验证证据

- EPUB 新增 4 项独立进程通过：手机/双页平板远跳的实际挂载正文；旧 PageView 回调不能
  覆盖新章；冷旧请求迟到仍保留较新的热目标；慢前章未完成时往回拖动不空白，前插后
  仍保留目标正文及同一控制器。
- TXT 竖向目录跳转 4 种 titlePage × scrollByChapter 组合分别独立进程通过。
  任务开始时组合合跑的初始化超时在各自隔离后不复现。
- TXT 横向目录首帧标题/前章就绪通过。
- EPUB 初始位置首帧、跨章净化后全文搜索、同章非零搜索锚点、连续滚动初始恢复通过。
- 分页持久化 3 项通过；自动翻页跨 EPUB 章边界通过。
- 实际《我与地坛》文件通过临时 widget 探针：currentPage 19 → spine 3 的目录正文可见；
  重复跳转 spine 3 的 onPaginationCacheMiss 总计为 1，证明分页复用。探针只通过参数读取
  用户本地文件，执行后清除临时源文件，不进入运行代码或永久测试集。
- 实际文件解析探针（macOS，仅解析）目标 spine 3：单章约 5ms、七章窗口约 18ms；
  全书 27 个 spine、14 个目录项。这些数字不包括替换、TextPainter、设备 GPU 或显示延迟。

最终验证：完整 EPUB 回归 12/12 通过；上列独立兼容检查 13 项通过；实际文件探针
1 项通过，共 26 项不同用例。目标 reader + 两个修改测试文件静态分析 No issues found；
12 个修改 Dart 文件格式检查无变化，git diff --check 通过。独立代码审查阻塞项为 0。
全仓 flutter analyze 无 error/warning，仍有 3 条已有 info：source_chapter_state.dart:313、
source_cookie_utils.dart:32、offline_reader_license_refresh_test.dart:9；本次未修改这些文件，
与任务开始前的结果一致。完整日志 `/tmp/origo-epub-jump-analysis-20261008.log`。

本地日志：`/tmp/origo-epub-jump-final-20261008.log`、
`/tmp/origo-epub-compat-results.json`（每项独立日志位于 `/tmp/origo-epub-compat-*.log`）、
`/tmp/origo-actual-ditan-jump-20261008.log`。实际文件临时探针源留在
`/tmp/origo-actual-ditan-jump-test.dart`，项目 `.dart_tool` 内的临时源已移除。

兼容测试的模拟环境仍打印 MissingPlatformDirectoryException、模拟书籍进度缺失等
已有日志；有效断言全部执行并通过。这不证明真实设备上的阅读进度持久化，设备验证仍单列。

## 实测边界

已完成本地代码修复、自动测试和真实文件的 widget 验证；尚未构建、安装或在用户平板
实测。热目标复用缓存；冷目标仍需解析、替换和目标章分页，不能将反馈及时性等同于
冷章节零加载时间，也不能把 macOS 解析数据当作 Android 帧率或端到端耗时。
