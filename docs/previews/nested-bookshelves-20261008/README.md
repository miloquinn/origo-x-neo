# 嵌套子书架视觉验证

真实 Flutter `LibraryPage`、共享顶栏/玻璃按钮及批量操作组件，使用明确的示例书籍和封面。图片用于布局验收，不是实体设备录屏；预览壳只提供标题与操作，不模拟完整首页导航。

| 场景 | 根目录 | 子书架 | 批量操作 |
| --- | --- | --- | --- |
| 390px 浅色 | [root](phone-light-root.png) | [folder](phone-light-folder.png) | [selection](phone-light-selection.png) |
| 390px 深色 | [root](phone-dark-root.png) | [folder](phone-dark-folder.png) | [selection](phone-dark-selection.png) |
| 320px、1.5 倍字号 | [root](narrow-large-text-root.png) | [folder](narrow-large-text-folder.png) | [selection](narrow-large-text-selection.png) |
| 834px 宽屏 | [root](tablet-root.png) | [folder](tablet-folder.png) | [selection](tablet-selection.png) |

第二轮 verdict: PASS，无 Flutter 布局异常；目录最多九张缩略图，完整总书数保留；目录按钮在左侧悬浮，批量新建、移动、删除在大字号下可达。首轮发现原书籍详情的固定高度会在放大字号时溢出，已在共享组件与网格高度中统一修复，并添加独立回归。

复现：设置 `SHELF_SCREENSHOT_DIR` 和 `SHELF_PREVIEW_FONT` 后运行 `flutter test --no-pub test/library_shelf_responsive_test.dart`。不设置环境变量时 CI 仍验证布局和交互，字体与图片 IO 在测试真实时钟中初始化。
