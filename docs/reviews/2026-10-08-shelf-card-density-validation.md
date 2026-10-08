# 分组卡片与网格密度验收

本轮已将独立目录验证的改动按所有权合回共享主目录，没有复制整份旧快照。

## 行为与清理

- 手机分组卡片展示名称、总书数和横向封面，最多九张预览，更多数量放在末尾；单本显示书名和作者，空目录显示空态。滑动不打开目录，点击、长按和选择模式保留原行为，返回保留预览位置。
- 文件夹从完整卡片展开并反向收回。导航前半段、返回按钮动画、搜索框和清空防抖逻辑未改。
- 列数偏好扩为2–5，实际按净宽/字号降密度：390dp普通字号5列，320dp4列；有元数据的2倍字号进一步降低，3倍字号在390/320均2列。宽屏最多8列，偏好不会被自动覆盖。
- 文件夹文字始终预留实测高度，书封保持2:3，文字测量资源在finally释放。纯书籍且关闭详情不预留额外空白。
- 删除旧ListTile空白布局、重复列数计算及各语言废弃的两列/三列文案。复用封面、目录投影、主题和设置持久化，没有新依赖或数据/备份改动。

## 文件范围

- `lib/pages/library/parts/library_folders_part.dart`：卡片内容、横向预览和完整卡片锚点。
- `lib/pages/library/parts/library_collection_part.dart`：网格净宽、可见元数据高度、固定书封比例。
- `lib/utils/layout_helper.dart`：统一密度策略。
- `lib/services/core/app_settings_service.dart`：2–5列偏好读取、保存与非法值恢复。
- `lib/pages/settings/library_layout_settings_page.dart`：可换行的2–5列选项与自动降密度说明。
- `lib/l10n/app_*.arb`、`app_localizations*.dart`：新文案、旧列数标签删除及从当前共享ARB重新生成；法律文案和接口保留。
- `test/app_settings_library_layout_test.dart`、`library_shelf_folders_test.dart`、`library_shelf_responsive_test.dart`：保留老偏好与已有行为断言，补全新场景。
- `test/library_shelf_card_test.dart`、`library_grid_density_test.dart`：新布局及真实组合回归。
- `.github/workflows/pr-checks.yml`：新增测试独立进程入口。
- `DESIGN.md`、`docs/plans/2026-10-08-nested-bookshelves.md`、本验收记录与预览目录。

逐文件的合并清单和原始快照在`build/validation/shelf-card-density-20261008/merge-record.json`及`before-merge/`。

## 验证

| 独立进程 | 通过 |
| --- | --- |
| app_settings_library_layout_test | 12 |
| library_grid_density_test | 4 |
| library_shelf_folders_test | 9 |
| library_shelf_card_test | 4 |
| library_shelf_motion_test | 8 |
| library_shelf_responsive_test | 1 |
| library_page_test | 7 |
| settings_navigation_and_layout_pages_test | 2 |
| book_open_transition_test | 27 |
| library_grid_details_test | 2 |
| settings_page_test（法律负责人修复测试资产读取） | 20 |

相关回归76项，加完整设置页20项，共96项/11个独立进程。范围Dart静态分析没有问题，`git diff --check`通过。合并只读复核没有新增实质发现，五个产品文件与隔离源一致，全部既有法律键保留，搜索与防抖哈希一致。

14个真实Flutter场景/54张PNG覆盖明暗、空目录/单本、窄屏大字号、4/5列、嵌套及展开/返回中间帧。第一次视觉复核发现3倍字号纯封面被单元拉长，回归测得高宽比2.506；已修复并重渲染为1.500。详见[预览索引](../previews/shelf-card-density-20261008/README.md)。

范围之外的验证边界：

- 完整SettingsPage中的欢迎页回放起初在单独进程也超时；法律模块负责人已修复测试资产读取/假时钟依赖：先挂载按需创建的最后一页，再完成真实异步资产读取。单测1项、完整设置页20项与范围分析通过；所有同意存储、Done和退出断言保留，产品代码未改。
- 模块验收时发现阅读器独立进程manifest的动态测试标题缺口；最终统一收尾已补齐并通过完整性校验。本轮新增两个测试均已纳入CI。
- 既有共享顶栏在3倍字号下会截断标题，未扩大本轮布局范围。
- 合成数据渲染不证明实体帧率、实际书库数据或手感。

## 交付

统一负责人已完成正常`lib/main.dart`、开发签名Release `2.7.3+261008005`构建及严格签名验证。包内版本、更新日志和法律内容已核对；全量748个源文件构建前后相同，SHA-256为`2bf6bd9ca397c8c56fa58f56c41cddb73771890afc6f2a0a4f363f64de534794`。

原位安装已实际尝试，因SloanePro通信不可用而返回CoreDeviceError 4016，尚未安装、启动或完成实体操作验收，设备数据未清除。`build/device-ios/latest-unified.json`指向最新005签名包；004仅为历史。连接请求由唯一装机负责人持有，恢复后核对设备版本、覆盖安装最新包并验证启动。

签名包与构建/源码/安装收据在`build/device-ios/shelf-card-density-20261008/`。

详细测试、合并备份、源码与渲染指纹位于`build/validation/shelf-card-density-20261008/`。

隔离工作树已可恢复归档，忽略目录内的日志和基线已先保存到共享验证目录。

最终统一收尾已补齐 CI 隔离清单并统一四处 Dart 格式，从正常入口重新签名同一 005 构建号。上述构建收据保留为格式调整前的历史证据；最新源码与包见[统一收尾记录](2026-10-08-unified-ios-delivery.md)。用户明确手机不在，安装延期至回来通知后。
