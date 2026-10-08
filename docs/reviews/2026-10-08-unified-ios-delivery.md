# 2026-10-08 统一代码与 iOS 交付收尾

这份记录描述本次共享主目录的最终合并快照。当前维护入口见[文档索引](../README.md)，共享视觉与组件契约见 [DESIGN.md](../../DESIGN.md)。代码收尾阶段用户明确手机暂时不在，先完成代码、文档与 Git；随后用户接回手机并授权安装，最新执行结果见下方设备交付记录。

## 合并范围与简化

- 全部 18 个搜索/筛选入口复用药丸搜索框；全局 AI 与阅读 AI 输入框复用同一圆润玻璃外壳，支持毛玻璃、液态玻璃和透明度。原生输入、多行增长、附件及发送保持各页面的职责，列表根据输入区实际高度避让。
- 各话题的嵌套书架、文件夹展开/收回、横向封面分组卡片和 2–5 列自适应密度已纳入同一正常应用。
- 同时合入在线加载/缓存竞态修复、在线更新计数、连续阅读章节间距、设置返回优化和已上线的协议正文/缓存/同意记录。
- 删除重复输入外壳、无用路由代码和重复列数文案；已完成的缓存/书源计划收敛到当前说明，保留有独立价值的历史证据、活动计划和用户预览素材。没有新增依赖。

## 最终检查

各模块的定向回归与渲染证据见[搜索/AI](2026-10-08-pill-search-fields-validation.md)、[卡片/密度](2026-10-08-shelf-card-density-validation.md)、[在线加载](2026-10-08-online-book-loading-validation.md)、[协议](2026-10-08-legal-documents-validation.md)、[设置返回](2026-10-08-settings-return-animation-validation.md)及[书库更新维护](../library-source-updates.md)。有全局状态的 Flutter 文件分别运行在独立进程。

收尾补齐了 CI 的 TXT、EPUB、书源阅读器静态/动态用例与旧标题，隔离清单完整性检查通过，没有跳过或降低断言。四处 Dart 格式差异已统一，调用与数据保持原逻辑；最终签名包从格式调整后的正常源码重新构建。收尾三个 Flutter 文件分别独立运行，49 项通过；Python 工具回归 14 项通过；全仓 1098 个 Dart 文件格式检查通过。全仓分析没有 error/warning，仍有三条既有 info。

本地链接、源码/测试路径和删除计划引用已核对。完整 GitHub Actions、其他平台产品构建、实体手机交互和实际 WebDAV 双设备恢复未在此次收尾重新验证；各模块历史验证范围以各自记录为准。

## 签名包与后续安装

- 正常入口：`lib/main.dart`。
- 身份：`com.niki.xxread / 2.7.3 / 261008005`。
- 渠道：本地开发签名 Release，独立于 TestFlight / App Store。
- 最终不可变签名包及构建/源码/签名收据：`build/device-ios/unified-final-20261008/`。
- 最新交付入口：`build/device-ios/latest-unified.json`。
- 745 个 Git 管理的运行输入与签名构建源码逐一匹配；完整本地指纹另外包含两个被 Git 忽略的 Flutter 自动注册文件和 Finder 元数据，明细在 `git-source-check.json`。
- 748 个本地源码/原生文件/资产的构建前后指纹完全相同，源码 SHA-256：`b3fce388f7239070de854bc4c7a889007145d865299b64d12b9a82f8bf7c0ff8`。
- AOT SHA-256：`69e426451db25ce74b6622238d0317610f619c99105381a0147b164f43251e0e`。

较早 004 和 005 收据分别保存在 `pill-search-fields-20261008/`、`shelf-card-density-20261008/`，它们记录真实历史构建和 CoreDeviceError 4016 安装失败。最终包在代码收尾时尚未安装；用户随后接回手机，唯一负责人已完成身份核对、保留数据原位更新和启动验证，结果如下。实体 UI 操作和观感仍需用户查看。

## 手机接回后的执行收据

- 验证时间：`2026-10-08T18:25:33.831701+08:00`（北京时间）。
- 当前共享源码与最终签名包逐文件一致；Git 同步核对没有更新的运行代码，因此直接安装已经成功构建并严格签名验证的正常统一包。
- 实体设备核对为 SloanePro / iPhone 16 Pro，UDID 与既定目标一致。安装前版本为 `261008001`，保留数据原位更新后回读为 `com.niki.xxread / 2.7.3 / 261008005`。
- 默认激活启动成功，进程 `15399` 的可执行路径与安装后的 `Runner.app/Runner` 精确匹配，后续进程查询确认仍在运行。安装和启动证明交付，不等于用户已接受搜索/AI 玻璃外观或实体操作手感。
- 收据位于 `build/device-ios/unified-final-20261008/device-acceptance/`：`apps-before.json`、`install.json`、`apps-after.json`、`launch.json`、`processes.json` 和 `acceptance.json`。本轮只补充交付记录，没有修改应用代码或再次发布 TestFlight / App Store。
