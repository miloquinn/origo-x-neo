import 'package:flutter/material.dart';

import '../../services/account/account.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/purchase_page_scaffold.dart';

/// Origo account codes are verified by the account service, not store billing.
class MembershipRedemptionPage extends StatefulWidget {
  const MembershipRedemptionPage({super.key, required this.account});

  final MemberAccountController account;

  @override
  State<MembershipRedemptionPage> createState() =>
      _MembershipRedemptionPageState();
}

class _MembershipRedemptionPageState extends State<MembershipRedemptionPage> {
  final _code = TextEditingController();
  String? _accountId;
  String? _message;
  bool _failed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.account.user?.id;
    widget.account.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (_accountId != widget.account.user?.id) {
      _accountId = widget.account.user?.id;
      _code.clear();
      _message = null;
      _failed = false;
    }
    setState(() {});
  }

  bool get _busy => _submitting || widget.account.loading;
  bool get _canRedeem =>
      !_busy && widget.account.isAuthenticated && _code.text.trim().isNotEmpty;

  Future<void> _redeem() async {
    if (!_canRedeem) return;
    final owner = _accountId;
    final code = _code.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _message = null;
      _failed = false;
    });
    try {
      await widget.account.redeemMembership(code);
      if (!mounted || widget.account.user?.id != owner) return;
      _code.clear();
      setState(() => _message = context.l10n.accountRedemptionSuccess);
    } catch (error) {
      if (!mounted || widget.account.user?.id != owner) return;
      setState(() {
        _failed = true;
        _message = error is MemberAccountException
            ? error.message
            : context.l10n.premiumOperationFailed;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    widget.account.removeListener(_accountChanged);
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final user = widget.account.user;
    return PurchasePageTheme(
      child: PurchaseDetailsPage(
        title: l10n.accountRedemptionCode,
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.redeem_rounded,
                size: 30,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.accountRedemptionHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (user != null) ...[
            Text(user.effectiveName, textAlign: TextAlign.center),
            if (user.email.isNotEmpty && user.email != user.effectiveName)
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('account-redemption-code'),
              controller: _code,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.accountRedemptionCode,
              ),
              onChanged: (_) => setState(() {
                _message = null;
                _failed = false;
              }),
              onSubmitted: (_) => _redeem(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('account-redeem-premium'),
              onPressed: _canRedeem ? _redeem : null,
              child: _submitting
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : Text(l10n.accountRedeemPremium),
            ),
          ] else
            Text(l10n.accountSignIn, textAlign: TextAlign.center),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: const ValueKey('membership-redemption-status'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _failed ? colors.error : colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
