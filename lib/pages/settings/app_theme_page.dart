import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_skin.dart';
import '../../services/core/theme_notifier.dart';
import '../../utils/app_skin_theme.dart';
import '../../utils/app_skin_image_provider.dart';
import '../../utils/app_theme_labels.dart';
import '../../utils/app_themes.dart';
import '../../utils/localization_extension.dart';
import '../../utils/page_style_helper.dart';
import '../../utils/ui_style.dart';
import '../../widgets/app_skin_icon.dart';
import '../../widgets/app_theme_preview.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/glass_buttons.dart';
import '../../widgets/side_toast.dart';
import 'about/open_source_licenses_page.dart';
import 'theme_market_page.dart';

enum AppThemeCategory { color, artwork }

class AppThemePage extends StatefulWidget {
  const AppThemePage({
    super.key,
    this.initialCategory = AppThemeCategory.color,
  });

  final AppThemeCategory initialCategory;

  @override
  State<AppThemePage> createState() => _AppThemePageState();
}

class _AppThemePageState extends State<AppThemePage> {
  late AppThemeCategory _category = widget.initialCategory;
  final _applyVersions = <AppThemeCategory, int>{};

  Future<void> _apply(
    Future<void> Function() change, {
    required AppThemeCategory category,
    required bool Function() isCurrent,
  }) async {
    final version = (_applyVersions[category] ?? 0) + 1;
    _applyVersions[category] = version;
    hideSideToast();
    try {
      await change();
    } catch (error, stackTrace) {
      developer.log(
        'Saving theme selection failed',
        name: 'app.theme',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted || _applyVersions[category] != version || !isCurrent()) {
        return;
      }
      final l10n = context.l10n;
      showSideToast(
        context,
        l10n.settingsThemeSaveFailed,
        kind: SideToastKind.error,
        actionLabel: l10n.settingsThemeRetry,
        onAction: () {
          if (_applyVersions[category] == version && isCurrent()) {
            _apply(change, category: category, isCurrent: isCurrent);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final l10n = context.l10n;
    return FloatingSubpageScaffold(
      title: l10n.settingsThemeGalleryTitle,
      body: SingleChildScrollView(
        padding: floatingSubpagePadding(context, bottom: 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 800 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 21;
                final preview = _buildPreview(notifier);
                final choices = _buildChoices(notifier);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.settingsThemeGalleryHeadline,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.settingsThemeGallerySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 340, child: preview),
                          const SizedBox(width: 28),
                          Expanded(child: choices),
                        ],
                      )
                    else ...[
                      preview,
                      const SizedBox(height: 24),
                      choices,
                    ],
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      key: const ValueKey('open-theme-market'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ThemeMarketPage(),
                        ),
                      ),
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(l10n.settingsThemeMarketTitle),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.settingsThemeReadPaperHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GlassTextButton(
                        key: const ValueKey('theme-asset-credits'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OpenSourceLicensesPage(
                              title: l10n.settingsThemeCredits,
                              prioritizeAssets: true,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSkinIcon.adapt(
                              const Icon(Icons.info_outline_rounded, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(l10n.settingsThemeCredits)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeNotifier notifier) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final material = !notifier.isGlassEffectsEnabled
        ? null
        : notifier.glassStyle == GlassStyle.frosted
        ? l10n.settingsGlassStyleFrostedTitle
        : l10n.settingsGlassStyleLiquidTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppThemePreview(key: ValueKey('theme-live-preview')),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsThemeCurrent,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${notifier.currentColorPackage?.name ?? appColorPresetName(l10n, notifier.currentColorPreset?.id)} · ${notifier.currentSkinPackage?.name ?? appSkinName(l10n, notifier.currentSkin.id)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (material != null) const SizedBox(width: 8),
            if (material != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  material,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoices(ThemeNotifier notifier) {
    final l10n = context.l10n;
    final colors = _category == AppThemeCategory.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<AppThemeCategory>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: AppThemeCategory.color,
              label: Text(l10n.settingsThemeColorCategory),
              icon: const Icon(Icons.palette_outlined, size: 18),
            ),
            ButtonSegment(
              value: AppThemeCategory.artwork,
              label: Text(l10n.settingsThemeSkinCategory),
              icon: const Icon(Icons.wallpaper_rounded, size: 18),
            ),
          ],
          selected: {_category},
          onSelectionChanged: (value) =>
              setState(() => _category = value.single),
        ),
        const SizedBox(height: 14),
        Text(
          colors ? l10n.settingsThemeColorHint : l10n.settingsThemeSkinHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (!colors && MediaQuery.highContrastOf(context)) ...[
          const SizedBox(height: 10),
          Text(
            l10n.settingsThemeHighContrastHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 23;
            final columns = largeText || constraints.maxWidth < 300
                ? 1
                : colors && constraints.maxWidth >= 610
                ? 3
                : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (colors && notifier.currentColorPreset == null)
                  SizedBox(width: width, child: _colorCard(null, notifier)),
                if (colors)
                  for (final preset in AppThemes.colorPresets)
                    SizedBox(width: width, child: _colorCard(preset, notifier))
                else
                  for (final skin in notifier.availableSkins)
                    SizedBox(width: width, child: _skinCard(skin, notifier)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _colorCard(AppColorPreset? preset, ThemeNotifier notifier) {
    final l10n = context.l10n;
    final theme = preset?.theme ?? notifier.currentAppTheme;
    final scheme = Theme.of(context).brightness == Brightness.dark
        ? theme.darkColorScheme
        : theme.lightColorScheme;
    final selected = preset?.id == notifier.currentColorPreset?.id;
    return _choiceCard(
      key: ValueKey('palette-${preset?.id ?? 'legacy'}'),
      selected: selected,
      title: appColorPresetName(l10n, preset?.id),
      onTap: preset == null
          ? null
          : () => _apply(
              () => notifier.setColorPreset(preset.id),
              category: AppThemeCategory.color,
              isCurrent: () => notifier.currentColorPreset?.id == preset.id,
            ),
      preview: Container(
        height: 74,
        padding: const EdgeInsets.all(14),
        color: scheme.surfaceContainerLow,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: 48,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    height: 23,
                    width: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in [scheme.secondary, scheme.tertiary])
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      subtitle: preset == null ? l10n.settingsThemeLegacyColorHint : null,
      swatches: [scheme.primary, scheme.secondary, scheme.tertiary],
    );
  }

  Widget _skinCard(AppSkin skin, ThemeNotifier notifier) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final asset = skin.artwork[AppSkinArtworkSlot.pageBackground];
    return _choiceCard(
      key: ValueKey('skin-${skin.id}'),
      selected: notifier.currentSkin.id == skin.id,
      title: appSkinName(l10n, skin.id),
      subtitle: appSkinDescription(l10n, skin.id),
      onTap: () => _apply(
        () => notifier.setSkin(skin.id),
        category: AppThemeCategory.artwork,
        isCurrent: () => notifier.currentSkin.id == skin.id,
      ),
      preview: Theme(
        data: Theme.of(context).copyWith(
          extensions: [
            ...Theme.of(context).extensions.values.where(
              (extension) => extension is! AppSkinTheme,
            ),
            AppSkinTheme(skin: skin),
          ],
        ),
        child: Builder(
          builder: (context) => Container(
            height: 112,
            decoration: BoxDecoration(
              gradient: PageStyleHelper.backgroundGradient(context),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (asset != null)
                  Image(
                    image: appSkinImageProvider(
                      asset,
                      Theme.of(context).brightness,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final item in const [
                          (AppSkinIconSlot.home, Icons.home_outlined),
                          (AppSkinIconSlot.library, Icons.auto_stories_rounded),
                          (AppSkinIconSlot.discover, Icons.explore_outlined),
                        ])
                          AppSkinIcon(
                            slot: item.$1,
                            selected: item.$1 == AppSkinIconSlot.library,
                            fallback: Icon(
                              item.$2,
                              size: 21,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required Key key,
    required bool selected,
    required String title,
    required Widget preview,
    required VoidCallback? onTap,
    String? subtitle,
    List<Color>? swatches,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ExcludeSemantics(child: preview),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (swatches != null) ...[
                        const SizedBox(height: 10),
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              for (final color in swatches)
                                Container(
                                  width: 16,
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
