import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/icloud/icloud_sync_controller.dart';
import '../../../services/icloud/icloud_sync_models.dart';
import '../../../widgets/app_skin_icon.dart';
import '../../../widgets/glass_buttons.dart';
import '../../../widgets/settings_panel.dart';
import '../../../widgets/floating_subpage_scaffold.dart';

String iCloudCopy(BuildContext context, String zh, String en) =>
    Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

class ICloudSyncPage extends StatelessWidget {
  const ICloudSyncPage({super.key});
  static const routeName = '/icloud-sync';
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    final title = iCloudCopy(context, 'iCloud 同步', 'iCloud sync');
    if (!isSupported) {
      return FloatingSubpageScaffold(
        title: title,
        body: Center(
          child: Text(
            iCloudCopy(
              context,
              '此设备不支持 iCloud 同步',
              'iCloud sync is unavailable on this device',
            ),
          ),
        ),
      );
    }
    return Consumer<ICloudSyncController>(
      builder: (context, sync, _) {
        return FloatingSubpageScaffold(
          title: title,
          body: ListView(
            padding: floatingSubpagePadding(context, top: 20, bottom: 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _syncPanel(context, sync),
                      const SizedBox(height: 26),
                      _sectionTitle(context, '同步内容', 'What syncs'),
                      const SizedBox(height: 12),
                      SettingsPanel(
                        child: Column(
                          children: [
                            SettingsInfoRow(
                              icon: Icons.auto_stories_rounded,
                              title: iCloudCopy(
                                context,
                                '你的书架',
                                'Your library',
                              ),
                              description: iCloudCopy(
                                context,
                                '书籍、子书架和排列，随设备一起接续。',
                                'Books, folders and library order follow you.',
                              ),
                            ),
                            const SizedBox(height: 20),
                            SettingsInfoRow(
                              icon: Icons.bookmark_outline_rounded,
                              title: iCloudCopy(
                                context,
                                '阅读足迹',
                                'Reading activity',
                              ),
                              description: iCloudCopy(
                                context,
                                '阅读进度、书签和笔记，回到上次读到的地方。',
                                'Reading position, bookmarks and notes, ready where you left off.',
                              ),
                            ),
                            const SizedBox(height: 20),
                            SettingsInfoRow(
                              icon: Icons.download_rounded,
                              title: iCloudCopy(context, '本地书籍', 'Local books'),
                              description: iCloudCopy(
                                context,
                                '正文与封面自动传输，占用你的 iCloud 存储空间。',
                                'Book files and covers transfer automatically using your iCloud storage.',
                              ),
                            ),
                            const SizedBox(height: 20),
                            SettingsInfoRow(
                              icon: Icons.tune_rounded,
                              title: iCloudCopy(
                                context,
                                '阅读与外观',
                                'Reading and appearance',
                              ),
                              description: iCloudCopy(
                                context,
                                '支持跨设备使用的阅读和外观设置。',
                                'Reading and appearance preferences that work across devices.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sync.conflicts.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        _sectionTitle(
                          context,
                          '选择要保留的版本',
                          'Choose the version to keep',
                        ),
                        const SizedBox(height: 8),
                        _caption(
                          context,
                          iCloudCopy(
                            context,
                            '设备离线期间修改了同一条数据。选定前，当前设备的数据会保留。',
                            'Devices changed the same item while offline. Current local data is kept until you choose.',
                          ),
                        ),
                        for (final conflict in sync.conflicts) ...[
                          const SizedBox(height: 12),
                          _conflictCard(context, sync, conflict),
                        ],
                      ],
                      const SizedBox(height: 24),
                      _caption(
                        context,
                        iCloudCopy(
                          context,
                          '应用在前台时自动检查改动，后台传输由系统安排。同时修改同一条数据时，由你选择保留哪个版本。',
                          'Changes are checked while the app is open; the system schedules background transfers. You choose which version to keep when devices edit the same item.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _caption(
                        context,
                        iCloudCopy(
                          context,
                          '应用登录、会员状态、WebDAV 密码和 AI 凭据留在本机。关闭同步会保留本机与 iCloud 中已有的数据。',
                          'App sign-in, membership, WebDAV passwords and AI credentials stay on this device. Turning sync off keeps existing local and iCloud data.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String zh, String en) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      iCloudCopy(context, zh, en),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _caption(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.55,
      ),
    ),
  );

  Widget _syncPanel(BuildContext context, ICloudSyncController sync) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SettingsPanel(
      key: const ValueKey('icloud-sync-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: AppSkinIcon.adapt(
                  Icon(Icons.cloud_outlined, size: 38, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iCloudCopy(
                        context,
                        '在另一台设备继续读',
                        'Pick up where you left off',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      iCloudCopy(
                        context,
                        '同一 Apple ID，连接 iPhone、iPad 与 Mac。',
                        'Your iPhone, iPad and Mac, connected by one Apple ID.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            key: const ValueKey('icloud-sync-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              iCloudCopy(context, '自动同步', 'Automatic sync'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              iCloudCopy(
                context,
                '开启后自动同步阅读数据',
                'Keep your reading data in sync',
              ),
            ),
            value: sync.enabled,
            onChanged: sync.busy
                ? null
                : (value) => unawaited(sync.setEnabled(value)),
          ),
          const Divider(height: 28),
          Semantics(
            liveRegion: true,
            child: SettingsInfoRow(
              icon:
                  sync.conflicts.isNotEmpty ||
                      sync.status == 'error' ||
                      sync.status == 'accountChanged'
                  ? Icons.info_outline_rounded
                  : Icons.sync_rounded,
              title: _statusTitle(context, sync),
              description: _status(context, sync),
            ),
          ),
          if (sync.busy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          if (sync.lastSync != null) ...[
            const SizedBox(height: 12),
            Text(
              '${iCloudCopy(context, '上次同步', 'Last sync')} · ${DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm().format(sync.lastSync!.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          GlassTextButton(
            key: const ValueKey('icloud-sync-now'),
            blurBackground: false,
            highlighted: true,
            onPressed: sync.enabled && !sync.busy
                ? () => unawaited(sync.synchronize())
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSkinIcon.adapt(const Icon(Icons.sync_rounded, size: 20)),
                const SizedBox(width: 8),
                Flexible(child: Text(iCloudCopy(context, '立即同步', 'Sync now'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusTitle(BuildContext context, ICloudSyncController sync) {
    final (zh, en) = switch (sync.status) {
      'accountChanged' => ('账号已变化', 'Account changed'),
      'unavailable' => ('等待 iCloud', 'Waiting for iCloud'),
      'pendingUpload' => ('等待系统上传', 'Waiting for upload'),
      'conflicts' => ('需要你选择版本', 'Choose a version'),
      'deferred' => ('等待接收改动', 'Waiting to receive changes'),
      'syncing' => ('正在同步', 'Syncing'),
      'error' => ('稍后重试', 'Will retry'),
      _ =>
        sync.enabled
            ? ('自动同步已开启', 'Automatic sync is on')
            : ('自动同步未开启', 'Automatic sync is off'),
    };
    return iCloudCopy(context, zh, en);
  }

  String _status(BuildContext context, ICloudSyncController sync) {
    final (zh, en) = switch (sync.status) {
      'accountChanged' => (
        'Apple ID 已变化，同步已暂停。重新开启以使用当前账号。',
        'Apple ID changed. Sync paused; turn it on again to use the current account.',
      ),
      'unavailable' => (
        'iCloud 暂不可用，请检查 Apple ID、iCloud Drive 和存储空间。',
        'iCloud is unavailable. Check Apple ID, iCloud Drive and available storage.',
      ),
      'pendingUpload' => (
        '已保存到 iCloud 本机空间，正在等待系统上传。',
        'Saved locally in iCloud Drive; waiting for the system to upload.',
      ),
      'conflicts' => (
        '部分数据需要你选择版本，其余改动会继续同步。',
        'Some items need your choice. Other changes continue to sync.',
      ),
      'deferred' => (
        '正在阅读或处理书籍，返回后接收其他设备的改动。',
        'Changes from other devices will be received after reading or book operations finish.',
      ),
      'syncing' => ('正在同步…', 'Syncing…'),
      'error' => (
        '同步未完成，本机数据已保留，稍后会重试。',
        'Sync did not finish. Local data is kept; it will retry.',
      ),
      'idle' => (
        '已开启，阅读数据会自动同步。',
        'Enabled. Reading data syncs automatically.',
      ),
      _ =>
        sync.enabled
            ? ('已开启，等待同步。', 'Enabled. Waiting to sync.')
            : ('尚未开启，不会上传阅读数据。', 'Off. Reading data is not uploaded.'),
    };
    return iCloudCopy(context, zh, en);
  }

  Widget _conflictCard(
    BuildContext context,
    ICloudSyncController sync,
    ICloudConflict conflict,
  ) => SettingsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _conflictLabel(context, conflict),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (_deletionHint(context, conflict) case final String hint) ...[
          const SizedBox(height: 8),
          _caption(context, hint),
        ],
        for (var index = 0; index < conflict.versions.length; index++) ...[
          const SizedBox(height: 18),
          if (index > 0) const Divider(height: 1),
          if (index > 0) const SizedBox(height: 18),
          SettingsInfoRow(
            icon: Icons.devices_rounded,
            title: conflict.versions[index].device,
            description:
                DateFormat.yMd(
                  Localizations.localeOf(context).toString(),
                ).add_Hm().format(
                  DateTime.fromMillisecondsSinceEpoch(
                    conflict.versions[index].modifiedAt,
                  ).toLocal(),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _preview(context, conflict.versions[index]),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: GlassTextButton(
              blurBackground: false,
              onPressed: sync.enabled && !sync.busy
                  ? () => unawaited(
                      sync.resolveConflict(
                        conflict.key,
                        conflict.versions[index],
                      ),
                    )
                  : null,
              child: Text(iCloudCopy(context, '保留此版本', 'Keep this version')),
            ),
          ),
        ],
      ],
    ),
  );

  String? _deletionHint(BuildContext context, ICloudConflict conflict) {
    if (!conflict.versions.any((r) => r.value == null)) return null;
    final kind = conflict.versions
        .map((r) => r.value?['kind'])
        .whereType<String>()
        .firstOrNull;
    return switch (kind) {
      'book' => iCloudCopy(
        context,
        '保留书籍会接续所选设备的改动；仍有冲突的书签和笔记会继续让你选择。删除只移除书架记录，原文件仍保留。',
        'Keeping the book continues the chosen device’s changes. Remaining bookmark and note conflicts still need your choice. Deleting removes the library entry and keeps the original file.',
      ),
      'folder' => iCloudCopy(
        context,
        '删除子书架后，里面的书籍和子书架会移至上一级。仍有冲突的改动会继续让你选择。',
        'Deleting a folder moves its books and subfolders to its parent. Remaining conflicts still need your choice.',
      ),
      _ => null,
    };
  }

  String _conflictLabel(BuildContext context, ICloudConflict conflict) {
    final value = conflict.versions
        .map((r) => r.value)
        .whereType<Map<String, Object?>>()
        .firstOrNull;
    final row = value?['row'];
    if (value?['kind'] == 'bookmark' &&
        conflict.label == 'Bookmark' &&
        row is Map &&
        (row['note'] as String? ?? '').trim().isEmpty) {
      return iCloudCopy(context, '书签', 'Bookmark');
    }
    if (value?['kind'] == 'note' &&
        conflict.label == 'Note' &&
        row is Map &&
        (row['reader_note'] as String? ?? '').trim().isEmpty) {
      return iCloudCopy(context, '笔记', 'Note');
    }
    if (value?['kind'] == 'setting') {
      final en = switch (conflict.label) {
        '阅读字号' => 'Reading font size',
        '阅读行距' => 'Reading line spacing',
        '外观主题' => 'Appearance',
        '阅读导航' => 'Reading navigation',
        '书架设置' => 'Library preferences',
        '应用语言' => 'App language',
        '阅读与应用设置' => 'Reading and app preferences',
        _ => conflict.label,
      };
      return iCloudCopy(context, conflict.label, en);
    }
    return conflict.label;
  }

  String _preview(BuildContext context, ICloudRecord version) {
    final value = version.value;
    if (value == null) {
      return iCloudCopy(context, '此设备已删除这条数据', 'Deleted on this device');
    }
    final row = value['row'];
    final sourceProgress = value['sourceProgress'];
    if (value['kind'] == 'progress' && sourceProgress is Map) {
      return '${iCloudCopy(context, '章节', 'Chapter')} ${(sourceProgress['chapter_index'] as num? ?? 0) + 1}';
    }
    if (value['kind'] == 'progress' && row is Map) {
      final progress = row['reading_progress'];
      if (progress is num) {
        return '${iCloudCopy(context, '阅读进度', 'Reading position')} · ${(progress.clamp(0, 1) * 100).toStringAsFixed(1)}%';
      }
    }
    if (row is Map) {
      for (final key in ['name', 'reader_note', 'note', 'content', 'title']) {
        final text = row[key];
        if (text is String && text.isNotEmpty) {
          return text;
        }
      }
    }
    if (value['kind'] == 'setting') {
      final setting = value['value'];
      if (setting is bool) {
        return iCloudCopy(
          context,
          setting ? '开启' : '关闭',
          setting ? 'On' : 'Off',
        );
      }
      if (setting is num || setting is String) {
        return '$setting';
      }
    }
    return iCloudCopy(context, '保留此设备上的记录', 'Keep this device’s record');
  }
}
