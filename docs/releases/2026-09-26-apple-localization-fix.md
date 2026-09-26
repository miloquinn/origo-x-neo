# Apple 商店语言与中文名称修正

## 现场核验（2026-09-26）

- App：`6756944051`，Bundle ID：`com.niki.xxread`，主要语言 `zh-Hans`。
- 中国区公开 Lookup 返回线上 `2.7.1`，名称 `Origo X`，语言代码 `EN, ZH, ZH`。
- Flutter 包含 10 个本地化版本：德语、英语、西班牙语、法语、意大利语、日语、葡萄牙语、俄语、简体中文、繁体中文。
- 原 iOS 工程只打包 `en / zh-Hans / zh-Hant` 原生资源，未设置 `CFBundleLocalizations`；macOS 的 Base 名称资源原先未加入 Resources。
- 已上线 appInfo `539523cb-a731-4724-b57e-9c0e0c9f7c24` 的中文名称均为 `Origo X`。修改返回 `409 ENTITY_ERROR.ATTRIBUTE.INVALID.INVALID_STATE`，不能直接修改线上名称。

## 本轮修正

- 可编辑 appInfo `8df2a630-2063-4e5e-b00f-29f42bb968f7` 已保存并回读：简体 `开元阅读`、繁体 `開元閱讀`；其余 7 个商店本地化仍为 `Origo X`。
- 创建 iOS `2.7.2` 草稿 `3bf729a9-f725-4f24-b66d-9a51be0243cf`，状态 `PREPARE_FOR_SUBMISSION`，发布方式 `MANUAL`；未关联构建、未提交审核。
- iOS/macOS 工程补齐与 Flutter 一致的 10 个原生语言声明和打包资源。默认名称为 `Origo X`，简体/繁体名称按上述规则本地化。
- 新增 `tool/test_apple_bundle_localizations.py`：检查语言列表与 Flutter ARB 一致，以及名称资源确实属于 Runner 的 Resources。2 项测试通过；补齐未来语言时遗漏原生声明会使测试失败。

## 发布边界

这次保存和源码修复不代表线上已生效。需要包含本轮修复的新安装包通过审核并发布，公开商店名称和语言列表才会更新。

其他发布任务已有 TestFlight `2.7.2 (260926003)`，该旧包不含本轮语言声明修复；不能把它当作修正后的生产包。后续打包须保留该发布线的账号/独立计费修复，使用新的未占用构建号。

资料：[Apple 语言识别说明](https://developer.apple.com/library/archive/qa/qa1828/_index.html)、[商店元数据本地化](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information)。
