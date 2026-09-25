import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xxread/services/sync/sync_models.dart';
import 'package:xxread/services/backup/webdav_backup_controller.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

import 'webdav_sync_translator.dart';

class WebDavSetupPage extends StatefulWidget {
  const WebDavSetupPage({super.key});

  @override
  State<WebDavSetupPage> createState() => _WebDavSetupPageState();
}

class _WebDavSetupPageState extends State<WebDavSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rootController = TextEditingController(text: 'OrigoX');

  var _obscurePassword = true;
  var _saving = false;
  WebDavSyncErrorCode? _connectionError;
  WebDavSyncFailure? _connectionFailure;

  @override
  void initState() {
    super.initState();
    final sync = context.read<WebDavBackupController>();
    _serverController.text = sync.serverUrl ?? '';
    _usernameController.text = sync.username ?? '';
    _rootController.text = sync.rootPath ?? 'OrigoX';
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _rootController.dispose();
    super.dispose();
  }

  WebDavSyncConfigDraft get _draft => WebDavSyncConfigDraft(
    serverUrl: _serverController.text.trim(),
    username: _usernameController.text.trim(),
    password: _passwordController.text,
    rootPath: _rootController.text.trim(),
  );

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final draft = _draft;
    final sync = context.read<WebDavBackupController>();
    setState(() {
      _saving = true;
      _connectionError = null;
      _connectionFailure = null;
    });
    try {
      final result = await sync.testConnection(draft);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _connectionError = result.errorCode ?? WebDavSyncErrorCode.unknown;
          _connectionFailure = result.failure;
        });
        return;
      }
      await sync.configure(draft);
      if (mounted) Navigator.of(context).pop();
    } on WebDavSyncFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionError = error.code;
        _connectionFailure = error;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _connectionError = WebDavSyncErrorCode.unknown);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearError(String _) {
    if (_connectionError != null) {
      setState(() {
        _connectionError = null;
        _connectionFailure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = PageStyleHelper.palette(context);
    final sync = context.watch<WebDavBackupController>();
    final hasStoredConfiguration = sync.isConfigured;
    return FloatingSubpageScaffold(
      title: l10n.webDavSetUp,
      body: ListView(
        padding: floatingSubpagePadding(context, top: 20, bottom: 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ConnectionHeader(
                      key: const ValueKey('webdav-connection-header'),
                      title: l10n.webDavConnectionTitle,
                      description:
                          Localizations.localeOf(context).languageCode == 'zh'
                          ? '填写你的 WebDAV 服务地址与应用密码。'
                          : 'Enter your WebDAV address and app password.',
                    ),
                    const SizedBox(height: 24),
                    Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: palette.cardStrong.withValues(alpha: 0.82),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            enabled: !_saving,
                            controller: _serverController,
                            keyboardType: TextInputType.url,
                            autofillHints: const [AutofillHints.url],
                            decoration: InputDecoration(
                              labelText: l10n.webDavServerUrl,
                              prefixIcon: const Icon(Icons.link_rounded),
                            ),
                            onChanged: _clearError,
                            validator: (value) {
                              final uri = Uri.tryParse(value?.trim() ?? '');
                              return uri != null && uri.host.isNotEmpty
                                  ? null
                                  : l10n.webDavErrorUnknown;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: !_saving,
                            controller: _usernameController,
                            autofillHints: const [AutofillHints.username],
                            decoration: InputDecoration(
                              labelText: l10n.webDavUsername,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            onChanged: _clearError,
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : l10n.webDavErrorAuthentication,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: !_saving,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: l10n.webDavPassword,
                              helperText: hasStoredConfiguration
                                  ? l10n.webDavPasswordHint
                                  : null,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? l10n.settingsShow
                                    : l10n.settingsHide,
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onChanged: _clearError,
                            validator: (value) =>
                                (value?.isNotEmpty ?? false) ||
                                    hasStoredConfiguration
                                ? null
                                : l10n.webDavErrorAuthentication,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.webDavRootPath,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            enabled: !_saving,
                            controller: _rootController,
                            decoration: InputDecoration(
                              labelText: l10n.webDavRootPath,
                              prefixIcon: const Icon(Icons.folder_outlined),
                              helperText: hasStoredConfiguration
                                  ? null
                                  : (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'zh'
                                        ? '默认 OrigoX，备份会保存在该目录下。'
                                        : 'Defaults to OrigoX. Backups are stored here.'),
                            ),
                            onChanged: _clearError,
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : l10n.webDavErrorUnknown,
                          ),
                          if (_connectionError != null) ...[
                            const SizedBox(height: 14),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            webDavSyncErrorText(
                                              context,
                                              _connectionError,
                                            ),
                                          ),
                                          if (_connectionFailure != null) ...[
                                            const SizedBox(height: 10),
                                            WebDavSyncFailureDetails(
                                              failure: _connectionFailure!,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.webDavSecurityNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('webdav-save-action'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving
                              ? l10n.webDavTestingConnection
                              : l10n.webDavSaveConfiguration,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = PageStyleHelper.palette(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.cloud_outlined, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
