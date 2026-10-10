import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';
import 'app_skin_icon.dart';
import 'glass_surface.dart';

/// One clear next membership step in the same glass language as the app shell.
class MembershipOfferCard extends StatelessWidget {
  const MembershipOfferCard({
    super.key,
    required this.offerRead,
    required this.onTap,
  });

  final bool offerRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final title = offerRead
        ? l10n.storeReaderLicenseTitle
        : l10n.premiumEditorialTitle;
    final summary = offerRead
        ? l10n.basicEditionSummary
        : l10n.premiumIncludesReaderAccess;
    final feature = offerRead
        ? '${l10n.basicAiTitle} · ${l10n.basicCloudTtsTitle} · ${l10n.basicComicTitle} · ${l10n.basicCustomFontsTitle}'
        : l10n.premiumUnlimitedSourcesBenefit(2);

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$title. $summary. $feature',
      child: GlassSurface(
        key: const ValueKey('settings-membership-offer'),
        role: GlassSurfaceRole.panel,
        emphasized: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey(
              offerRead
                  ? 'settings-reader-license'
                  : 'settings-membership-entry',
            ),
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppSkinIcon.adapt(
                      Icon(
                        offerRead
                            ? Icons.auto_stories_rounded
                            : Icons.explore_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          key: const ValueKey('settings-membership-title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature,
                          key: const ValueKey('settings-membership-benefits'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
