# 活动中心与在线详情

Status: 用户于 2026-10-08 授权实施；本地开发与验证，不代表新客户端已分发或生产已部署。

## 页面与更新边界

- 原生活动中心提供卡片、活动状态、简短介绍及「了解活动」「我的邀请进度」两个明确入口。使用现有主题、浮动子页、44px 触摸目标；窄屏和大字号按钮换行，不把长规则放入列表。
- 详情使用现有 url_launcher 的应用内浏览器（iOS 系统浏览器面板 / Android Custom Tabs），桌面回退系统浏览器，不新增依赖。网页可独立更新；不实现下载 Flutter 代码或任意 JS 原生桥。
- H5 仅展示公开活动内容，客户端不向网页传递账户 token、邀请码或个人资料。邀请进度、登录、领奖继续走现有原生账户页；未登录时提供原生登录入口，登录及双重验证完成后再打开进度。
- 第一次安装活动入口仍需要客户端更新。旧客户端的登录、购买、兑换不变；现有邀请协议与规则快照保持不变。
- 商店渠道可展示公告；邀请会员奖励继续仅在官方渠道显示，后台配置不能绕过客户端限制。

## 共享 API 合同

- `GET /api/v1/activities?channel=official|store` 返回 `{activities: [...]}`；缺省为 store。返回公开且 enabled 的条目，按 sort_order、id 稳定排序。
- `GET /api/v1/activities/{id}?channel=...` 返回活动详情；隐藏/渠道不符为 404。路径 `/activities/{id}?channel=...&v={revision}` 由客户端按自己的 API origin 构造，后台不接受任意跳转 URL。
- 条目字段：`id, revision, kind(announcement|referral), title, subtitle, accent(sky|mint|amber), starts_at, ends_at, state(upcoming|active|paused|ended), sort_order, channels, sections[{heading,body}], campaign`。
- `campaign` 仅邀请活动提供现有公开邀请活动配置，供 H5 展示实时门槛。默认邀请活动 id 为 `referral`；介绍/规则从现有邀请配置生成，奖励不复制成独立账本。
- `GET /api/admin/activities` 返回含 disabled 的运营条目；读取沿用 membership.read。
- `PUT /api/admin/activities/{id}` 创建/修改，body 含以上可编辑字段（不含 state/campaign）和 revision（创建 0）、reason。沿用 user.premium、CSRF、原子 revision 冲突检查和审计。referral 仅 official；最多一个 referral 且 id 固定 referral。日期必须带时区，结束晚于开始。
- 持久化使用现有会员 PostgreSQL 连接，独立 presentation 表及审计；幂等建表/默认邀请卡片，不改旧奖励记录。

## 运维与验收

- 后台支持发布/隐藏、排序、标题简介、配色、开始结束时间、内容分段和渠道。网页负责详情排版，内容数据保存后即可读取。
- 无本地旧文案兜底；离线/请求失败显示重试；页面恢复前台重新加载；过期异步请求不能覆盖新状态。
- 验证 API 权限/CSRF、默认渠道、商店过滤、隐藏活动、revision 冲突、时间状态、XSS 文本显示及邀请配置关联；原生窄屏/大字号/加载错误/链接 origin/平台回退/登录导航；网页桌面手机视觉与类型检查。
- 不在此次开发中自动重发 TestFlight、复制密钥、或更改现有活动资格与奖励政策。
