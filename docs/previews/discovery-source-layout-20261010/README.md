# 发现页书源布局原生预览

这组截图由生产 `BookSourcesPage`、`BookSourceDiscoverLayout.source` 和共享玻璃半屏菜单在 iOS 模拟器中直接渲染。预览入口只注入内存中的 `BookSourceRegistry`、`BookSourceClient` 与书架桩，不读取或修改用户书源、账号或书架数据。

## 捕获环境

- 模拟器：`Origo Discovery Source Preview`（`6ECD0D15-DC02-4695-8512-FCC2F1423AF4`）
- Flutter target：`tool/preview_discovery_source_layout.dart`
- 平台：iOS 模拟器，Impeller shader-filter 路径
- 像素比：2x
- 生产入口保持为 `lib/main.dart`；未安装到 SloanePro，未清理任何真机或用户数据

## 场景

- `main-liquid-light.png` / `main-liquid-dark.png`：主页面亮色、暗色玻璃效果
- `main-narrow-320x740-text-1.6.png`：窄屏与 1.6 倍字体
- `main-legado-categories-only.png`：混合 ORSP/阅读源数据中选中阅读源，仅保留分类内容
- `source-menu-liquid-light.png`：共享玻璃书源菜单
- `source-menu-search-filtered.png`：书源搜索筛选为单项结果
- `source-menu-narrow-320x740-text-1.6-keyboard-inset.png`：窄屏、大字、键盘安全区的书源菜单
- `category-menu-liquid-light.png`：共享玻璃分类菜单
- `category-menu-list-end.png`：分类列表滚动到末尾
- `category-menu-narrow-320x740-text-1.6-keyboard-inset.png`：窄屏、大字、键盘安全区的分类菜单
- `category-narrow-large-keyboard-native.png`：含真实 iOS 软件键盘的系统截图

## 几何与渲染证据

完整数据见 `render-context.json`：

- `shaderFilterSupported=true` 且 `shaderReady=true`
- 各主页面场景的 `viewportToBottom=0`，内容视口覆盖到底部
- 阅读源场景的 `sectionTrackPresent=false`、`categoryControlsPresent=true`，同时分类栏与全部分类按钮仍有有效几何
- 阅读源配置经生产 `parseSourceExploreCatalog` 解析为两个有效探索目录，结果记录在 `readingSourceExploreCatalog`
- 正常与窄屏菜单的 `sheetPanelToBottom=8`，符合共享半屏菜单的底部外边距
- 正常菜单同行搜索框约为 `285x52`；窄屏 1.6 倍字体下约为 `188x62`，两者右边缘均距面板 `16` 点
- 两个 source 布局菜单均记录持续显示的右侧 `Scrollbar` 几何，`closeButtonCount=0`，仅保留共享拖动条
- 窄屏键盘场景注入 `keyboardInset=264`，菜单列表底部为 `468`，位于键盘上沿
- 视觉检查覆盖标题、同行搜索框、共享拖动条、滚动条、筛选结果、末尾分类、横向分类与展开按钮，未发现字体或图标截断

## 验证命令

```sh
dart analyze tool/preview_discovery_source_layout.dart

xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination id=6ECD0D15-DC02-4695-8512-FCC2F1423AF4 \
  -derivedDataPath /tmp/origo-discovery-source-preview-derived \
  FLUTTER_TARGET="$PWD/tool/preview_discovery_source_layout.dart" \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS=arm64 \
  build
```

构建结果为 `BUILD SUCCEEDED`。这些截图证明模拟器原生渲染与布局几何，不替代真机交互验收。
