# 开卷与探元购买页修正验收

## 结果

- 两页的「恢复购买 / 我有兑换码」同行、等宽、至少 48px 点击高度；登录后兑换继续进入原有账号兑换页。
- 正文统一外边距；插画压缩到 174px。完整权益、购买说明、条款与隐私移入右上角「⋯」菜单，不再占正文或底部操作行。探元移除重复标题和重复永久已解锁状态。
- 已购状态条缩薄，正文到操作区间距由 20px 降为 8px；按钮仍保持至少 48px 点击高度。
- 已购页不再显示商品价格，操作紧跟正文，取消强制贴底产生的巨大空白。待购买页面保留固定底部主操作；短屏、键盘、大字号使用滚动布局。
- 后台商品加载状态与交易失败分开；已购页隐藏商品查询失败，但保留真实购买、验证、恢复失败。
- 试用和历史恢复商品缺失不阻断当前正式商品；当前销售商品全部缺失仍可重试，恢复流程不依赖商品查询成功。

## 实时商店证据

2026-10-04 使用现有 App Store Connect 工具进行只读 GET 核验：iOS 2.7.2 为 READY_FOR_SALE；开卷永久、探元完整、探元升级和历史永久商品均 APPROVED；14 天试用商品为 READY_TO_SUBMIT。公开会员配置仍包含该试用商品。

原代码要求同一权益域所有商品都返回，试用或历史商品缺失会误报「商店商品尚未配置或不可用」。未批准试用商品是截图提示的最强解释；未读取截图设备的实际 StoreKit 响应，不能确定该次返回缺失的具体 SKU。

## 修改文件

- `lib/pages/account/store_reader_unlock_page.dart`
- `lib/pages/account/premium_membership_page.dart`
- `lib/widgets/purchase_page_scaffold.dart`
- `lib/services/account/store_purchase_service.dart`
- `test/store_reader_unlock_page_test.dart`
- `test/premium_membership_page_test.dart`
- `test/store_purchase_service_test.dart`
- 计划：`docs/plans/2026-10-04-purchase-page-layout.md`
- 真实 Flutter 渲染：`docs/previews/purchase-layout-20261004/`

## 验证

各测试文件以独立 Flutter 进程运行：

| 文件 | 通过 |
| --- | ---: |
| store_purchase_service_test.dart | 17 |
| store_reader_unlock_page_test.dart | 19（含截图导出） |
| premium_membership_page_test.dart | 39 |
| membership_redemption_page_test.dart | 6 |
| store_reader_account_test.dart | 29 |
| account_service_test.dart | 74 |
| 合计 | 184 |

探元和兑换页自带的可选截图导出未启用；两页深浅色与购买/已购截图通过开卷测试的截图入口统一生成。所有功能断言保持启用。

用户第二轮修订后重新运行两页 58 项测试，覆盖菜单入口、隐私页直达、权益与购买说明跳转、底部按钮、大字号及窄屏；其余 126 项服务与账号验证沿用同会话前轮结果，该轮之后未修改这些模块。

- 修改范围 `flutter analyze --no-pub` 无问题；Dart 格式检查和 `git diff --check` 通过。
- 320px 窄屏、放大文字、德语长标签、键盘、兑换入口、账号切换和 Sandbox 权益测试通过。
- 已购深浅色和待购深浅色截图逐一检查。首轮独立代码审查无 P1/P2 问题；第二轮菜单与布局修改通过新增回归和渲染检查。

## 交付边界

本次完成本地代码、回归测试和渲染验收。未打包、提交或发布新的商店版本，未在用户实际 iPhone 上复测。工作区中其他阅读器、书源和版本修改保留。
