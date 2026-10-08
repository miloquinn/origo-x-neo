# 自定义阅读背景图

背景图属于用户文件，保存在当前 Application Support 的 `reader_theme_backgrounds/`，不属于可清理的阅读缓存。选择图片时复制文件内容，不依赖系统选择器的临时路径；单张最大 20 MiB，支持 JPEG、PNG、WebP。

## 保存、升级与显示

- `lib/services/core/reader_theme_background_service_io.dart` 写入 UUID 文件名，返回 `reader_theme_backgrounds/<文件名>`。运行时 `resolvePath` 映射到当前 Application Support。
- `lib/core/reader/reader_background_image_reference.dart` 负责稳定引用和旧绝对路径的识别。只处理受管目录内的直接文件，拒绝 `.`、`..`，其他外部路径保持原义；兼容 POSIX 和 Windows 分隔符。
- `lib/core/reader/reader_custom_theme.dart` 读取旧主题时将受管绝对路径转换成稳定引用，再次保存时写入稳定引用。主题 ID、排序、颜色、透明度和当前选择不变；读取损坏的 JSON 不覆盖原始偏好。
- `lib/widgets/reader_theme_background_image_io.dart` 在组件初始化和图片引用变化时解析路径，阅读过程的普通重建复用解析结果。阅读界面、主题列表和编辑预览经 `ReaderThemeBackground` 共用此处理。Web 保持原有不支持本地图片的边界。

iOS 更新后数据容器路径可能变化，保留的图片通过当前目录重新定位；Android 和桌面也使用同一稳定引用。图片缺失时继续显示主题底色，保留主题元数据，不把缺失误认为用户主动移除。

## 替换与删除

编辑器取消时只清理本次新选的暂存图片。保存替换后或删除主题后，服务只删除当前受管目录中的文件。列表用 `sameImage` 比较旧绝对路径和新相对引用，避免只改变路径形式时误删同一张图。

## 验证与限制

回归入口：`test/reader_theme_background_service_test.dart` 验证选择器复制、容器重定位、重启、路径边界、安全删除和元数据保留；`test/reader_theme_background_image_test.dart` 从旧主题偏好读取后实际解码 PNG，并验证普通重建和切换背景；`test/reader_custom_theme_test.dart`、`test/reader_themes_test.dart`、`test/reader_custom_themes_page_test.dart` 保护已有主题行为。状态型 Widget 套件分进程运行。

此兼容恢复依赖图片文件仍保留在应用数据内，无法恢复已被删除的图片。当前 [WebDAV 备份](webdav-backup.md) 保存主题配置，但没有打包背景图片文件；卸载后重装或跨设备恢复仍需重新选择图片。
