# 阅读文字与版式调节

阅读二级菜单的调节条由 `lib/widgets/glass_adjustment_slider.dart` 的 `GlassAdjustmentSlider` 统一提供。`lib/widgets/reader_settings_controls.dart` 的 `ReaderSettingSlider` 保留阅读设置入口，`ReaderFontWeightControl` 在同一个组件中提供字体预览与说明；本地文件和在线书源沿用各自既有的保存、重排与正文位置恢复链路。

## 材质与交互

- 轨道外壳和两端圆形按钮使用共用 control 材质，数值胶囊使用 selection 材质；全部经 `GlassControlSurface` → `GlassSurface` → `GlassMaterial`。遵循毛玻璃、液态玻璃、Material 3、全局关闭和高对比度策略，颜色来自当前阅读主题。数值胶囊不另采样背景，组件不复制模糊、透明度或高光配方。
- 保留原生 `Slider` 的拖动、键盘和辅助功能操作；滑块半径增至 12，拖动区域至少 48 高。左右按钮各 48×48，间隔 8，左减右加；边界禁用相应按钮，辅助功能标签通过现有本地化体系提供。
- 拖动经 `onChanged` 预览，松手经 `onChangeEnd` 提交；按钮按 `(max - min) / divisions` 步进，依次预览一次、提交一次。避免拖动过程反复触发持久化和重排。
- 打开面板不将旧小数值量化到刻度，包括默认行高 1.75。按钮从实际值增减一个步幅，移除浮点累积误差并夹紧边界；直接拖动使用原生离散刻度。
- 标题与数值允许在大字模式下换行。按压使用现有 `GlassIconButton` / `ElasticPress`，遵循减少动态效果设置。

## 共享范围

| 设置 | 范围 | 步幅 |
| --- | --- | --- |
| 字号 | 12–72 | 1 |
| 文字亮度 | 0–100 | 1 |
| 字重 | 300–700 | 100 |
| 行高 | 1.2–4 | 0.1 |
| 字距 | 0–6 | 0.1 |
| 首行缩进 | 0–4 字格 | 1 |
| 段间距 | 0–4 额外空行 | 1 |
| 左右边距 | 0–96 | 1 |
| 上、下边距 | 各 0–120 | 1 |

范围由 `lib/core/reader/reader_settings.dart` 和 `reader_margin_settings.dart` 所有。`copyWith`、存储恢复、`native_reader_configuration.dart`、`book_source_reader_settings.dart` 以及最终 `ReaderTextLayout.build` 共同引用这些约束。偏好键、默认值、旧亮度与边距迁移不变；字重仍遵循字体自身的可变轴能力。修改范围时同时检查 UI divisions 和辅助功能数值格式。

## 验证入口与边界

- `test/glass_adjustment_slider_test.dart`：按钮步进及边界、旧小数值、拖动提交、键盘、语义数值、320/375/720 宽、3.2 倍大字、减少动态效果、玻璃与实底策略。
- `test/reader_settings_controls_test.dart`、`reader_margin_controls_test.dart`：二级菜单的字体预览、独立边距、切页与共享控件接入。
- `test/reader_settings_test.dart`、`reader_margin_settings_test.dart`、`reader_text_layout_mapping_test.dart`：新上限保存恢复、旧默认值、段间距投影与源偏移映射。
- `test/native_reader_settings_wiring_test.dart`、`native_text_paginator_test.dart`、`book_source_text_paginator_test.dart`、`reader_justified_indent_test.dart`：实际读取/保存、共享分页与缩进测量。
- `tool/preview_reader_adjustment_slider.dart`：使用生产控件的真实 iOS 模拟器组件预览，包含毛玻璃/液态玻璃深浅色、实底、大字窄屏、横屏。纯 widget 测试不能证明液态 shader；预览记录 shader 支持状态。

2026-10-10 的组件预览：[毛玻璃浅色](previews/reader-adjustments-20261010/frosted-light.png)、[毛玻璃深色](previews/reader-adjustments-20261010/frosted-dark.png)、[液态玻璃浅色](previews/reader-adjustments-20261010/liquid-light.png)、[液态玻璃深色](previews/reader-adjustments-20261010/liquid-dark.png)、[实底](previews/reader-adjustments-20261010/solid-light.png)、[窄屏大字](previews/reader-adjustments-20261010/liquid-large-text.png)、[横屏](previews/reader-adjustments-20261010/liquid-landscape.png)。[渲染环境](previews/reader-adjustments-20261010/render-context.json)记录 iOS shader 支持；截图使用生产组件，不能代替物理阅读菜单验收。

有状态 widget 套件独立进程执行；Flutter 命令顺序运行，避免同时写同一 native-assets 构建目录。缩进和段间距只改变显示投影，不改变原始正文、书签或批注源偏移。很大的字号、行高和边距组合会减少每页内容；极窄窗口及长内嵌章节标题仍沿用现有正文容器限制，不能从正文完整性测试推断所有极端组合的物理可读性。额外空行跨页时可折叠，原始位置映射保持完整。

模拟器组件预览、签名构建、原地安装/启动与用户的物理阅读 UI 验收分别记录；本轮证据见[2026-10-10 验证记录](reviews/2026-10-10-reader-adjustment-slider.md)。当前共用材质约定见[共用玻璃材质](glass-material.md)。
