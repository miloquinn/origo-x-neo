# 2026-10-09 登录恢复与协议复查验证

当前维护入口：[协议与隐私](../legal-documents.md)。构建 `2.7.3+261009003` 的本地验证记录，公开发布和用户实机 Google 登录仍需独立证据。

## 事实与修复

截图提示由 App 本地网络守卫生成。平台 Google 登录请求只接收 identity token，当前服务端没有该协议错误或账号同意版本检查。只读 HTTPS 检查确认当前公开 catalog 为 `2026-10-08.2`，隐私同意版本 `.2`，使用和书源协议 `.1`；政策确实更新过，但无法据此推定截图用户的设备 receipt 缺失。

`lib/main.dart` 原前台恢复流程先撤销账号、诊断和阅读网络许可，再异步复查政策。Google 系统授权返回也触发恢复，导致正在进行的令牌交换因网络代次失效而抛出“请先同意最新协议”，即使政策并未变化。新实现删除复查前的无条件撤销，沿用确认重要政策更新后的统一关闭与协议覆盖入口；首次启动仍等待协议检查，已有凭据和用户数据保留。没有新增依赖、服务端改动或 Google 特例。

## 回归证据

修改前新增当前政策复查回归失败：恢复前台后网络许可变成 false。日志 `build/validation/legal-resume-261009003/pre-fix.log`。

修改后七个独立 Flutter 进程共 124 项通过：启动恢复 10、协议根导航 1、同意 receipt 5、账号禁网 5、账号服务 86、阅读云禁网 3、欢迎同意页 14。新增回归使用真实账号 API 和受控 HTTP 响应，在 Google 令牌交换期间模拟恢复前台及当前、普通修订、离线、重要更新四种结果，检查网络许可、协议入口、交换结果和凭据保存。重要更新使过期结果被拒绝且不写入 token；另外三种结果继续登录。既有首次安装、旧布尔标记、新 receipt 及重要更新导航断言保持。

并行独立进程曾因共用 native assets 目录造成一个套件签名文件缺失；该套件随后单独运行通过。此为构建临时目录竞争，不是产品构建或断言失败。后续验证避免同时生成同一目录的 native assets。

全库静态分析无错误和警告；保留三条此前无关 info。修改的 Dart 格式、diff 和包内政策资产同步检查通过。结果及日志：`build/validation/legal-resume-261009003/`。

## 交付边界

待发布元数据合并本修复与另一聊天的 iOS 常亮修复，继承 002 的朗读字体和 001 的背景图修复。最终 SloanePro 构建与安装由常亮聊天统一负责，共享协调收据 `build/device-ios/coordination.json`。合并后的 iOS Release 已通过产品构建与签名验证，并原地安装至物理 iPhone 16 Pro、UDID `00008140-001979421E93001C`；读回 bundle `com.niki.xxread`、版本 `2.7.3`、build `261009003`，启动 PID `21528`，后续进程收据确认运行。使用 Apple Store 渠道配置的开发签名，本地验收，未上传 TestFlight。

已独立核对 `build/device-ios/keep-screen-on-261009003/signed-build.json`、`source-final.json` 和 `device-acceptance/` 的应用身份、启动及进程输出。最终源码指纹 `a3eb344b5051b695d093dd64309101f0d2b21abd40ef58d8cb778dcaa183db92` 与交付收据一致，其中 `lib/main.dart` 的 hash 与本修复一致。构建基线 `be472090` 包含当时已完成但尚未提交的导航修改，交付后核对提交 `b972ecf3`；本次没有重装第二份包。不能把安装与启动当成实际 Google OAuth 验收；用户报告的 Android Google 登录与覆盖安装流程仍未在该用户设备验证。

当前主机是 `sloane.local`；源码完成后推送并核对 live remote。Windows `192.168.1.10:22` 连接超时，未同步。四张无关预览 JPEG 保留。

未取得报告用户安装的构建号、签名证书和设备同意 receipt；无法判定其覆盖安装失败原因，也未公开发布 GitHub Release、TestFlight 或 Google Play。
