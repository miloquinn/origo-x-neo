# 毛玻璃导航与弹性菜单验证

已在本地代码完成：首页悬浮底栏与共用三点菜单融合 FlClash 的超椭圆形状和弹性动效，保留开元阅读原有玻璃配置。没有新增运行时依赖。

## 变更文件

- `lib/widgets/elastic_motion.dart`：连续重定向并保留速度的弹簧，以及路由使用的弹簧曲线。
- `lib/widgets/elastic_press.dart`：共用按压膨胀、阻尼拉伸、松手回弹；仅绘制变形，不改变布局和弹层锚点。
- `lib/widgets/elastic_pill_navigation_bar.dart`：连续选中块、拖动提交、取消复位、RTL 与减少动态效果。
- `lib/widgets/floating_pill_navigation_surface.dart`：超椭圆玻璃外壳和整体弹性反馈；玻璃底景单独裁切。
- `lib/pages/home/widgets/home_bounce_navigation_item.dart`：复用图标、标签、语义，可交由共用选中块绘制背景；删除原先收缩的按压控制器和无效缩放层。
- `lib/pages/home/home_shell_page.dart`、`lib/pages/home/parts/home_shell_layout_part.dart`：首页接入连续选中块，沿用原导航尺寸、布局和切页状态。
- `lib/widgets/app_menu.dart`：三点按压反馈，尺寸/X/Y 独立弹簧，超椭圆卡片、内容缩放/淡入与单轮廓实色表面；保持原菜单数据、键盘、关闭后回调等接口。
- `test/app_menu_test.dart`、`test/elastic_motion_test.dart`、`test/elastic_press_test.dart`、`test/elastic_pill_navigation_bar_test.dart`、`test/home_bounce_navigation_item_test.dart`：定向回归。
- `tool/preview_glass_elastic_chrome.dart`：使用真实 Flutter 组件采集浅色/深色按压、拖动、松手、展开和收起动画。
- `DESIGN.md`、`docs/plans/2026-10-07-glass-elastic-chrome.md`：更新现有菜单与导航规范，保留其他已有修改。

## 验证证据

| 验证 | 结果 |
| --- | --- |
| 导航与真实子按钮交互两文件 | 14 项通过 |
| 菜单、弹簧、玻璃配置/控件、浮动子页面五文件 | 29 项通过 |
| 共用按压反馈 | 2 项通过 |
| 手机首页、阅读路由返回与导航避让 | 4 项通过 |
| 平板、窄屏放大字号、旋转与窗口缩放 | 4 项通过 |
| 浅色/深色真实 Flutter 动画采集 | 1 项通过 |
| 本次涉及的 14 个 Dart 文件定向静态分析 | 无问题 |
| 全库 `flutter analyze --no-pub --no-fatal-infos` | 无错误或警告；4 条范围之外的已有 info |
| 本次代码 `git diff --check` | 通过 |

共计 53 项定向功能测试通过，另有 1 项动画采集测试通过。各有状态首页套件按独立 Flutter 进程运行；其他组件套件使用 `--concurrency=1`，避免原生资产构建竞争。

全库 info 位于 `source_chapter_state.dart:313`、`source_cookie_utils.dart:32`、`book_source_reader_recovery_test.dart:236`、`offline_reader_license_refresh_test.dart:9`，本次未扩展修改这些文件。

## 预览与复现

预览为真实组件搭配演示内容，生成脚本并非完整产品页面。

- [浅色底栏动画](../previews/glass-elastic-20261007/light-nav.gif)
- [深色底栏动画](../previews/glass-elastic-20261007/dark-nav.gif)
- [浅色菜单动画](../previews/glass-elastic-20261007/light-menu.gif)
- [深色菜单动画](../previews/glass-elastic-20261007/dark-menu.gif)

```sh
flutter test --no-pub tool/preview_glass_elastic_chrome.dart
```

预览脚本使用当前 macOS 中文字体和已有 `/opt/homebrew/bin/ffmpeg`。可通过 `--dart-define=CHROME_PREVIEW_OUTPUT=/absolute/output/path` 将输出放到独立目录。

## 验证边界

已完成 Android arm64 debug 构建，并通过 adb 安装到 PKT110。覆盖安装因签名不同被拒绝，随后按用户授权卸载原应用并重新安装；原应用本地数据随卸载清除。版本回读为 2.7.2（261005001），包含 DEBUGGABLE 标记；冷启动 `am start -W` 返回 `Status: ok`，前台 Activity 与截图确认首页和新悬浮底栏可见，启动日志未见 AndroidRuntime/flutter 错误。

APK：`build/app/outputs/flutter-apk/app-debug.apk`；SHA-256：`98b102e39676d87d9047baccce15e5d9f356f4cac9fd4bea8b4f5bb7e92cc650`。

尚未进行触摸手感验收、真机 GPU 性能测量或正式发布验证。改动保留在当前工作区，未提交或发布。

## 知识沉淀与版本记录

2026-10-07 用户确认 Android 真机上的融合效果符合预期。可复用笔记写入 `/Users/xiaoyuan/work/knowledge-base/flutter/glass-elastic-navigation-and-menu.md`，包含接入示例、弹簧参数、实现边界、踩坑和四份深浅色动图，知识库 README 已添加入口。

源码构建号更新为 `2.7.2+261007001`；`CHANGELOG.md`、对应 release-note 与应用内中英文日志已同步。生成目录同时补入已有 `260926001` 欢迎页说明，保留原有条目与翻译。版本策略及日志生成的 17 项 Python 测试、日志服务与页面的 8 项 Flutter 测试通过；生成目录一致性、知识库附件链接及 diff 空白检查通过。此次元数据更新未重新安装：手机已验收的 debug 仍为 `261005001`。未提交、发布或推送。

## 菜单重影修复与真机验收

用户在手机上反馈展开时玻璃背景比卡片大，出现重影。新增两项深浅色像素回归在修复前均失败：弹簧轮廓超出最终布局，边缘采样仍为页面背景，而 BackdropFilter 已扩展到该区域。菜单改用与裁剪、描边和阴影共用的路径直接填充不透明主题色，并删除背景与内容模糊层；内容保留缩放与淡入。保留原独立弹簧、过冲手感和菜单交互契约。

修复后菜单、弹簧与玻璃控件 23 项测试通过，两文件静态分析无问题；最终深浅色展开/收起逐帧捕获通过。更新日志和知识库动图同步。debug APK 内嵌更新日志与源码一致，通过 adb 覆盖安装到 PKT110，原数据保留，回读 2.7.2（261007001）。用户随后明确确认“修好了”。APK SHA-256：b9df1fcaa36bcd339ec18bf4d503e855d093dfe024753510944296b272c1bb55。

菜单默认及自定义底色均强制不透明。导航原有毛玻璃配置继续保留。正式发布和真机 GPU 性能量化未验证。
