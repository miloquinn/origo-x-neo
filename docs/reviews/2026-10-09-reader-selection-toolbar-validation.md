# 2026-10-09 阅读选中文字工具栏验收

本文记录本次本地验证与设备交付边界。当前维护入口见 [选中文字工具栏](../reader-selection-toolbar.md)。

## 改动

- 抽出专属 `ReaderSelectionToolbar`，删除正文页内嵌的胶囊按钮与通用弹出菜单。主栏为「复制｜高亮｜笔记｜⋯」，按钮只用文字和分隔线。
- 根据用户预览反馈，把初版 14px 矩形改为悬浮导航同款 `RoundedSuperellipseBorder`；收起状态圆角为外壳高度的一半，展开保留同一柔和轮廓。共享材质边框计入宽度，三条分隔线完整显示，普通宽度不产生横向滚动。
- 一层背景适配毛玻璃、液态、不透明度、关闭玻璃及高对比。更多展开搜索、净化与问 AI，删除原来无回调的占位操作；空间不足时主操作从末尾收入更多。
- 选区快照、正文映射、保存和服务回调保持原所有权。增加更多展开语义与收起提示，不引入依赖或平台桥接。

## 验证

- 原始 `reader_annotated_text_page_test.dart` 在修改前独立运行，14 项通过。
- 最终专属工具栏回归 15 项通过：顺序、回调、禁用语义、更多显隐/展开语义、单层材质、玻璃/实色/高对比、320px 大字、英文/RTL、边缘锚点、320×180 安全区与滚动可达性、分隔线完整显示。
- 正文选区回归 14 项通过：长按、高亮保存、搜索/净化/AI 选区交接以及旧正文映射与批注行为。有状态 widget 文件分别运行，未混跑；一次原生测试资产签名竞争在单独 `--no-pub` 重跑后通过，不记为产品失败。
- 六个修改的 Dart 入口局部分析无问题，格式与 diff 检查通过。当前指南链接与源码/测试/预览路径已核对。
- 独立快照的 iOS 模拟器 Debug 产品构建成功（iPhone 18 Pro Max / iOS 27.0），以 Impeller 运行，运行时读回 `ImageFilter.isShaderFilterSupported=true`。七张实际 Flutter 组件截图见 [预览目录](../previews/reader-selection-toolbar-20261009/)：毛玻璃、液态深浅色、更多展开、320px 大字、英文大字与关闭玻璃。最终视觉判定通过；截图正文和选中底色是明确标记的组件预览，不是物理设备上的真实选区。

日志、源码 SHA-256 与视觉判定保存在忽略目录 `build/validation/reader-selection-toolbar/` 和 `.omx/state/reader-selection-toolbar/ralph-progress.json`。

## 设备与同步边界

本聊天已在共享 `build/device-ios/coordination.json` 将 `readerSelectionToolbar` 登记为 `ready` / `sourceFinalized`。常亮修复聊天是 SloanePro 的既有统一安装负责人，等待其余阅读导航改动最终化后，从共享最新 checkout 重建、保留数据覆盖安装；本聊天不以独立模拟器快照替换手机包。实际安装/启动以该负责人的合并构建收据为准，物理选区 UI 验收仍未获得证据。TestFlight/App Store 发布不属于本轮交付。

当前主机为 `sloane.local`。Windows `192.168.1.10:22` 本次连接超时，尚未同步；未改动远端工作树。其他聊天的阅读导航、常亮文档、发布元数据与四张用户活动中心 JPEG 保持原状。
