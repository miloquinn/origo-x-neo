# SloanePro 活动中心渠道恢复 — 2026-10-09

用户在 SloanePro 报告活动中心显示没有活动。10 月 8 日活动中心验收使用官方 `direct` 渠道；10 月 9 日后续合并安装使用 `appleStore` 配置。当前邀请活动仅 official 可见，商店客户端请求 store 并再次过滤邀请卡片，因此渠道切换会使活动中心显示空列表。本次恢复本地官方渠道验收包，未修改产品代码、活动配置或商店渠道规则。

## 原因与边界

- `lib/services/account/member_account_controller.dart` 按 `AppDistribution.usesStoreBilling` 请求 `/api/v1/activities?channel=store|official`。
- `lib/services/account/account_api_client.dart` 无需登录获取公开活动目录；`lib/services/activities/activity.dart` 和活动中心页面再次按渠道过滤，邀请卡片仅 official 可见。官网登录失败与公开目录的认证依赖分开排查。
- 平台的 `docs/activity-center-operations.md` 说明邀请卡片只允许 official；生产当前活动是否发布，由本次平台公开接口及数据库检查确认，不能只引用昨日上线记录。
- 10 月 9 日最新 `shared-glass-cleanup-261009003/build-command.json` 显式配置 `appleStore`。本次使用 `direct`，不把 App Store/TestFlight 版本改成官网支付渠道，也不删除任何邀请记录或权益。

## 构建、回归与安装

- 来源为最新共享 checkout，Git HEAD `eeb40f5a3a44d066bc455bf43030489b0eb8a65c`。没有改动产品源码，保留其他聊天的全部功能与未提交活动截图。
- 活动服务测试独立进程 9 项通过，活动页面测试独立进程 11 项通过。
- `flutter build ios --release --no-pub --target lib/main.dart --build-number=261009003 --dart-define=ORIGO_DISTRIBUTION_CHANNEL=direct --dart-define=ORIGO_STORE_READER_LICENSE_REQUIRED=false` 通过，Xcode 构建 64.6 秒，`codesign --verify --deep --strict` 通过。
- 构建前、构建后、安装前及安装后 774 个产品输入文件完全一致，源码 SHA-256 `134112a4eba2ccd2e92b54470cc66b84288c7672bc5b4405e7e26b945955a916`。
- direct 产物 AOT SHA-256 `5508798a4cd41709eba70ab30649d90bff49be4727238b7e9e5995afb7e87ffa`。
- 设备核对为 SloanePro、物理 iPhone 16 Pro，UDID `00008140-001979421E93001C`。使用 `devicectl device install app` 原地更新，没有卸载或清空数据；安装后读回 `com.niki.xxread`、`2.7.3`、`261009003`，应用位置与安装结果一致。
- 渠道为官方 direct 配置的开发签名 Release，本地验收，未上传 TestFlight/App Store，未发布新 GitHub Release。无源码变化，因此保留现有版本和构建号，产物通过安装收据与 AOT 指纹区分。

## 启动与实机验收

覆盖安装后的两次启动曾被 iOS 以 `Locked` 拒绝（CoreDevice 10002、FBSOpenApplicationErrorDomain 7）。用户随后确认解锁，已直接前台启动现有安装包，无需重建或重装。启动收据显示 `activatedWhenStarted=true`、PID `25085`，独立进程列表确认同一 PID 与同一安装路径仍在运行。设备再次核对为 SloanePro / iPhone 16 Pro / 指定 UDID，读回的 bundle、版本、构建号及安装位置均与本次 direct 安装收据一致。

本次私有安装、设备身份、测试日志、源码清单及启动收据位于忽略目录 `build/device-ios/activity-channel-recovery-261009003/`；解锁后的证据为 `launch-after-unlock.json`、`installed-after-unlock.json`、`devices-after-unlock.json` 和 `processes-after-unlock.json`。`build/device-ios/coordination.json` 已标记本次安装与启动完成。安装期间的全局锁已原子归档至本次目录的 `installation-lock-completed`，不阻塞后续交付；后续本地验收仍须遵循当前版本指南的渠道保持约定。

前台启动和进程存活已验证。用户仍需打开「设置 → 关于与支持 → 活动中心」确认活动卡片、详情浏览器打开返回和原生邀请进度；尚未收到这项实机 UI 确认，自动化测试、安装及启动成功不替代它。官网的新 Google/GitHub 授权回跳亦单独等待用户确认。
