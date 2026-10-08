# 探元页面简化验收

- 移除探元购买页大插画；体验状态与到期时间合为单条轻量状态栏，日期使用本地紧凑格式，保留完整年份、月份、日期及分钟精度，并遵循设备的 12／24 小时时间设置。
- 三项权益图标与文字对齐，去掉外框，只保留两条轻分隔线；权益标题和说明允许大字号换行，账号名称靠右对齐。
- 底部购买按钮与恢复／兑换同行、右上角说明菜单继续复用当前实现；购买、权限和价格选择逻辑未改动。

## 本轮文件

- `lib/pages/account/premium_membership_page.dart`
- `test/premium_membership_page_test.dart`
- `test/store_reader_unlock_page_test.dart`（主题验证改为读取探元正文，不再依赖已移除的插画，全部色彩与明暗断言保留）
- `DESIGN.md`
- `docs/plans/2026-10-05-explore-page-simplification.md`
- 本文与 `docs/previews/purchase-layout-20261005/` 的十一张真实 Flutter 截图。

## 验证

- 新增集中体验状态回归先在修改前复现失败，然后实现后通过。
- `premium_membership_page_test.dart` 独立进程：49 项通过，启用真实截图导出。覆盖 390×844 的体验态深浅色与正常购买态，320×700、1.5 倍字号中文／德文体验态，12／24 小时时间偏好，以及永久会员深浅色与平板。
- `store_reader_unlock_page_test.dart` 独立进程：18 项通过；一个原有可选截图导出入口未启用。插画移除导致主题测试找不到旧元素，已单独复现并更新查找目标，未删除任何主题断言。
- 三个 Dart 文件格式检查通过；针对三个文件的 `flutter analyze --no-pub` 无问题；`git diff --check` 通过。
- 人工检查体验态、永久态、深浅色及窄屏大字号截图：常规手机全部权益位于固定底栏上方，无裁切；大字号状态自然换行，购买与兑换可滚动抵达；恢复／兑换保持同行。
- 视觉迭代证据存于 `.omx/state/explore-purchase-ui/ralph-progress.json`。当前环境没有可调用的 visual-verdict skill，使用实际 Flutter 截图人工检查记录。

- 独立审查发现强制 24 小时格式会忽略设备偏好，已改为读取 MediaQuery 时间偏好；浅色／深色两种时间格式及窄屏回归重新通过。其余 scoped diff 未发现可操作问题。

## 交付边界

本地代码与渲染验证完成；未打包、提交、推送或更新 App Store，未在用户实际 iPhone 上复测。既有未提交的阅读器、书源和购买服务工作保留。
