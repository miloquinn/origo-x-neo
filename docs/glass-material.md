# 共用玻璃材质

所有普通玻璃背景由 `lib/widgets/glass_surface.dart` 的 `GlassSurface` 绘制，样式由 `lib/utils/glass_material.dart` 的 `GlassMaterial` 统一解析。组件只提供外形、布局、交互和主题配色意图；不在组件里调透明度、模糊、白色混合、描边或阴影。

## 更新入口

- 底色渐变、透明度、描边、阴影、液态高光与可读性密度：修改 `GlassMaterial`。
- 用户偏好、总开关和性能状态：`GlassEffectConfig` 仅保存状态与 `blurScale`，沿用 `UiStyleThemeExtension` 和已有设置服务，不新增存储或依赖。模糊基数、密度、染色及折射值全部属于 `GlassMaterial`。
- 背景合成、裁切与普通毛玻璃滤镜：修改 `GlassSurface`。
- 液态采样、shader 加载和变换坐标：`LiquidGlassSurface` 是能力渲染器，接收已解析材质，不自行读取主题决定外观。shader 不支持或加载失败时保留轻模糊，失败有日志。

一个材质角色描述视觉用途，不对应某个组件：`control` 为轻量控件，`floating` 为悬浮 chrome，`panel` 为较长内容的面板，`selection` 为选中指示。角色配方仍集中在同一解析层；不得为每个页面再建立一份数字参数。

## 组件边界

| 消费方 | 组件负责 | 背景负责 |
| --- | --- | --- |
| 悬浮导航、阅读控制栏 | 尺寸、圆角、弹性、图标与操作 | 共用 floating 材质 |
| 选中文字工具栏 | 超椭圆、分隔线、复制/高亮/笔记/更多、空间限位 | 共用 floating 材质，阅读器配色 |
| 按钮、搜索框、AI 输入框 | 命中、输入、焦点、禁用、布局 | control 或 floating 材质 |
| 选中透镜、书源分区指示 | 位置、外形、选择动画 | selection 材质；已过滤父层内不重复采样 |
| 侧栏、导入按钮、书籍操作和提示条 | 页面行为、尺寸、内容与动作 | 共用材质角色 |
| 设置预览 | 预览状态 | 直接复用生产导航组件 |

`GlassSurface` 不增加内容内边距，背景在独立图层绘制，阴影在裁切之外。形状裁切、内容留白及按钮 ripple 由专属组件管理。`GlassControlSurface` 仅是控件布局适配入口，明确保留原一像素留白并委托公共背景。消费者统一传语义 `outlineColor`，没有只读取颜色却接收宽度/样式的旧 `BorderSide` 接口；描边透明度与宽度由材质解析。

阅读器传自己的背景、描边、阴影与亮暗主题。`ReaderThemePalette.toThemeData(parentTheme: ...)` 保留应用的外观扩展及文字排版，再应用阅读配色；目录面板缓存也以父主题身份失效，切换阅读配色不会丢掉玻璃设置。

## 策略与特殊渲染

优先级固定为：全局关闭 → 高对比实底 → Material 3 实底 → 当前主题玻璃样式/透明度 → 没有主题扩展时使用全局默认。当前默认在 `ui_style.dart`，液态不透明度设置沿用已有存储。关闭效果及高对比是正常策略，不是异常兜底。

可见度直接缩放背景染色、边缘、阴影和滤镜；不要在移动背景滤镜外套 `Opacity` 或 `FadeTransition`。提示条只让前景单独淡入淡出。关闭玻璃、切换材质与可见度归零都不改变布局或命中范围。

`GradientTopBackdrop` 是全宽顶部的专用渐进渲染器：材质策略、底色与 `progressiveBlurSigma` 来自公共解析层，保留自己的 clear tail、可变 sigma、镜像边缘和分段兼容算法。`GlassTopBar` 与宽屏首页消费这个背景，实色策略下同样有不透明底色。实色模式不初始化渐进 shader，之后切换玻璃仍可加载。

首次支持引导的全屏暗化遮罩，以及移动弹出菜单的实底，属于不同用途。菜单保持实底，避免移动时在玻璃导航上叠加模糊产生重影。这些不会被强行换成液态玻璃。

## 回归与证据

本次结果见 [2026-10-09 共用玻璃背景验证](reviews/2026-10-09-shared-glass-background-validation.md)。

- `test/shared_glass_background_test.dart`：布局/点击稳定、模式优先级、高对比、单次采样、内部可见度和全 `lib/` 的渲染所有权。
- `test/glass_material_consumers_test.dart`：顶部实底与模式优先级、弹窗范围/键盘/大字、提示条前景淡出、渐进染色。
- `test/reader_theme_glass_policy_test.dart`：阅读配色与应用外观策略同时保留。
- 既有控件、导航、书源、输入框、工具栏、阅读栏、书库及渐进模糊 widget 套件分别进程运行，不合并全局状态。
- `tool/preview_shared_glass_background.dart`：真实 Flutter/Impeller 的深浅色、毛玻璃、液态、实色及高对比预览。图像在 `docs/previews/shared-glass-background-20261009/`；预览与安装启动都不等于用户真实阅读场景的视觉验收。
