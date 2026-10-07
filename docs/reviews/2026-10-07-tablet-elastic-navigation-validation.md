# 平板顶部弹性导航验证

## 实现与新增回归

平板共用已有 `FloatingPillNavigationSurface → ElasticPillNavigationBar → HomeBounceNavigationItem`，不新增平板组件。窗口达到平板布局条件后置顶，标签按设置显示；同排标题工具栏在两侧对称留出导航空间，空间不足时分行。导航保留超椭圆、原毛玻璃、按压膨胀和拖动高光。

`test/tablet_home_shell_test.dart` 补充真实壳层手势回归：按住时布局不变；高光在释放前跟随指针；释放前仍选中原页；释放后选中目标页；过程中导航矩形不移动。截图使用真实组件及演示书籍，未包含用户账号或真实阅读数据。

- 壳层横竖屏、窄窗口、大字号及键盘：4 项通过。
- 顶部 chrome 尺寸与弹性导航：15 项通过。
- 新增手势所在壳层测试的带字体截图采集：通过。
- 改动文件静态分析、diff 空白和知识库附件链接：通过。

## 安装与数据保留

Android OPD2404 平板，物理分辨率 2120×3000、密度 420，Android 16。旧 debug 2.6.7（260908001）与当前 APK 签名不兼容，先停止进程并保存本地数据，再替换安装 debug 2.7.2（261007001）。运行时 Flutter 资源由新 APK 提供；恢复后的 102 个用户数据文件 SHA-256 与备份一致。首次横屏前台截图确认顶部导航、原阅读记录和书库封面可见。

私有备份保留在本机 `/tmp/origo-tablet-validation-20261007/`，权限受限，不进入 Git 或知识库附件。

## 预览

- [顶部按压膨胀](../previews/glass-elastic-20261007/tablet/tablet-top-navigation-pressed.png)
- [拖动高光](../previews/glass-elastic-20261007/tablet/tablet-top-navigation-dragged.png)
- [竖屏顶部布局](../previews/glass-elastic-20261007/tablet/tablet-home-portrait.png)

复现捕获需要环境变量：

```sh
TABLET_SCREENSHOT_DIR=/tmp/tablet-preview \
TABLET_PREVIEW_FONT='/System/Library/Fonts/Hiragino Sans GB.ttc' \
flutter test --no-pub test/tablet_home_shell_test.dart
```

## 验证边界

用户持续操作平板账号页，自动手势会与手动操作冲突，已请求约一分钟独占操作窗口。实际平板连续拖动、旋转与菜单动态观察仍待该窗口；不将组件回归或静态截图宣称为完整实机动态验收。平板系统 screenrecord 命令被拒绝，后续可用截图观察关键状态。没有改变账号逻辑、设备安全设置或导航业务。正式发布和 GPU 性能量化未验证。
