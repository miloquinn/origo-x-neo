# 阅读文字与版式调节

## 悬浮阅读进度条

阅读设置的「主题」页签提供「悬浮阅读进度条」开关和「全书进度／当前章节」选择。默认开启并显示全书进度；偏好由 `ReaderSettingsStore` 的 `reader_progress_bar_enabled`、`reader_progress_bar_scope` 保存。本地和在线文字阅读共享这两个键。变更只更新控制栏，不重新分页或改动阅读位置；与页脚的章节信息样式分别保存。

`ReaderChromeOverlay.progressBar` 在底部控制栏上方留 12 点放置 `ReaderProgressPill`，随控制栏呼出和收起。两侧 44 点按钮跳上一章／下一章；开头、结尾和章节加载期间禁用对应操作。中间 36 点高的容器从左向右填充，显示范围与百分比；原生 `Slider` 保留拖动、键盘和辅助功能。拖动只预览，松手后一次跳转；拖动期间暂停自动翻页并取消控制栏的自动隐藏计时，跳转完成后恢复隐藏计时。

- `lib/core/reader/reader_progress_position.dart`：全书以 `(章节索引 + 本章比例) / 章节数` 计算，每章占相同权重；100% 跳最后一章末尾。无需为显示进度预加载其他章节。
- `lib/pages/reader/native/native_reader_progress.dart`：TXT 以来源章节身份合并内部 32K 存储段，按 `sourceBodyStart` 与末段原文 UTF-16 长度计算章内比例；只懒加载当前或目标逻辑章节的末段并缓存长度，不预读全书。EPUB 使用实际目录项和 fragment 锚点。分页跳转取目标页原文起点，再由现有双页恢复逻辑对齐；连续阅读按章节范围的 canonical 字符偏移恢复。正文仍沿用原来的存储段、书签和保存位置身份。
- `lib/pages/reader/book_source/book_source_reader_progress.dart`：分页与双页阅读复用当前实际页比例，连续阅读复用 canonical 正文比例；松手委托现有 `_loadChapter` 的定位及过期请求保护。
- `lib/pages/reader/native/native_reader_vertical_paging.dart`：连续阅读的通知值跟随 canonical 字符偏移，同一个长正文 part 内的滚动也能刷新胶囊。
- `lib/widgets/reader_progress_bar_setting_tile.dart`：常规尺寸用横向范围选择，窄屏或大字用纵向单选列表；沿用可滚动的阅读设置页。全部文案通过现有本地化生成链路提供。

外壳和内轨分别复用 `GlassSurface` 的 floating／control 材质；内轨不重复采样背景。进度填充属于内容，使用阅读主题强调色；玻璃、毛玻璃、全局关闭、Material 3、高对比和深浅色策略由公共材质解析。减少动态效果时不做填充动画。

回归入口为 `test/reader_progress_position_test.dart`、`reader_progress_pill_test.dart`、`reader_progress_bar_settings_test.dart`、`native_reader_progress_navigation_test.dart` 和 `book_source_reader_progress_navigation_test.dart`；原生组件预览入口为 `tool/preview_reader_progress_pill.dart`。PDF、漫画及在线纯图片正文沿用原有页导航，不显示这条文字阅读胶囊；EPUB 纯图片正文也保持原有控制。已有 iCloud 阅读偏好白名单暂未包含新键，当前开关与范围在本机持久化。

2026-10-10 的 iOS 组件预览：[液态玻璃浅色](previews/reader-progress-20261010/liquid-light.png)、[液态玻璃深色](previews/reader-progress-20261010/liquid-dark.png)、[毛玻璃](previews/reader-progress-20261010/frosted-light.png)、[实底](previews/reader-progress-20261010/solid-light.png)、[窄屏大字](previews/reader-progress-20261010/liquid-chapter-large.png)。[渲染环境](previews/reader-progress-20261010/render-context.json)记录 iOS shader 支持；生产组件预览使用独立包名，不加载用户书籍，物理设备阅读验收单独记录。

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
