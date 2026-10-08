import 'package:flutter/material.dart';

import 'diagnostics_consent_copy.dart';

Future<bool> showDiagnosticsConsentDialog(
  BuildContext context, {
  required Future<void> Function() onOpenPrivacy,
  required Future<void> Function(bool enable) onAnswer,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => DiagnosticsConsentDialog(
      onOpenPrivacy: onOpenPrivacy,
      onAnswer: onAnswer,
    ),
  );
  return result == true;
}

class DiagnosticsConsentDialog extends StatefulWidget {
  const DiagnosticsConsentDialog({
    super.key,
    required this.onOpenPrivacy,
    required this.onAnswer,
  });

  final Future<void> Function() onOpenPrivacy;
  final Future<void> Function(bool enable) onAnswer;

  @override
  State<DiagnosticsConsentDialog> createState() =>
      _DiagnosticsConsentDialogState();
}

class _DiagnosticsConsentDialogState extends State<DiagnosticsConsentDialog> {
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _answer(bool enable) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.onAnswer(enable);
      if (mounted) Navigator.of(context).pop(enable);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = DiagnosticsConsentCopy.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('diagnostics-consent-dialog'),
        scrollable: true,
        icon: Icon(
          Icons.monitor_heart_outlined,
          color: scheme.primary,
          size: 32,
        ),
        title: Text(copy.title, textAlign: TextAlign.center),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.introduction),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    copy.fields,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(copy.useAndLinking),
              const SizedBox(height: 8),
              Text(
                copy.exclusions,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('diagnostics-consent-privacy'),
                  onPressed: _saving ? null : widget.onOpenPrivacy,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: Text(copy.privacyPolicy),
                ),
              ),
              if (_saveFailed) ...[
                const SizedBox(height: 8),
                Text(
                  copy.saveFailed,
                  key: const ValueKey('diagnostics-consent-error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('diagnostics-consent-decline'),
            onPressed: _saving ? null : () => _answer(false),
            child: Text(copy.notNow),
          ),
          FilledButton(
            key: const ValueKey('diagnostics-consent-accept'),
            onPressed: _saving ? null : () => _answer(true),
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(copy.agreeAndEnable),
          ),
        ],
      ),
    );
  }
}
