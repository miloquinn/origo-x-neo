# 在线书籍加载与统一缓存验证

2026-10-08 历史验收记录，覆盖在线文字阅读器启动与共享缓存的独立回归，以及随后合并书架、玻璃组件的统一真机交付。当前维护契约见 [阅读缓存](../reading-cache.md)，文档入口见 [维护索引](../README.md)；下文源码、版本、检查结果和提交状态均描述当时快照。

## 问题与最终行为

调查确认统一缓存已经接入，并非重新建立缓存系统。额外等待来自两个边界：启动先等待替换规则和书架查询，随后才发起目录、进度和设置读取；缓存冷读在检查进行中的请求之前各自读取磁盘。并发用例还复现了迟到的旧目录覆盖新内存结果。

本次实现并行启动、复用已有书架身份、共享冷读和请求、修复迟到旧目录及内存释放后的刷新等待。身份/规则净化屏障、已有取消机制、错误反馈和分页资源所有权均保留；没有新增依赖或缓存层级。完整调用链、失效条件和维护检查收敛在 [阅读缓存维护](../reading-cache.md#maintenance-source-map)。ORSP 目录请求作用域和 runtime 初始化等待者的取消覆盖，不代表 ReadingSource 外层目录缓存请求已隔离，见维护说明中的 [已知限制](../reading-cache.md#known-limitation-readingsource-catalog-cancellation)。

## 修改文件

| 文件 | 职责 |
| --- | --- |
| `lib/book_sources/caching/book_source_chapter_cache.dart` | 共享磁盘读、请求复用、刷新标记及新结果优先 |
| `lib/pages/reader/book_source/book_source_reader_catalog_loading.dart` | 并行启动、单次身份查询、异步附加数据 |
| `lib/pages/reader/book_source/book_source_reader_page.dart` | 初始书架身份和进行中的查询 |
| `lib/pages/reader/book_source/book_source_reader_navigation.dart` | 设置更新后的当前身份 |
| `lib/pages/reader/book_source/online_reader_factory.dart` | 传递已有持久化书架记录 |
| `test/book_source_cache_concurrency_test.dart` | 19 个缓存并发、清除、错误恢复和内存压力用例 |
| `test/online_reader_startup_test.dart` | 5 个启动、净化屏障和身份更新用例 |
| `docs/reading-cache.md` | 更新实际读取与启动契约 |
| `docs/README.md` | 当前维护入口与文档生命周期规则 |

修改前的完成计划已合并到维护说明并删除；原文保存在已归档的独立工作区快照中，不作为后续 AI 的待执行指令。

## 回归与静态检查

独立验证工作区从 `7e6ecfba5425ab87a8cd2e90dad46d567914bedb` 建立，只带入本次修改。有全局状态的 Flutter 用例在 22 个独立进程中运行，没有跳过断言，共 115 项通过：

| 范围 | 通过数量 |
| --- | ---: |
| 缓存并发、章节缓存、目录新旧版本、请求取消范围、兼容目录边界、规则和登录身份 | 76 |
| 阅读器错误恢复与新启动用例 | 22 |
| 真实 SQLite 在线分页重开复用 | 1 |
| 客户端与书架服务资源所有权 | 7 |
| 按书净化、初始化期间规则更新、预加载、非阻塞进度、关闭取消和进度恢复 | 9 |
| 合计 | 115 |

- 本次 7 个 Dart 文件使用项目 Flutter SDK 执行 `flutter analyze --no-pub`，无问题。项目 Dart 格式检查与本次 diff 空白检查通过。
- 独立代码复核在补齐「释放内存后后台刷新不得阻塞旧磁盘缓存」回归后通过，无剩余发现。
- 全仓静态检查保留 3 条原有 info：`source_chapter_state.dart:313` 的花括号、`source_cookie_utils.dart:32` 的 rethrow、`offline_reader_license_refresh_test.dart:9` 的冗余 import。默认命令因 info 返回 1；没有发现 error 或 warning。这三个文件与验证基线完全一致。
- 架构检查 3 项通过、1 项原有失败：`source_script_bootstrap_program.dart` 为 912 行，超过 800 行职责预算。未修改的 HEAD 与本次树均复现此项；未降低断言。本次修改的生产文件均在既有预算内。

## 独立验收与统一安装交接

先在独立工作区执行：

```sh
flutter build ios --release --no-pub --target lib/main.dart \
  --dart-define=ORIGO_DISTRIBUTION_CHANNEL=direct \
  --dart-define=ORIGO_STORE_READER_LICENSE_REQUIRED=false
```

- 产品构建成功，Xcode 196.1 秒，整个命令 211.63 秒，应用 58.7 MB。deep/strict 签名检查通过。
- 669 个 lib、shader、资产和 pubspec 文件构建前后无漂移。清单 SHA-256：`1668548dc31aa341f16d8d979d4a11076d0daaae8b9fd457a5962c32afbad3b3`。该检查不包含原生工具链配置。
- 独立包 AOT SHA-256：`97e410e2f1e65e56a1a4a39b917d17f49fcbb77265ba3752f64aa2e7c5c90faa`。
- SloanePro 身份为 iPhone 16 Pro / `00008140-001979421E93001C`；独立验收包覆盖安装后回读 `com.niki.xxread / 2.7.3 / 261008001 / builtByDeveloper=true`。前台启动成功，PID `13588`，安装、启动和进程回读路径一致。没有卸载或清空数据。
- 安装后数据目录 UUID 改变，因此没有以 UUID 相同作为数据保留证明。实际回读 v27 数据库有 11 本书、11 条阅读统计及 11 条在线进度；2 个原有导入文件合计 10,812,730 字节，修改时间仍为 2026-09-17。临时数据库副本只作只读版本/行数检查，随后删除，没有保存数据库或凭据内容。
- 主要日志、签名包、源码清单和安装/启动/数据回读收据保存在本地忽略目录 `build/device-ios/online-loading-20261008/`。

随后用户在「添加液态玻璃与毛玻璃切换」要求多个话题共同安装，防止独立旧快照覆盖新按钮。本话题立即停止后续独立安装，统一交付由该话题负责。独立验收包不能作为多个功能合并后的最终包。

统一交付已完成。已逐个比对最终 `261008003` 构建前后清单，本次 5 个产品代码文件全部一致，没有未合入文件或后续产品修改。最终清单共 679 个文件，SHA-256：`a0b19e21e29392c118b104bcc907ed0eb77b6fba5acf72f7859efa1f7c878c02`，AOT SHA-256：`669ae7b79c327b01c1a7fda58b78db513b95fd57b869716d61363e411a50b91f`。

- 统一包从共享主目录构建，包含共享玻璃弹簧按钮与阅读控制栏、嵌套书架 v28 迁移和备份，以及本次在线启动/共享缓存优化。
- 回读 SloanePro 为 `com.niki.xxread / 2.7.3 / 261008003`；原手机版本为 `261008001`，覆盖安装未清空数据。前台启动成功，PID `14018`，安装路径、启动路径和后续进程回读一致。本话题核对了实际收据，没有再次执行构建或安装。
- 最终签名包与收据在 `build/device-ios/shared-glass-buttons-20261008/`；本话题也保存了 `build/device-ios/online-loading-20261008/unified-delivery.json` 与更新后的交接记录。
- 交付时，按钮代码已提交并推送为 `7f71282ee361074b4ceaaf7bbbb1d161feab75b1`；加载/缓存代码当时保留在共享主目录 WIP，没有混入按钮提交。后续提交状态以 Git 为准。
- 交付为本地 direct 开发签名 Release 验收包，未发布 TestFlight/App Store。真机手感和实际书源耗时仍待实际验收。后续安装继续由统一交付话题负责，使用共享主目录的最新合并代码。

## 网络引擎判断与实际限制

[rhttp 官方说明](https://pub.dev/packages/rhttp)列出基于 Rust/reqwest 的 HTTP/1、HTTP/2、HTTP/3 支持；[客户端文档](https://pub.dev/documentation/rhttp/latest/rhttp/RhttpClient-class.html)强调复用客户端和连接。现有 `SourceHttpTransport` 已持有并复用 Dio 客户端，不为每个请求重建。

推断：当目标服务器支持相应协议且传输确为主要等待时，更换传输可能有收益。当前没有代表性书源的对照数据，不能把文件下载基准直接当作读书加速证明；本次先消除已复现的重复工作。书源服务器、DNS、WebView 验证、脚本解析和分页仍可影响首次加载。

兼容书源在读取未缓存正文前需要恢复目录脚本状态与下一章边界，保留这一经过回归验证的依赖，避免把相邻章节合并。离线旧缓存、损坏缓存重建及缓存写入失败继续使用既有恢复策略。

控制并发的用例证明等待关系、读盘次数和结果新旧边界，不代表真机书源耗时百分比。实际阅读手感与服务器延迟需要在对应书源上测量；不宣称所有书源都已变快。

## 文档维护收尾

- 当前维护说明收敛到 `docs/reading-cache.md`，增加源码职责、不可破坏的契约、排障和回归入口；仓库及模块概览只链接到它。
- 删除 5 份被现有实现、维护说明和验收覆盖的完成计划：2026-08-08 本地分页、2026-08-09 书源所有权、2026-09-05 统一缓存、2026-10-07 可靠性、2026-10-08 在线加载。历史原文可从 Git 或已有归档快照恢复。
- 保留独立诊断与验收证据，并标明日期和历史状态；旧“未修复”“当前工作区”和已完成任务步骤不再作为当前事实或行动入口。
- `AGENTS.md` 固定同步维护与旧文档清理规则，记录同仓库多个话题的统一安装约定。仅文档修改检查链接、源码/测试路径和 diff，不执行产品构建或设备安装。
- 独立复核纠正了取消隔离的过度概括：ReadingSource 的阅读/下载目录仍使用外层缓存默认 `#shared` 作用域，该场景未由既有 ORSP/runtime 取消回归证明。限制和后续修复需要的回归已写入当前维护说明，本次没有改动应用代码。
- 文档校验覆盖 10 个文件、72 个本地链接/锚点和 23 个源码/测试路径，无断链或已删除计划的残留引用；diff 空白检查与独立文档复核通过。应用及测试文件摘要保持不变。检查记录在 `build/validation/documentation-maintenance-20261008/checks.json`。
