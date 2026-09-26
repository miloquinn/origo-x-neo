# 独立应用解锁与高级版

状态：用户已授权实施。覆盖 Flutter、账户后端和两家商店商品配置；不把配置草稿、模拟测试或编译当作真实交易验收。

## 已确认规则

- Google Play / Apple：应用永久解锁 US$9.99；高级版永久 US$8.99，单独购买并绑定 Origo 账号。
- 商店应用的购买、恢复和 14 天阅读试用不要求 Origo 登录。试用不授予高级版。
- 商店用户永久拥有应用前，不显示高级版入口，也不能发起高级版交易。试用不满足条件；后端同时检查永久阅读购买。
- 官网发行版自带永久基础阅读权限；高级版继续使用现有卡密购买与账号兑换。
- 商店版不加入自有卡密输入框；已取得的高级权益通过 Origo 同步，应用使用权仍需独立满足。
- 登出或切换 Origo 账号不会清除商店阅读许可。高级版不会自动赋予商店应用许可。
- 两家商店旧商品的已售承诺与恢复路径保持；新商品使用独立 ID。旧 `premium` 字段不能普遍推导为新阅读权。

## 改动顺序

1. 保留已有账号、交易和权限测试；补阅读与高级版互不授权、访客购买/恢复及购买前置回归。
2. 后端分离商店阅读交易与账号高级权益，复用 Apple/Google 验单；添加独立匿名阅读凭据和一次性试用记录。
3. Flutter 统一商店状态机分发不同商品；新增与 Origo 会话无关的安全缓存、阅读权限与恢复路径。
4. 将购买页拆成应用解锁与高级版，设置/账户入口按真实永久阅读许可展示；修正全部已支持语言的打包文案。
5. 分进程验证 Flutter 状态测试，运行后端检查，构建两平台并检查真实组件截图。配置准确商品 ID、价格、状态到证书维护目录。

## 恢复与离线边界

- 已验证阅读交易可以恢复到同一商店的另一台设备；交易关联多个安装，不把正常换机当成跨账号盗用。
- 高级交易只绑定一个 Origo 账号，使用后端幂等和归属校验。
- 退款分别撤销相应商品，不能互相误撤；匿名阅读缓存有明确刷新期限。
- Google 匿名试用按安装凭据记录，不声称能直接读取 Google 用户身份或保证跨重装每人一次。Apple 使用独立零价试用商品。
- 测试商店订单不写正式永久权益；测试许可不跨重启伪装成生产购买。

## 验收重点

官网永久阅读 / 商店未买 / 试用 / 阅读已买 / 高级已买 / 仅有高级 / 登出 / 换号 / 重装恢复 / 待付款 / 退款 / 网络失败分别验证。读者数据、导出与备份不因无许可而删除或阻断。

## 本轮实施与验证结果（2026-09-26）

- Google Play 两项新商品 Active：`origo_x_reader_lifetime` US$9.99、`origo_x_premium_lifetime` US$8.99，173 地区。旧 SKU 保留。
- Apple 新商品 `com.niki.xxread.reader.lifetime`（6816424044，US$9.99）、`com.niki.xxread.reader.trial14d`（6816423923，US$0）、`com.niki.xxread.premium.lifetime.v2`（6816424162，US$8.99）均 READY_TO_SUBMIT，175 地区，价格/中英文字/审核截图齐全；尚未提交审核。
- 后端已部署 `aliyun-prod:/srv/open-reading/code-releases/20260926T141509Z-split-products`。只覆盖 12 个计费相关 Python 文件，保留生产 cookie、邮件、前端、目录和库存锁；不发布工作区其他修改。
- 部署前备份：`/srv/open-reading/backups/20260926T141509Z-split-products`，含旧环境、previous-release、PostgreSQL/SQLite/头像备份。迁移为新增计费表及可注销的历史账本，不删除业务数据。
- 预检端口 3003 health 正常后切换 current；公网 `/api/health` 四项 OK，`/api/v1/membership/config` 正确返回两平台新 SKU 和 14 天试用。匿名 reader/status 在两平台返回 locked 和带签名凭据。未在生产伪造购买或消耗用户试用。
- 后端 PostgreSQL 全量 493 passed / 5 Redis-only skipped，聚焦数据库 38 passed；生产兼容候选 69 passed。Flutter 账号、入口、试用、恢复、缓存及沙盒测试通过，相关 analyze 无问题；Android debug APK 与 iOS unsigned release 编译通过。发布脚本测试 iOS 16、macOS 21 项通过。
- Apple 原生恢复按请求商品集合读取交易，不再只识别旧高级 SKU；旧 bundle 恢复等待服务端验单。退款墓碑不可被旧 JWS 复活或覆盖证据，注销账号保留不可转移账本，独立应用阅读可恢复。
- 测试阅读许可仅当前进程生效，独立于 Origo 登出；测试高级版仅当前账号会话生效。两者均不缓存为正式购买。过期试用不再展示“开始试用”。
- 完整标识、截图资产 ID、线上环境及 SHA-256 索引位于 `/Users/xiaoyuan/certs/origo-x/store-billing.md`、`manifest.json` 和根 `INDEX.md`。私钥不入源码。

尚待真实商店设备验收：免扣款测试卡购买、取消/拒绝、pending、重装/换机恢复、退款撤销和老客户购买迁移。编译、服务健康和商品元数据不等于付款闭环通过。Google 先前送审的 2.7.1+260926001 不含本轮拆分；本轮没有上传新测试包或提交 Apple 审核。

### 最终复核补充

最终线上目录为 `aliyun-prod:/srv/open-reading/code-releases/20260926T143112Z-split-products-final`，前一份完整拆分版 `20260926T141509Z-split-products` 保留。追加修复：同一账号存在多笔有效商店高级订单时，退款仅撤销对应购买，自动延续另一笔有效权益；旧 Apple 订单仍使用原 `Production:<transaction>` 引用，后续退款可以正确匹配。最后数据库持久化回归 29 项通过，独立审查无待解决代码问题；公网 health 再检四项 OK。

最终调试 APK：`/Users/xiaoyuan/code/origo-x/build/app/outputs/flutter-apk/app-debug.apk`，SHA-256 `137d2d9f81bf41ecac05914e7ade245232490e37c05f148791a103ac01209748`。它是开发测试产物，尚未上传 Play；iOS 产物为未签名 `build/ios/iphoneos/Runner.app`，未上传 TestFlight。应用版本名保持 2.7.1，本轮未发布新构建。
