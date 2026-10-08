# Android 登录实机验证（2026-10-07）

## 交付

OPD2404 平板已安装当前工作区构建的 Android ARM64 调试包，版本 2.7.2（261007001），使用已登记的官网发布签名。没有发布商店或公开 Release。

最终 APK：`build/app/outputs/flutter-apk/app-debug.apk`。

SHA-256：`490057ea5ba85c8df956b96052247135d04e4c9d6dd1184b2dc7ef4545cbfb84`。平板已安装的 base.apk 校验值与本地产物一致。

旧包为 2.6.7（260908001），使用本机 debug 证书，与已登记的官网签名不同。用户授权重装后，先保存完整私有数据备份，再重装正式签名 debug 包并恢复书架、书籍、数据库和偏好；没有恢复旧 Flutter assets 或编译缓存。备份与恢复后的书籍文件数量均为 25，原阅读进度仍显示。完整备份保存在本机私有目录 `/Users/xiaoyuan/.codex/device-backups/origo-auth-20261007/tablet-app-data.tar`。

## 登录验收（北京时间）

- 原生 Google：新版实际展示 GMS 系统账号选择器；选择账号后返回 App，“我的”显示账号和权益。服务端在 17:34:58.471 创建有效 Google session，MFA 不挂起。
- GitHub：新版从更多登录方式打开浏览器；17:36:34.232 创建 challenge，17:36:35.343 接收 provider 回调，17:36:38.198 批准设备授权，17:36:39.931 App 兑换成功。App 自动返回已登录的“我的”，GitHub 与 device session 均有效。
- 强制停止并重新启动 App 后，进入“我的”仍显示 GitHub 账号和权益。
- 平板已实际启动已有 FlClash 配置，浏览器可访问 Google；最终登录在该出口下验证。最初 GitHub 授权页卡住的请求没有到达服务器回调；不能仅凭这一现象归因于服务器隧道。
- 平板系统曾阻止 App 打开 Chrome，已在系统提示中允许该跳转。多个待处理的 OEM 安装确认曾中断验收；最终重新安装并检查 APK 校验值后再执行两家登录。

## 服务端调查

阿里云实际进程使用 `socks5h://127.0.0.1:1080`，GitHub 不在 NO_PROXY 排除列表。香港 SSH SOCKS 隧道正常；相同 Python 解释器、运行环境能访问 Google token/JWKS 和 GitHub token/API。Google JWKS 返回 200，其他诊断请求返回预期的无效凭据响应。服务器配置、代码、服务和数据库没有进行修改。

这些验证证明当前网络和已安装包完成登录。没有证明最初用户反馈的每次失败都只有一种原因，也没有覆盖 Play 签名、iOS 或其他网络环境。

## 本次界面修改

- `lib/pages/account/parts/account_auth_part.dart`：删除无需手工输入的授权码卡片及相关私有参数。
- `lib/pages/account/account_page.dart`、`lib/pages/account/parts/account_auth_form_part.dart`：移除对应 UI 参数。
- `test/account_page_test.dart`：新增授权码不显示、进度动画和取消按钮仍存在的回归测试。

保留浏览器链接中的自动授权信息、会话轮询、回调、重新打开授权页和取消操作；没有更改登录协议。

## 检查

- Google 原生适配测试：4 项通过。
- 授权取消服务测试：2 项通过。
- 新增授权进度 widget 测试、既有 iOS 取消及错误提示测试分别在独立进程通过。
- 修改文件定向 Flutter analyze 无问题，git diff --check 通过。
- 最终 Android debug 构建通过并在平板实测两家登录。
- 完整 account_page_test.dart 在与本次删除无关的“Origo 探元”数量断言失败：期望 2，当前工作区渲染 1。未为了通过该断言修改用户其他界面工作；不报告完整套件全绿。
