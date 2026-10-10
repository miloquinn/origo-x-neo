import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/theme_package.dart';
import '../../services/account/member_account_controller.dart';
import '../../services/core/theme_notifier.dart';
import '../../services/themes/theme_market_item.dart';
import '../../utils/app_skin_image_provider.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/glass_buttons.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/side_toast.dart';

typedef ThemeMarketLoader = Future<List<ThemeMarketItem>> Function();
typedef ThemeMarketDownloader =
    Future<Uint8List> Function(ThemeMarketItem item);
typedef ThemeMarketPreviewUriBuilder = Uri Function(ThemeMarketItem item);
typedef ThemeMarketUriLauncher = Future<bool> Function(Uri uri);
typedef ThemeMarketInstallAction =
    Future<void> Function(ThemeMarketItem item, Uint8List bytes);
typedef InstalledThemeAction = Future<void> Function(ThemePackage package);
typedef InstalledThemeLoader = Future<void> Function();

class ThemeMarketPage extends StatefulWidget {
  const ThemeMarketPage({
    super.key,
    this.loader,
    this.downloader,
    this.previewUriBuilder,
    this.creatorUri,
    this.uriLauncher,
    this.canFetch,
    this.installAction,
    this.applyAction,
    this.removeAction,
    this.installedLoader,
  });

  final ThemeMarketLoader? loader;
  final ThemeMarketDownloader? downloader;
  final ThemeMarketPreviewUriBuilder? previewUriBuilder;
  final Uri? creatorUri;
  final ThemeMarketUriLauncher? uriLauncher;
  final bool? canFetch;
  final ThemeMarketInstallAction? installAction;
  final InstalledThemeAction? applyAction;
  final InstalledThemeAction? removeAction;
  final InstalledThemeLoader? installedLoader;

  @visibleForTesting
  static bool shouldPreserveActiveVersion({
    required Iterable<ThemePackage?> activePackages,
    required String incomingId,
    required int incomingVersion,
  }) => activePackages.whereType<ThemePackage>().any(
    (active) => active.id == incomingId && active.version != incomingVersion,
  );

  @visibleForTesting
  static bool usesAnyLayer({
    required ThemePackage package,
    required ThemePackage? currentSkinPackage,
    required ThemePackage? currentColorPackage,
  }) =>
      (_hasSkin(package) && _samePackage(currentSkinPackage, package)) ||
      (package.palette != null && _samePackage(currentColorPackage, package));

  @visibleForTesting
  static bool isFullyApplied({
    required ThemePackage package,
    required ThemePackage? currentSkinPackage,
    required ThemePackage? currentColorPackage,
  }) {
    final hasSkin = _hasSkin(package);
    final hasPalette = package.palette != null;
    if (!hasSkin && !hasPalette) return false;
    return (!hasSkin || _samePackage(currentSkinPackage, package)) &&
        (!hasPalette || _samePackage(currentColorPackage, package));
  }

  static bool _hasSkin(ThemePackage package) =>
      package.skin.icons.isNotEmpty || package.skin.artwork.isNotEmpty;

  static bool _samePackage(ThemePackage? active, ThemePackage candidate) =>
      active?.id == candidate.id && active?.version == candidate.version;

  @override
  State<ThemeMarketPage> createState() => _ThemeMarketPageState();
}

class _ThemeMarketPageState extends State<ThemeMarketPage> {
  List<ThemeMarketItem> _remote = const [];
  Object? _loadError;
  String? _actionError;
  bool _loading = true;
  bool _started = false;
  bool _installedStarted = false;
  bool _installedLoading = true;
  bool _networkAllowed = true;
  int _loadGeneration = 0;
  String? _busyKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_installedStarted) {
      _installedStarted = true;
      unawaited(_loadInstalled());
    }
    final allowed =
        widget.canFetch ??
        context.watch<MemberAccountController>().networkAllowed;
    if (_networkAllowed != allowed) {
      _networkAllowed = allowed;
      _loadGeneration++;
      if (!allowed) {
        _started = false;
        _remote = const [];
        _loadError = null;
        _loading = false;
      }
    }
    if (_started || !allowed) return;
    _started = true;
    unawaited(_load());
  }

  Future<void> _loadInstalled() async {
    try {
      await (widget.installedLoader ??
          context.read<ThemeNotifier>().reloadInstalledThemes)();
    } catch (error) {
      if (mounted) {
        setState(() {
          _actionError = context.l10n.themeMarketInstalledLoadFailed(
            _readableError(error),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _installedLoading = false);
    }
  }

  Future<void> _load() async {
    if (!_networkAllowed) return;
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final account = widget.loader == null
          ? context.read<MemberAccountController>()
          : null;
      final themes = await (widget.loader ?? account!.loadThemes)();
      if (!mounted || !_networkAllowed || generation != _loadGeneration) return;
      setState(() {
        _remote = List.unmodifiable(themes);
        _loading = false;
      });
    } catch (error) {
      if (!mounted || !_networkAllowed || generation != _loadGeneration) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _downloadAndApply(ThemeMarketItem item) async {
    if (!_networkAllowed) return;
    final key = 'download-${item.id}-${item.version}';
    if (_busyKey != null) return;
    setState(() {
      _busyKey = key;
      _actionError = null;
    });
    try {
      final account = widget.downloader == null
          ? context.read<MemberAccountController>()
          : null;
      final bytes = await (widget.downloader ?? account!.downloadTheme)(item);
      if (!mounted || !_networkAllowed) return;
      if (widget.installAction case final install?) {
        await install(item, bytes);
        if (mounted) {
          _showMessage(
            context.l10n.themeMarketInstalledMessage(item.name),
            kind: SideToastKind.success,
          );
        }
        return;
      }
      final notifier = context.read<ThemeNotifier>();
      final preserveOlderSelection =
          ThemeMarketPage.shouldPreserveActiveVersion(
            activePackages: [
              notifier.currentSkinPackage,
              notifier.currentColorPackage,
            ],
            incomingId: item.id,
            incomingVersion: item.version,
          );
      final package = await notifier.packageStore.install(
        bytes,
        expectedSha256: item.sha256,
        expectedId: item.id,
        expectedVersion: item.version,
      );
      await notifier.reloadInstalledThemes();
      if (!preserveOlderSelection) {
        await notifier.applyInstalledTheme(package);
      }
      if (!mounted) return;
      _showMessage(
        preserveOlderSelection
            ? context.l10n.themeMarketUpdateInstalledMessage(item.name)
            : context.l10n.themeMarketInstalledAndAppliedMessage(item.name),
        kind: SideToastKind.success,
      );
    } catch (error) {
      if (mounted) {
        final message = context.l10n.themeMarketInstallFailed(
          _readableError(error),
        );
        setState(() => _actionError = message);
        _showMessage(message, kind: SideToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _apply(ThemePackage package) async {
    final key = 'apply-${package.id}-${package.version}';
    if (_busyKey != null) return;
    setState(() {
      _busyKey = key;
      _actionError = null;
    });
    try {
      await (widget.applyAction ??
          context.read<ThemeNotifier>().applyInstalledTheme)(package);
      if (mounted) {
        _showMessage(
          context.l10n.themeMarketAppliedMessage(package.name),
          kind: SideToastKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        final message = context.l10n.themeMarketApplyFailed(
          _readableError(error),
        );
        setState(() => _actionError = message);
        _showMessage(message, kind: SideToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _remove(ThemePackage package) async {
    if (_busyKey != null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.themeMarketRemoveDialogTitle),
        content: Text(l10n.themeMarketRemoveDialogMessage(package.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final key = 'remove-${package.id}-${package.version}';
    setState(() {
      _busyKey = key;
      _actionError = null;
    });
    try {
      await (widget.removeAction ??
          context.read<ThemeNotifier>().removeInstalledTheme)(package);
      if (mounted) {
        _showMessage(
          context.l10n.themeMarketRemovedMessage(package.name),
          kind: SideToastKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        final message = context.l10n.themeMarketRemoveFailed(
          _readableError(error),
        );
        setState(() => _actionError = message);
        _showMessage(message, kind: SideToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _openCreator() async {
    if (!_networkAllowed) return;
    final account = widget.creatorUri == null
        ? context.read<MemberAccountController>()
        : null;
    final uri = widget.creatorUri ?? account!.themeCreatorUri;
    final opened =
        await (widget.uriLauncher ??
            (value) =>
                launchUrl(value, mode: LaunchMode.externalApplication))(uri);
    if (mounted && !opened) {
      _showMessage(
        context.l10n.themeMarketCreatorOpenFailed,
        kind: SideToastKind.error,
      );
    }
  }

  void _showMessage(String message, {SideToastKind kind = SideToastKind.info}) {
    showSideToast(context, message, kind: kind);
  }

  String _readableError(Object error) => error
      .toString()
      .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')
      .trim();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = context.watch<ThemeNotifier>();
    final installed = notifier.installedThemes.toList();
    for (final selectedPackage in <ThemePackage>[
      ?notifier.currentSkinPackage,
      ?notifier.currentColorPackage,
    ]) {
      if (!installed.any(
        (package) =>
            package.id == selectedPackage.id &&
            package.version == selectedPackage.version,
      )) {
        installed.insert(0, selectedPackage);
      }
    }
    return FloatingSubpageScaffold(
      title: l10n.settingsThemeMarketTitle,
      actions: [
        FloatingSubpageAction(
          key: const ValueKey('theme-market-refresh'),
          icon: Icons.refresh_rounded,
          tooltip: l10n.themeMarketRefresh,
          onPressed: _loading || !_networkAllowed ? null : _load,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('theme-market-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(),
                    if (_actionError case final error?) ...[
                      const SizedBox(height: 14),
                      _MessagePanel(
                        key: const ValueKey('theme-market-action-error'),
                        icon: Icons.error_outline_rounded,
                        title: l10n.themeMarketActionFailedTitle,
                        message: error,
                      ),
                    ],
                    if (_installedLoading) ...[
                      const SizedBox(height: 18),
                      const LinearProgressIndicator(
                        key: ValueKey('theme-market-installed-loading'),
                      ),
                    ],
                    if (installed.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _sectionTitle(
                        l10n.themeMarketInstalledSectionTitle,
                        l10n.themeMarketInstalledSectionSubtitle,
                      ),
                      const SizedBox(height: 12),
                      _responsiveCards(
                        installed.map((package) {
                          final active = ThemeMarketPage.usesAnyLayer(
                            package: package,
                            currentSkinPackage: notifier.currentSkinPackage,
                            currentColorPackage: notifier.currentColorPackage,
                          );
                          final fullyApplied = ThemeMarketPage.isFullyApplied(
                            package: package,
                            currentSkinPackage: notifier.currentSkinPackage,
                            currentColorPackage: notifier.currentColorPackage,
                          );
                          return _InstalledThemeCard(
                            key: ValueKey(
                              'installed-${package.id}-${package.version}',
                            ),
                            package: package,
                            active: active,
                            selected: fullyApplied,
                            busy: _busyKey != null,
                            applying:
                                _busyKey ==
                                'apply-${package.id}-${package.version}',
                            removing:
                                _busyKey ==
                                'remove-${package.id}-${package.version}',
                            onApply: () => _apply(package),
                            onRemove: () => _remove(package),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _sectionTitle(
                      l10n.themeMarketFeaturedSectionTitle,
                      l10n.themeMarketFeaturedSectionSubtitle,
                    ),
                    const SizedBox(height: 12),
                    _buildRemote(notifier),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      role: GlassSurfaceRole.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.themeMarketHeroTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.themeMarketHeroDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    key: const ValueKey('theme-market-create'),
                    onPressed: _networkAllowed ? _openCreator : null,
                    icon: const Icon(Icons.brush_rounded),
                    label: Text(l10n.themeMarketCreateAction),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.auto_awesome_rounded, size: 46, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildRemote(ThemeNotifier notifier) {
    final l10n = context.l10n;
    if (!_networkAllowed) {
      return _MessagePanel(
        key: const ValueKey('theme-market-network-disabled'),
        icon: Icons.cloud_off_rounded,
        title: l10n.themeMarketNetworkDisabledTitle,
        message: l10n.themeMarketNetworkDisabledMessage,
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return _MessagePanel(
        key: const ValueKey('theme-market-error'),
        icon: Icons.cloud_off_rounded,
        title: l10n.themeMarketLoadFailedTitle,
        message: _readableError(_loadError!),
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }
    if (_remote.isEmpty) {
      return _MessagePanel(
        key: const ValueKey('theme-market-empty'),
        icon: Icons.inventory_2_outlined,
        title: l10n.themeMarketEmptyTitle,
        message: l10n.themeMarketEmptyMessage,
      );
    }
    return _responsiveCards(
      _remote.map((item) {
        final installed =
            <ThemePackage>[
                  ...notifier.installedThemes,
                  ?notifier.currentSkinPackage,
                  ?notifier.currentColorPackage,
                ]
                .where(
                  (package) =>
                      package.id == item.id && package.version == item.version,
                )
                .firstOrNull;
        final active =
            installed != null &&
            ThemeMarketPage.usesAnyLayer(
              package: installed,
              currentSkinPackage: notifier.currentSkinPackage,
              currentColorPackage: notifier.currentColorPackage,
            );
        final fullyApplied =
            installed != null &&
            ThemeMarketPage.isFullyApplied(
              package: installed,
              currentSkinPackage: notifier.currentSkinPackage,
              currentColorPackage: notifier.currentColorPackage,
            );
        return _MarketThemeCard(
          key: ValueKey('market-${item.id}-${item.version}'),
          item: item,
          previewUri:
              (widget.previewUriBuilder ??
              context.read<MemberAccountController>().themePreviewUri)(item),
          installed: installed != null,
          active: active,
          selected: fullyApplied,
          busy: _busyKey != null,
          downloading: _busyKey == 'download-${item.id}-${item.version}',
          onAction: installed == null
              ? () => _downloadAndApply(item)
              : () => _apply(installed),
        );
      }).toList(),
    );
  }

  Widget _responsiveCards(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 720 &&
              MediaQuery.textScalerOf(context).scale(16) < 23
          ? 2
          : 1;
      final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _MarketThemeCard extends StatelessWidget {
  const _MarketThemeCard({
    super.key,
    required this.item,
    required this.previewUri,
    required this.installed,
    required this.active,
    required this.selected,
    required this.busy,
    required this.downloading,
    required this.onAction,
  });

  final ThemeMarketItem item;
  final Uri previewUri;
  final bool installed;
  final bool active;
  final bool selected;
  final bool busy;
  final bool downloading;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => GlassSurface(
    role: GlassSurfaceRole.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: active
          ? BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.55),
            )
          : BorderSide.none,
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.network(
                previewUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0x14000000),
                  child: Center(child: Icon(Icons.wallpaper_rounded, size: 38)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.author} · v${item.version} · ${item.license}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: ValueKey('download-${item.id}-${item.version}'),
            onPressed: busy || selected ? null : onAction,
            icon: downloading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : installed
                        ? Icons.download_done_rounded
                        : Icons.download_rounded,
                  ),
            label: Text(
              selected
                  ? context.l10n.themeMarketInUse
                  : installed
                  ? context.l10n.settingsApply
                  : context.l10n.themeMarketDownloadAndApply,
            ),
          ),
        ],
      ),
    ),
  );
}

class _InstalledThemeCard extends StatelessWidget {
  const _InstalledThemeCard({
    super.key,
    required this.package,
    required this.active,
    required this.selected,
    required this.busy,
    required this.applying,
    required this.removing,
    required this.onApply,
    required this.onRemove,
  });

  final ThemePackage package;
  final bool active;
  final bool selected;
  final bool busy;
  final bool applying;
  final bool removing;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => GlassSurface(
    role: GlassSurfaceRole.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: active
          ? BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.55),
            )
          : BorderSide.none,
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: appSkinImageProvider(
              package.preview,
              Theme.of(context).brightness,
            ),
            child: const Icon(Icons.style_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${package.author} · v${package.version}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!selected)
            TextButton(
              key: ValueKey('apply-${package.id}-${package.version}'),
              onPressed: busy ? null : onApply,
              child: applying
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.settingsApply),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.check_circle_rounded),
            ),
          GlassIconButton(
            key: ValueKey('remove-${package.id}-${package.version}'),
            icon: removing
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.delete_outline_rounded),
            tooltip: context.l10n.delete,
            dimension: 44,
            onPressed: busy ? null : onRemove,
          ),
        ],
      ),
    ),
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => GlassSurface(
    role: GlassSurfaceRole.panel,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
