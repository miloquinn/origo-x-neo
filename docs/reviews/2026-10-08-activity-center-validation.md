# 活动中心与在线详情验证

2026-10-08。已完成本地实现、自动化回归和样例页面检查。本次未部署生产、未更新构建号、未发布新的 TestFlight，也未在真机验证新活动中心。

随后用户要求自动真机交付，已将官方渠道 Release 包覆盖安装到 SloanePro 并启动，未清空数据。版本仍为 2.7.3（261008001），未上传新 TF；安装与启动证据见 [SloanePro 安装记录](2026-10-08-activity-center-sloanepro.md)。上面的本地阶段状态不替代随后服务端部署收据。

用户随后明确要求服务端发布，API/H5 已上线至阿里云实际账号/API生产，公开健康、官方活动列表和详情均成功；商店过滤与 no-store 检查通过。SloanePro 上的新包已在服务上线后重新启动。平台的 `docs/reviews/2026-10-08-activity-center-production-rollout.md` 记录服务端来源、备份及回退边界；没有发布新的 TF。

## 实现范围

- 原生入口：设置的「关于与支持」、账户菜单；新页面 `lib/pages/activities/activity_center_page.dart` 展示活动卡片、状态、日期和明确的详情/邀请进度按钮。
- 公共数据与详情：`lib/services/activities/`、账户 API/controller；复用已有 url_launcher，按可信 API origin 生成详情 URL，不把账户凭证或邀请码传入网页。手机采用系统浏览器面板，桌面采用系统浏览器。
- 邀请进度继续复用既有原生页面和规则快照；未登录或双重验证未完成时先进入账户流程。商店版过滤邀请会员奖励卡片，公告仍可展示。
- 后端：platform 的 `app/activities.py`、`app/routes/activities.py`，以及数据库初始化和路由接入。展示配置独立存储，邀请门槛和状态关联已有邀请配置；隐藏入口不会停止邀请结算。
- 网页及运营：platform 的 `/activities/{id}`、`/milo/activities`、详情 composable、类型、权限菜单及三语言文案。详情分段呈现，规则按需展开；发布有 CSRF、版本冲突、修改原因和审计。
- 文档：本仓库计划与 DESIGN.md，platform 的 `docs/activity-center-operations.md`。已有无关开发改动均保留。

## 验证证据

| 范围 | 结果 |
| --- | --- |
| 新原生 API/链接/浏览器测试 | `test/activity_service_test.dart`：9 通过 |
| 新原生页面测试 | `test/activity_center_test.dart`：11 通过；覆盖失败重试、旧请求、登录/退出/MFA、渠道、浏览器失败及窄屏大字体 |
| 原生账户回归 | `test/account_page_test.dart` 独立进程：31 通过 |
| 静态分析 | 本次相关 12 组 Dart 文件：无问题 |
| 原生视觉采样 | 生产 widgets 配合明确的样例数据，390px 明/暗、1024px、320px 两倍中文字体、390px 两倍英文字体，截图脚本通过 |
| 后端活动与邀请专项 | 独立 PostgreSQL：33 通过，含并发创建、版本冲突、权限、CSRF、渠道和规则关联 |
| 后端完整回归 | 从 platform HEAD 加本次变更形成隔离源码快照；真实 PostgreSQL：573 通过，5 项 Redis 专用环境测试未运行 |
| 后端静态与合同 | 本次文件 Ruff 通过；API 错误翻译和 Markdown 回归 10 通过 |
| 网页构建 | Nuxt typecheck、production build 通过；1929 个文案键三语言一致性检查通过 |
| 浏览器验收 | 桌面、390px 明色、320px 暗色无横向溢出；嵌入模式无网站邀请进度链接；最新页面无 Vue/Nuxt warning 或 error |
| 运营闭环 | 在 localhost 样例后台修改标题并保存，成功提示可见，旧 `v=1` 链接读到最新标题；隐藏后同链接显示活动不可用，再发布后恢复；API、正常详情和渠道拒绝 404 均为 `Cache-Control: no-store` |

完整后端验证使用隔离快照，避免把共享工作区的邮件模板、部署文件等无关改动混入本功能结论。共享工作区曾有无关邮件模板测试失败，未为本功能改写该模块。测试产生的临时数据库、网页预览服务和浏览器标签在验证后清理。

## 视觉产物

`docs/previews/activity-center-20261008/` 下的 PNG 为真实原生组件配合样例数据；JPG 为 localhost 样例后台及 H5 的浏览器截图。样例中的「秋日阅读」没有发布到生产。

## 发布与维护边界

首次活动入口需要客户端更新；之后标题、说明、配色、排序和发布状态可后台修改，网页布局可独立部署。Flutter 原生功能仍需客户端发版。本实现未新增依赖、未下载可执行客户端代码，也未新增网页支付桥。

尚需正式交付阶段完成前后端生产部署、客户端构建与分发、iOS/Android 真机系统浏览器打开和返回验证。上述本地验证不证明 App Store 审核或真实奖励发放结果。生产邀请活动沿用既有政策，本次没有更改奖励门槛。
