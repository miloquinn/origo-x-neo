# 毛玻璃导航与弹性菜单融合

范围：首页悬浮底栏，以及使用 `AppPopupMenuButton` 的共用三点菜单。

依据：本地 FlClash 的 `navigation_dock.dart` 和 `popup.dart`；开元阅读现有
`FloatingPillNavigationSurface`、`HomeBounceNavigationItem` 和 `AppPopupMenuButton`。

- 保留 `GlassEffectConfig` 的透明度、主题染色、模糊强度和性能模式；保留导航尺寸、边距、标签与宽屏布局设置。
- 导航外壳和选中块使用 Flutter 超椭圆形状。按下膨胀、拖动拉伸、松手弹簧回弹；变形只作用于绘制，不改变布局和弹层锚点。
- 三点菜单从按钮形状长成卡片；尺寸、横向和纵向分别使用弹簧，内容缩放与淡入；表面改用不透明主题色，底色、裁剪、描边和阴影共用动画路径，以消除展开重影。沿用原菜单数据、禁用项、选中项、滚动、安全区、焦点与关闭后回调契约。
- 系统减少动态效果时立即进入稳定状态；不新增依赖，不修改阅读器底部工具栏。
- 验收：定向导航/菜单/玻璃测试，静态分析，浅色与深色真实 Flutter 渲染，以及按压、拖动和展开/收起的动画帧。

现有菜单基线：`test/app_menu_test.dart` 的 14 项通过；预览保存在
`/tmp/origo-glass-elastic-20261007/baseline/menu`。
