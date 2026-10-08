# 活动中心 SloanePro 安装

2026-10-08，用户要求每次完成 APP 修改后自动构建、覆盖安装并启动 SloanePro，供用户真机验收。该默认交付要求已写入 `AGENTS.md`。

## 构建与安装证据

- `flutter build ios --release --dart-define=ORIGO_DISTRIBUTION_CHANNEL=direct --dart-define=ORIGO_STORE_READER_LICENSE_REQUIRED=false` 成功，Xcode 构建约 65.6 秒；产物 `build/ios/iphoneos/Runner.app`，58.6 MB。
- 此包采用官方渠道，便于验收邀请活动；不是 App Store / TestFlight 发布。手机原先的商店渠道验收包被本地开发签名包覆盖，会员权益仍以原有账户服务判断。
- 安装身份 `com.niki.xxread` / `2.7.3` / `261008001`。本次未递增发布构建号、未上传 TF；版本号与上一包相同，安装收据、来源清单和代码摘要用于区分本次开发安装。
- 目标 SloanePro，iPhone 16 Pro，iOS 27.0.1，设备已解锁。使用 `devicectl device install app` 覆盖安装，没有卸载或清空应用数据。
- deep/strict 代码签名验证通过；安装后回读应用身份一致。前台启动成功，PID `12438`，随后进程查询仍在运行，路径与新安装收据一致。
- AOT 代码 `Frameworks/App.framework/App` SHA-256：`90ce7d743373b49c316f425bc4bf9ba0470910d7f4a056e2ea391b0d7ab8d077`。
- 构建来源为当前共享工作区，包含已存在的其他阅读/设置改动；没有回退这些工作。构建期间采集的 744 个源文件/资产清单在结束时无漂移；清单摘要 `0644296467fd96df09a0e79ae1343615d5d082eb55d4b414563041ccb24bd9c2`。该清单在构建启动后采集，不能作为冻结源码归档的替代。
- 本地忽略目录 `build/device-ios/activity-center-20261008/` 保留来源、代码摘要、安装、身份回读、启动及存活验证 JSON。设备私有元数据不提交到仓库。

## 真机验收入口

打开「设置 → 关于与支持 → 活动中心」或账户菜单的活动中心。「我的邀请进度」仍走原生页面；「了解活动」通过系统浏览器面板显示 H5。

本次已证明安装及前台启动，具体排版、触摸、浏览器打开和返回、真实邀请及支付由用户真机验收。服务端交付以平台仓库 `docs/reviews/2026-10-08-activity-center-production-rollout.md` 的实际部署收据为准。

## 服务上线后的交付

用户明确要求发布服务端后，活动中心 API 和 H5 已部署到实际生产 `aliyun-prod:/srv/open-reading/code-releases/20261008-activity-center-043546`。根代理独立通过公开 HTTPS 核对：健康四项 ok；official 活动列表包含 active 的 referral；store 列表为空；官方嵌入 H5 为 200，商店渠道详情为 404，活动响应均 no-store。以 Dart 客户端 User-Agent 请求官方列表同样为 200，排除仅浏览器可用的情况。

原邀请配置仍为 enabled=true / revision=2 / active，未修改奖励政策。服务上线后重新前台启动已安装的新应用，PID `12461`，再次查询确认同安装路径的进程存活。用户可直接在活动中心验收真实公开内容；未创建样例公告到生产，也未把网页 HTTP 成功当作真机触摸或支付验收。
