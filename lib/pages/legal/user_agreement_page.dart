// 用户首次启动时展示连续欢迎动画、使用条款与隐私说明。
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/pages/legal/agreement_summary.dart';
import 'package:xxread/pages/onboarding/reading_welcome_page.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/side_toast.dart';

class UserAgreementPage extends StatefulWidget {
  final VoidCallback onAgreed;
  final VoidCallback? onDisagreed;

  const UserAgreementPage({
    super.key,
    required this.onAgreed,
    this.onDisagreed,
  });

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return ReadingWelcomePage(
      finalContent: const AgreementSummary(),
      completionLabel: context.l10n.agreementV2ContinueLabel,
      isCompleting: _saving,
      onComplete: _onAgreePressed,
      onDeclined: _onDisagreePressed,
    );
  }

  Future<void> _onAgreePressed() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await UserAgreementService.acceptAgreement(
        locale: Localizations.localeOf(context).toLanguageTag(),
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
  static const String currentAgreementVersion = '2026-07-19.2';
  static const String _keyAgreementAccepted = 'userAgreementAccepted';
  static const String _keyAcceptedDate = 'agreementAcceptedDate';
  static const String _keyAcceptedVersion = 'agreementAcceptedVersion';
  static const String _keyAcceptedLocale = 'agreementAcceptedLocale';
  static const String _keySourceBoundaryAccepted =
      'thirdPartySourceBoundaryAccepted';

  static Future<bool> hasUserAcceptedAgreement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getBool(_keyAgreementAccepted) ?? false) &&
          prefs.getString(_keyAcceptedVersion) == currentAgreementVersion &&
          (prefs.getBool(_keySourceBoundaryAccepted) ?? false);
    } catch (error) {
      debugPrint('检查用户协议状态失败: $error');
      return false;
    }
  }

  static Future<void> acceptAgreement({required String locale}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAgreementAccepted, true);
    await prefs.setString(
      _keyAcceptedDate,
      DateTime.now().toUtc().toIso8601String(),
    );
    await prefs.setString(_keyAcceptedVersion, currentAgreementVersion);
    await prefs.setString(_keyAcceptedLocale, locale);
    await prefs.setBool(_keySourceBoundaryAccepted, true);
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
  }
}
