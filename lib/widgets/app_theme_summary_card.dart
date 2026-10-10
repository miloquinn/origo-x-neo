import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_skin.dart';
import '../services/core/theme_notifier.dart';
import '../utils/app_theme_labels.dart';
import '../utils/localization_extension.dart';
import '../utils/app_skin_image_provider.dart';
import 'app_skin_icon.dart';

class AppThemeSummaryCard extends StatelessWidget {
  const AppThemeSummaryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selection = context
        .select<ThemeNotifier, (String?, AppSkin, Color, String?, String?)>(
          (theme) => (
            theme.currentColorPreset?.id,
            theme.currentSkin,
            theme.accentColor,
            theme.currentColorPackage?.name,
            theme.currentSkinPackage?.name,
          ),
        );
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final skin = context.read<ThemeNotifier>().currentSkin;
    final image = skin.artwork[AppSkinArtworkSlot.pageBackground];
    return Semantics(
      button: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('settings-theme-gallery'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsThemeGalleryTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${selection.$4 ?? appColorPresetName(l10n, selection.$1)} · ${selection.$5 ?? appSkinName(l10n, selection.$2.id)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ExcludeSemantics(
                        child: Row(
                          children: [
                            for (final color in [
                              scheme.primary,
                              scheme.secondary,
                              scheme.tertiary,
                            ])
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ExcludeSemantics(
                  child: Container(
                    width: 72,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                      image: image == null
                          ? null
                          : DecorationImage(
                              image: appSkinImageProvider(
                                image,
                                Theme.of(context).brightness,
                              ),
                              fit: BoxFit.cover,
                              opacity: .65,
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppSkinIcon(
                        slot: AppSkinIconSlot.library,
                        selected: true,
                        fallback: Icon(
                          Icons.auto_stories_rounded,
                          color: scheme.primary,
                          size: 26,
                        ),
                      ),
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
}
