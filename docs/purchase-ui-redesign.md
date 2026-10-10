# 会员权益与开通界面

当前指南：2026-10-11。权益与账号同步以 [会员合同](account-membership-sync.md) 为准。此前 2026-09-27 的纸页/书封购买页和其截图属于历史视觉方案，不作为本轮实现或发布证据。

## 页面与风格

- `StoreReaderUnlockPage`：开卷主页、四项权益详情、购买/恢复说明。付费能力为 AI 助手、云端 TTS、漫画、自定义字体，不把基础文字阅读、系统朗读、书库或 ORSP 作为独占权益。
- `PremiumMembershipPage`：探元主页、完整权益、购买和条款；明确包含全部开卷功能，以及不限量其他协议书源和私有网络访问。普通与开卷账号的其他协议书源共用两个名额。
- `MembershipOfferCard`、`SettingsAccountCard`、`StoreReaderAccountEntry`：按照真实/展示权益决定开卷入口、探元入口或已拥有状态，GitHub 版的免费基础阅读不能伪装为已购买开卷。
- `PurchasePageTheme` 只统一按钮尺寸，沿用应用当前主题和语义颜色；`PurchasePageScaffold` 复用 `FloatingSubpageScaffold`、共享玻璃材质与底部操作区，背景延伸至系统底边，按钮避让安全区。短屏、大字、键盘使用整体滚动，不固定裁切购买操作。
- 主界面和二级页保留原商品、恢复、兑换、账号、限时/永久与支付状态；所有文案通过十种语言 ARB 与生成的本地化实现维护。

## 商店与校验

显示商店返回的当地价格，不写死价格。完整探元和开卷用户优惠升级为不同合法商品；恢复和退款由现有服务器验单及账号合同处理。GitHub/direct 采用同一功能校验，仅购买入口按渠道变化。没有新增依赖或另建会员缓存。

页面渲染、沙盒交易、真实扣款、商店审核、安装启动和用户验收分别记录，不能互相替代。当前用户要求先验收再发布；261011002 GitHub 发布工作流已取消，Apple 候选构建已 EXPIRED，Google Play 未上传 AAB 的草稿未提交。

## 回归与预览

隔离进程运行 `store_reader_unlock_page_test.dart`、`premium_membership_page_test.dart`、`store_account_entry_test.dart`、`settings_page_test.dart`、`settings_premium_access_test.dart`，覆盖三渠道、不同权益、恢复/验证中状态、当地价格、窄屏、大字、键盘和主题更新。账号与实际功能门禁回归见会员合同。

`tool/render_membership_redesign.sh` 使用正式 Flutter 页面和演示账户，依次导出手机/平板、浅深色及权益状态预览。该脚本不连接真实支付，不改变设备安装。视觉判定位于忽略的 `.omx/state/membership-redesign/ralph-progress.json`；本轮验证与签名安装证据汇总到 `docs/reviews/2026-10-11-membership-redesign-acceptance.md`。用户验收通过前，不创建发布标签、不上传或分发新商店构建。
