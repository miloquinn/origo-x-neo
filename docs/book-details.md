# 书籍详情展示维护

## 入口与所有权

- 搜索、发现、书单和 AI 返回的书籍，经 `lib/pages/book_sources/widgets/sourced_book_actions.dart` 的 `showBookDetails` 进入 `lib/pages/book_sources/sourced_book_details_page.dart`。详情控制器继续负责补全详情、阅读、加书架、下载和重试；展示组件不发请求或保存元数据。
- 书库长按菜单中的书籍信息，经 `lib/pages/library/parts/library_book_details_part.dart` 的 `_showBookInfo` 打开共享底部菜单，内容为 `lib/widgets/library_book_info_sheet.dart`。保留原有 `SourceBookStatusCard` 和本地页数、在线章节编码换算。
- `lib/widgets/book_details_header.dart` 共用封面、书名、作者、来源和标签。在线详情使用一层共享面板材质；已由底部菜单绘制材质的书库信息使用 `framed: false`，避免叠加玻璃。
- 阅读器书籍设置页和旧的独立详情 Sheet 保留各自入口；本次展示更新不更改阅读引擎、书源协议、书架数据或封面缓存。

## 布局与标签

普通 360 点及以上手机保持封面在左、身份信息在右。可用信息区不足 280 点或 14 点文字缩放后超过 20 点时，封面和文字改为纵向布局。书名、作者和来源自然换行；分类与状态始终在身份信息下方使用整行宽度，不挤在封面旁边。

`lib/widgets/book_details_tags.dart` 仅在展示时修剪空白、去除空项和重复项，保持状态及分类的原有顺序，不修改 `BookSourceBook`。根据实际字体、文字缩放和可用宽度测量标签，默认显示最多两行，多余项通过系统本地化的展开/收起按钮查看。单个标签限制为一行并显示省略号，长按或悬停提示保留完整文字，辅助功能仍可读取完整名称。展开时采用尺寸动画；系统关闭动画时直接更新内容。

书库信息的正文和统计可滚动，关闭按钮固定在滚动区域外。来源关联通过 `bindingFrom` 一次读取并验证；损坏或身份不匹配时显示详情不可用提示，保留书籍身份和原有来源操作，诊断仅记录异常类型，不输出存储 JSON。

## 材质与操作

在线身份面板复用 `GlassSurface`，继承当前配色、毛玻璃、液态玻璃和无玻璃设置，形状统一用于材质与内容裁剪。加入书架和阅读按钮分别悬浮，周围是透明布局，没有包住两个按钮的共同底板；按钮自身保留原有类型和回调，并使用主题颜色和轻阴影保证可读性。`FloatingSubpageScaffold.extendBody` 委托 Flutter Scaffold，使详情背景与真实滚动 viewport 延伸到屏幕底部。正文在末尾消费 Scaffold 提供的实际底部栏高度，因此大字、原生安全区和失败重试导致的按钮区高度变化也不会挡住末项；没有写死按钮高度。添加失败时，独立的小型错误提示和重试仍固定在按钮上方。

共享底部菜单的安全区和滚动内容契约见 [底部菜单维护](bottom-sheets.md)，玻璃策略见 [玻璃材质维护](glass-material.md)。

## 回归与验收

- `test/sourced_book_details_page_test.dart`：加载失败时保留阅读、读后返回与再次打开、共享书籍设置、重复加书架保护、下载取消，以及普通手机、窄屏、大字体、平板、多标签和超长标签。
- `test/book_details_header_test.dart`：横向和纵向身份布局、标签展示标准化与数据不变、两行折叠和展开、长文字 Tooltip、RTL、辅助功能和关闭动画。
- `test/library_book_info_sheet_test.dart`：在线章节编码与进度、损坏关联可见、320 点/大字体/暗色的真实菜单路由、关闭按钮可触达、单层材质及来源操作保留。
- `tool/preview_book_details.dart`：原生生产组件的固定数据场景，无网络或账户依赖。截图是展示验收，不代表真实书源、账户或真机交互验收。

日期验证记录见 [2026-10-10 书籍详情更新](reviews/2026-10-10-book-details.md)。APP 的签名构建、原地安装和启动由当前合并安装负责人对最新共享源码统一交付；不得用独立预览包替换真机上的正式 APP。
