# 独立会员卡 — Flutter 实际渲染

2026-09-27。取代旧的 single-membership 合并卡方案。

账号与购买卡分开，间距 14px。购买卡使用应用强调色和原创 Canvas 书页，展开 1.4 秒后静止；减少动态效果时直接显示最终帧。不引入图片素材或依赖。

- 未拥有永久开卷：`account-read.png`。
- 已有开卷 / 官网免费版：`account-upgrade.png`。
- 已有探元（含旧高级版）：`account-explore.png`，购买卡完全隐藏。
- 深色紫色强调色：`account-dark.png`。
- 320px / 1.6 倍文字：`account-large.png`、`account-english.png`。
- 德文：`account-german.png`。
- `opening.gif`：Flutter 每 70ms 实际采样的展开过程，播放一次。

验证：`store_account_entry_test.dart` 12 项、`settings_page_test.dart` 18 项、`settings_premium_access_test.dart` 2 项通过；三个状态型套件分进程执行。修改文件的 Flutter analyze 通过。预览使用系统 PingFang，权益与账号为测试数据；未在实体手机或新商店构建上验证。

复现静态截图及动画帧：设置 `PROFILE_SCREENSHOT_DIR` 与可选 `PROFILE_PREVIEW_FONT` 后运行 `flutter test --no-pub test/store_account_entry_test.dart`。绘图源见 `lib/widgets/membership_offer_card.dart`。
