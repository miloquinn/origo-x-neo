# 2026-10-08 反馈与性能摘要交付证据

本文记录当天的历史验证与交付；当前维护合同见 [反馈与诊断](../feedback-diagnostics.md)，版本、服务及设备状态以新收据为准。

## 交付范围

Android/iOS 提供主动问题反馈、默认关闭的轻量诊断，以及协议同意后的独立授权弹窗。弹窗披露固定字段、账号关联、自动摘要 30 天保留、隐私政策和设置关闭入口。同意/拒绝均为设备本地决定；保留旧版手动开启选择。关闭立即停采集并清待上传队列。反馈附带摘要另行选择，保留 90 天。后台侧边栏使用独立的用户反馈与性能统计页面。

## 服务交付

- 平台源提交 `b18640d0276f1b5a92942702c730a2bdcff987d6`，数据库标记 `2026100804`；先交付 `d67fb53` schema004 兼容桥，再切换功能候选，回滚前驱可继续读取同一数据库版本。
- 当前 `/srv/open-reading/code-releases/20261008-support-feature-b18640d`，Web/API 与 frontend 服务 active，ready 通过。服务收据 `/srv/open-reading/shared/deployment-receipt.json`。
- 公共检查：ready 200、法律目录 200，反馈/诊断 POST 和后台读取未登录均 401；两个后台页面导向登录页。隐私同意版本 `2026-10-08.2`。验证没有发送真实用户反馈或诊断记录。
- 后台 [用户反馈](https://open.xxread.top/milo/support) 与 [性能统计](https://open.xxread.top/milo/performance) 分别验证宽屏/窄屏、加载/空态/失败及反馈附件。预览截图保留在平台 `output/playwright/support/`。
- 冻结 feature 候选 54 项所属 Postgres、schema、API、法律回归通过；Ruff、i18n、Nuxt typecheck/build、维护文档 typecheck/build 通过。部署候选每一 manifest 文件均核对归档内 SHA-256。

## APP 验证

APP runtime 提交 `a1b080c9f6aff9069a2fe133e9e70b01d25678e8`，版本 `2.7.3+261008010`，正常 `lib/main.dart` direct Release。未通过测试入口替代产品包，也未卸载/清数据。

- 隔离回归：diagnostics controller 20、consent dialog 3、legal startup 6、feedback 5、settings 20；320px/1.5x 明暗 preview 2。新增回归覆盖法律门、paused/resumed、隐私文档导航、保存失败和旧授权兼容。
- 定向静态检查无问题；全仓库 Flutter analyze 没有新错误，仅原有三条 info。版本规则 8、changelog 检查和隔离测试 manifest 通过。
- iOS 隐私 manifest 与包内声明保持一致；客户支持、性能/诊断和用户 ID 声明为账号关联且非 tracking。Required Reason API 未改变。
- Android PKT110 原地安装并启动，APK SHA-256 与设备一致，dataDir 和 firstInstallTime 保持，PID 15797。iOS SloanePro（iPhone 16 Pro，UDID `00008140-001979421E93001C`）原地安装并读回 `261008010`；两次启动明确返回 Locked。已请求解锁，当前尚未完成此构建的 iOS 启动验证，不能使用上一构建的成功启动替代。

本次安装是开发者直接分发；不等同 TestFlight/App Store 发布。未替真实用户点击协议或诊断授权，未完成真实反馈提交与至少 20 分钟连续前台掉电验收。掉电率是整机电量下降估算，不能归因成 APP 独占功率；缺失指标保留为空。

两端源摘要相同：`6ce188c831d77d1e87db1c59cd68f5acb0af07e4b6cc77710d9e519bf59c7e37`。Android AOT 与符号的 Build ID 均为 `b718850943cfc6d71ab806423cbcc94a`。

## 收据及同步边界

忽略目录下保留：`build/validation/support-consent-20261008/verification.json`、两端 `build/device-{ios,android}/support-consent-20261008/signed-build.json`、设备 acceptance 收据及匹配 AOT 的 Android symbols 收据。生产公共检查在 `build/support-delivery-20261008/public-endpoint-verification.json`。

Sloane 本机 `sloane.local` 与 live remote HEAD 验证一致。Windows `192.168.1.10` SSH 多次超时，本轮无法快进同步，未覆盖其工作树。商店提交前还需核对完整 App Store 隐私问卷与既有云服务类型。
