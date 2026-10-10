# 书源管理布局与共享分类栏

管理页保留书源门面、协议分区、搜索/状态/分组交集筛选、分页和多选行为。此说明维护显示和控件边界；分组存储见[书源分组](book-source-group-design.md)，材质策略见[共用玻璃材质](glass-material.md)。

## 卡片

`lib/pages/book_sources/widgets/book_source_management_source_card.dart` 负责名称、描述、状态/分组、收藏、启停与更多操作。名称、描述和分组最多两行；状态色继续使用主题语义色。普通字号且内容宽度至少 260 点时，状态/分组与收藏/启停共享页脚；窄屏和放大文字改为上下排列。卡片按内容取得自然高度，不能以固定高度裁切文字，也不通过缩小字号压缩信息。

收藏、开关和更多操作保持原生交互及至少 44 点操作区域；多选模式用选择框替代图标，维持标题对齐并隐藏单源动作。附加协议未开启或没有可执行能力时，仍按控制器的规则禁用开关。空状态和无匹配状态保留原有重置入口。

## 共享分类控件

- `lib/widgets/app_filter_bar.dart` 的 `AppFilterBar<T>` 接收带稳定值的 `AppFilterOption<T>`、当前选项、选择回调及可选的尾部操作。选项值必须唯一；标签由使用页负责本地化。
- `lib/widgets/app_selection_pill.dart` 的 `AppSelectionPill` 统一胶囊形状、选中语义、44 点命中、键盘焦点、按压与减少动画行为。原 `BookSourcePill` 是类型别名，发现页的懒加载/分类顺序继续由其原组件管理。
- 整条分类栏用一个 `GlassSurface` control 背景，选中指示使用 selection 材质并关闭重复背景采样。玻璃开关、毛玻璃/液态、实色和高对比沿用 `GlassMaterial`，组件不复制材质配方。
- 单行横向内容按文字自然增高，长标签可横向滚动。外部选中值变化时只滚动分类栏，不滚动所在页面；当前选项已可见时保持位置。正常筛选/切换状态由调用者管理。
- 管理页接入位于 `lib/pages/book_sources/widgets/book_source_management_list.dart`，分组仍是独立尾部动作，不改变状态筛选值。

此组件面向有限数量的状态/标签；书源发现的数百个动态分类继续使用原有懒加载列表，不将全部分类一次构建。标签条与卡片变矮不能据此断言海量书源解析或加载更快。

## 回归与预览

- `test/book_source_management_source_card_test.dart`：窄屏/两倍文字、长名称/说明/分组、普通密度、元信息/操作同排、无元信息、44 点操作、协议禁用与多选对齐。
- `test/app_filter_bar_test.dart`：单次背景采样、玻璃关闭/实色/高对比的尺寸与交互、选中语义、横向滚动、大字自然高度、外部选择不改变纵向位置、键盘和独立尾部动作。
- `test/book_source_pill_test.dart`：共享胶囊原有按压、减少动画、语义、键盘及发现页懒加载/排序行为。
- `test/book_source_management_organization_test.dart`、`test/book_source_management_page_test.dart` 与 `test/book_source_management_controller_test.dart`：收藏/启停、保存失败、分组、多选、筛选/分页和真实管理页入口，按独立 Flutter 进程运行。
- `tool/preview_book_source_cards.dart`：中文字体卡片截图，默认输出忽略的 `build/source-management-20261010/card-previews/`，可设置 `BOOK_SOURCE_PREVIEW_OUTPUT`。
- `tool/preview_source_management.dart`：复用生产管理列表的原生预览，包含深浅色、毛玻璃、液态、实色、高对比和窄屏大字。只使用演示书源，不读取真实账户或修改用户书源。

真实设备的点击手感、选项辨识和一屏信息量由合并后的最新安装包验收；模拟器截图、测试和安装启动分别记录，不能互相替代。
