// 文件说明：账号登录、外部授权与登录态头部组件。
// 技术要点：同一账号功能库内的私有实现拆分，不扩大公开 API。

part of '../account_page.dart';

class _ExternalLoginMethods extends StatelessWidget {
  const _ExternalLoginMethods({
    required this.account,
    required this.polling,
    required this.authorization,
    required this.onLogin,
    required this.onLoginApple,
    required this.onCancel,
    this.onEmailCode,
  });
  final MemberAccountController account;
  final bool polling;
  final DeviceAuthorization? authorization;
  final ValueChanged<MemberExternalAuthMethod> onLogin;
  final VoidCallback onLoginApple;
  final VoidCallback onCancel;
  final VoidCallback? onEmailCode;

  List<_ProviderBrand> get _available => [
    if (!kIsWeb &&
        {
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform) &&
        account.providers.apple)
      _ProviderBrand.apple,
    if (account.providers.google) _ProviderBrand.google,
    if (account.providers.github) _ProviderBrand.github,
    if (account.providers.passkey) _ProviderBrand.passkey,
  ];

  Widget _button(
    BuildContext context,
    _ProviderBrand brand, {
    VoidCallback? beforeLogin,
  }) {
    final (name, label, method) = switch (brand) {
      _ProviderBrand.apple => (
        'apple',
        context.l10n.accountUseApple,
        MemberExternalAuthMethod.apple,
      ),
      _ProviderBrand.google => (
        'google',
        context.l10n.accountUseGoogle,
        MemberExternalAuthMethod.google,
      ),
      _ProviderBrand.github => (
        'github',
        context.l10n.accountUseGithub,
        MemberExternalAuthMethod.github,
      ),
      _ProviderBrand.passkey => (
        'passkey',
        context.l10n.accountUsePasskey,
        MemberExternalAuthMethod.passkey,
      ),
    };
    return _ProviderLoginButton(
      key: ValueKey('account-provider-$name'),
      label: label,
      brand: brand,
      enabled: !account.loading,
      onTap: () {
        beforeLogin?.call();
        if (brand == _ProviderBrand.apple &&
            defaultTargetPlatform == TargetPlatform.iOS) {
          onLoginApple();
        } else {
          onLogin(method);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (polling) {
      return _AuthorizationProgress(
        authorization: authorization,
        onCancel: onCancel,
      );
    }
    final available = _available;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (available.isNotEmpty) _button(context, available.first),
        if (available.length > 1 || onEmailCode != null)
          TextButton(
            key: const ValueKey('account-more-providers'),
            onPressed: account.loading
                ? null
                : () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (sheetContext) => SafeArea(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.sizeOf(sheetContext).height * .75,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.accountMoreSignInMethods,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),
                              for (final brand in available.skip(1)) ...[
                                _button(
                                  context,
                                  brand,
                                  beforeLogin: () =>
                                      Navigator.pop(sheetContext),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (onEmailCode != null)
                                OutlinedButton.icon(
                                  key: const ValueKey(
                                    'account-other-email-code',
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    onEmailCode!();
                                  },
                                  icon: const Icon(Icons.mail_outline_rounded),
                                  label: Text(context.l10n.accountUseEmailCode),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            child: Text(context.l10n.accountMoreSignInMethods),
          ),
      ],
    );
  }
}

class _AuthorizationProgress extends StatelessWidget {
  const _AuthorizationProgress({
    required this.authorization,
    required this.onCancel,
  });

  final DeviceAuthorization? authorization;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userCode = authorization?.userCode ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.accountExternalHint,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ),
          if (userCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.75),
                ),
              ),
              child: SelectableText(
                userCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ProviderBrand { github, google, apple, passkey }

class _ProviderLoginButton extends StatelessWidget {
  const _ProviderLoginButton({
    super.key,
    required this.label,
    required this.brand,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final _ProviderBrand brand;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark =
        brand == _ProviderBrand.github || brand == _ProviderBrand.apple;
    final isPasskey = brand == _ProviderBrand.passkey;
    final foreground = isDark ? Colors.white : colorScheme.onSurface;
    final background = isDark
        ? const Color(0xFF24292F)
        : isPasskey
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.52)
        : colorScheme.surface;

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF24292F)
                    : colorScheme.outlineVariant.withValues(alpha: 0.86),
              ),
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: isPasskey ? 21 : 24,
                  child: switch (brand) {
                    _ProviderBrand.passkey => Icon(
                      Icons.key_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    _ProviderBrand.apple => const Icon(
                      Icons.apple_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    _ProviderBrand.github ||
                    _ProviderBrand.google => _ProviderBrandMark(brand: brand),
                  },
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isPasskey
                          ? colorScheme.onSurfaceVariant
                          : foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: (isPasskey ? colorScheme.onSurfaceVariant : foreground)
                      .withValues(alpha: 0.68),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderBrandMark extends StatelessWidget {
  const _ProviderBrandMark({required this.brand});

  final _ProviderBrand brand;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: switch (brand) {
      _ProviderBrand.github => const _GithubMarkPainter(),
      _ProviderBrand.google => const _GoogleMarkPainter(),
      _ProviderBrand.apple || _ProviderBrand.passkey => null,
    },
  );
}

class _GithubMarkPainter extends CustomPainter {
  const _GithubMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final mark = Path()
      ..moveTo(6.1, 7.2)
      ..lineTo(5.1, 3.1)
      ..quadraticBezierTo(8.2, 3.2, 10.1, 4.8)
      ..quadraticBezierTo(12, 4.35, 13.9, 4.8)
      ..quadraticBezierTo(15.8, 3.2, 18.9, 3.1)
      ..lineTo(17.9, 7.2)
      ..quadraticBezierTo(19.6, 9, 19.6, 11.8)
      ..quadraticBezierTo(19.6, 16.7, 15.8, 18.2)
      ..quadraticBezierTo(14.9, 18.55, 14.9, 20)
      ..lineTo(14.9, 22)
      ..lineTo(9.1, 22)
      ..lineTo(9.1, 20.3)
      ..quadraticBezierTo(7.5, 20.65, 6.7, 19.5)
      ..quadraticBezierTo(6, 18.45, 5, 17.75)
      ..quadraticBezierTo(4.4, 17.3, 4.7, 16.9)
      ..quadraticBezierTo(5, 16.55, 5.7, 17)
      ..quadraticBezierTo(6.9, 17.75, 7.4, 18.35)
      ..quadraticBezierTo(8, 19, 9.1, 18.7)
      ..quadraticBezierTo(9.15, 18, 9.55, 17.55)
      ..quadraticBezierTo(4.4, 16.95, 4.4, 11.8)
      ..quadraticBezierTo(4.4, 9, 6.1, 7.2)
      ..close();
    canvas.drawPath(mark, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    Paint segment(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, -0.18, 1.3, false, segment(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 1.12, 1.16, false, segment(const Color(0xFF34A853)));
    canvas.drawArc(rect, 2.28, 0.92, false, segment(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 3.2, 1.55, false, segment(const Color(0xFFEA4335)));
    canvas.drawArc(rect, 4.75, 0.78, false, segment(const Color(0xFF4285F4)));

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.5),
      Offset(size.width * 0.93, size.height * 0.5),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user, required this.supporter});

  final MemberUser user;
  final bool supporter;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: supporter
          ? null
          : Theme.of(context).colorScheme.surfaceContainerLow,
      gradient: supporter
          ? const LinearGradient(colors: [Color(0xFF252B38), Color(0xFF121925)])
          : null,
      border: supporter
          ? Border.all(color: const Color(0xFFAA9871).withValues(alpha: .5))
          : null,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        _MemberAvatar(user: user, size: 50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.effectiveName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: supporter
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (supporter) ...[
                    const SizedBox(width: 8),
                    _Badge(label: context.l10n.accountSupporterBadge),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: supporter
                      ? Colors.white.withValues(alpha: 0.72)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
