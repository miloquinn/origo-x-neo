// 用户首次启动时展示连续欢迎动画、使用条款与隐私说明。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/legal_document.dart';
import '../../services/legal/legal_document_repository.dart';

import 'package:xxread/pages/legal/agreement_summary.dart';
import 'package:xxread/pages/onboarding/reading_welcome_page.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/side_toast.dart';

class UserAgreementPage extends StatefulWidget {
  final VoidCallback onAgreed;
  final VoidCallback? onDisagreed;
  final LegalDocumentRepository? repository;
  final int initialPage;

  const UserAgreementPage({
    super.key,
    required this.onAgreed,
    this.onDisagreed,
    this.repository,
    this.initialPage = 0,
  });

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  bool _saving = false;
  LegalCatalogSnapshot? _snapshot;
  LegalCatalogSnapshot? _update;
  Future<LegalCatalogSnapshot>? _initialRefresh;
  String? _locale;
  LegalDocumentRepository get _repository =>
      widget.repository ?? LegalDocumentRepository.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale != locale) {
      _locale = locale;
      _snapshot = null;
      _update = null;
      _saving = false;
      unawaited(_loadDocuments(locale));
    }
  }

  Future<void> _loadDocuments(String locale) async {
    final local = await _repository.load(locale: locale);
    if (!mounted || _locale != locale) return;
    final pending = _repository.refresh(locale: locale);
    _initialRefresh = pending;
    setState(() => _snapshot = local);
    final latest = await pending;
    if (!mounted || _locale != locale) return;
    setState(() {
      if (latest.catalog.contentHash == _snapshot?.catalog.contentHash) {
        _snapshot = latest;
      } else {
        _update = latest;
      }
    });
  }

  void _showUpdatedDocuments() {
    if (_saving || _update == null) return;
    setState(() {
      _snapshot = _update;
      _update = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReadingWelcomePage(
      initialPage: widget.initialPage,
      finalContent: _snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_update != null)
                  TextButton(
                    key: const Key('legal-welcome-updated'),
                    onPressed: _showUpdatedDocuments,
                    child: Text(
                      _locale!.startsWith('zh')
                          ? '协议已更新，查看新版本'
                          : 'Updated documents are available. View update',
                    ),
                  ),
                AgreementSummary(
                  catalog: _snapshot!.catalog,
                  source: _snapshot!.source,
                  checkedAt: _snapshot!.checkedAt,
                  repository: _repository,
                ),
              ],
            ),
      completionLabel: context.l10n.agreementV2ContinueLabel,
      isCompleting: _saving || _snapshot == null,
      onComplete: _onAgreePressed,
      onDeclined: _onDisagreePressed,
    );
  }

  Future<void> _onAgreePressed() async {
    if (_saving || _snapshot == null) return;
    final displayed = _snapshot!.catalog;
    final clickedLocale = _locale!;
    setState(() => _saving = true);
    try {
      // Finish the already-started, bounded update check before committing.
      // Offline failure still permits the explicitly displayed local version.
      final latest = await _initialRefresh;
      if (!mounted || _locale != clickedLocale) return;
      final update = _update ?? latest;
      if (update != null &&
          !update.refreshError &&
          update.catalog.acceptanceDocuments.any(
            (document) =>
                displayed.document(document.id)?.consentVersion !=
                document.consentVersion,
          )) {
        setState(() {
          _snapshot = update;
          _update = null;
          _saving = false;
        });
        showSideToast(
          context,
          clickedLocale.startsWith('zh')
              ? '条款已更新，请查看后再次同意。'
              : 'The terms have changed. Review them before agreeing.',
        );
        return;
      }
      await UserAgreementService.acceptAgreement(
        locale: clickedLocale,
        catalog: displayed,
      );
      if (mounted) widget.onAgreed();
    } catch (error) {
      debugPrint('保存用户协议状态失败: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      showSideToast(
        context,
        context.l10n.agreementV2SaveFailed,
        kind: SideToastKind.error,
      );
    }
  }

  void _onDisagreePressed() {
    if (_saving) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.agreementV2ExitDialogTitle),
        content: Text(context.l10n.agreementV2ExitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.agreementV2CancelLabel),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDisagreed?.call();
            },
            child: Text(context.l10n.agreementV2ConfirmExitLabel),
          ),
        ],
      ),
    );
  }
}

class UserAgreementService {
  static const String _keyAgreementAccepted = 'userAgreementAccepted';
  static const String _keyAcceptedDate = 'agreementAcceptedDate';
  static const String _keyAcceptedVersion = 'agreementAcceptedVersion';
  static const String _keyAcceptedLocale = 'agreementAcceptedLocale';
  static const String _keySourceBoundaryAccepted =
      'thirdPartySourceBoundaryAccepted';
  // Device-local receipts must not be imported as another user's consent.
  static const String receiptKey = 'member_legal_acceptance_v1';

  static Future<bool> hasUserAcceptedAgreement({
    LegalCatalog? catalog,
    LegalDocumentRepository? repository,
    String locale = 'en',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyAgreementAccepted) != true ||
          prefs.getBool(_keySourceBoundaryAccepted) != true) {
        return false;
      }
      final raw = prefs.getString(receiptKey);
      if (raw == null) return false;
      final receipt = jsonDecode(raw) as Map<String, dynamic>;
      if (receipt['schemaVersion'] != 1 ||
          DateTime.tryParse(receipt['acceptedAt'] as String) == null) {
        return false;
      }
      final accepted = receipt['documents'] as Map<String, dynamic>;
      catalog ??= (await (repository ?? LegalDocumentRepository.instance).load(
        locale: locale,
      )).catalog;
      return catalog.acceptanceDocuments.every((document) {
        final entry = accepted[document.id];
        return entry is Map &&
            entry['consentVersion'] == document.consentVersion &&
            entry['revision'] is String &&
            entry['hash'] is String &&
            (entry['hash'] as String).length == 64;
      });
    } catch (error) {
      debugPrint('检查用户协议状态失败: $error');
      return false;
    }
  }

  static Future<void> acceptAgreement({
    required String locale,
    LegalCatalog? catalog,
    LegalDocumentRepository? repository,
  }) async {
    catalog ??= (await (repository ?? LegalDocumentRepository.instance).load(
      locale: locale,
    )).catalog;
    final prefs = await SharedPreferences.getInstance();
    final acceptedAt = DateTime.now().toUtc().toIso8601String();
    final receipt = jsonEncode({
      'schemaVersion': 1,
      'acceptedAt': acceptedAt,
      'locale': locale,
      'contentLocale': catalog.locale,
      'bundleVersion': catalog.bundleVersion,
      'documents': {
        for (final document in catalog.acceptanceDocuments)
          document.id: {
            'revision': document.revision,
            'consentVersion': document.consentVersion,
            'hash': document.contentHash,
            'updatedAt': document.updatedAt,
            'effectiveDate': document.effectiveDate,
            'canonicalUrl': document.canonicalUrl.toString(),
          },
      },
    });
    Future<void> requireWrite(Future<bool> write) async {
      if (!await write) throw StateError('Could not persist agreement');
    }

    await requireWrite(prefs.setString(_keyAcceptedDate, acceptedAt));
    await requireWrite(
      prefs.setString(_keyAcceptedVersion, catalog.bundleVersion),
    );
    await requireWrite(prefs.setString(_keyAcceptedLocale, locale));
    await requireWrite(prefs.setBool(_keySourceBoundaryAccepted, true));
    await requireWrite(prefs.setBool(_keyAgreementAccepted, true));
    // Last write commits the document receipt. Older flags alone cannot grant consent.
    await requireWrite(prefs.setString(receiptKey, receipt));
  }

  static Future<DateTime?> getAgreementAcceptedDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyAcceptedDate);
      return value == null ? null : DateTime.tryParse(value);
    } catch (error) {
      debugPrint('读取用户协议同意时间失败: $error');
      return null;
    }
  }

  static Future<void> resetAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAgreementAccepted);
    await prefs.remove(_keyAcceptedDate);
    await prefs.remove(_keyAcceptedVersion);
    await prefs.remove(_keyAcceptedLocale);
    await prefs.remove(_keySourceBoundaryAccepted);
    await prefs.remove(receiptKey);
  }
}
