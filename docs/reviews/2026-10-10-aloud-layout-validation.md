# 2026-10-10 听书封面与响应式布局验证

这是本批实现与验证的历史记录。当前维护合同见 [听书维护](../tts-jump-reading-design.md)。

## 结果与简化

手机默认显示正文，顶部为小封面、书名、作者与章节；滚动正文收起扩展控制，底部保留前后句、播放暂停和展开入口。大屏同时显示左侧封面与控制、右侧可滚动并点句播放的正文。手机可切换大封面，不改变播放位置或定时器。

封面元数据由两类阅读器传入共享朗读 source。同书重开时刷新元数据快照；本地路径、下载书的在线地址和请求头不再在播放器丢失。书架网格、列表与听书共用 `BookCoverReference` / `BookCoverImage`，删除书架重复的 JSON 解析，使用本地 → 在线 → 默认封面回退。本地成功不加载远端；无效 URI 安全回退；听书图片按显示宽度与像素密度解码。音量、前后章和结束听书进入「更多」，移除播放器正文外重复卡片边框，不增加依赖。

主要修改入口为 `lib/core/reader/reader_aloud_controller.dart`、两类阅读器的朗读 source、`lib/models/book_cover_reference.dart`、`lib/widgets/book_cover_image.dart`、`reader_aloud_cover.dart`、`reader_aloud_panel.dart`、`reader_aloud_transcript.dart` 及书库封面构建入口。源码和回归入口的具体所有权见当前维护合同。

## 验证

11 个顺序独立 Flutter 进程，共 124 项回归通过。原有播放、暂停、停止、目录、声音设置、音量提交、定时与跳读断言保留；旧底部控制菜单继续可用。

| 回归入口 | 通过数 |
| --- | ---: |
| `book_cover_image_test.dart` | 10 |
| `reader_aloud_cover_test.dart` | 7 |
| `reader_aloud_panel_test.dart` | 38 |
| `native_reader_aloud_typography_test.dart` | 3 |
| `library_cover_fit_test.dart` | 1 |
| `library_cover_storage_repair_test.dart` | 1 |
| `library_page_test.dart` | 7 |
| `reader_aloud_controller_test.dart` | 40 |
| `reader_aloud_typography_test.dart` | 3 |
| `book_source_reader_aloud_transition_test.dart` | 11 |
| `source_cover_image_test.dart` | 3 |

实际 TXT、EPUB 阅读页进入播放器验证了失效本地封面到在线封面的 URI、请求头与展示入口。真实 PNG 解码、成功本地封面不请求远端、协议相对地址、无效协议/基地址、同书元数据刷新均有独立断言。正文首句定位、浏览与跟随区分、收起/展开、减少动态效果和中英日文 2 倍大字在组件测试中通过。

17 个相关源码/测试/预览入口静态分析无问题，21 个文件格式检查通过，`git diff --check` 通过。独立代码复核最终 APPROVE。

`tool/preview_reader_aloud_layout.dart` 渲染 10 个生产组件状态：390×844 手机、320×568 窄屏、568×320 横屏、844×390 横屏、768×1024 平板、1194×834 平板、1440×900 桌面、深色大字、手机收起控制、手机大封面。每次截图都断言真实本地图片已解码。示例文字和插画只用于布局验证；Widget 渲染不代表原生玻璃效果、真机触摸或实际音频体验。

- [手机正文](../previews/aloud-layout-20261010/phone.png)
- [手机收起控制](../previews/aloud-layout-20261010/phone-focused.png)
- [手机大封面](../previews/aloud-layout-20261010/phone-cover.png)
- [平板双栏](../previews/aloud-layout-20261010/tablet-landscape.png)
- [深色大字](../previews/aloud-layout-20261010/large-text-dark.png)

完整日志、检查汇总与源码冻结记录保存在忽略目录 `build/aloud-layout-20261010/`。

## 交付边界

设备由统一安装者从共享 checkout 构建合并的 261010005。本批不独立安装旧快照；构建入口保持 `lib/main.dart`，覆盖更新保留现有用户数据。源码冻结后等待签名包、已安装身份及成功启动收据，再更新本记录。

真实云端请求延迟、语音听感以及用户书籍的物理触摸验收仍需在设备上确认；模拟引擎和测试书籍不构成这些结果。
