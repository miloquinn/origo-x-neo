import 'package:flutter/material.dart';

import 'package:xxread/utils/localization_extension.dart';

/// Compact, read-only disclosure of the terms shown before first use.
///
/// The parent owns scrolling and the final acceptance action. This widget only
/// presents the existing localized legal text and lets readers expand it.
class AgreementSummary extends StatelessWidget {
  const AgreementSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.agreementV2Title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.agreementV2Subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.62),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _Disclosure(
          disclosureKey: const Key('agreementTermsDisclosure'),
          icon: Icons.article_outlined,
          title: context.l10n.agreementFlowStepTerms,
          summary: context.l10n.agreementV2OpenSourceBody,
          children: [
            _Notice(text: context.l10n.agreementV2ImportantNotice),
            const SizedBox(height: 18),
            _LegalSection(
              title: context.l10n.agreementV2Section1Title,
              body: context.l10n.agreementV2Section1Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section2Title,
              body: context.l10n.agreementV2Section2Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section3Title,
              body: context.l10n.agreementV2Section3Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section4Title,
              body: context.l10n.agreementV2Section4Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section7Title,
              body: context.l10n.agreementV2Section7Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section8Title,
              body: context.l10n.agreementV2Section8Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section9Title,
              body: context.l10n.agreementV2Section9Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section10Title,
              body: context.l10n.agreementV2Section10Body,
            ),
            _LegalSection(
              title: context.l10n.agreementV2Section11Title,
              body: context.l10n.agreementV2Section11Body,
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Disclosure(
          disclosureKey: const Key('agreementSourceDisclosure'),
          icon: Icons.hub_outlined,
          title: context.l10n.agreementFlowStepSource,
          summary: context.l10n.agreementV2SourceBoundaryPoint1,
          children: [
            _SourceBoundary(),
            const SizedBox(height: 18),
            _LegalSection(
              title: context.l10n.agreementV2Section5Title,
              body: context.l10n.agreementV2Section5Body,
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Disclosure(
          disclosureKey: const Key('agreementPrivacyDisclosure'),
          icon: Icons.shield_outlined,
          title: context.l10n.agreementFlowStepPrivacy,
          summary: context.l10n.agreementFlowPrivacyLocalBody,
          children: [
            _PrivacySummary(
              title: context.l10n.agreementFlowPrivacyLocalTitle,
              body: context.l10n.agreementFlowPrivacyLocalBody,
            ),
            _PrivacySummary(
              title: context.l10n.agreementFlowPrivacyNetworkTitle,
              body: context.l10n.agreementFlowPrivacyNetworkBody,
            ),
            _PrivacySummary(
              title: context.l10n.agreementFlowPrivacyRetentionTitle,
              body: context.l10n.agreementFlowPrivacyRetentionBody,
            ),
            const SizedBox(height: 8),
            _LegalSection(
              title: context.l10n.agreementV2Section6Title,
              body: context.l10n.agreementV2Section6Body,
              last: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.disclosureKey,
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
  });

  final Key disclosureKey;
  final IconData icon;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: disclosureKey,
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: Icon(icon, size: 20, color: scheme.primary),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.64),
                height: 1.35,
              ),
            ),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.78),
        fontWeight: FontWeight.w600,
        height: 1.6,
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.body,
    this.last = false,
  });

  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBoundary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final points = [
      context.l10n.agreementV2SourceBoundaryPoint1,
      context.l10n.agreementV2SourceBoundaryPoint2,
      context.l10n.agreementV2SourceBoundaryPoint3,
    ];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.agreementV2SourceBoundaryTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    point,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrivacySummary extends StatelessWidget {
  const _PrivacySummary({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
