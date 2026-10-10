# 阅读导航菜单

本地与书源阅读器共用 `lib/widgets/reader_navigation_sheet.dart`，调用方通过 `showGlassBottomSheet` 管理路由、关闭、跳章和返回值。菜单展示读取位置，业务回调继续由 `native_reader_navigation.dart` 与 `book_source_reader_navigation.dart` 管理；不改变书籍位置、书签或批注的存储合同。

## 紧凑布局

公共菜单保留 44 点拖动区域，点横条、下拉、点遮罩或系统返回均可关闭。内容不再重复显示大号「阅读导航」标题和右上关闭叉；标题保留为路由语义。目录、书签、笔记共用 44 点标签栏，选中标签使用轻量强调底色。

目录下方一行展示章节进度和「当前」定位。搜索入口位于标签栏右侧，点开后在进度行原位显示 14 点圆角输入框并聚焦；再次点搜索关闭按钮清空过滤并收起输入。输入框内清除按钮只清空文字，保留搜索输入。切换标签释放键盘焦点但保留过滤状态；返回目录不会丢失查询。列表拖动收起键盘。

点击「当前」会清空搜索、收起输入、展开当前章节祖先并恢复定位，包含过滤结果为空的情况。延迟 EPUB 子标题解析不关闭用户已经打开的搜索。

目录行基础高度 56 点，随文字缩放至最多 96 点；初次定位与回到当前使用同一行高计算，继续保留虚拟列表、层级折叠、命中项祖先、6000 项目录及当前小节标识。标题最多两行，当前章节用色彩、侧边标记和图标同时表达。

## 材质与边界

背景继续由唯一 `GlassBottomSheetSurface` 提供；搜索与按钮消费公共 `GlassControlSurface` / `GlassIconButton`，不重复建立模糊配方。无玻璃、毛玻璃、液态玻璃遵循应用外观扩展，阅读配色通过 `ReaderThemePalette` 保留。菜单高度由调用方控制，这次没有改变各阅读器路由的高度或全局拖动区域。

## 回归入口

- `test/reader_navigation_sheet_test.dart`：阅读配色、延迟解析、子标题当前位置、树折叠、6000 项虚拟列表、搜索清除/收起/标签保留与空结果恢复。
- `test/reader_annotations_navigation_test.dart`：笔记排序、复制、删除和导出。
- `test/txt_unresolved_navigation_test.dart`：失效位置仍可查看/复制但不能跳转。
- `test/reader_navigation_sheet_visual_test.dart`：390 点宽的 430 点高半屏布局，三种材质的明暗模式，以及 320 点宽的 1.5 倍文字；保留共享拖动区，检查目录可用高度和无溢出。

设置 `ORIGO_NAV_PREVIEW_DIR=build/navigation-redesign/after` 运行视觉测试可保存真实 Flutter PNG 和场景尺寸。测试使用软件渲染器，液态玻璃遵循公共降级，不能作为原生折射效果或真机手感的验收。安装启动与用户物理体验分别记录，由共享安装负责人交付最新合并源码。

## 2026-10-10 验证

实际 Flutter 对比见[调整前后](previews/reader-navigation-20261010/comparison.png)和[320 点大字搜索](previews/reader-navigation-20261010/search-large-text.png)。相同 430 点半屏中，普通目录视口由 154 增至 268 点；320 点大字号由 123 增至 268 点，搜索展开后仍有 266 点。场景参数见同目录 `render-context.json`；软件截图只证明布局与公共降级状态。

导航、视觉、批注、失效 TXT 和手机/平板 EPUB 目录远跳回归分别进程验证；详情收据在忽略的 `build/navigation-redesign/`。首次 TXT 验证遇到共享 `build/native_assets` 中 SQLite 动态库消失，改用独立验证副本后通过，未修改产品数据库代码。共享安装负责人负责合并后的 SloanePro 原位安装，当前未以这些截图宣称真机验收。
