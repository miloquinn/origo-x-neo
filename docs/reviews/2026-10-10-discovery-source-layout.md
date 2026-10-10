# 2026-10-10/11 发现页书源布局

当前维护入口：[发现页布局](../discovery.md)。

## 结果与范围

新增第三种书源布局，顶部显示当前书源，可在带本地搜索框的共享玻璃半屏菜单中切换。分类沿用生产横向懒列表及全部分类入口；新布局的两个菜单约为屏幕 55% 高度，滚动 viewport 抵达玻璃面板底边，末项避开 Home Indicator。布局偏好先于书源请求恢复，避免恢复书源布局前加载聚合结果。

复用现有书源客户端、控制器、分类加载、分页、请求代次、玻璃材质、搜索框和共享菜单。没有新增依赖或独立缓存。进入此样式清除隐藏的收藏/分组过滤，让菜单可以选全部可发现来源。无源、仅推荐/最新能力、移除/禁用来源及异步旧响应均有处理。

独立审查发现并修复了退出书源布局不立即重绘、以及分类菜单快照在移除来源后仍可请求旧来源的两个问题；都有针对性回归。

ORSP 来源显示其支持的“推荐 / 分类 / 最新”入口，Legado 兼容来源不显示这组分段栏，直接展示探索分类。沿用控制器已有协议索引，补充混合来源库来回切换与标准布局的 UI 回归。最后修正布局过渡标识以包含第三种布局，确保退出时内容滚动回顶部。

两个新菜单进一步简化为标题右侧同行搜索，只保留共享拖动条关闭入口，去除头部叉号。列表使用常驻右侧滚动条与专用控制器，保持懒构建和底部安全区；分类 picker 通过 `inlineSearch` 复用，标准布局不启用紧凑头部。针对 320px / 1.6 倍字体和键盘输入，验证同行几何、搜索框占满剩余宽度、无重复关闭、滚动条方向及控制器一致、真实分类选择和拖动取消。独立复核为 APPROVE。

## 软件证据

- controller 原有与新增单书源回归合计 35 项通过，新增 UI 6 项、共享分类胶囊 10 项、首页边距 11 项、共享 edge-to-edge 4 项通过。
- 原发现页 32 条 Widget 用例按独立进程验证，最终全部通过。最初两条组织操作失败已在干净 HEAD 上复现，后由组织界面维护任务确认 Undo 反馈在显示期间覆盖后续筛选按钮；提交 `7c232731` 通过真实横向手势先关闭反馈再继续操作，保留分组、筛选及后续 Undo 的全部断言，两条均独立进程重跑通过。历史基线收据为 `build/discovery-source-regressions/baseline-summary.json`，补充收据为 `build/book-details-20261010/discovery-feedback-validation.json`。并发 Flutter 测试会争抢 `build/native_assets/macos/libsqlite3.dylib`；相关工具链失败已按顺序重跑，不删断言或跳过用例。
- 范围静态分析、格式和 diff-check 通过。完整日志位于忽略的 `build/discovery-source-regressions/` 及 `build/discovery-*-test.log`。

## 原生与设备交付

原生预览通过 `tool/preview_discovery_source_layout.dart` 使用内存演示注册表、客户端和书架桩，在独立 iOS 模拟器上捕获生产页面与共享菜单。原生构建 `BUILD SUCCEEDED`，Impeller shader-filter 路径的 `shaderFilterSupported` 与 `shaderReady` 均为 true。主页面亮色、暗色及 320×740 / 1.6 倍字体的 viewport 均覆盖到底部；正常与窄屏菜单保持共享外壳的 8px 底部外边距，列表 viewport 到达面板底边，末项保留安全区。还捕获搜索筛选、分类末尾和真实 iOS 软件键盘。截图与逐场景几何见[原生预览收据](../previews/discovery-source-layout-20261010/README.md)。生产入口仍为 `lib/main.dart`；预览没有安装到 SloanePro。

最终 10 个自动场景与 1 张真实键盘截图已刷新并逐图检查。两个菜单的 `closeButtonCount=0`，常驻右侧滚动条有有效几何，同行搜索右边缘距面板为 16px。Legado 演示配置经生产探索解析器验证为有效的两项目录，原生主页面 `sectionTrackPresent=false`、`categoryControlsPresent=true`，其 viewport 同样覆盖到底部。

SloanePro 合并安装继续由现有唯一安装负责人执行。本项登记在 `build/device-ios/coordination.json` 的 `discoverySourceLayout`，来源提交和文件哈希进入组合源码门禁；在预览及所有并行来源定稿后，使用最新共享工作区、`direct` 本地开发签名 Release 原地更新并启动，不卸载、不清除账户或书籍。构建、安装、启动及用户真实书源/视觉/手感验收分别记录，尚未将预览当作真机验收。
