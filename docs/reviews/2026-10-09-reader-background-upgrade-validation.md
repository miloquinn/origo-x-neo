# 2026-10-09 自定义背景升级修复验证

这是构建 `2.7.3+261009001` 的历史交付记录；维护入口见 [阅读背景图](../reader-backgrounds.md)。公开商店和 Release 尚未发布此构建。

## 修复范围

产品源码提交：`077cf2611b81c903291f968d1b12585b18f74df5`。旧代码将受管背景的完整绝对路径写进主题 JSON，并直接用此路径显示；更新导致数据容器路径变化时，保留的文件也无法显示。现改为稳定引用、当前目录解析、旧引用兼容及同图比较；没有扩大备份或上传数据范围。

主要文件：`lib/core/reader/reader_background_image_reference.dart`、`lib/core/reader/reader_custom_theme.dart`、`lib/services/core/reader_theme_background_service_io.dart`、`lib/widgets/reader_theme_background_image_io.dart`、`lib/pages/reader/themes/reader_custom_themes_page.dart`。共用引用识别替代保存、显示和删除各自依赖绝对目录的处理。

## 验证

- 五个独立 Flutter 进程，共 27 项测试通过。新增服务测试验证选图复制后删除源缓存仍可读取、旧容器重定位、稳定引用跨实例、安全删除、Windows 外部路径和主题元数据。新增 Widget 测试从旧偏好读取后实际解码 PNG，验证普通重建仅取目录一次，换图更新路径和图像。
- 原有主题模型、调色板和主题列表测试通过。全量静态分析没有错误或警告，保留此前三个无关 info 提示（书源两处、离线授权测试一处）；本次修改无新增提示。格式和 diff 检查通过，当前指南链接与源码/测试引用已核对。
- iOS 与 Android 正常 Release 产品构建和签名检查通过；构建前后产品源码指纹一致，两平台共用 `97e16ba7c0935d02853e657f891a231a47f026f41c9eff835e03c9ca35b66fb6`。

验证日志：`build/validation/reader-background-261009001/`；签名与安装收据：`build/device-ios/reader-background-261009001/` 和 `build/device-android/reader-background-261009001/`。这些为本地验收材料，不是公开发布渠道。

## 设备交付

- Android PKT110：原地从上一构建更新，实际 package versionCode `261011001`。安装前后数据目录与首次安装时间相同，设备 APK 散列与签名包一致；启动及前台进程 PID 7677 已验证。
- SloanePro：已核对为 iPhone 16 Pro、UDID `00008140-001979421E93001C`，原地安装，bundle version `261009001`。采用 Apple Store 渠道配置的开发签名 Release；不是 TestFlight。启动被 iOS `Locked` 明确阻止，已请求解锁；等待后再次启动仍为 `Locked`，尚未完成启动和实机背景视觉验收。

Android 已安装 APK SHA-256：`16df6b4a6aa910bd324b1d6901a5f7f4650efd79cdbb8a0420a9beed1f7fff67`。iOS AOT SHA-256：`e2dcffbad8812b3fa332199b959c78c256a16b8c1a9e55816ba314f075569245`。这两个指纹标识本次本地签名产物，不是公开 Release 的下载校验清单。

## 已知边界

没有打开用户私有书籍或更改真实用户的主题偏好，未验证其实际背景文件是否仍在磁盘；升级兼容的路径和 PNG 解码由临时目录模拟验证。文件已经被删除、卸载后重装或跨设备恢复缺少图片文件时，仍须重新选择图片。WebDAV 当前不打包背景图片文件。

源码已推送并核对 live origin/main。当前主机是 sloane.local，无需自我 SSH 同步；Windows `192.168.1.10:22` 连接超时，尚未同步。四张无关未跟踪预览 JPEG 保持原状。
