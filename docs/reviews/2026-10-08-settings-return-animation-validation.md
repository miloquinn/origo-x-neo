# 设置返回动画：调查、清理与真机测量

日期：2026-10-08。用户场景：设置首页打开偏好设置，再点击返回，偶发顿一下。

## 结论与证据边界

偏好入口采用普通 MaterialPageRoute，iOS 走 Flutter 标准 Cupertino 转场，
与阅读器自定义动画无关。不能据此说偏好整页每帧都重建。
此次确认并清除了首页的过宽通知订阅与重复系统栏恢复。

SloanePro 原生 Profile 实测显示：常规 UI 工作小于 120Hz 的 8.33ms 预算，
返回开始阶段仍有少量 raster 峰值，几乎每次第二帧约 11.6–13.6ms。
这说明该场景不能仅用“Dart 代码执行慢”解释；两层实时玻璃背景参与绘制，
但 FrameTiming 无法进一步区分纹理分配、raster cache 或具体 Gaussian pass。
精确的 Metal/Impeller 起始峰值原因仍需 GPU trace，不能宣称全部掉帧消失。

## 已完成的代码清理

| 文件 | 改动 |
| --- | --- |
| lib/pages/home/home_shell_page.dart | 在 build 中 select 导航配置，按语言/目的地顺序真实变化维护原缓存；删除全量 watch 和每 build 的系统栏回调 |
| lib/pages/home/parts/home_shell_layout_part.dart | 删除重复的路由判断及两套系统栏 helper；保留其他话题的书架修改 |
| lib/widgets/page_system_ui.dart | 复用原子页逻辑，统一首页与子页的系统栏所有权；仅当前路由、亮度与前台恢复时写入，保留 AnnotatedRegion |
| lib/widgets/floating_subpage_scaffold.dart | 使用共享 PageSystemUi，删除原私有重复实现 |
| lib/utils/page_transitions.dart | 删除 131 行未被外部使用的 fade/slide-up/旧 reader 工厂与扩展；旧 reader 包含空占位页面；保留活跃统计页、即时与阅读器转场 |
| test/home_shell_system_bar_test.dart | 30 次无关通知不重建整壳，导航重排仍更新 |
| test/floating_subpage_scaffold_test.dart | 同亮度父重建不重复写 SystemChrome |
| test/page_system_ui_test.dart | 覆盖路由恢复、被遮挡时不写、亮度与前台恢复 |
| tool/benchmark_settings_return.dart | 原生 Profile 诊断入口，调用真实应用，点击真实设置入口，保存实际 FrameTiming JSON |

没有新依赖、没有修改玻璃强度/shader/布局，也没有改变设置键、权限或阅读器
转场。版本/旧平台 shader 的回退是原有兼容边界，保留原错误记录。
没有用静默异常、跳过测试或延迟用户保存来掩盖问题。

## 原生 Profile 对照与被撤销的方案

设备：SloanePro，iPhone 16 Pro，UDID 00008140-001979421E93001C。
报告显示屏刷新率 120Hz。两轮均为 12 次真实偏好页返回、731 个动画帧；
按 FrameTiming.vsyncStart 与 Timeline.now 的实际返回窗口分组，报告 UI/raster
阶段耗时。统计超预算帧数，不能称为直接测得的屏幕掉帧率或独立 GPU 时间。
该场景是重复点击返回；不代表用户所有阅读页面、后台负载或拖拽操作。

| 指标 | CPU 清理后的实时转场基线 | 双页返回快照实验 |
| --- | ---: | ---: |
| UI p50 / p90 | 0.419 / 0.724ms | 0.517 / 0.695ms |
| UI max | 4.771ms | 20.670ms |
| UI > 8.33ms / > 16.67ms | 0 / 0 | 12 / 11 |
| Raster p50 / p90 | 2.235 / 3.040ms | 0.443 / 0.561ms |
| Raster max | 18.814ms | 9.913ms |
| Raster > 8.33ms / > 16.67ms | 14 / 1 | 5 / 0 |
| UI 或 raster 超 8.33ms 的唯一帧数 | 14 | 17 |

快照放在标准 Cupertino 位移以内，对上下两页使用 SnapshotWidget；仅在
返回/拖拽阶段启用，取消后释放，保留平台与 route optout。7 项回归通过，
但真机同步抓图把开销搬到 UI，增加了明显起始峰值，所以整个实验模块、
测试和入口改动已删除。最终分类入口仍为 MaterialPageRoute。
没有为了较低的 raster 平均值保留整体更慢的方案。

原始 JSON 与诊断安装/启动收据位于 build/device-ios/settings-return-20261008/。
首次无线 flutter run 没能连接日志服务，没有有效性能报告；后改为在应用
Documents 保存 JSON 并通过 devicectl 回读。比较基线已经包含 CPU 清理，
所以这些帧时间不是 CPU 修改的前后加速百分比。
代码审查建议不要相加两阶段超预算数。用原始样本回算唯一帧数为 14/17，
两轮 UI/raster 超预算重合均为 0。诊断工具随后补上所属 FlutterView、
逐帧 iteration/frameIndex/vsync timestamp、totalSpan 与唯一计数；该报告
已采样的两轮没有 totalSpan，新增报告字段未另做真机复测。

Flutter 官方资料：[性能测量](https://docs.flutter.dev/perf/rendering-performance)、
[SnapshotWidget 及抓图成本](https://api.flutter.dev/flutter/widgets/SnapshotWidget-class.html)。
具体实现同时核对当前本地 Flutter SDK 的 Cupertino、SnapshotWidget 与路由代码。

## 验证

- 首页 5 项、共享子页 7 项、系统栏 1 项、平板壳层 4 项通过。
- 设置页 19 项、设置工作量 14 项、阅读器打开/完成边界 4 项、书本转场 27 项通过。
- 首页旧实现的无关通知回归失败（PageView 实例改变）；清理后每次 notify+pump
  保持 PageView 与 shell Scaffold 实例，30 次均无整壳重建。
- 子页旧实现的同亮度父重建多写一次系统模式；清理后为 0。
- 初始系统模式/样式各写 1 次；遮挡页亮度变化写 0 次；返回正确恢复各 1 次；
  当前页亮度变化只更新样式，前台恢复正确恢复模式和样式。
- 有状态测试分别在独立 Flutter 进程执行。一次并行测试发生共享 native-assets
  工具竞争，串行重跑通过，没有为测试工具问题修改应用行为。
- 范围内静态检查、格式与 diff 空白检查通过。本轮锁定清理源码时的全仓检查为 3 条既有 info：
  source_chapter_state.dart:313、source_cookie_utils.dart:32、
  offline_reader_license_refresh_test.dart:9。无本次新增提示，不能记作全仓零问题。
- 独立最终代码审查 APPROVE，无 P1/P2；诊断报告的低优先级完善已落实。

## 统一设备交付

已核对另一个话题中用户要求“多个话题相互配合、一起装到手机”的原文。
004 阶段的正常应用由搜索框话题统一交付，已构建版本 2.7.3（261008004），显式使用
lib/main.dart，包括本次清理及已验收的其他话题改动；原位覆盖诊断入口且保留数据。
本话题 5 个产品文件的已验收 SHA-256 保存于 source-ready.json。

已独立回读 pill-search-fields-20261008/ 的 signed-build.json、source-before.json
与 source-after.json：748 个源码文件的构建前后指纹完全一致，本话题 5 个文件
全部匹配已验收指纹。聚合 SHA-256 为
67d291dde3a6dc9b139b5bcefd94247a818d6bda186f35c456145becdb99cf02。
再次执行 codesign --verify --deep --strict 成功；不可变 Runner.app 的实际
Info.plist 为 com.niki.xxread / 2.7.3 / 261008004，AOT 文件散列也与收据一致。

2026-10-08 最后一次独立 devicectl 检查显示 SloanePro 为 unavailable，
实机型号与 UDID 正确；收据为 final-device-status.json。统一安装负责人已向用户
请求重新连接设备。本话题未继续重启诊断入口，也未重复发出连接请求。
手机最后核验的应用仍为临时 Profile 2.7.3（261008001），不能记为最终修改已安装。
正常包已就绪，原位安装已实际尝试，但 install.json 记录 CoreDeviceError 4016：
设备可信连接不可用。尚未安装或启动，用户实体观感也未验收。
统一安装负责人在连接恢复后继续安装已保存的正常签名包并回传收据。
该交付属于开发签名的本地直接安装，未发布到 TestFlight 或 App Store。

随后各话题已合并到正常入口 `2.7.3+261008005`。用户明确手机不在，要求先完成
代码收尾，安装延期至回来通知后。004 的源码、签名和失败收据保留为历史；最终
代码、格式检查和签名包信息见[统一收尾记录](2026-10-08-unified-ios-delivery.md)。
