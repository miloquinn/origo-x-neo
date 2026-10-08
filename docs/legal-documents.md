# 协议与隐私维护

当前契约：官网发布正文、App 原生呈现；法律内容变化不依赖重新发 App 包。包内快照只在发包时同步，联网或已有缓存的客户端可读取新的发布版本。

## 内容与接口

- 唯一编辑源：兄弟平台仓库 `app/legal/content.json`，中英文 catalog；官网页面、公开 API 与 App 包内资产共用该源。
- 六份文档：使用协议 `terms`、隐私政策 `privacy`、书源与第三方内容规则 `sources`、会员与购买条款 `membership`、隐私选择 `privacyChoices`、第三方服务说明 `third-party-services`。
- 匿名接口：`GET https://open.xxread.top/api/v1/legal/documents?locale=zh-CN`；`zh-*` 归中文，其他正文语言回退英文。请求不带账号令牌、设备标识或分析事件。
- `schemaVersion` 是渲染契约；`bundleVersion` 是整体发布；每份文档有 `revision`、`consentVersion`、`updatedAt`、`effectiveDate`、`changeSummary`。更新日期、生效日期与同意时间各有含义，不能混用。
- 正文只包含已支持的章节、段落、列表与链接；新增渲染能力仍需要客户端发布。App 校验 schema、语言、必需文档、重复章节、版本和安全链接；不执行远端脚本。

## 发布一次政策更新

1. 对照真实产品、服务与数据处理更新正文和简介。官网与 App 不另写一份正文。
2. 修改过的文档递增 `revision`，填写实际更新日期、生效日期和具体变更摘要；整体递增 `bundleVersion`。重要权利、数据用途或服务条件变更递增 `consentVersion`；排版和不改变含义的修订保留同意版本。
   会员、用户选择或第三方服务说明默认是说明文档；它们的变更若影响已经接受的服务条件或数据处理范围，还需同步更新对应的使用协议或隐私政策及其 `consentVersion`，保证原生同意检查能识别。
3. 保留平台 `app/legal/history/` 的已发布不可变快照。初次草稿尚未发布时可调整；已公开的同一 revision 不得替换正文。中英文需要接受的文档和同意版本保持一致。
4. 运行平台内容/API/官网验证后，按平台当前真实生产边界部署。验证公开文档、更新日期、接口、ETag 与 304，并确认现有账号功能保持正常。生产默认脚本与实际目标不一致时不能直接执行旧默认值。
5. 下次 App 发包前执行 `python3 tool/sync_legal_documents.py`，再用 `--check` 检查包内资产同步。官网内容更新无需立即重新发包；首次断网安装只能知道包内日期，不能宣称已经确认最新。

## App 所有权与导航

- [模型](../lib/models/legal_document.dart)：内容解析、版本、正文校验及快照摘要。
- [仓库](../lib/services/legal/legal_document_repository.dart)：完整 catalog 的读取、缓存与请求合并；不承担用户同意。
- [欢迎与同意](../lib/pages/legal/user_agreement_page.dart)：固定展示版本、更新提示、一次明确接受和设备本地 receipt。欢迎重播复用摘要但不写同意。
- [摘要](../lib/pages/legal/agreement_summary.dart)：欢迎页显示简介并导航详情。
- [文档列表](../lib/pages/legal/legal_documents_page.dart) 与 [原生详情](../lib/pages/legal/legal_document_page.dart)：设置及会员共用入口、版本/日期/变更说明、全文与章节阅读。
- [启动检查](../lib/main.dart)：先检查本地同意状态，再等待本次有界联网验证（或缓存/离线降级），确认当前同意仍有效后才启动账号和阅读同步。运行中获取到需要重新接受的同意版本时，暂停阅读联网并用独立协议导航覆盖根路由，保留原阅读页面；系统返回键只能返回协议详情，不移除隐藏的阅读路由。一次打开详情期间保持已展示文档稳定，更新通过明确切换。

启动同意检查完成前，[阅读云控制器](../lib/services/reading/reading_cloud_controller.dart) 必须以 `networkAllowed: false` 创建。此状态只读取本地阅读缓存、访客时长和待同步计数；定时器、账号监听、owner 监听、`initialize`、`synchronize`、公开偏好和访客记录认领均不得触发账号同步或阅读 API。主启动流程确认当前协议仍有效后，显式调用 `setNetworkAllowed(true)`，再调用 `initialize` 或 `synchronize`；开关本身不自动发请求。权限被撤回会使正在进行的同步代次失效，每次网络等待前后都重新检查，避免旧请求继续上传、读取榜单或保存偏好。

[账号控制器](../lib/services/account/member_account_controller.dart) 同样在生产 Provider 以 `networkAllowed: false` 创建。主流程同时开放或关闭账号与阅读许可；关闭时取消会员重试，并在共享 [账号 API](../lib/services/account/account_api_client.dart) 请求边界失效旧代次，防止旧响应继续刷新令牌或触发下一请求。权限暂停不会退出登录、清除凭据、删除会员缓存或变更账号归属。已经发送的单个请求无法撤回，其过时结果不能推动后续联网链。

## 缓存与同意边界

先读完整缓存，否则读包内完整快照；界面呈现后后台检查更新。缓存按接口来源和正文语言隔离，六小时内复用，用户刷新强制再验证；同语言并发共用一个请求。服务端 ETag 对应精确内容，304 只更新时间，不替换正文。

仅验证通过的整体 catalog 能写入一个持久化值。损坏缓存、网络/解析失败、错误语言、不支持 schema、版本倒退、同 revision 正文突变均保留可读旧版本。新版 App 的包内快照优先于更老缓存；缓存存储失败不会隐藏已获取正文。界面必须显示包内、缓存或已检查的状态，不能把离线旧文本当作刚确认的最新版。

同意 receipt 保存展示文档的 revision、consentVersion、正文 hash、更新/生效日期、语言和 UTC 接受时间。异步获取新正文不等于用户接受。重要新版本在点击时已知则先展示更新并要求再次点击；普通文字修订不自动改写旧 receipt。旧布尔同意标记本身不足以接受新版政策。

receipt 使用 `member_legal_acceptance_v1`，沿用备份排除的设备本地账户/隐私边界，不迁移到另一设备。公开内容缓存可以重建，不能授予会员或账号权利。

## 回归与限制

- [缓存回归](../test/legal_document_repository_test.dart)：离线、持久化重开、304、并发、语言隔离、损坏、拒绝异常发布及包内真实内容。
- [同意回归](../test/legal_agreement_receipt_test.dart)：旧标记、新版本、原样快照、语言、普通修订及清除边界。
- [欢迎回归](../test/user_agreement_page_test.dart) 与 [摘要回归](../test/agreement_summary_test.dart)：明确操作、多次点击保护、拒绝和多语言大字布局；状态相关 Flutter 测试隔离进程运行。
- [根路由回归](../test/legal_agreement_gate_test.dart)：运行中的重要协议覆盖既有阅读路由、系统返回与详情导航、接受后原路由保留。
- [阅读禁网回归](../test/reading_cloud_network_gate_test.dart)：未同意零网络、恢复授权、进行中撤销不再发后续请求。
- [账号禁网回归](../test/member_account_legal_gate_test.dart)：暂停共享传输、后台重试失效、旧 401 不刷新及登录/会员/凭据保留；[实际冷启动回归](../test/legal_startup_gate_test.dart) 验证等待政策、重要版本、普通修订和离线降级时的真实启动顺序。
- [入站回归](../test/incoming_book_service_test.dart)：处理中的外部文件在最终路由边界等待同意恢复，不重复导入或提前清除临时文件；销毁可解除等待。

文本仅说明当前真实功能与处理方式，不构成商店交易、法律审核或真机视觉验收证明。接口和原生页面完成后需要独立记录公开 HTTPS 验证、共享源码构建、SloanePro 原位安装和启动证据；具体手感与用户接受仍由真实设备流程验证。

[2026-10-08 验证记录](reviews/2026-10-08-legal-documents-validation.md) 记录首次官网上线、缓存再验证及 App 定向回归，后续维护仍以本文和当前实现为准。
