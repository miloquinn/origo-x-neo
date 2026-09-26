# 商店授权与官网高级版统一方案

## 当前产品规则（2026-09-26，取代下文旧打包方案）

实施与验收入口：[独立应用解锁与高级版](2026-09-26-independent-store-products.md)。

- 商店应用永久解锁 US$9.99，使用商店账号购买和恢复，无需 Origo 登录。
- 商店高级版永久 US$8.99，独立购买并绑定 Origo 账号。永久拥有应用后才显示入口；14 天阅读试用不能用于解锁高级版入口。
- 官网发行版自带永久阅读；高级版使用原有官网购买/卡密兑换，绑定 Origo 账号。
- 商店版使用对应原生内购，不显示自有卡密输入或官网购卡导流；登录可同步已取得的高级权益，但高级版本身不授予商店阅读使用权。
- 老客户按明确的旧购买/迁移记录保留既有承诺，不能用所有账号的 `premium=true` 推导永久阅读许可。

新 Google 商品已 Active：`origo_x_reader_lifetime` / `origo_x_premium_lifetime`，购买选项均为 `lifetime`。Apple 新商品为 `com.niki.xxread.reader.lifetime`、`com.niki.xxread.reader.trial14d`、`com.niki.xxread.premium.lifetime.v2`，价格已配置，仍需审核材料和审核。旧 SKU 保留兼容路径。

真实交易验收尚未完成。已送审 Google `260926001` 不包含本次权益拆分，不能用旧包验收新方案。完整后台标识/状态登记于 `/Users/xiaoyuan/certs/origo-x/store-billing.md`。

下文仅为旧实现历史；其中“永久购买包含高级书源”“账号试用”“登出撤销阅读”等不再是新产品规则。

规则来源：[Apple 3.1.1 / 3.1.3(b)](https://developer.apple.com/app-store/review/guidelines/)、[Google Payments](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)。

## 旧实现历史

状态：本地实现与回归已完成；Google Play 封闭测试候选 `2.7.1 (260926001)` 已完成隔离签名构建与本地校验，正在上传现有 Alpha 草稿。这不代表已发布或已向测试者推送；真机支付、恢复和退款验收仍待完成。

## 已确认产品规则

- 官网直接发行版：本地阅读和 ORSP 长期免费，现有高级版解锁更多书源格式和私有网络访问。
- Google Play / App Store 版：主动开始一次 14 天完整试用；到期后一次性购买完整使用权，包含高级书源能力。
- 商店通过各自内购交易，官网保持现有购买与兑换。商店不显示卡网导购或自有兑换入口。
- 永久购买继续映射现有 `premium`，不拆出重复收费商品。已有付费会员、活动权益及其到期时间保留。
- 商店试用单独记录，不能冒充永久会员，也不能让旧客户端或官网端错误获得高级版。
- 免费官网阅读是渠道许可，不是账号购买；不能因为登录官网免费账号而解锁商店。
- 老免费商店用户的阅读资格与高级书源权限分开；不因升级丢失既有阅读能力。
- 未授权仅阻止进入实际阅读；书架管理、本地书籍文件导出、笔记/高亮/划线导出、备份、登录、购买和恢复仍可达，已有数据不删除。
- 收费执行默认关闭。真实商店商品、验证服务、老用户过渡及设备测试完成后才能启用；这不是远端悄悄改变审核行为的开关，发行版规则必须明示。

## 实施边界与整理计划

1. 保留现有会员与 Apple 购买回归作为行为基线；补渠道、试用、恢复、过期、账号切换、退款和老客户保护测试。
2. 把 Apple 专用购买状态机整理为共用商店状态机；Apple 原生同步保留在渠道适配边界，Google 走其原生购买流及服务端凭据校验。删除替代路径，避免复制状态机或引入新依赖。
3. 渠道从 Apple/其他扩成 direct/googlePlay/appleStore，并贯穿构建脚本、购买页与阅读授权。
4. 后端增加 Google 订单验证/确认/撤销对账和商店试用记录。授权以服务端验证为准，禁止仅凭客户端成功事件授予权益。
5. 客户端集中计算阅读与高级功能许可；统一阅读路由拦截，不给每个格式各加一套门槛。
6. 维护本文及运维说明，记录尚待商店配置与物理设备验证的事项。

已发现的边界：原有未指定渠道的 Android 是官网版，保留兼容；显式错误渠道必须报错而不能静默进入卡网。网络临时失败可使用已验证且绑定当前身份的授权；UI 昵称/徽章缓存不是授权来源。恢复超时保留错误与重试，不能当成没有购买。

## 并行职责

- 主线：账号模型与 API、共用购买状态机、购买/试用界面、统一阅读入口和老用户迁移、最终集成验证。
- 渠道线：AppDistribution、渠道测试和构建/发行契约。
- 后端线：platform 仓库服务、接口、持久化和后端维护文档。

## 验收

- 官网基础阅读在未登录、断网、试用到期时均可使用；高级书源仍需原有高级权限。
- 商店只有有效购买、有效试用或旧用户阅读许可才能在收费启用后阅读；旧用户阅读许可不解锁高级书源。
- 同一账号重复开始试用不续期；换账号、登出、过期不会继承上一个账号的试用。
- 商店购买与恢复必须验证成功，待支付不能授权；退款仅撤销对应交易来源。
- 已购买/已有活动会员跨渠道沿用原权益，不降权、不诱导重复购买。
- 阅读受限时用户数据不删除，返回、导出和购买恢复可达。
- Flutter 状态型测试分进程执行；静态分析、相关构建契约测试与后端 ruff/pytest 单独报告。
- 商店后台配置、真实沙盒支付、退款通知/对账、物理设备离线重启及实际商店审核不由模拟测试代替。

## 对外产品口径

按安装渠道和实际能力区分，不按用户国籍、IP、语言推断收费方式。

| 安装渠道 | 基础阅读和 ORSP | 更多书源格式 / 私有网络 | 购买方式 |
| --- | --- | --- | --- |
| 官网 direct | 长期免费，无基础阅读试用倒计时 | 现有高级版解锁 | 官网原有购买与兑换 |
| Google Play | 免费下载，主动开始 14 天完整试用，到期永久解锁 | 同一次永久购买已包含 | Google Play Billing |
| App Store / Mac App Store | 免费下载，通过零价试用商品开始 14 天完整试用，到期永久解锁 | 同一次永久购买已包含 | Apple IAP |

产品售卖的是阅读软件和格式兼容能力，不是书籍、书源地址或内容访问权。无需“国内版/海外版”两套账号权益。官网下载的免费使用权不等于付费账号权益。

## 已落地的共同边界

- `AppDistribution` 显式区分 `direct`、`googlePlay`、`appleStore`。Play AAB 与官网 APK 分别携带正确编译参数；商店版不展示卡网兑换、依赖卡密兑换的邀请漏斗和外部打赏入口。Play 关闭 APK 自更新并从合并 manifest 移除安装包权限，官网保留。
- `StorePurchaseService` 接管原 Apple 购买状态机；保留 StoreKit 原生恢复，Google 使用相同购买、待支付、验证、恢复和错误处理流程。服务端验证之前不把商店回调当权益；Google 待支付不确认交易，后续付款事件不会被并发去重吞掉。
- `premium` 保持原有含义。`store_trial` 是一次性、到期不续期的商店体验。`store_reader` 只代表老用户基础阅读许可。登录后已有永久高级版不再重复收费。
- 依赖卡密兑换的邀请页面只在官网版展示，已有邀请奖励仍按后端原权益保留。试用商品必须为零价且与永久商品 ID 不同，配置冲突时在打开付款界面之前拒绝。
- 所有阅读入口由 `BookOpenTransition` 和 `StoreReaderAccessGate` 统一保护，先判许可再构造阅读器；授权过期会退出实际阅读内容并停止听书。书库管理、数据导出、账号和恢复购买仍可访问。
- 已核验的永久/限期阅读权益保存在安全存储，绑定安全登录会话；刷新令牌轮换时按同一用户重绑。试用的离线阅读期限严格保留服务端返回的截止时间。离线许可只让本地阅读继续，不伪造已登录身份或高级书源权限。
- 登出、换号或服务端明确拒绝登录时撤销对应许可；暂时断网不撤销已核验许可。离线期间无法即时获知退款，联网对账后撤销。修改设备时钟的抗篡改不属于当前离线许可机制保证。
- Apple Sandbox / Google 测试购买只在本次客户端会话解锁相同功能，不写正式 `premium` 或离线永久许可。Apple 沙盒试用按签名原交易时间加 14 天到期；重启后需要恢复购买重新验证。所有测试用户遵循同一规则。
- 新增商店提示已覆盖全部 10 个语言，不因英语以外界面遗漏试用条款或渠道说明。

数据访问的具体边界：书架长按书籍可导出笔记、高亮、划线为 Markdown，本地书籍文件也可单独导出；已配置 WebDAV 后可备份书架、阅读进度、书签与笔记。笔记/书签的查看、编辑和跳转列表仍位于阅读器中，阅读被锁时该列表不可达；当前没有独立的本地书签导出功能。本轮同时修正书架笔记导出使用已关闭底部面板 context 的问题，改为使用仍存活的书架页面 context。

## 老客户处理

| 旧状态 | 升级后处理 |
| --- | --- |
| 卡密、Apple、管理赠送等永久会员 | 保留原有永久权益，商店版同样可用 |
| 活动 / 有期限高级权益 | 按原期限继续生效，不能误转成永久或新的 14 天试用 |
| 迁移前已使用的免费安装 | 在首次迁移、展示新协议之前记录本地基础阅读资格；不赋高级书源权 |
| 新安装用户 | 先记录非老用户，之后同意协议也不会被误识别为老用户 |
| 老免费用户卸载重装或换设备 | 核对支持记录后，由后端私有 `store_reader` 工具补授权 |

本地迁移依据是迁移前已有 `userAgreementAccepted=true`，兼容旧协议版本；它是避免伤害升级用户的设备证据，不是购买凭据，也不能证明旧包的精确安装来源。旧官网包直接被旧商店包覆盖的历史来源无法凭这个值追溯。新官网包会记录非老商店许可，不能再靠后续切换到商店生成老用户资格。该标记随 `member_` 规则排除于应用备份，不能跨设备兑换。

不要用“注册日期早”批量授予高级版，也不要开放可由客户端自报领取老用户权益的接口。后台补授权、撤销和工单记录流程见 platform 仓库的 `docs/store-billing-and-trials.md`。

## 启用步骤与需要的材料

1. Google Play 永久商品已于 2026-09-26 创建为草稿：`origo_x_lifetime`，购买选项 `lifetime`（Buy，Backwards compatible），包名 `com.niki.xxread`。美国区 USD 9.99；173 个国家/地区使用 Console 批量换算价格。尚未激活，须完成服务端配置与测试准备后激活。应用继续免费下载安装，付费发生在内购；Console 已明确该免费应用不能改为付费下载。
2. 确认现有 Apple 永久商品；建立独立零价、非消耗型 `14-day Trial` 商品，提供确切 ID。试用不是自动续费订阅。历史永久 SKU 必须继续保留在服务器永久商品白名单中。
3. 将有本应用 Android Publisher 购买查询/确认权限的 Google 服务账号凭证配置到服务器私有环境。聊天与仓库只需要商品 ID，不接收或保存私钥。
4. 按后端文档先在可丢弃 PostgreSQL/Redis 环境验证 schema 和持久化回归，再部署兼容新增字段的 API。老客户端继续只读取 `premium`。
5. 用 Play 测试账号和 Apple Sandbox / TestFlight 完成购买、恢复、取消、待支付、重复交易、跨账号拒绝、试用到期、退款、离线重启和老用户升级。模拟测试不能替代这一项。
6. 配好 Google 退款可信轮询；确认 Apple 通知能分别撤销试用与永久交易，单笔退款不会误撤其他来源有效永久权益，也不会把试用订单回退成永久。
7. 开启后端相应 readiness / trial 开关，检查实际商品和接口；再在已向用户明确告知规则的商店新版本中启用 `ORIGO_STORE_READER_LICENSE_REQUIRED=true`。当前 CI 与构建脚本明确传 `false`，不会自动开始锁阅读。

后端详细环境变量、退款对账命令与老客户补授权命令，以 platform 仓库 `docs/store-billing-and-trials.md` 为维护入口。每次改变商品含义、SKU 或期限，应同时更新本文、后端文档和用户可见条款。

## 主要维护入口

| 职责 | 文件 |
| --- | --- |
| 渠道与构建开关 | `lib/services/core/app_distribution.dart`、`android/app/build.gradle.kts`、`.github/workflows/release.yml` |
| 权益、试用、账号撤权 | `lib/services/account/member_account_controller.dart`、`account_models.dart` |
| 共用购买与恢复状态机 | `lib/services/account/store_purchase_service.dart`（取代原 `apple_purchase_service.dart`） |
| 安全离线许可与会话轮换 | `lib/services/account/offline_reader_license.dart`、`account_api_client.dart` |
| 老免费安装迁移 | `lib/services/core/legacy_reader_access.dart` |
| 统一阅读拦截 / 听书停播 | `lib/widgets/store_reader_access_gate.dart`、`lib/utils/book_open_transition.dart` |
| 购买/试用/条款文案 | `lib/pages/account/premium_membership_page.dart`、`premium_policy_page.dart`、`lib/l10n/app_*.arb` |

## 本轮验证记录（2026-09-26）

- Chrome 登录态实查 Google Play Console：Origo X / `com.niki.xxread` 一次性商品列表为空；应用下载定价为免费，页面明确不能改为付费下载。Monetization setup 的实时开发者通知未启用且未填写 Pub/Sub topic，应用未加入替代支付或外部购买链接计划。该页面不能证明服务账号权限、收款资料或服务端凭证已配置；本次未修改任何 Console 配置。下一步需确定永久解锁售价后创建商品，并验证服务器购买查询/确认权限。
- 账号、试用、购买状态机、恢复、老用户、离线绑定轮换、会员 UI、渠道、转场和相关阅读器回归通过。商店 SDK 使用可控测试替身，不能据此宣称线上支付已通。
- 状态型阅读测试遵守 `.github/workflows/pr-checks.yml` 的按用例独立进程方式。曾整文件运行 `native_reader_initial_progress_test.dart` 复现共享缓存清理失败；本次改动的超长 TXT 恢复、EPUB 首帧恢复和 TXT 封面预加载用例独立运行通过，没有移除断言。
- 本轮账户/内购/授权生产与测试代码的静态分析无问题。全仓分析无 error/warning，仍有 7 条既存风格 info，位于书源章节/Cookie/听书和 native 阅读控制文件；未借本轮收费变更改写那些逻辑。
- iOS 构建工具 16 项、macOS 构建工具 21 项通过；生成文案完整覆盖 10 语言。
- Android arm64 调试产物已实构建：Play 使用 `googlePlay + readerLicenseRequired=true`，官网使用 `direct + false`。使用 APK 分析工具验证最终包权限，Play 不含 `REQUEST_INSTALL_PACKAGES`，官网保留。初版 `tools:node` 动态占位符在真实 merger 中失败，已改为 Gradle 在合并前生成字面量渠道 manifest 并重建验证。
- 两个验证 APK 与权限清单保存在忽略目录 `build/verification-store/`，不是上传包或正式发布：Play SHA256 `e238fee8f24afcfa9e672f92a36a5c24cf12287bb5ea543012f507366d560d15`；direct SHA256 `0660a91214d19bf94a70d4d3871fb98e98633d2eb76353c125ff8ed8f6dba7af`。
- Google Play Alpha 测试候选 AAB 使用干净 HEAD 快照叠加明确内购文件构建，未包含并行的 welcome/onboarding 文件或协议页视觉改版。产物 `build/verification-store/origo-x-google-play-2.7.1+260926001.aab`，105,756,103 bytes，SHA256 `684b4cacd58951e0681583e4879ea13eb18a2ae576a93101bc064e13f79e5ff8`。已校验包名 `com.niki.xxread`、版本 `2.7.1 (260926001)`、Billing 权限存在、`REQUEST_INSTALL_PACKAGES` 不存在、AAB 签名有效且与归档 keystore 一致。已上传并提交 Alpha 审核，尚未审核通过或发布。完整构建边界和文件校验值见同目录 `origo-x-google-play-2.7.1+260926001-build-receipt.md`。
- 重点回归计数：共用内购 40；账户服务 53；商店试用/离线/撤权 11；令牌轮换 5；会员界面 20、账户界面 10；渠道 12 及真实编译参数 1；试用模型 3、老安装迁移 3、阅读授权门 4。会员截图导出 4 项仅在指定截图目录时运行，本轮未当作验收通过项。
- 笔记导出对话框 2 项、书架导出入口独立回归 1 项通过。
- 后端追加使用本机已安装 OrbStack 创建的一次性 PostgreSQL/Redis 容器进行验证，没有安装新的宿主软件、挂载用户数据卷或连接生产数据库。真实数据库发现并修复退款恢复 SQL 的可空参数类型问题；完整结果与清理状态见 platform 仓库 `docs/store-billing-and-trials.md`。
- 后端最终全量 **472 passed / 1 skipped**；唯一跳过项需本机 Caddy 执行真实 origin admission，与支付持久化无关。原先因 PostgreSQL/Redis 缺失跳过的项目已全部实跑；两轮本任务创建的数据库容器均已清理。Ruff、compileall 和文档回归通过。

## Google Play 初始商品配置（2026-09-26；后续状态见下方）

用户确定永久解锁售价为 USD 9.99 后，已在 Console 保存 `Origo X Lifetime Unlock` 商品草稿，商品 ID `origo_x_lifetime`，购买选项 `lifetime`。页面确认状态 Draft，覆盖 173 个国家/地区，尚未激活、部署或开启阅读收费限制。

以 USD 9.99 批量生成地区价格，已核对：美国 USD 9.99、英国 GBP 8.99、德国 EUR 9.99、日本 JPY 1,720、香港 HKD 78.00、台湾 TWD 330.00。地区价格受汇率、税费和当地定价取整规则影响；这是配置时换算，不承诺随汇率每日浮动，也没有按购买力另设折扣。实际购买以 Google 结账页为准。

服务端待配置 `OPEN_READING_GOOGLE_PRODUCT_ID=origo_x_lifetime`；商品保存不代表服务账号、API 权限、退款对账或真实支付测试已完成。

本机商店标识与配置归档入口：`/Users/xiaoyuan/certs/origo-x/store-billing.md`，总索引为 `/Users/xiaoyuan/certs/INDEX.md`。新增或变更平台 ID、商品、购买选项、凭据位置与上线状态时同步维护；仓库不保存私钥或密码。

最新状态（2026-09-26）：Google `origo_x_lifetime` / `lifetime` 已 Active，许可测试账号已保存；生产 Google 凭据、Publisher API、Billing 和 14 天试用均已启用，撤销订单查询返回 HTTP 200。Alpha `2.7.1 (260926001)` 已提交，Console 显示 Changes in review，快速检查仍在运行；尚未提供给测试人员。真机购买/恢复/退款待验收。维护登记见本机 `certs/origo-x/store-billing.md`。

### Google Alpha upload verification

Build `2.7.1 (260926001)` is uploaded. Google parsed the expected version code, signed bundle and supported device set; preview reports Ready to release. The Alpha change has been submitted: Publishing overview shows Changes in review, with quick checks still running. It is not yet available to testers. Backend code and credentials are deployed; Publisher API and Google billing/trial flags are enabled and public health checks pass. Device purchase/restore/refund acceptance is still outstanding.
