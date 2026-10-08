# 邀请活动界面实际渲染

来源：`flutter test tool/preview_referral_campaign_test.dart`，直接渲染生产邀请页面，使用示例服务器数据（3 位有效好友、1 位首次付费好友、已领取 30 天），不代表真实账号或上线活动。

- `mobile-light.png` / `mobile-dark.png`：390 × 844，默认字号。
- `wide-light.png` / `wide-dark.png`：1024 × 768，分享操作横排，活跃与付费进度并排。
- `narrow-large.png`：320 × 568，2 倍字号。
- `english-large.png`：390 × 844，英文界面、2 倍字号；服务器示例活动名称仍为中文。

截图采用 2 倍像素密度。大字号保留自然换行和滚动；共享浮动顶栏在极大字号下仍按既有规则截断长标题。预览测试还验证奖励记录二级页可进入且没有布局溢出。
