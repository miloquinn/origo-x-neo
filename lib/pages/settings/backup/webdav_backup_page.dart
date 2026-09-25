import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/backup/webdav_backup_controller.dart';
import '../../../services/sync/sync_models.dart';
import '../../../widgets/floating_subpage_scaffold.dart';
import '../../../widgets/restartable_app.dart';
import '../sync/webdav_setup_page.dart';
import '../sync/webdav_sync_translator.dart';
import 'backup_copy.dart';
import 'restore_options_dialog.dart';
import '../../../utils/page_style_helper.dart';
import 'backup_selection_panel.dart';
import '../../../services/backup/backup_selection.dart';
import '../../../services/library/download_task_controller.dart';
import '../../../book_sources/services/book_source_maintenance_coordinator.dart';
import '../../../utils/reader_themes.dart';

class WebDavBackupPage extends StatefulWidget {
  const WebDavBackupPage({super.key});
  @override
  State<WebDavBackupPage> createState() => _WebDavBackupPageState();
}

class _WebDavBackupPageState extends State<WebDavBackupPage> {
  String? _message;
  WebDavSyncFailure? _failure;
  bool _restored = false;
  bool _preparingBookFiles = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<WebDavBackupController>().isConfigured) {
        final backup = context.read<WebDavBackupController>();
        _prepareBookFiles(backup);
        _run(backup.refresh);
      }
    });
  }

  Future<void> _prepareBookFiles(WebDavBackupController backup) async {
    setState(() => _preparingBookFiles = true);
    try {
      await backup.prepareDefaultBookSelection();
    } catch (_) {
      if (mounted) setState(() => _message = BackupCopy.of(context).failed);
    } finally {
      if (mounted) setState(() => _preparingBookFiles = false);
    }
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() {
      _message = null;
      _failure = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e is WebDavSyncFailure
            ? webDavSyncErrorText(context, e.code)
            : BackupCopy.of(context).failed;
        _failure = e is WebDavSyncFailure ? e : null;
      });
    }
  }

  Future<void> _restore(CloudBackup snapshot) async {
    final options = await showDialog<RestoreSelection>(
      context: context,
      builder: (_) => const RestoreOptionsDialog(),
    );
    if (options == null || !mounted) return;
    context.read<WebDavBackupController>().restoreSelection = options;
    await _run(() async {
      await context.read<WebDavBackupController>().restore(snapshot);
      if (mounted) setState(() => _restored = true);
    });
  }

  Widget _card(BuildContext context, Widget child) {
    final palette = PageStyleHelper.palette(context);
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _connectionCard(
    BuildContext context,
    WebDavBackupController backup,
    BackupCopy copy,
    bool otherWrites,
  ) {
    final palette = PageStyleHelper.palette(context);
    final scheme = Theme.of(context).colorScheme;
    final host = Uri.tryParse(backup.serverUrl ?? '')?.host;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.hero, palette.cardStrong],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.cloud_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.isConfigured
                          ? copy.connectedTitle
                          : copy.unconnectedTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      backup.isConfigured
                          ? (host?.isNotEmpty == true
                                ? host!
                                : backup.serverUrl ?? '')
                          : copy.connectionPrompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (backup.isConfigured)
                IconButton(
                  tooltip: copy.configure,
                  onPressed: backup.busy || otherWrites
                      ? null
                      : () => _openSetup(backup),
                  icon: const Icon(Icons.tune_rounded),
                ),
            ],
          ),
          if (!backup.isConfigured) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: backup.busy || otherWrites
                    ? null
                    : () => _openSetup(backup),
                icon: const Icon(Icons.add_link_rounded),
                label: Text(copy.connect),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSetup(WebDavBackupController backup) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WebDavSetupPage()));
    if (mounted && backup.isConfigured) {
      await _prepareBookFiles(backup);
      if (mounted) await _run(backup.refresh);
    }
  }

  Widget _operationMessage(
    BuildContext context,
    String message,
    WebDavSyncFailure? failure,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = failure != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasError
            ? scheme.errorContainer.withValues(alpha: 0.65)
            : scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 21,
                color: hasError
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          if (failure != null) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(BackupCopy.of(context).errorDetails),
                children: [WebDavSyncFailureDetails(failure: failure)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<WebDavBackupController>();
    final copy = BackupCopy.of(context);
    final otherWrites =
        (context.watch<DownloadTaskController?>()?.hasActiveTasks ?? false) ||
        (context.watch<BookSourceMaintenanceCoordinator?>()?.state.isRunning ??
            false);
    return PopScope(
      canPop: !backup.busy && !_restored,
      child: FloatingSubpageScaffold(
        title: copy.title,
        body: ListView(
          padding: floatingSubpagePadding(context, top: 20, bottom: 40),
          children: [
            if (_restored) ...[
              Text(
                copy.restored,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(copy.restartHint),
              if (backup.recoveryPath != null)
                SelectableText(backup.recoveryPath!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ReaderThemes.invalidateSavedPaletteCache();
                  RestartableApp.restart(context);
                },
                child: Text(copy.restart),
              ),
            ] else ...[
              _connectionCard(context, backup, copy, otherWrites),
              if (otherWrites) ...[
                const SizedBox(height: 12),
                Text(copy.waitForTasks),
              ],
              if (backup.isConfigured) ...[
                const SizedBox(height: 22),
                Text(
                  copy.backupSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _card(context, BackupSelectionPanel(controller: backup)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed:
                        backup.busy ||
                            otherWrites ||
                            _preparingBookFiles ||
                            backup.selection.isEmpty
                        ? null
                        : () => _run(backup.backup, success: copy.done),
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(copy.backup),
                  ),
                ),
                if (_preparingBookFiles)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(copy.preparingBookFiles),
                  ),
              ],
              if (backup.busy) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: backup.progress,
                  ),
                ),
                const SizedBox(height: 12),
                Text(copy.stage(backup.stage)),
                if (backup.progress != null)
                  Text(
                    '${(backup.progress! * 100).toStringAsFixed(0)}% · ${backupBytes(backup.completedBytes)} / ${backupBytes(backup.totalBytes)}',
                  ),
                if (backup.stage == 'uploading' ||
                    backup.stage == 'downloading')
                  Text('${backupBytes(backup.bytesPerSecond)}/s'),
                Text(copy.working),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                _operationMessage(context, _message!, _failure),
              ],
              if (backup.isConfigured) ...[
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.history,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: copy.refresh,
                      onPressed: backup.busy
                          ? null
                          : () => _run(backup.refresh),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                if (backup.backups.isEmpty && !backup.busy && _failure == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      copy.empty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PageStyleHelper.palette(context).textMuted,
                      ),
                    ),
                  ),
              ],
              for (final item in backup.backups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _card(
                    context,
                    ListTile(
                      leading: const Icon(Icons.folder_zip_outlined),
                      title: Text(
                        DateFormat.yMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_Hms().format(item.createdAt.toLocal()),
                      ),
                      subtitle: Text(
                        item.bytes == null
                            ? 'ZIP'
                            : '${(item.bytes! / 1024 / 1024).toStringAsFixed(1)} MB · ZIP',
                      ),
                      trailing: TextButton(
                        onPressed: backup.busy || otherWrites
                            ? null
                            : () => _restore(item),
                        child: Text(copy.restore),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text(
                copy.privacy,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PageStyleHelper.palette(context).textMuted,
                  height: 1.5,
                ),
              ),
              if (backup.isConfigured)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: backup.busy
                        ? null
                        : () => _run(backup.disconnect),
                    child: Text(copy.disconnect),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
