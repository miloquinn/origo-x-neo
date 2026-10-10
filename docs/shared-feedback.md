# 统一瞬时提示

全应用瞬时反馈只通过 `lib/widgets/side_toast.dart` 的 `showSideToast` 显示；不要直接调用 `SnackBar` / `ScaffoldMessenger.showSnackBar`。AI 推荐评价、书籍打开失败、活动详情、排行榜和主题应用/市场已接入同一入口。页面持久错误与需要确认的对话框仍由各自页面管理。

## 外观与交互

手机提示位于顶部安全区下方 8 点，水平居中，两侧至少 16 点；桌面右上角留 24 点。短消息按内容收窄，最大宽度 440 点。单一 20 点圆角面板、28 点状态标识和 14 点正文；成功、提醒、错误同时使用图标与语义颜色。长文完整换行，极端高度下可滚动。窄屏或大字号的操作按钮移至正文下方，命中高度至少 44 点。

背景只消费 `GlassSurfaceRole.floating`，无玻璃、毛玻璃、液态玻璃、高对比和性能降级均由 `GlassMaterial` / `GlassSurface` 解析；不在提示中另建模糊、透明度或阴影配方。提示加入根 Overlay 前捕获调用位置的继承主题，保留阅读页局部配色。玻璃可见度在公共材质内部变化，只有前景淡入淡出。顶部短距离滑入遵循减少动态效果。

默认时长随消息长度增加，最长 8 秒；带操作至少 5 秒，可传明确 duration。屏幕阅读辅助导航开启且带操作时不自动消失。提示提供 liveRegion 和语义关闭动作，左右滑动关闭；浮层不拦截卡片以外的操作。

同一时间只显示最新提示，不积压队列。`hideSideToast()` 立即移除当前提示及过期操作。删除闭包幂等，已关闭旧条的异步回调不能移除新条；操作执行一次后关闭，可在操作内显示下一条提示。全局入口保持原名称以兼容所有已有消费者。

## 回归与边界

- `test/side_toast_test.dart`：替换/退出竞态、自动关闭、滑动、操作、非遮罩命中、安全区、内容宽度、三个材质、高对比、局部主题、窄屏大字号、辅助导航及减少动态效果。
- `test/shared_feedback_entrypoints_test.dart`：扫描生产 Dart 源码，阻止重新引入直接 SnackBar 入口。
- `test/glass_material_consumers_test.dart`：前景淡出与液态背景分离。
- `test/app_theme_page_test.dart`、`test/theme_market_page_test.dart`、`test/reading_agent_page_test.dart`、`test/activity_center_test.dart`、`test/leaderboard_page_test.dart`、`test/tablet_ai_layout_test.dart`：迁移后的页面行为分别进程验证。
- `tool/preview_side_toast.dart`：生产根浮层实际 Flutter 渲染，三种材质的明暗模式、320 点大字带操作及长错误文案。

继承主题在显示时捕获；已显示的短暂提示不会订阅调用页后续主题变化，下一条读取最新主题。原生截图、安装启动与用户真实推荐反馈体验是分别验证的信号，不能互相替代。

## 2026-10-10 验证状态

82 项独立回归、最终静态分析和直接 AI 点踩路径通过；六个产品文件与提交 `ed482f40` 的 SHA-256 一致。iOS 原生预览构建通过，首次八组实际采样确认 `shaderFilterSupported=true`；macOS 八组同时覆盖实色、毛玻璃及液态公共降级。有效的首个独立主题截图见 [无玻璃反馈预览](previews/shared-feedback-20261010/solid-light.png)。

连续场景的默认文字样式受前一个主题影响，预览已改为每个场景创建独立 MaterialApp、取消主题插值并提前关闭旧提示，修正后的原生编译通过。补录被当前 CoreSimulator 服务调用卡住，因此其余初次截图只保留在忽略的 `build/unified-feedback/ios-initial-captures/`，不作为全页主题验收。收据为 `build/unified-feedback/validation.json`。SloanePro 已核对为 iPhone 16 Pro，统一安装负责人已接收冻结源码；共享 iCloud、段评等改动尚未定稿，当前没有新合并包的安装或物理 UI 验收证据。
