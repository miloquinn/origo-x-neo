import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/legal/legal_document_repository.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../legal/legal_copy.dart';
import '../legal/legal_document_page.dart';

enum PremiumPolicy { terms, privacy }

/// Membership legal information with the purchase channel disclosures that
/// Apple and Google require at the point of sale.
class PremiumPolicyPage extends StatefulWidget {
  const PremiumPolicyPage({
    super.key,
    required this.policy,
    this.usesAppleBilling = true,
    this.usesGoogleBilling = false,
    this.repository,
  });

  static final appleEulaUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  final PremiumPolicy policy;
  final bool usesAppleBilling;
  final bool usesGoogleBilling;
  final LegalDocumentRepository? repository;

  @override
  State<PremiumPolicyPage> createState() => _PremiumPolicyPageState();
}

class _PremiumPolicyPageState extends State<PremiumPolicyPage> {
  LegalCatalogSnapshot? _snapshot;
  Object? _error;
  String? _locale;

  LegalDocumentRepository get _repository =>
      widget.repository ?? LegalDocumentRepository.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale == locale) return;
    _locale = locale;
    unawaited(_load(locale));
  }

  Future<void> _load(String locale) async {
    try {
      final snapshot = await _repository.load(locale: locale);
      if (!mounted || _locale != locale) return;
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted || _locale != locale) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.policy == PremiumPolicy.terms
        ? l10n.premiumMembershipTerms
        : l10n.premiumPrivacyPolicy;
    if (_snapshot == null) {
      final sections = _channelSections(context);
      return FloatingSubpageScaffold(
        title: title,
        body: SingleChildScrollView(
          padding: floatingSubpagePadding(context, bottom: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _error == null
                          ? LegalCopy.of(context).loading
                          : LegalCopy.of(context).loadFailed,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _error = null);
                            unawaited(_load(_locale!));
                          },
                          child: Text(LegalCopy.of(context).retry),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    for (final section in sections) ...[
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        section.body,
                        style: const TextStyle(fontSize: 16, height: 1.65),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final document = snapshot.catalog.document(
      widget.policy == PremiumPolicy.terms ? 'membership' : 'privacy',
    );
    if (document == null) {
      return FloatingSubpageScaffold(
        title: title,
        body: Center(child: Text(LegalCopy.of(context).loadFailed)),
      );
    }
    return LegalDocumentPage(
      document: document,
      repository: _repository,
      source: snapshot.source,
      checkedAt: snapshot.checkedAt,
      additionalSections: _channelSections(context),
    );
  }

  List<LegalDocumentSupplement> _channelSections(BuildContext context) {
    final l10n = context.l10n;
    if (widget.policy == PremiumPolicy.terms) {
      return [
        LegalDocumentSupplement(
          title: l10n.premiumBenefitsTitle,
          body:
              '${l10n.settingsAdditionalSourceProtocolsTitle}\n${l10n.premiumProtocolsBenefit}\n\n'
              '${l10n.settingsPrivateBookSourceNetworkTitle}\n${l10n.premiumPrivateNetworkBenefit}\n\n'
              '${l10n.premiumSourceNotice}\n${l10n.premiumSetupHint}',
        ),
        LegalDocumentSupplement(
          title: l10n.premiumBillingTitle,
          body: widget.usesAppleBilling
              ? l10n.premiumBillingBody
              : widget.usesGoogleBilling
              ? l10n.storePremiumBilling('Google Play')
              : l10n.premiumBillingBodyOther,
        ),
        LegalDocumentSupplement(
          title: l10n.premiumAccountBindingTitle,
          body: l10n.premiumAccountBindingBody,
        ),
        if (widget.usesAppleBilling) ...[
          LegalDocumentSupplement(
            title: l10n.accountAppleRestore,
            body: l10n.premiumRestoreHelp,
          ),
          LegalDocumentSupplement(
            title: l10n.premiumRefundTitle,
            body: l10n.premiumRefundTerms,
          ),
        ],
        if (widget.usesGoogleBilling) ...[
          LegalDocumentSupplement(
            title: l10n.accountAppleRestore,
            body: l10n.storePremiumRestoreHelp('Google Play'),
          ),
          LegalDocumentSupplement(
            title: l10n.premiumRefundTitle,
            body: l10n.storeGoogleRefundTerms,
          ),
        ],
      ];
    }
    return [
      LegalDocumentSupplement(
        title: l10n.premiumPrivacyAccountTitle,
        body: l10n.premiumPrivacyAccountBody,
      ),
      LegalDocumentSupplement(
        title: Localizations.localeOf(context).languageCode == 'zh'
            ? '账号阅读统计与排行榜'
            : 'Account reading statistics and leaderboards',
        body: Localizations.localeOf(context).languageCode == 'zh'
            ? '登录后，阅读记录的唯一编号、账号归属、起止时间及阅读时长会同步到官方服务器，用于跨设备统计和去重；此功能不上传书籍正文、书名或书单。未登录的记录保存在本机，仅在你确认合并后归入所选账号，不能重复转给其他账号。公开排行榜默认关闭，开启后展示昵称、头像和有效阅读时长；关闭后不再公开排名，个人云端统计仍保留。注销账号会删除对应云端阅读记录。'
            : 'While signed in, record IDs, account ownership, reading timestamps and durations sync to our server for cross-device statistics and deduplication. Book text, titles and book lists are not uploaded by this feature. Guest records stay on your device until you choose an account to import them into; imported records cannot be reassigned. Public rankings are off by default. Opting in shares your name, avatar and ranked reading time. Opting out hides your ranking while preserving private cloud statistics. Deleting your account deletes its cloud reading records.',
      ),
      LegalDocumentSupplement(
        title: l10n.premiumPrivacyPurchaseTitle,
        body: widget.usesGoogleBilling
            ? l10n.storePrivacyPurchaseBody
            : l10n.premiumPrivacyPurchaseBody,
      ),
    ];
  }
}
