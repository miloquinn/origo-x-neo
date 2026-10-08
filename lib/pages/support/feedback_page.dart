import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../pages/account/account_page.dart';
import '../../services/account/account.dart';
import '../../services/diagnostics/diagnostics_controller.dart';
import '../../utils/page_style_helper.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import 'feedback_copy.dart';

typedef FeedbackSubmitter =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> feedback);

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.submitter, this.platformName});

  final FeedbackSubmitter? submitter;
  final String? platformName;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.bug;
  String _feedbackId = const Uuid().v4();
  bool _attachDiagnostics = false;
  bool _submitting = false;
  bool _changingDiagnostics = false;
  String? _error;
  String? _receiptId;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _pendingPayload;

  @override
  void initState() {
    super.initState();
    _message.addListener(_invalidatePendingSubmission);
    unawaited(_loadPackageInfo());
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  void dispose() {
    _message.removeListener(_invalidatePendingSubmission);
    _message.dispose();
    super.dispose();
  }

  void _invalidatePendingSubmission() {
    if (_pendingPayload == null) return;
    _pendingPayload = null;
    _feedbackId = const Uuid().v4();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = FeedbackCopy.of(context);
    final account = context.watch<MemberAccountController>();
    final diagnostics = context.watch<DiagnosticsController>();
    return FloatingSubpageScaffold(
      title: copy.title,
      body: ListView(
        padding: floatingSubpagePadding(context, bottom: 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: account.isAuthenticated
                  ? _receiptId == null
                        ? _buildForm(copy, account, diagnostics)
                        : _buildReceipt(copy)
                  : _buildSignIn(copy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignIn(FeedbackCopy copy) => _Card(
    key: const ValueKey('feedback-sign-in-required'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.forum_outlined, size: 30),
        const SizedBox(height: 14),
        Text(
          copy.signInTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(copy.signInBody),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('feedback-sign-in'),
          onPressed: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const AccountPage())),
          icon: const Icon(Icons.person_outline_rounded),
          label: Text(copy.signIn),
        ),
      ],
    ),
  );

  Widget _buildForm(
    FeedbackCopy copy,
    MemberAccountController account,
    DiagnosticsController diagnostics,
  ) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.intro),
              const SizedBox(height: 20),
              Text(
                copy.category,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FeedbackCategory>(
                key: const ValueKey('feedback-category'),
                initialValue: _category,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final category in FeedbackCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(copy.categoryLabel(category)),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                            _invalidatePendingSubmission();
                          });
                        }
                      },
              ),
              const SizedBox(height: 18),
              Text(copy.message, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('feedback-message'),
                controller: _message,
                enabled: !_submitting,
                minLines: 6,
                maxLines: 12,
                maxLength: 4000,
                decoration: InputDecoration(
                  hintText: copy.messageHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length == 0) return copy.messageRequired;
                  if (length > 4000) return copy.messageTooLong;
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDiagnosticsCard(copy, diagnostics),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            key: const ValueKey('feedback-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('feedback-submit'),
          onPressed: _submitting
              ? null
              : () => _submit(copy, account, diagnostics),
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_submitting ? copy.submitting : copy.submit),
        ),
      ],
    ),
  );

  Widget _buildDiagnosticsCard(
    FeedbackCopy copy,
    DiagnosticsController diagnostics,
  ) => _Card(
    child: Column(
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('feedback-diagnostics-enabled'),
          contentPadding: EdgeInsets.zero,
          title: Text(copy.improvePerformance),
          subtitle: Text(
            diagnostics.supported
                ? copy.improvePerformanceBody
                : copy.diagnosticsUnavailable,
          ),
          value: diagnostics.enabled,
          onChanged: diagnostics.supported && !_changingDiagnostics
              ? (value) => _setDiagnosticsEnabled(diagnostics, value)
              : null,
        ),
        const Divider(height: 20),
        CheckboxListTile(
          key: const ValueKey('feedback-attach-diagnostics'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(copy.attachDiagnostics),
          subtitle: Text(copy.attachDiagnosticsBody),
          value: _attachDiagnostics && diagnostics.enabled,
          onChanged: diagnostics.enabled && !_submitting
              ? (value) => setState(() {
                  _attachDiagnostics = value ?? false;
                  _invalidatePendingSubmission();
                })
              : null,
        ),
      ],
    ),
  );

  Future<void> _setDiagnosticsEnabled(
    DiagnosticsController diagnostics,
    bool value,
  ) async {
    setState(() => _changingDiagnostics = true);
    await diagnostics.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _changingDiagnostics = false;
      if (!diagnostics.enabled && _attachDiagnostics) {
        _attachDiagnostics = false;
        _invalidatePendingSubmission();
      }
    });
  }

  Future<void> _submit(
    FeedbackCopy copy,
    MemberAccountController account,
    DiagnosticsController diagnostics,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    var payload = _pendingPayload;
    try {
      if (payload == null) {
        final expectedUserId = account.user?.id;
        if (expectedUserId == null) {
          _resetAfterAccountChange(copy);
          return;
        }
        Map<String, dynamic>? snapshot;
        if (_attachDiagnostics && diagnostics.enabled) {
          snapshot = diagnostics.snapshot();
        }
        final info = _packageInfo ?? await PackageInfo.fromPlatform();
        payload = Map<String, dynamic>.unmodifiable(<String, dynamic>{
          'feedback_id': _feedbackId,
          'expected_user_id': expectedUserId,
          'category': _category.apiValue,
          'message': _message.text.trim(),
          'app_version': info.version,
          'build_number': info.buildNumber,
          'platform': widget.platformName ?? _platformName(),
          'diagnostics': ?snapshot,
        });
        _pendingPayload = payload;
      }
      if (account.user?.id != payload['expected_user_id']) {
        _resetAfterAccountChange(copy);
        return;
      }
      final response =
          await (widget.submitter ?? account.readingApi.submitFeedback)(
            payload,
          );
      if (!mounted) return;
      if (account.user?.id != payload['expected_user_id']) {
        _resetAfterAccountChange(copy);
        return;
      }
      final receipt = response['feedback_id'];
      setState(() {
        _submitting = false;
        _receiptId = receipt is String && receipt.isNotEmpty
            ? receipt
            : _feedbackId;
      });
    } catch (_) {
      if (!mounted) return;
      if (payload != null && account.user?.id != payload['expected_user_id']) {
        _resetAfterAccountChange(copy);
        return;
      }
      setState(() {
        _submitting = false;
        _error = copy.failed;
      });
    }
  }

  void _resetAfterAccountChange(FeedbackCopy copy) {
    if (!mounted) return;
    setState(() {
      _pendingPayload = null;
      _feedbackId = const Uuid().v4();
      _message.clear();
      _attachDiagnostics = false;
      _submitting = false;
      _receiptId = null;
      _error = copy.accountChanged;
    });
  }

  Widget _buildReceipt(FeedbackCopy copy) => _Card(
    key: const ValueKey('feedback-success'),
    child: Column(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          copy.successTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SelectableText(
          copy.successBody(_receiptId!),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const ValueKey('feedback-send-another'),
          onPressed: () => setState(() {
            _feedbackId = const Uuid().v4();
            _message.clear();
            _attachDiagnostics = false;
            _error = null;
            _receiptId = null;
            _pendingPayload = null;
          }),
          child: Text(copy.sendAnother),
        ),
      ],
    ),
  );
}

String _platformName() => switch (defaultTargetPlatform) {
  TargetPlatform.android => 'android',
  TargetPlatform.iOS => 'ios',
  TargetPlatform.macOS => 'macos',
  TargetPlatform.windows => 'windows',
  TargetPlatform.linux => 'linux',
  TargetPlatform.fuchsia => 'fuchsia',
};

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = PageStyleHelper.palette(context);
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
