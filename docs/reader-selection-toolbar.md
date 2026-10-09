# 阅读选中文字工具栏

当前实现由 `lib/widgets/reader_selection_toolbar.dart` 的 `ReaderSelectionToolbar` 独立维护，本地与在线正文共用；入口是 `lib/widgets/reader_annotated_text_page.dart` 的 `_buildSelectionToolbar`。

## 视觉与布局

- 默认顺序为「复制｜高亮｜笔记｜⋯」。主栏用纯文字、细分隔线和 悬浮导航同款圆润超椭圆，按钮无独立背景、边框或胶囊。
- 整个主栏与展开菜单只有一层公共 `GlassSurface` 背景，`GlassControlSurface` 只保留控件留白适配；材质、描边与阴影归 [共用玻璃材质](glass-material.md) 维护。阅读器明确传入自己的配色。高对比模式使用实底，液态 shader 不支持时由共享材质轻模糊兜底。
- 更多菜单在同一背景内展开搜索、净化所选文字与问 AI。只展示已提供回调的操作，不展示原先未实现的分享、翻译、朗读或反馈占位项。
- 使用界面字体与系统文字缩放，按实际本地化文本测量宽高。空间不足时，从末尾将笔记、高亮依次收入更多，保留复制及更多入口；极端窄屏的复制文字可横向滚动。菜单长文字换行，内容过高可滚动，不缩小字号或省略操作名。
- 点击区域至少 44px；按钮保持禁用、焦点、键盘与语义。更多按钮再次点击收回；执行菜单操作先收回面板，再调用原选区回调。
- 使用 Flutter `TextSelectionToolbarLayoutDelegate` 的上下锚点与横向限位，补充底部限位及安全区。展开面板重新按真实高度选上下位置，不能越过屏幕底部。

## 所有权

工具栏只拥有更多面板的显隐状态。选区、复制、选区快照、正文偏移映射、高亮保存、笔记编辑、搜索及 AI 请求仍归正文页与阅读器；本轮不改变存储或服务端协议。

## 验证入口与限制

- `test/reader_selection_toolbar_test.dart`：操作顺序、回调、可用性、禁用语义、玻璃模式、主题、窄屏/大字/长语言、RTL、安全区与边缘锚点。
- `test/reader_annotated_text_page_test.dart`：长按真实正文、高亮保存、更多菜单交接 AI/净化选区与既有选区映射。两个 widget 文件独立进程运行。
- `tool/preview_reader_selection_toolbar.dart`：真实 Flutter 组件的毛玻璃、液态、实色、深浅色与窄屏大字预览；预览不代表物理设备 UI 验收。
- 多聊天正在修改 APP 时，最终真机包由共享 `build/device-ios/coordination.json` 登记的安装负责人从最新合并源码构建；本工具栏完成测试后登记 `sourceFinalized`，避免较早快照覆盖新功能。
