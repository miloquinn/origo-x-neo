# 2026-10-10 书籍详情更新验证

当前维护入口：[书籍详情展示](../book-details.md)。

## 变更与行为

在线详情和书库书籍信息复用 `BookDetailsHeader`、`BookDetailsTags`；普通手机保持封面与身份并排，窄屏和大字改为纵向。分类在身份下方占满宽度，显示时去除空项和重复项，默认折叠到两行，通过展开按钮查看全部；长标签保留完整语义及 Tooltip，原始书源元数据不变。

在线详情的一层身份材质继承液态玻璃、毛玻璃及无玻璃模式。底部两个按钮分别悬浮，移除了共同玻璃底板，详情背景与滚动 viewport 延伸到底部。末项使用 Scaffold 实测动作区高度避让；添加失败的重试仍固定可见。书库信息使用共享底部菜单外壳和同一身份组件，关闭按钮固定在正文滚动区域外。读取在线关联只进行一次验证；损坏的关联显示可见提示并保留身份和原有来源操作，不输出存储 JSON。

## 软件回归

详情的三个测试在各自独立 Flutter 进程运行，22 项通过；共享二级页框架另有 7 项回归通过：

| 测试 | 项数 | 主要断言 |
| --- | ---: | --- |
| `sourced_book_details_page_test.dart` | 14 | 悬浮按钮全高 viewport、末项可达、失败后重试仍可见；原有加载、阅读、返回、加书架、下载；普通/窄屏/大字/平板、多分类及超长标签 |
| `book_details_header_test.dart` | 5 | 横纵布局、两行折叠展开、数据不变、Tooltip、RTL、辅助功能及减少动态效果 |
| `library_book_info_sheet_test.dart` | 3 | 章节/进度换算、损坏关联提示、窄屏大字、单层材质、固定关闭页脚与真实关闭 |

展示组件、详情页、父级 library 页面、测试和预览入口的定向静态分析无问题；`git diff --check` 通过。既有普通手机回归在修改前通过；新增标签几何用例在原布局上失败，悬浮按钮的全高 viewport 用例在旧底部栏上失败（844 点屏幕，旧 viewport 到 740 点），见本地构建目录中的 baseline/geometry-before 和 floating-actions-before 记录。

## 原生展示

`tool/preview_book_details.dart` 使用真实生产组件和本地固定数据，覆盖液态浅色/暗色、毛玻璃、无玻璃、24 标签折叠/展开、320×740 的 1.6 倍文字、844×390 横屏及本地书籍信息浅色/暗色。

最终 10 个原生场景已完成，所有 PNG 与场景清单齐全，Impeller 的液态玻璃着色器已就绪；8 个在线详情场景的 viewport 均到达屏幕底边，阅读按钮的祖先均没有共同玻璃底板。截图以 [渲染收据](../previews/book-details-20261010/render-context.json) 为准。场景重建 Navigator 和页面 key，避免复用上一个场景的详情状态；展开场景触发真实组件的展开回调，并确认第 24 个标签实际出现。

- [浅色详情](../previews/book-details-20261010/online-liquid-light.png)
- [暗色详情](../previews/book-details-20261010/online-liquid-dark.png)
- [24 标签展开](../previews/book-details-20261010/online-24-tags-expanded.png)
- [窄屏大字](../previews/book-details-20261010/online-narrow-320x740-text-1.6.png)

## 交付边界

模拟器渲染、软件回归、签名构建、原地安装、成功启动及物理视觉验收分别记录。预览数据不代表真实书源或账户验收。SloanePro 的 `direct` 通道正式 APP 由现有合并安装负责人从最新共享源码统一构建，保留已安装书籍和账户；最终安装状态见共享交付收据，不能用展示预览包替代。
