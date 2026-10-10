# iCloud 自动同步

仅原生 iOS（含 iPadOS）与 macOS 显示“我的 → 数据与同步 → iCloud 同步”。Android、Windows、Linux、Web 不显示、不初始化 iCloud 通道。WebDAV 继续提供[手动备份与恢复](webdav-backup.md)。

## 开启与范围

默认关闭。主动开启后，应用使用当前 Apple ID 的 `iCloud.com.niki.xxread` CloudDocuments 容器，自动同步书籍与子书架、阅读进度、书签/笔记、可跨设备的阅读和外观设置、本地正文、封面及书源章节 sidecar。在线书籍同步关联信息和章节位置，不自动抓取远端正文。书籍最近阅读时间与手动排序位置也会同步；书源注册表和阅读统计会话不在本功能范围内。

应用登录、会员状态、WebDAV 密码、AI/TTS 凭据、授权许可留在本机。书籍关联的书源配置随书籍同步；用户自行嵌入这些配置的访问参数也会随配置传输。自定义字体、背景图片、社区主题文件和本地缓存不传输，其依赖本机文件的设置不作为通用设置发布。同步使用用户的 iCloud 空间；关闭不删除任何本机或云端数据。

前台每 30 秒检查，在恢复前台和返回主页面时也尝试同步。切后台时尽力发布本地修改，系统控制实际后台传输，不保证结束应用后持续执行。正在阅读、编辑、下载、整理书源、WebDAV 操作或朗读时推迟接收其他设备的修改，避免覆盖仍在使用的内存会话。完成接收后通知书库事件总线，并重新载入应用偏好和外观。

## 页面与共享组件

页面沿用 `FloatingSubpageScaffold` 的导航、皮肤背景与安全区；内容宽度最多 680 点。`lib/widgets/settings_panel.dart` 提供可复用的 `SettingsPanel` 与 `SettingsInfoRow`，统一使用 `GlassSurface` panel 材质与 `AppSkinIcon` 语义图标。操作使用 `GlassTextButton`，开关保留原生自适应交互。玻璃关闭、Material 3、高对比、毛玻璃与液态玻璃均由[共用材质层](glass-material.md)决定，页面不复制模糊、透明度或描边配方。面板内按钮不重复过滤背景。

`test/icloud_sync_page_test.dart` 校验深浅色下实色/毛玻璃/液态三种材质的尺寸与操作一致，以及窄屏大字体；可选 `ORIGO_ICLOUD_CAPTURE` 生成六张布局预览。布局预览不代表实体设备液态玻璃与完整皮肤验收。

## 记录与冲突

每个安装维护独立的设备清单 `Documents/sync-v1/devices/<UUID>.json`；正文对象为 `Documents/sync-v1/assets/<SHA-256>`。安装身份额外绑定本机的匿名设备摘要，避免系统迁移复制偏好后两台设备共用同一清单。Apple 账号标识只用于本机分区与逐操作校验；切换已绑定账号会暂停，须主动重新开启。

每条记录包含设备版本向量、来源设备名和修改时间。不同记录独立合并。存在因果顺序时采用后续版本；相同内容合并向量。设备尚未互相同步就修改同一条数据且内容不同，保留各版本并显示设备、时间和内容摘要，用户选择后产生覆盖所有候选向量的新版本。时间戳只展示，不用于决定胜负；进度不会取最大百分比，因此回读同样可同步。

书籍或书架删除与进度、书签、笔记或子项修改同时发生时，以关联数据组成一个删除/保留选择，选定前不移除仍被使用的父记录。多个设备的不同候选保留各自的来源身份；无关的安全改动继续接收。

删除以持续保留的墓碑传播，云端缺少文件或查询失败不当成删除。书籍使用已有冻结 UID，子书架使用 UUID，书签与笔记拥有稳定身份。本地数据库整数 ID 不传输，接收端重映射外键。正文路径、分页页数、rendered locator 等排版缓存属于当前设备，接续以 canonical locator/归一化进度及在线章节进度为依据。删书同步移除书架记录，正文文件保留；当前实现不自动回收历史正文对象或墓碑。

书库整理元数据通过 `library_organization_v1_` 前缀的 setting 记录扩展：每条记录按书籍冻结 UID 或文件夹 UUID 标识，携带父目录、排名和最近阅读时间。既有 book/progress/folder 记录保持旧字段白名单，旧客户端可接收并转发 setting，避免一台设备升级后阻断整个同步批次。新客户端只在归属匹配时应用排名，最近阅读时间取已知最大值，旧数据缺少扩展时保留本地字段。详见[书库整理](library-organization.md)及 `icloud_sync_store_test.dart` 的真实旧 Store 往返回归。

## 完整性与故障恢复

正文采用流式 SHA-256 校验，读写期间检测文件变化。资源先传输，全部确认上传后才提交引用它们的设备清单。原生层使用 `NSMetadataQuery` 发现其他设备及被系统回收的占位文件，`NSFileCoordinator` 协调读取和替换；相同内容的写入不反复替换，避免重置未完成上传。界面区分已进入本机 iCloud 队列与已确认云端上传。

本地改动先持久化，再执行网络操作。接收使用应用日志，可重放中途退出的幂等应用操作；应用完成后才推进本机基线。网络下载后再次核对本机数据，保留传输期间的新修改。账号、网络许可和当前任务代次在异步步骤后复核。无法访问的本地正文不作为删除发布。

外来清单限制大小、结构和版本；不执行外来 SQL，不接受外来本机路径。原生只接受设备清单和 SHA-256 对象命名空间，拒绝路径越界及符号链接。适配器验证字段、文件校验和、书架环与外键，使用 SQLite 事务；原正文不直接覆盖。

## 维护入口

- 同步协议、向量与冲突：`lib/services/icloud/icloud_sync_models.dart`、`icloud_sync_controller.dart`。
- 数据投影、身份映射、文件与偏好边界：`lib/services/icloud/icloud_sync_store.dart`。
- Dart 通道与原生运输：`lib/services/icloud/icloud_sync_transport.dart`、`apple/ICloudSyncBridge.swift`。
- 开关、状态和冲突选择：`lib/pages/settings/sync/icloud_sync_page.dart`。
- 生命周期、许可与刷新：`lib/main.dart`、`icloud_sync_navigation_observer.dart`。
- 平台授权：iOS `Runner.entitlements` 已有容器；macOS Debug、Store、Website 三份 entitlements 使用同一容器。官网与商店配置仅保留现有 Apple 登录差异。

回归按独立 Flutter 进程运行：`test/icloud_sync_models_test.dart`、`test/icloud_sync_controller_test.dart`、`test/icloud_sync_store_test.dart`、`test/icloud_sync_page_test.dart`；设置入口矩阵在 `test/settings_page_test.dart`。既有 WebDAV 回归、协议启动门禁和 macOS 分发 entitlement 校验保持有效。原生 RunnerTests 覆盖命名空间、摘要及原始身份不披露。

2026-10-10 本批已通过 107 项相关 Flutter 回归：协议与控制器 27、真实双 SQLite 数据适配器 7、页面与导航 11、实际设置入口平台矩阵 6、协议启动门禁 10、WebDAV 34、既有应用设置 12。状态型页面按独立进程验证；功能范围静态分析无问题。另通过 31 项 macOS 构建、分发与签名工具回归及 iOS/macOS SDK 原生类型检查。六种页面布局预览保存在本机 `build/icloud-sync/preview-*.png`，不作为实体 UI 验收。

同日隔离产品验证：iOS Release 编译通过，最终源码 Debug 编译通过且输入摘要未变化；macOS arm64 Release 编译通过。macOS 本机 Developer ID 密码学签名校验通过，但本机安装的 iCloud profile 未包含当前签名证书，因此受限权限签名链尚未验收；未公证、未发布。该本机签名限制不等于 CI 使用的签名材料失效。iPhone 由现有唯一安装任务等待全部共享页面定稿后构建并覆盖安装，保留已有数据；隔离验证包不用于替换设备上的合并版本。

真实 Apple ID 的 iPhone/Mac 双设备传输、系统存储不足、长时间后台传输及实体 UI 验收必须单独记录，模拟运输、SDK 类型检查和产品编译不能替代这些证据。macOS 签名 profile 必须实际授权 CloudDocuments 容器；仅编辑 entitlements 不证明授权已生效。
