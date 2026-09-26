# App 审核资料草稿

这份资料用于准备审核信息，不代表已向 Apple 提交。提交前必须逐项按最终候选包复核。

## 审核操作说明（英文草稿）

Origo X is a local-first ebook reader. Local reading does not require an Origo
account, but App Store builds require either the optional 14-day trial or a
permanent app unlock. Import an authorized TXT or EPUB from Files to test reading.

The three non-consumable products are separate:
- `com.niki.xxread.reader.trial14d`: zero-price, one 14-day reading trial from the
  original transaction date; no automatic charge or renewal.
- `com.niki.xxread.reader.lifetime`: US base price $9.99, permanent local reading;
  purchase and restore require the Apple Account only, without Origo sign-in.
- `com.niki.xxread.premium.lifetime.v2`: US base price $8.99, permanent account
  Premium. This entry appears only after permanent app ownership, and requires
  Origo sign-in. A reading trial does not qualify. Premium enables more formats
  of user-imported sources and trusted private-network sources; it does not
  include books or source addresses and does not grant the app reading license.

Open Settings > Account > App unlock to trial, buy or restore reading access.
After permanent unlock, sign in and open Premium to purchase the separate account
upgrade. Prices shown by StoreKit are localized. Both purchases are one-time.
Reader restore uses the original Apple Account; Premium restore also requires
its original Origo account. Signing out of Origo keeps the app reading license.
Deleting an Origo account removes its Premium entitlement and leaves an anonymized,
terminal transaction record to prevent transferring the purchase to a new account.
Independent app ownership can still be restored. Existing purchases of the old
`com.niki.xxread.premium.lifetime` product retain their promised bundle access;
the new client offers the separate products for new purchases.

Sandbox receipts provide temporary verification access without writing production
entitlements. After relaunch, restore purchases to verify sandbox access again.
Provide a dedicated review account in the private review fields. Do not publish
personal credentials. Three new products currently have complete metadata and
READY_TO_SUBMIT status; this document does not establish approval or a completed
real-device purchase test. Submit them with the matching new app version.

Third-party content sources are added by the user. The official app does not
bundle a third-party source directory or commercial books. Provide a stable,
authorized sample source for review if source functionality is included in the
submitted build. Document all source and comic functionality honestly after
the separate source implementation is complete.

AI requests use a service configured by the user. Explain which content is sent
and where consent appears in the final build. Background audio is used for
reading aloud.

## 需要补齐的材料

| 项目 | 当前状态 / 完成标准 |
| --- | --- |
| 审核联系人 | 后台填真实姓名、电话、邮箱；不放在公开仓库 |
| 审核账号 | 后台私密字段填写；测试登录、多因素验证及权限，避免审核时被一次性验证码挡住 |
| 本地示例书 | 使用自有或已获授权的 TXT/EPUB，保证能离线导入；不拿未知版权书籍作为附件 |
| 书源/漫画源示例 | 等另一条开发线完成，用稳定且有授权的服务验证；注明联网与配置步骤 |
| 账号删除 | 客户端与线上 20260912-apple-account-review 后端均已实现；入口：设置 → 账号 → 账号安全 → 注销账号。本轮已覆盖独立阅读/账号高级版及终止交易的回归；仍需最终候选包真机全流程及录屏；后台所有者须先移交权限 |
| 内购 | 核实商品、价格、权益描述、税务协议，使用沙盒和 TestFlight 验证购买/恢复/退款 |
| 截图 | 重新采集 iPhone 与 13 英寸 iPad；现有宣传图包含 Android 状态栏 |
| 年龄分级 | 后台现有 4+，尚未按新增书源/漫画功能复核；按最终可访问内容回答问卷 |
| 发行地区 | 尚未确认；中国大陆备案、欧盟交易商资料由账号持有人根据实际情况提供 |

## App Privacy 填写依据

不要因为本地优先，或 `NSPrivacyCollectedDataTypes` 为空，就勾选“未收集数据”。
下面是按现有客户端/官网后端得到的核对项，最终申报取决于真实部署、保留期限、
第三方服务及 Apple 对 collected/linked/tracking 的定义。

| 数据 | 现有用途 | 提交前核对 |
| --- | --- | --- |
| 邮箱、显示名称、用户 ID | 登录、账号资料、会话 | 与账号关联；用于 App 功能；核对保留与删除期限 |
| 头像 | 用户主动上传的账号头像 | 照片或视频类别及服务器保留行为 |
| 购买记录 | 签名交易、永久会员权益 | 购买历史、与账号关联、退款后的保留依据 |
| 阅读文字、提问 | 用户配置的 AI 服务 | 第三方接收范围、明确同意、服务商是否保留数据 |
| 本地书籍、笔记、阅读统计 | 设备存储，可选 iCloud/WebDAV | 区分设备内处理、用户控制的同步、开发者可访问的收集 |
| 网络日志 | 官网与内容服务访问 | 核对真实服务器/CDN日志配置与保留期限，不凭客户端推断“不记录” |

需要一份公开可访问的隐私政策，说明开发者联系方式、具体数据用途、第三方共享、
保留与删除机制。2026-09-12 线上账号安全页已展示 `/privacy` 和 `/privacy-choices` 链接；需核对页面实际内容与 App Store Connect 已填写的 URL，不能再用落后的本地后端源码推断线上页面缺失。
内购授权绑定和退款处理也应与政策、会员文案一致。

Apple 参考：[账号删除](https://developer.apple.com/support/offering-account-deletion-in-your-app/)、
[App Privacy](https://developer.apple.com/app-store/app-privacy-details/)、
[审核指南](https://developer.apple.com/app-store/review/guidelines/)、
[截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)。
