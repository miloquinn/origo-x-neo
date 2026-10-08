# 设置页性能优化验证

日期：2026-10-08。范围：设置首页、四个分类、账户卡片，以及账户到全局设置的通知边界。

## 已确认原因与改动

| 原因 | 改动 | 自动测量结果 |
| --- | --- | --- |
| 整页监听完整主题、全局设置和备份控制器 | 按分类选择不可变展示值，备份状态只更新对应行 | 五个页面中，每类 30 次无关通知的列表更新均从 30 次降至 0 次 |
| 普通账户事件被转发成全局设置广播 | 只有高级功能权限变化时广播；账户卡只选择展示字段 | 30 次普通事件：账户内容更新/全局广播从 30/30 降至 0/0 |
| 偏好与 AI 配置串行混合加载 | 每个分类只加载其拥有的数据 | 偏好页 AI 读取 1→0；内容服务页偏好读取 1→0 |
| 偏好未就绪时可写入默认值 | 页面拥有的开关和阅读顶栏样式等待偏好加载 | 加载期间实际点击不会保存；加载后正确显示已有值 |
| 分类列表的全部区域属于一个巨大列表项 | 用 WidgetBuilder 与 ListView.separated 按区域构建 | 最后“通用”区域初始挂载 1→0；滚动后正常可达 |
| 毛玻璃开关重复保存整份页面偏好 | 只由 ThemeNotifier 保存该开关 | 页面偏好保存次数 1→0 |
| 8 个页面字段只为加载/转存而存在 | 隐藏字段保留在一个不可变偏好快照中 | 切换可见设置后，封面、间隔、开发者等已有值仍保留 |

测量在 Flutter widget 测试中进行，每次通知后独立 pump，共 30 次。
统计的是实际 widget identity 更新与服务调用次数，不是 FPS、毫秒或 GPU 加速幅度。
默认 evaluator 始终执行优化后的断言；SETTINGS_PERF_BASELINE 模式用于输出历史实现的工作量。

## 改动文件

- `lib/pages/settings/settings_page.dart`：分类加载、就绪保护、隐藏偏好快照、删除重复字段和无用备份辅助方法。
- `lib/pages/settings/parts/settings_hub_part.dart`：局部备份状态选择、分类所需值选择、按区域延迟构建。
- `lib/pages/settings/parts/settings_layout_part.dart`：备份忙碌图标局部选择、阅读顶栏样式就绪保护。
- `lib/pages/settings/parts/settings_appearance_part.dart`：消除毛玻璃重复保存和重复字体数量投影。
- `lib/pages/settings/parts/settings_about_part.dart`：操作行支持就绪期间禁用。
- `lib/services/core/app_settings_service.dart`：账户通知只在有效高级权限变化时转发。
- `lib/widgets/settings_account_card.dart`：不可变展示字段投影，保留账户/会员跳转。
- `test/settings_performance_test.dart`：工作量 evaluator、分类 IO、同步状态、权益与加载/保存回归。
- `test/app_settings_library_layout_test.dart`：30 次普通账户通知和授予/撤销的通知及全局策略断言。
- `docs/plans/2026-10-08-settings-performance.md`：清理计划、兼容边界、验收合同和架构/审查记录。

未增加依赖。保留现有 Provider、偏好保存接口、存储键、语言、路由与毛玻璃实现。
版本平台读取失败、默认阅读配色和旧偏好迁移作为已有兼容/显示保护保留；没有添加静默吞错分支。
字体服务缓存、首页壳层重构和 shader 改写未纳入此次范围。

## 验证结果

所有有状态测试均以独立 Flutter 进程执行。以下合计 92 项通过：

| 测试文件 | 通过数 |
| --- | ---: |
| settings_performance_test.dart | 14 |
| settings_page_test.dart | 19 |
| settings_page_preferences_test.dart | 3 |
| settings_premium_access_test.dart | 2 |
| tablet_home_settings_layout_test.dart | 2 |
| settings_navigation_and_layout_pages_test.dart | 2 |
| app_settings_navigation_labels_test.dart | 7 |
| app_settings_library_layout_test.dart | 12 |
| account_page_test.dart | 31 |

```sh
flutter test --no-pub test/settings_performance_test.dart --reporter expanded
```

范围内 Flutter 静态检查：No issues found。格式、范围内 diff 空白检查通过。
架构审查与最终代码审查均 APPROVE。

全仓 `flutter analyze --no-pub` 仍报告三条既有 info，相关文件没有本次差异：
`source_chapter_state.dart:313` 的花括号提示，`source_cookie_utils.dart:32` 的
rethrow 提示，`offline_reader_license_refresh_test.dart:9` 的重复导入提示。
全仓检查因此退出 1，不能记作全仓静态检查完全通过。

一次导航测试启动遇到临时 native-assets 文件缺失；同一测试独立重跑 7 项通过，
没有为测试工具问题修改应用逻辑。已有字体存储 fixture 的平台插件缺失日志不代表真机行为。

## 验证边界

未构建、安装或发布新版本。当前可见的 Android 设备为 PKT110，未连接此前的
OPD2404 平板；没有对报告掉帧的设备进行 profile、手势或最终视觉验收。
玻璃滤镜、阴影和会员卡入场动画的 raster 耗时仍需在报告设备上测量。
本次确认减少的是重复构建、配置读取和保存，不能据此宣称所有设备已经完全无掉帧。

后续添加新展示字段时同步更新其选择投影，并运行此 evaluator 和相应功能回归。
