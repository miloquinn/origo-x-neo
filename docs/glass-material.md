# 共用玻璃材质

所有普通玻璃背景由 `lib/widgets/glass_surface.dart` 的 `GlassSurface` 绘制，样式由 `lib/utils/glass_material.dart` 的 `GlassMaterial` 统一解析。组件只提供外形、布局、交互和主题配色意图；不在组件里调透明度、模糊、白色混合、描边或阴影。

## 更新入口

- 底色渐变、透明度、描边、阴影、液态高光与可读性密度：修改 `GlassMaterial`。
- 用户偏好、总开关和性能状态：`GlassEffectConfig` 仅保存状态与 `blurScale`，沿用 `UiStyleThemeExtension` 和已有设置服务，不新增存储或依赖。模糊基数、密度、染色及折射值全部属于 `GlassMaterial`。
- 背景合成、裁切与普通毛玻璃滤镜：修改 `GlassSurface`。
- 液态采样、shader 加载和变换坐标：`LiquidGlassSurface` 是能力渲染器，接收已解析材质，不自行读取主题决定外观。shader 不支持或加载失败时保留轻模糊，失败有日志。

一个材质角色描述视觉用途，不对应某个组件：`control` 为轻量控件，`floating` 为悬浮 chrome，`panel` 为较长内容的面板，`selection` 为选中指示。角色配方仍集中在同一解析层；不得为每个页面再建立一份数字参数。

液态玻璃的边缘光照同样由 `GlassMaterial` 解析。反光颜色靠近当前底色，背光侧使用语义轮廓色与前景色；深色下收敛反光，浅色下保留柔和的暗侧轮廓。方向性渐变沿原有边缘绘制，不增加第二层均匀描边。阅读配色、亮暗覆盖与内部可见度共同生效；染色透明度、毛玻璃配方、shader 折射及降级规则保持独立。

皮肤图片的所有权和切换契约见[应用素材皮肤](app-skins.md)。导航装饰在现有玻璃下面绘制，只裁切装饰图片；皮肤不修改本文件的材质配方、全局偏好或阅读配色。

## 组件边界

| 消费方 | 组件负责 | 背景负责 |
| --- | --- | --- |
| 阅读悬浮进度胶囊 | 原生进度拖动、范围显示、章节切换与液体填充内容 | floating 外壳与 control 内轨；内轨不重复过滤，见[阅读调节控件](reader-adjustments.md) |
| 悬浮导航、阅读控制栏 | 尺寸、圆角、弹性、图标与操作 | 共用 floating 材质 |
| 选中文字工具栏 | 超椭圆、分隔线、复制/高亮/笔记/更多、空间限位 | 共用 floating 材质，阅读器配色 |
| 按钮、搜索框、AI 输入框 | 命中、输入、焦点、禁用、布局 | control 或 floating 材质 |
| 圆角下拉选择 | `PillDropdown` 的锚点、选中项、键盘、焦点和关闭；复用共享锚定菜单 | 输入外壳 control，静止弹层为单一 panel；玻璃与实色策略由公共层解析 |
| 阅读文字与版式调节条 | 原生拖动、加减步进、提交边界、语义与字体预览 | control 轨道/按钮、selection 数值胶囊；见[阅读调节控件](reader-adjustments.md) |
| 共用底部菜单 | 原生弹层路由、圆角、拖动横条、安全区与内容裁切 | 单一 panel 材质；见[底部菜单](bottom-sheets.md) |
| 选中透镜、书源分区指示 | 位置、外形、选择动画 | selection 材质；已过滤父层内不重复采样 |
| 横向分类栏 | `AppFilterBar` 的选项、滚动、自然高度与选中语义 | 整栏 control 单次采样；选中胶囊 selection 不重复过滤，见[书源管理布局](source-management-ui.md) |
| 侧栏、导入按钮、书籍操作和提示条 | 页面行为、尺寸、内容与动作 | 共用材质角色 |
| 设置内容面板 | `SettingsPanel` 的圆角与内边距，`SettingsInfoRow` 的文字与皮肤语义图标 | panel 材质统一适配实色、毛玻璃与液态玻璃；面板内按钮不重复采样 |
| 设置预览 | 预览状态 | 直接复用生产导航组件 |

`GlassSurface` 不增加内容内边距，背景在独立图层绘制，阴影在裁切之外。形状裁切、内容留白及按钮 ripple 由专属组件管理。`GlassControlSurface` 仅是控件布局适配入口，明确保留原一像素留白并委托公共背景。消费者统一传语义 `outlineColor`，没有只读取颜色却接收宽度/样式的旧 `BorderSide` 接口；描边透明度与宽度由材质解析。

首页底置导航的位置由 `lib/pages/home/home_mobile_chrome.dart` 的 `HomeMobileChromeMetrics` 统一计算，`home_shell_layout_part.dart` 消费同一份指标。带 Home Indicator 的 iOS 设备（底部 `viewPadding` 至少 20 点）保留完整系统安全区，只将区外间距设为 2 点，比原位置下移 8 点；Android 和无 Home Indicator 的 iPhone 仍留 10 点。内容底部留白、书库多选操作栏及悬浮按钮随同一指标避让；平板顶置导航位置不受底部间距影响。键盘隐藏导航和阅读返回安全区稳定策略保持原有契约。回归入口为 `test/home_mobile_chrome_metrics_test.dart` 与 `test/home_shell_system_bar_test.dart`；实际触感与视觉位置仍需真机验收。

阅读器传自己的背景、描边、阴影与亮暗主题。`ReaderThemePalette.toThemeData(parentTheme: ...)` 保留应用的外观扩展及文字排版，再应用阅读配色；目录面板缓存也以父主题身份失效，切换阅读配色不会丢掉玻璃设置。

阅读悬浮标题栏和控制栏由 `ReaderControlBar` 持有唯一的 floating 背景，栏内 `ReaderControlIconButton` 是 44 点的透明图标按钮，不再绘制自己的玻璃外壳。栏外独立的定位等按钮仍有自己的背景。整条阅读栏通过既有 `ElasticPress` 响应按压、阻尼拖动和松手回弹，前景与玻璃一起形变，布局和弹出菜单锚点保持稳定；减少动态效果时保持静止。图片/PDF/漫画阅读栏的页码与图标标签使用透明 TextButton，同样不再叠加按钮玻璃。该绘制变换继续由液态玻璃的坐标收集器处理。

## 策略与特殊渲染

优先级固定为：全局关闭 → 高对比实底 → Material 3 实底 → 当前主题玻璃样式/透明度 → 没有主题扩展时使用全局默认。当前默认在 `ui_style.dart`，液态不透明度设置沿用已有存储。关闭效果及高对比是正常策略，不是异常兜底。

可见度直接缩放背景染色、边缘、阴影和滤镜；不要在移动背景滤镜外套 `Opacity` 或 `FadeTransition`。提示条只让前景单独淡入淡出。关闭玻璃、切换材质与可见度归零都不改变布局或命中范围。

`GradientTopBackdrop` 是全宽顶部的专用渐进渲染器：材质策略、底色与 `progressiveBlurSigma` 来自公共解析层，保留自己的 clear tail、可变 sigma、镜像边缘和分段兼容算法。`GlassTopBar` 与宽屏首页消费这个背景，实色策略下同样有不透明底色。实色模式不初始化渐进 shader，之后切换玻璃仍可加载。

首次支持引导的全屏暗化遮罩，以及 `AppPopupMenuButton` 锚定动作菜单的实底，属于不同用途。动作菜单默认保持移动实底，避免在玻璃导航上叠加模糊产生重影。表单下拉使用同一锚定路由的 `AppMenuPresentation.adaptivePanel`：静止的圆角面板读取共用 panel 材质，前景单独淡入淡出，不另写模糊或透明度配方。`PillDropdown` 复用 `PillInputSurface` 作为输入外壳；AI 的三个选择器统一接入。弹层等宽于触发器，空间不足时向上放置并在安全区与键盘之外滚动；选择或关闭后恢复可用触发器焦点。底部菜单也按共用 panel 策略显示。

## 回归与证据

当日更新见 [2026-10-10 共享菜单与阅读栏验证](reviews/2026-10-10-glass-sheets-reader-chrome.md)；原始材质迁移见 [2026-10-09 共用玻璃背景验证](reviews/2026-10-09-shared-glass-background-validation.md)。

- `test/shared_glass_background_test.dart`：布局/点击稳定、模式优先级、高对比、单次采样、内部可见度和全 `lib/` 的渲染所有权。
- `test/pill_dropdown_test.dart`、`test/app_menu_test.dart`：共享下拉的选择、关闭、禁用、当前值语义、窄屏大字、键盘、毛玻璃/液态/全局关闭/实色/高对比，以及原动作菜单行为。
- `test/glass_material_consumers_test.dart`：顶部实底与模式优先级、弹窗范围/键盘/大字、提示条前景淡出、渐进染色。
- `test/reader_theme_glass_policy_test.dart`：阅读配色与应用外观策略同时保留。
- `test/liquid_glass_lighting_test.dart`：白色、羊皮纸、夜色、纯黑与深蓝画布的边缘光照，阅读语义颜色/亮暗覆盖与可见度。
- `test/reader_control_chrome_test.dart`：栏内单一背景、栏外独立按钮、整条按压/拖动/回弹、点击取消和减少动态效果。
- 既有控件、导航、书源、输入框、工具栏、阅读栏、书库及渐进模糊 widget 套件分别进程运行，不合并全局状态。
- `tool/preview_shared_glass_background.dart`：真实 Flutter/Impeller 的深浅色、毛玻璃、液态、实色及高对比预览。图像在 `docs/previews/shared-glass-background-20261009/`；预览与安装启动都不等于用户真实阅读场景的视觉验收。

- `tool/preview_shared_glass_sheets.dart`：第一批底部菜单与平整阅读栏的 24 张原生截图及录屏动图见 `docs/previews/shared-glass-sheets-20261010/`。菜单外间距和连续圆角的跟进验证见[菜单几何记录](reviews/2026-10-10-sheet-geometry.md)，使用同一工具的 `ORIGO_SHEET_GEOMETRY_PREVIEW` 场景。
