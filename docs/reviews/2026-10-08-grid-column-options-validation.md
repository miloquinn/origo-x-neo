# 2026-10-08 书库列数选项与实际容量一致

## 行为与简化

书库网格此前按实际容量限制显示列数，但设置固定提供 2、3、4、5，导致选 5 后仍显示 4。本批让设置与网格复用 `LayoutHelper` 的边距、间距、最小封面宽度和列数计算，仅显示当前容量能容纳的选项。360dp 普通手机提供 2、3、4；390dp 正常字号可提供 5。大字号、有可见详情或分组文字时相应减少选项。

当前选中值投影为可用列数，保存的偏好保持不变；更宽的窗口可恢复原来的 5，只有手动选择才写入新的偏好。设置打开后旋转/调整窗口时重新计算，不冻结打开前的宽度。书库 controller 提供当前可见分组快照，设置路由传递该 controller；尚未加载时只读根目录元数据，读取失败显示现有错误提示。未增加依赖或第二套持久化状态。

修改集中在 `lib/utils/layout_helper.dart`、书库 renderer/controller、首页与设置路由、`LibraryLayoutSettingsPage`，回归集中在 `test/library_grid_density_test.dart`。设计契约见 [DESIGN.md](../../DESIGN.md)。

## 验证证据

- 修改前 360dp 回归明确失败：预期 3 个选项，实际固定显示 4 个，包含不支持的 5。原始 RED 在 `build/validation/grid-column-options-20261008/red.log`。
- 360/390dp、保存 5 的窄屏投影与扩宽恢复、点击持久化、大字号详情、无分组纯封面、可见分组、真实 controller 路由、设置内边距、手机横屏、1200dp 宽屏内容上限与极窄 1 列容量均有回归。
- 设置入口、偏好存储、真实书库、嵌套分组、首页系统栏、设置页与更新日志分别在独立 Flutter 进程运行。9 个文件共 78 项通过（密度文件 15 项，其他 8 个文件 63 项）。真实字体截图的同一密度文件另跑 15 项通过；没有降低断言。
- 本批 9 个 Dart 文件静态分析无问题，格式检查与 diff 检查通过。独立代码评审无阻塞；完整 HomeShell 入口的 controller 路由及 legacy rail 设置侧未单独新增专门用例，已有真实 controller→设置路由、共享几何与首页回归覆盖。全仓分析中途遇到其他话题尚未同步的 cancellation API fake override，冻结后已全部修复：最终分析无 error/warning，仅三条既有 info。跨话题功能回归去重共 323 项通过，另有真实字体截图 15 项与 Python 17 项。架构预算检查保持全部断言：新改服务恢复到 798 行，仍有既有 bootstrap program 912 行超过 800 的历史预算（基线相同），单独记录，不冒充产品构建失败。
- 可选截图通过真实 Flutter 页面渲染，正常 CI 无截图目录环境变量时不加载系统字体或写文件。截图使用系统预览字体，仅用于排版判断，不等于手机玻璃效果或实际操作验收。
- 更新构建号 `261008006` 并生成应用内更新日志；生成器及发布版本规则共 17 项 Python 回归通过，stateful CI 清单检查通过。

## 设备交付边界

正常入口 `lib/main.dart` 的 iOS、Android Release 均构建成功，基于源码提交 `aae2683109511e64b6f8f320c6846e21ef5ad311`。构建前后源码完全一致，共享源码 SHA-256：`1d607439dcd83ab20f3abd0d7cec305b89b938960a79d1b6ce3ede33fc8e5073`。745 个 Git 管理的运行输入与不可变构建快照逐一匹配，Android 原生输入另做独立校验。正常安装包包含本批列数修复和[书源退出/调度修复](2026-10-08-source-exit-anr-validation.md)，没有用旧快照覆盖共享改动。

- iOS：`SloanePro / iPhone 16 Pro` 原位更新为 `com.niki.xxread / 2.7.3 / 261008006`。严格签名校验通过，激活启动与进程 `15726` 的可执行路径匹配；AOT SHA-256 为 `5529effc936bb304856b3be0fbe52ff43e5b9b6af023d14c9d601d872b8efa02`。收据在 `build/device-ios/grid-column-options-20261008/` 及其 `device-acceptance/`。
- Android：`OPPO PKT110` 原位更新到同版本。保留既有签名、首次安装时间和数据目录；安装 APK SHA-256 回读完全匹配 `da8891a16bf6828fd601d2bbfc351fc5f665a699f7f981f67eb45e280d1e48ed`。进程 `672` 与 `ResumedActivity` 已核对。AOT SHA-256 为 `8540848d19ff7ddcbe07dd2c2c52dfb3cda1b3a941ff7bd401480096e9a49f16`，启用 `--split-debug-info` 并保存对应符号。收据在 `build/device-android/grid-column-options-20261008/`。
- 两个平台的 `build/device-*/latest-unified.json` 指向已安装并验证启动的 006 收据。当前 Mac 是 `sloane.local`；Windows 以 fast-forward 同步到共享源码提交，保留未跟踪文件。

渠道为开发者直接签名 Release，独立于 TestFlight、App Store 和正式公开 Android 发版。安卓继续使用设备原有开发证书（优化后的 Release 代码，非 debuggable），以保留数据。安卓截图采集时屏幕 Dozing 且锁屏，黑图仅记录屏幕状态；已验证进程与活动，不声称用户已验收物理 UI。两台手机的实际列数、操作手感和真实书源 ANR 复现仍需用户体验。

此前 `261008005` 安卓包已原位安装到 OPPO PKT110 并启动，安装 APK SHA-256 为 `324478f48e8803f980fd2f09f39de16093f734a3ee6c20c9a37f2dd917029b73`，安装前后 `firstInstallTime` 与数据目录保持不变，收据在 `build/device-android/unified-20261008/acceptance.json`。该设备原包使用 Android Debug 证书，交付包用相同证书签署优化后的 Release 代码，以保留数据；它与正式公开发行证书渠道不同。此记录仅证明旧 005 的安装与启动，不能代替本批 006 的交付证据。

其他话题的书源卡顿与详情入口已冻结并纳入同一 006 包；归因、请求隔离、位置保存回归及实体卡顿验收边界见上述书源记录。四个用户预览 JPEG 保持未跟踪且未修改。
