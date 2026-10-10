# 2026-10-10 底部菜单间距与连续圆角

本记录描述当日的几何跟进；当前组件约定见[共用底部菜单](../bottom-sheets.md)。第一批材质、调节控件和整条阅读栏动效的记录保留在[原始验证](2026-10-10-glass-sheets-reader-chrome.md)，其中 261010005 安装证据不代表本次几何已交付。

## 结果与边界

`lib/widgets/glass_bottom_sheet.dart` 将系统避让移到面板内部，手机面板左右、底部及外壳自身顶部均留 8 点。原先 iOS 底部 34 点安全区加 8 点外间距形成 42 点空白，现在为外部 8 点、内容内部保护 26 点。菜单上方仍是阅读背景，不把半屏菜单顶边描述为距屏幕顶边 8 点。

窗口短边小于 600 点时横屏也占满可用宽度，内部单独避让刘海；平板保留最大 640 点居中面板。高菜单通过路由最大高度避开状态栏，键盘 inset 继续由业务内容管理。内部消耗已处理的 MediaQuery padding，避免旧 SafeArea 再次增加空隙。

背景、液态反光及 Material 裁切共用连续 `RoundedSuperellipseBorder`。手机默认视觉半径 40 点，独立宽屏面板 32 点；平台报告有效屏幕半径时，手机采用最小有效值减外边距。复用既有材质和原生拖动路由，没有新增依赖或机型表。

Flutter 当前只在 Android API 31+ 提供 `displayCornerRadii`，iOS 返回 null。iPhone 的连续曲线采用视觉适配，不能声称读取到每款设备的物理 R；见 [Flutter 屏幕半径 API](https://api.flutter.dev/flutter/widgets/MediaQueryData/displayCornerRadii.html) 与[连续圆角 API](https://api.flutter.dev/flutter/painting/RoundedSuperellipseBorder-class.html)。

## 验证

修改前原有 14 项共享菜单回归通过。先加入几何断言，观察到 7 项失败后才修改生产外壳。最终 59 项测试在 6 个独立进程中通过，无跳过：

| 套件 | 通过数 |
| --- | ---: |
| `glass_bottom_sheet_test.dart` | 19 |
| `reader_settings_controls_test.dart` | 5 |
| `reader_navigation_sheet_test.dart` | 13 |
| `font_selection_sheet_test.dart` | 4 |
| `import_book_page_test.dart` | 4 |
| `book_source_add_flow_test.dart` | 14 |

新断言覆盖 iOS/Android/零安全区的实际面板边界、横屏内部刘海避让、运行时 inset 与键盘变化、全高状态栏保护、系统半径及回退、平板宽度和材质/前景统一裁切。既有取消拖动、泛型结果、不可关闭事务等交互断言继续执行。

生产组件、测试和预览工具的静态分析通过；独立代码复核批准，未发现问题。日志保存在 `build/sheet-geometry-20261010/`。原生预览首次构建遇到同一 UIKit 模块缓存的路径别名冲突，改用独立且规范化的 derived-data 路径，不修改应用或依赖源码。

## 原生预览与交付

同一 `tool/preview_shared_glass_sheets.dart` 通过 `--dart-define=ORIGO_SHEET_GEOMETRY_PREVIEW=true`，在 iOS 模拟器原生 Impeller 渲染器上捕获 8 张截图：液态浅色/夜色、毛玻璃、实底、高对比、横屏、320 点窄屏，以及 Android 几何模拟。`shaderFilterSupported=true`，安装的模拟器应用 kernel 与本次构建逐字节一致，生产外壳、测试与工具在捕获期间的源码哈希保持一致。

全部场景测得面板左右与底部外间距均为 8.0 点，裁切类型均为 `RoundedSuperellipseBorder`。模拟 Android 上报 64 点半径的场景得到 56 点内缩半径，其他手机场景为 40 点。像素复核及独立视觉复核均通过：圆角、高光裁切、横屏和窄屏保持一致，未见边缘泄漏或横向溢出。内容底部的下一行部分可见属于滚动视口，不是额外的外部空隙。

截图和测量/构建哈希在 [`docs/previews/sheet-geometry-20261010/`](../previews/sheet-geometry-20261010/render-context.json)，可查看[浅色](../previews/sheet-geometry-20261010/liquid-light.png)、[夜色](../previews/sheet-geometry-20261010/liquid-night.png)、[实底](../previews/sheet-geometry-20261010/solid-light.png)及[横屏](../previews/sheet-geometry-20261010/geometry-landscape.png)。Android 是 iOS 渲染器上的显式模拟，不是 Android 真机证据。预览后已恢复 `lib/main.dart` 及移除预览 define，交还统一安装构建配置。

本次源码尚未进入 261010005。当前统一安装负责人按 `build/device-ios/coordination.json` 的全部活动源码门禁制作下一批合并开发包；避免单独安装较旧快照。安装、成功启动与用户物理视觉/手感验收分别记录。
