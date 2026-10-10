# 书库整理与排序

书库顶栏的“整理书库”使用 `LibraryOrganizationButton`，手机、平板与桌面共用同一入口。菜单复用 `showGlassBottomSheet`，包含拖动整理、最近添加、最近阅读、阅读进度、手动顺序，以及原有全部/在读/已读筛选。自动排序提供两个方向；最近阅读时间未知的书籍始终放在已知时间之后。默认保持最近添加、新到旧。

## 手动顺序与交互

点击“拖动整理”切到手动顺序，清除搜索和阅读状态筛选，完整显示当前目录。长按书籍或文件夹即可混排，保存后仍留在整理模式；点“完成”或系统返回结束整理。当前层级独立排序，拖动不改变书籍或文件夹的归属。要整理子目录，先结束整理再进入。卡片和封面网格保留原有显示方式，拖动模式阻止打开书籍及长按操作菜单，并提供无障碍向前/向后移动操作。

自动排序时文件夹置顶，文件夹之间保留手动相对顺序；书籍按选定条件排列。切换自动排序不会重写手动位置，切回“手动顺序”即可恢复。未排过的旧条目保持文件夹在前、最近添加在前的默认行为；已排过的目录中，新添加或移入的条目接在已排序条目之后。

`library_organization.dart` 只处理排序，不查询正文、封面或逐书查库。页面投影缓存身份包括数据版本、目录、搜索、状态筛选、排序和方向；书源元数据更新也更新排序投影内的书籍快照。拖动由稳定的 viewport 接收，松手时按当前条目布局解析目标，避免自动滚动回收条目后落到旧位置。边缘自动滚动随拖动结束停止，反馈浮层只显示名称，不重复挂载封面的 GlobalKey。

## 持久化与阅读时间

数据库迁移 `ShelfOrganizationSchemaMigration`（v29）增加 `books.shelf_sort_index`、`books.last_read_at` 和 `shelf_folders.sort_index`，均可为空。旧书的时间只从有效 `reading_sessions` 回填，没有阅读证据则保留空值。升级和新建数据库均运行迁移；不把导入时间当作最近阅读时间。

`ShelfFolderDao.reorder` 要求提交当前父目录的完整且无重复成员集合，在一个事务内同时更新书籍和文件夹位置。跨目录移动、解散文件夹时清除旧排名；同目录移动保留排名。普通 `BookDao.updateBook` 不覆盖持久化的目录、手动顺序和阅读时间，避免缓存中的旧书对象覆盖新的整理结果。页面写入失败重新加载已保存数据并提示重试。

`ReadingActivityRecorder` 在一次阅读会话首次成功展示正文时记录时间。原生文字、在线文字、PDF 和漫画都接入；漫画/PDF 只接受当前可见图片成功解码，预加载或失败不算阅读。听书只在音频引擎真实开始播放时记录。分页、章节切换、重排、前后台切换和暂停续播不重复记录；试读加入书库后补记本次首次阅读时间。`BookDao.markRead` 只单调更新这个字段，不保存整份过期书籍对象。

排序方式和方向由 `AppSettingsNotifier` 的 `library_sort_mode_v1`、`library_sort_descending_v1` 保存。手动位置及最近阅读时间随[WebDAV 书架快照](webdav-backup.md)备份；[iCloud 同步](icloud-sync.md)通过旧客户端兼容的 setting 扩展记录携带新增元数据，既有 book/progress/folder 记录结构不扩展。缺少新增元数据的旧快照/同步不会清空已有位置或阅读时间。

升级后的首次同步会把旧客户端转发的整理 setting 导入数据库，并记录已导入版本，避免后续重放覆盖新的手动顺序。同步冲突中，整理元数据随所属书籍或文件夹一起等待选择；删除文件夹后，仍待选择的子项继续携带阅读时间，原目录排名按归属变化失效。确认删除的条目同步删除对应扩展记录。

## 源码与回归入口

| 范围 | 入口 |
| --- | --- |
| 排序规则、菜单与拖动组件 | `lib/pages/library/library_organization.dart`、`library_organization_sheet.dart`、`library_reorderable_item.dart` |
| 页面状态、保存与边缘滚动 | `lib/pages/library/parts/library_organization_part.dart` |
| 排名事务、迁移与最近阅读写入 | `lib/services/library/shelf_folder_dao.dart`、`lib/data/migration/shelf_organization_schema_migration.dart`、`lib/services/books/book_dao.dart` |
| 阅读/听书活动 | `lib/services/reading/reading_activity_recorder.dart`、各格式 reader、`lib/services/reader_aloud_session.dart` |
| 排序与偏好 | `test/library_organization_test.dart`、`test/library_organization_settings_test.dart` |
| 菜单、混排、搜索清除、失败恢复、静止自动滚动 | `test/library_organization_widget_test.dart` |
| 数据事务、旧库升级与备份/同步兼容 | `test/shelf_folder_dao_test.dart`、`test/book_dao_storage_paths_test.dart`、`test/webdav_backup_test.dart`、`test/icloud_sync_store_test.dart`、`test/icloud_sync_controller_test.dart` |
| 真实内容就绪与音频开始 | `test/reading_activity_recorder_test.dart`、`test/reading_activity_reader_test.dart`、`test/image_reader_activity_ready_test.dart` |
| 实际组件布局预览 | `tool/preview_library_organization.dart` |

涉及 SharedPreferences、平台通道、数据库或全局事件总线的 widget 套件使用独立 Flutter 进程。测试和布局截图不能代替真实 Apple ID 双设备同步及实体设备拖动验收；安装/启动收据与这些功能验收分别记录。
