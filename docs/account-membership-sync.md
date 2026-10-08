# 会员状态缓存与同步

## 启动与展示

`MemberAccountController.initialize` 在协议允许联网后，先读取本地身份摘要、会员快照及签名阅读授权，再将 `initialized` 置为真并通知界面。页面无需等待网络或商店产品查询即可显示上次会员状态。

`membershipForDisplay` 优先使用当前会话的服务器结果，否则使用与身份摘要账号一致的会员快照。恢复快照要求本机仍有非 MFA 待验证状态的刷新令牌；快照内外账号也必须一致。`premiumForDisplay` 仅用于设置卡、账户徽章和会员说明，实时结果为非会员时立即覆盖旧快照。限时权益仍按到期时间失效，并调度界面更新。

本地 SharedPreferences 快照可以修改，因此不得用于购买校验或功能授权。`membership`、`hasPremiumAccess`、购买与兑换校验继续使用当前账号的服务器结果；离线阅读沿用账号及设备绑定、有时效的签名授权。身份摘要中的 premium 布尔值独自不能显示会员或授权。

## 联网与失效

登录配置与会话恢复并行；会话恢复后会员、阅读权益、邀请资料并行请求。启动在已恢复账号、商店配置就绪后仅监听未完成交易，不等待 StoreKit 产品查询；购买页面和明确购买/恢复动作按既有流程准备商店。商店或登录配置延迟不能阻止会员请求开始。

生命周期和阅读云同步共用 `synchronize` 的进行中任务。成功同步后五分钟内的被动重复调用复用已有状态；`synchronize(force: true)`、显式 `loadMembership` 和购买前校验仍请求服务器。临时失败保留已有显示与当前会话已验证权益，按既有重试间隔恢复；失败不会获得五分钟缓存有效期。

退出、失效会话、MFA 与账号切换清除或隔离旧快照。协议撤回保留本地数据，但禁用网络并使在途请求代次失效，旧响应不能重写已撤回后的状态。无令牌时清除身份及会员缓存，避免匿名状态显示旧账号。

## 维护入口与回归

- `lib/services/account/member_account_controller.dart`：本地恢复、显示 getter、并行启动、被动同步节流和过期通知。
- `lib/services/account/membership_cache.dart` / `account_summary_cache.dart`：会员快照与身份摘要存储，沿用现有格式以兼容已安装版本。
- `lib/widgets/settings_account_card.dart`、`lib/pages/account/account_page.dart`、`premium_membership_page.dart`：显示快照，有身份时不显示启动同步转圈；商店加载提示只对应实际商店操作。
- `test/account_service_test.dart`：阻塞网络时的首屏、配置独立性、实时覆盖、账号隔离、失败保留、被动请求次数及严格授权。
- `test/member_account_legal_gate_test.dart`、`store_reader_account_test.dart`、`offline_reader_license_refresh_test.dart`、`store_reader_access_gate_test.dart`、`store_purchase_service_test.dart`：协议、签名阅读授权、未完成交易监听和商店契约。
- `test/account_page_test.dart`、`settings_premium_access_test.dart`、`premium_membership_page_test.dart`：缓存徽章、重复购买入口及加载提示。含全局状态的界面测试分别在独立 Flutter 进程运行。

## 已知边界

五分钟节流仅在本进程成功同步后生效；冷启动仍在后台验证会话与权益。新安装或没有有效快照时需首次服务器结果。缓存展示不保证退款、撤销或另一设备变更已实时获取，明确购买动作必须重新校验。

2026-10-08 的匿名探测显示源站 HTTPS 约 75–81ms，经 Cloudflare 约 0.54–2.81 秒；Dart HTTP 未复现持久阻断。这些测量不能代表用户手机网络或已登录账号请求。不得据此关闭 Cloudflare：历史海外直连失败仍需保留可用入口。原始测量位于忽略的 `build/network-diagnostics/20261008-membership/network-diagnosis-receipt.json`。
