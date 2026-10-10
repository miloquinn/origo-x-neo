import 'package:flutter/material.dart';

import '../models/app_skin.dart';
import '../utils/localization_extension.dart';
import '../utils/page_style_helper.dart';
import 'app_skin_icon.dart';
import 'floating_pill_navigation_surface.dart';
import 'glass_surface.dart';
import 'glass_buttons.dart';

/// A decorative preview using the same background, asset and glass renderers
/// as the app. It never handles navigation or represents an actual book.
class AppThemePreview extends StatelessWidget {
  const AppThemePreview({super.key, this.height = 226});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: MediaQuery(
            // Thumbnail typography is illustrative; the surrounding controls
            // continue to follow the user's text scale.
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: DecoratedBox(
              decoration: PageStyleHelper.backgroundDecoration(context),
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GlassIconButton(
                            dimension: 32,
                            iconSize: 22,
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {},
                            animatePress: false,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              l10n.settingsThemePreviewTitle,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          GlassIconButton(
                            dimension: 32,
                            iconSize: 22,
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () {},
                            animatePress: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GlassSurface(
                        role: GlassSurfaceRole.panel,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.book_outlined,
                                  color: scheme.onSecondaryContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.settingsThemePreviewBody,
                                      maxLines: 2,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: [
                                        Container(
                                          width: 55,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 30,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: scheme.tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            FloatingPillNavigationSurface(
                              width: constraints.maxWidth,
                              height: 48,
                              child: Row(
                                children: [
                                  for (final item in const [
                                    (AppSkinIconSlot.home, Icons.home_outlined),
                                    (
                                      AppSkinIconSlot.library,
                                      Icons.auto_stories_rounded,
                                    ),
                                    (
                                      AppSkinIconSlot.discover,
                                      Icons.explore_outlined,
                                    ),
                                    (
                                      AppSkinIconSlot.ai,
                                      Icons.auto_awesome_rounded,
                                    ),
                                  ])
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 2,
                                        ),
                                        decoration:
                                            item.$1 == AppSkinIconSlot.library
                                            ? BoxDecoration(
                                                color: scheme.primaryContainer
                                                    .withValues(alpha: .65),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              )
                                            : null,
                                        child: Center(
                                          child: AppSkinIcon(
                                            slot: item.$1,
                                            selected:
                                                item.$1 ==
                                                AppSkinIconSlot.library,
                                            fallback: Icon(
                                              item.$2,
                                              size: 21,
                                              color:
                                                  item.$1 ==
                                                      AppSkinIconSlot.library
                                                  ? scheme.primary
                                                  : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
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
          ),
        ),
      ),
    );
  }
}
