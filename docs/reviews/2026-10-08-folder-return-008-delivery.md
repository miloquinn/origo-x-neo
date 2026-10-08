# 书架返回修复统一交付 008 — 2026-10-08

两处可复现缺陷的修复位于 `lib/pages/library/library_shelf_transition.dart` 与 `lib/pages/library/parts/library_folders_part.dart`：暂停过渡时释放输入锁/快照，使晚到回调失效；本地 mutation 的立即加载覆盖已登记的重复通知，新外部事件仍独立处理。没有数据迁移、新依赖、卸载或登录变更。[调查与 40 项针对性回归](2026-10-08-folder-return-freeze-validation.md)记录了事实、归因边界和修复。交付更新了 pubspec、更新日志与应用内元数据；17 项版本/更新日志回归、生成检查及 stateful 清单通过。

## 同一源码的正常产品包

构建号 `261008008`，正常入口 `lib/main.dart`。基于产品提交 `2399fdb7f6daeac30204421575814002eb874f1b`，包含修复 `2446ef15` 与此前 007 全部改动。两平台构建前后源码不变，共享源码 SHA-256：`94364333c1e314b45d4f11dec981a89bc61588cd3b8fdf5d100bd1a537bf3119`。745 个 Git 管理的运行输入与 iOS 构建快照逐一匹配，Android 原生输入另行校验。

- iOS：Release 构建与严格签名验证通过；SloanePro / iPhone 16 Pro（`00008140-001979421E93001C`）原位安装 `com.niki.xxread / 2.7.3 / 261008008`，核对安装版本、激活启动和进程 16238 的可执行路径。AOT SHA-256：`499d1d04c0f35a675e20e6e9c9b393a98963ae9907520e042d312720ecab1787`。收据在 `build/device-ios/folder-return-20261008/` 与 `device-acceptance/`。
- Android：OPPO PKT110 原位安装同版本，安装前旧包与 007 收据哈希一致，安装后 APK 回读 SHA-256 与交付包一致：`f7b171908aa5ec7619591bc347c3586c168cf16cc689155df0af4679d7726581`。首次安装时间、数据目录保持不变，进程 9483 与 ResumedActivity 核对。AOT SHA-256：`44dc1662e31008bcce0f0f40f24e12097408f15d56796a2d4d48f73a67301af0`。符号与 AOT Build ID `b718850982e802e31ab8064216f9528b` 一致，独立保存在 `build/validation/folder-return-20261008/symbols/`，不覆盖 007。收据在 `build/device-android/folder-return-20261008/`。

渠道为开发者直接签名 Release，独立于 TestFlight、App Store 与公开 Android 发版。Android 使用设备原有开发签名，以保留数据；运行代码仍是优化后的非 debuggable Release。两端 latest-unified 指向 008。Sloane 本机与 GitHub main 已同步；Windows 已 fast-forward 到产品提交 `2399fdb7`，包含 008 全部运行代码。同步最后交付文档时 `milo-pc.local` 无法解析，备用 Tailscale peer 也离线，因此最新文档暂未同步到 Windows；设备安装不受影响。保留四张用户 JPEG 和 Windows 未跟踪文件。

## 物理点击边界

Android 屏幕 Awake 且已解锁。现有含六本书的目录完成“进入 → 返回上一级 → 再次进入 → 返回上一级”，五张截图逐一查看，标题/六本成员/根页返回与后续点击均正常，最后停在根页；没有创建目录或移动书籍。原始截图与点击序列保存在 `build/device-android/folder-return-20261008/physical-clicks/`。短时窗口内 PID 9483 保持运行、没有新增 ApplicationExitInfo ANR；18:48 的 PID 9030 历史 ANR不能用于新版归因。一次返回后 CPU 快照不能证明此前或长时不会卡顿。

“新建临时子目录、移入几本、进入、返回、恢复原成员”的精确可逆流程交由调查话题继续复测；iOS 物理点击与完整冻结复现场景也尚未验收。上述有限成功不等于完整解释或消除了用户报告的所有冻结原因。
