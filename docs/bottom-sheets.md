# 共用底部菜单

底部菜单通过 `lib/widgets/glass_bottom_sheet.dart` 的 `showGlassBottomSheet<T>` 打开。阅读设置、目录、字体、朗读、AI、应用外观、书库、书源及账户菜单共用同一个外壳；业务组件继续管理内容、滚动与返回值。

## 外壳与交互

- `GlassBottomSheetSurface` 提供四边 8 点外间距和一个 44 点高的顶部拖动区域。手机（窗口短边小于 600 点）占满可用宽度，横屏也保留屏幕左右各 8 点；平板和宽屏使用居中的最大 640 点面板。背景委托 `GlassSurface(role: panel)`，遵循[共用玻璃材质](glass-material.md)的液态、毛玻璃、实底与高对比策略。
- 背景、反光、阴影和 Material 裁切共用 `RoundedSuperellipseBorder` 连续圆角。平台没有上报屏幕 R 角时，手机使用 40 点、独立宽屏面板使用 32 点的视觉半径；这些是设计值，不是按安全区推测的硬件参数。手机平台上报有效 `MediaQueryData.displayCornerRadii` 时，取最小有效半径减去外边距，形成统一的同心内缩曲线。当前液态着色器只接收一个半径，因此不引入不一致的逐角折射参数。
- 原生 `ModalBottomSheetRoute` 负责下拉关闭、取消拖动后复位、遮罩、返回、焦点及泛型返回值。原生路由背景透明、阴影为零、不再画另一根拖动横条。共享横条始终位于内容滚动区域外；允许关闭时也可以点按横条关闭，并提供系统本地化语义。
- 打开使用 300 毫秒缓出、关闭使用 220 毫秒缓入动画；减少动态效果时取消路由动画。不要给整个玻璃背景套 `Opacity` 或 `FadeTransition`。
- 前景放在透明、按同一圆角裁切的 `Material` 内，保持 ListTile、Radio 等组件的 Ink 祖先与圆角边缘。实底模式只切换材质，不改变几何和命中区域。
- 内部继承作用域避免迁移后的内容外壳再次画玻璃或横条。嵌套的 `GlassBottomSheetSurface` 只返回内容；独立展示时仍能提供完整背景、Material 和横条。

## 消费者约定

阅读目录、书签和笔记的紧凑标签、按需搜索及定位合同见[阅读导航菜单](reader-navigation.md)。

`builder` 保留内容布局。共享外壳不强制所有菜单为屏幕的一半，不替换 ScrollController，也不增加键盘 inset。`backgroundColor` 表示共享背景的语义底色；透明色按主题底色解析，不能把玻璃背景一并关掉。

阅读入口应给外层路由传 `theme: palette.toThemeData(parentTheme: ...)` 及阅读背景色，保留应用的外观扩展。只在内容里套 Theme 不足以改变外层玻璃与横条的颜色。

可以在打开期间切换配色的本地、书源及漫画阅读设置使用 `builderOwnsSurface: true`，由内容里的 `ReaderSettingsSheetFrame` 持有唯一共享背景。这样实时配色变化会同时更新玻璃、文字和横条。此模式的 builder 必须提供 `GlassBottomSheetSurface`；路由继续管理动画、关闭规则和安全区，并向内容传递横条是否可见。静态菜单使用默认路由外壳。

默认 `useSafeArea: true` 时，系统避让与面板外部留白分开处理：左右和底部的玻璃边缘始终距手机屏幕 8 点；内容内侧补 `max(0, 当前 padding - 对应外边距)`。例如 iOS 底部安全区 34 点时，面板外留 8 点，内部保护 26 点，Home Indicator 不会挤出一条额外的外部空隙。内部消耗左右和底部的 MediaQuery padding，旧内容的 SafeArea 不会重复避让。

原生路由自身 `useSafeArea` 关闭，共享路由按 Navigator 上方的当前顶部 inset 限制最大高度，保留接近全屏时的状态栏/灵动岛保护，又不在普通半屏菜单上方加一块隐形留白。使用当前 `padding` 而非固定 `viewPadding` 计算内部底部保护，因此键盘出现不会重复增加 Home Indicator 空白；键盘 `viewInsets` 仍由业务内容管理。显式 `useSafeArea: false` 完全交给消费者；导入菜单保留清理异常安全区与过期键盘 inset 的已有逻辑。

iOS 不向 Flutter 提供物理屏幕圆角半径，连续曲线是视觉适配，不能声称与每款 iPhone 的硬件 R 数值完全相等。公开 `displayCornerRadii` 当前只在 Android 31+ 提供；见 [Flutter API](https://api.flutter.dev/flutter/widgets/MediaQueryData/displayCornerRadii.html)。宽屏的居中面板以及调用方自定宽度约束会产生更大的左右留白，不将它们误报为手机的 8 点外边距。

阅读设置保留 50% 高度，目录、字体和漫画目录保留 86% 上限，搜索保留 90% 上限；内容高度计算扣除 `GlassBottomSheetSurface.dragHandleExtent`，把共享横条计入总高度。AI、朗读及定时器保留各自上限。可拖动的导入与调试菜单继续使用自己的 `DraggableScrollableSheet` 及配套控制器。

书源导入事务保留 `enableDrag: false`、`isDismissible: false`、`showDragHandle: false`，只由显式关闭和提交操作结束。不要为了统一外观改变事务关闭规则。

## 验证入口

- `test/glass_bottom_sheet_test.dart`：各材质、单一背景和横条、真实拖动及中止、返回与泛型结果、横条点按、iOS/Android/无安全区的等宽外间距、横屏内部刘海避让、实时 inset/键盘、连续圆角与系统上报半径、宽屏上限、滚动、减少动态效果、不可关闭事务、独立 Material。
- `test/reader_settings_controls_test.dart`、`reader_navigation_sheet_test.dart`、`font_selection_sheet_test.dart`、`comic_reader_page_test.dart`、`reader_aloud_panel_test.dart`：阅读内容行为、主题、控制器与拖动关闭。
- `test/app_text_scale_test.dart`、`import_book_page_test.dart`、`book_source_add_flow_test.dart`、`book_source_management_organization_test.dart`、`replace_rules_page_test.dart`：大字、特殊安全区、导入事务及编辑交互。
- `tool/preview_shared_glass_sheets.dart`：真实 iOS 渲染器上的共享路由、生产阅读调节控件与标题/控制栏。设置 `--dart-define=ORIGO_SHEET_GEOMETRY_PREVIEW=true` 可以单独捕获间距/圆角场景和实际面板边界；其中 Android 数据场景是 iOS 渲染器上的显式 MediaQuery 模拟，不能当作 Android 真机证据。模拟器预览及安装启动均不能代替用户的物理视觉和手感验收。

当前几何验证见[2026-10-10 底部菜单间距与连续圆角](reviews/2026-10-10-sheet-geometry.md)；第一批材质与阅读栏交付记录见[共享底部菜单与阅读栏验证](reviews/2026-10-10-glass-sheets-reader-chrome.md)。
