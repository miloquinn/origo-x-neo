# 发现页布局与选择菜单

发现页由 `lib/pages/book_sources/book_sources_page.dart` 组合布局和导航，`controllers/book_sources_controller.dart` 管理书源、请求代次、分类及分页。布局按钮依次切换标准、列表和书源布局，使用已有 `book_source_discover_layout_v1` 偏好保存；旧值与未知值仍回到标准布局。页面先恢复布局，再加载来源，避免恢复书源布局前发出聚合请求。

## 书源布局

- 顶部 `BookSourceDiscoverySourceButton` 显示当前来源及展开箭头。点击打开可搜索的书源半屏列表，选中后关闭菜单，重新加载该来源的分类和内容。搜索复用 `BookSourcesPage.listSourceMatchesQuery`，匹配名称、说明、地址、标识及分组；不会发出远端搜索请求。
- 进入此布局清除隐藏的收藏/分组过滤，保留有效来源选择，否则选择第一个可发现来源。来源具备分类能力时优先进入分类；只有推荐或最新能力时显示相应内容。移除、禁用来源及权限变化后重新选择有效来源；空库禁用选择按钮并显示原有空态。
- 横向分类和右侧全部分类按钮复用 `BookSourceCategoryChannels`。分类菜单选择后沿用 `selectCategory`，自动将远处分类滚入横向可见区域，加载结果仍由现有 category revision、分页和缓存边界管理。新布局不使用平板标准布局侧栏；宽屏仍遵守页面最大宽度。
- `setSourceLayout` 仅在进入时作废旧聚合请求；退出时保留同源在途请求，避免永久加载状态。标准、列表与书源三种布局共用控制器，不能另建一套书源客户端或缓存。

## 共享外观与菜单

来源按钮使用 `GlassControlSurface`，选中来源使用 `GlassSurface(role: selection)`。书源和分类菜单都从 `showGlassBottomSheet<T>` 返回业务对象，继承毛玻璃、液态、实底及高对比外观，不复制材质配方。来源搜索框复用 `PillSearchField`，关闭面板内重复背景采样。

书源布局的两个菜单保持约 55% 屏幕高度，横条计入总高；键盘 inset 由页面内容消费。默认边到边合同见[共用底部菜单](bottom-sheets.md)：列表 viewport 到达玻璃底边，安全区只保留在滚动内容末端。共享外壳继续管理拖动关闭、返回和类型化结果，取消菜单不修改来源或分类。标准布局原有的分类菜单尺寸与宽屏对话框保持其原合同。

## 回归入口

- `test/book_source_focused_layout_test.dart`：三种布局循环/持久化、未知偏好回退、80 个来源本地搜索和切换、两个实际菜单的 55% 高度/到底几何、分类末项安全区与远处标签回显、窄屏大字及键盘、取消菜单、空源。
- `test/book_sources_single_source_layout_test.dart`：单源作用域、已有选择、有限能力和无源、删除/元数据/组织变化、旧异步响应、隐藏筛选复位及退出时在途请求完成。
- `test/book_source_discovery_page_test.dart`：标准与列表的原有回归。此套件持有进程级注册表与平台状态，按具体用例在独立 Flutter 进程运行，不能把组合执行泄漏报成产品构建失败。
- `test/book_source_pill_test.dart`、`test/glass_bottom_sheet_edge_to_edge_test.dart`：共享分类懒构建、选中项可见、减少动态效果及共享边到边合同。
- `tool/preview_discovery_source_layout.dart`：生产页面与菜单的原生模拟器预览，使用注入演示书源，不访问用户账号或真实书源。预览不能代替 SloanePro 的真实来源、视觉与手感验收。

本轮验证和设备交付边界见[2026-10-10 发现页书源布局](reviews/2026-10-10-discovery-source-layout.md)。
