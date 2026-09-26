part of '../account_page.dart';

extension _AccountAuthForm on _AccountPageState {
  Widget _authHeading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _authField(
    TextEditingController controller,
    String label,
    String name, {
    String? Function(String?)? validator,
    bool secret = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? helper,
    bool last = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('account-auth-$name'),
      controller: controller,
      enabled: !context.read<MemberAccountController>().loading,
      focusNode: _authFocus.putIfAbsent(name, () => FocusNode()),
      validator: validator,
      obscureText: secret && _obscurePassword,
      autocorrect: false,
      enableSuggestions: !secret,
      textCapitalization: TextCapitalization.none,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (last) unawaited(_submit());
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        suffixIcon: secret
            ? IconButton(
                tooltip: _obscurePassword
                    ? context.l10n.accountShowPassword
                    : context.l10n.accountHidePassword,
                onPressed: () =>
                    _updateAuth(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    ),
  );

  Widget _formCard(MemberAccountController account) {
    final l10n = context.l10n;
    final entry = _mode == _AccountMode.email;
    final collectingEmail =
        entry || (_mode != _AccountMode.password && _challenge == null);
    final registrationCode =
        _mode == _AccountMode.register &&
        _challenge != null &&
        !_registerDetails;
    final showingCode = _challenge != null && !_registerDetails;
    final showingPassword =
        _mode == _AccountMode.password ||
        _registerDetails ||
        (_mode == _AccountMode.reset && _challenge != null);
    final newPassword = _mode != _AccountMode.password;
    return AutofillGroup(
      child: Form(
        key: _authForm,
        child: Column(
          key: const ValueKey('account-sign-in-card'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: AppBrandIcon(size: 46),
              ),
              const SizedBox(height: 24),
              _authHeading(l10n.accountSignInTitle, l10n.accountSignInSubtitle),
            ] else ...[
              if (_mode == _AccountMode.register)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.accountRegistrationStep(
                      _challenge == null
                          ? 1
                          : _registerDetails
                          ? 3
                          : 2,
                    ),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _authHeading(
                registrationCode
                    ? l10n.accountVerificationCode
                    : _registerDetails
                    ? l10n.accountSetupTitle
                    : _modeTitle(),
                _registerDetails
                    ? l10n.accountSetupHint
                    : showingCode
                    ? _challenge!.message
                    : collectingEmail
                    ? _modeHint()
                    : '',
              ),
              if (!collectingEmail)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('account-change-email'),
                    onPressed: account.loading
                        ? null
                        : () => _switchMode(
                            _mode == _AccountMode.password
                                ? _AccountMode.email
                                : _mode,
                          ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(
                      _email.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
            if (collectingEmail)
              _authField(
                _email,
                l10n.accountEmail,
                'email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                last: true,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.accountEmailRequired;
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                      ? null
                      : l10n.accountInvalidEmail;
                },
              ),
            if (showingCode)
              _authField(
                _code,
                l10n.accountVerificationCode,
                'code',
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                last: _mode != _AccountMode.reset,
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : l10n.accountCodeFormat,
              ),
            if (_registerDetails)
              _authField(
                _username,
                l10n.accountUsername,
                'username',
                autofillHints: const [AutofillHints.newUsername],
                helper: l10n.accountUsernameHint,
                validator: (value) =>
                    RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : l10n.accountUsernameHint,
              ),
            if (showingPassword)
              _authField(
                _password,
                l10n.accountPassword,
                'password',
                secret: true,
                autofillHints: [
                  newPassword
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                helper: newPassword ? l10n.accountPasswordLengthHint : null,
                last: !newPassword,
                validator: (value) =>
                    (value?.length ?? 0) >= (newPassword ? 12 : 1) &&
                        (value?.length ?? 0) <= 128
                    ? null
                    : newPassword
                    ? l10n.accountPasswordLengthHint
                    : l10n.accountPasswordRequired,
              ),
            if (showingPassword && newPassword)
              _authField(
                _confirmPassword,
                l10n.accountConfirmPassword,
                'confirm',
                secret: true,
                autofillHints: const [AutofillHints.newPassword],
                last: true,
                validator: (value) => value == _password.text
                    ? null
                    : l10n.accountPasswordsMismatch,
              ),
            if (_authError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _authError!,
                    key: const ValueKey('account-auth-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            FilledButton(
              key: ValueKey(
                entry ? 'account-email-continue' : 'account-auth-submit',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  account.loading ||
                      (collectingEmail && !entry && _resendSeconds > 0)
                  ? null
                  : _submit,
              child: account.loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      registrationCode ? l10n.accountContinue : _submitLabel(),
                    ),
            ),
            if (showingCode)
              TextButton(
                key: const ValueKey('account-resend-code'),
                onPressed: account.loading || _resendSeconds > 0
                    ? null
                    : () => _requestCode(resend: true),
                child: Text(
                  _resendSeconds > 0
                      ? l10n.accountResendIn(_resendSeconds)
                      : l10n.accountDeleteResendCode,
                ),
              ),
            if (entry) ...[
              Center(
                child: TextButton(
                  key: const ValueKey('account-open-register'),
                  onPressed: account.loading
                      ? null
                      : () => _switchMode(_AccountMode.register),
                  child: Text(l10n.accountNoAccount),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _ExternalLoginMethods(
                account: account,
                polling: false,
                authorization: null,
                onLogin: _externalLogin,
                onLoginApple: _loginWithApple,
                onCancel: _backAuth,
                onEmailCode: () => _switchMode(_AccountMode.code),
              ),
            ] else if (_mode == _AccountMode.password) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('account-open-reset'),
                  onPressed: account.loading
                      ? null
                      : () => _switchMode(_AccountMode.reset),
                  child: Text(l10n.accountForgotPassword),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('account-use-email-code'),
                onPressed: account.loading
                    ? null
                    : () => _switchMode(_AccountMode.code),
                child: Text(l10n.accountUseEmailCode),
              ),
            ] else
              TextButton(
                key: const ValueKey('account-auth-back'),
                onPressed: account.loading
                    ? null
                    : _registerDetails
                    ? _backAuth
                    : () => _switchMode(_AccountMode.email),
                child: Text(
                  _registerDetails
                      ? l10n.accountBackToCode
                      : l10n.accountHaveAccount,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _modeTitle() => switch (_mode) {
    _AccountMode.email => context.l10n.accountLoginTab,
    _AccountMode.password => context.l10n.accountPasswordLoginTitle,
    _AccountMode.register => context.l10n.accountRegisterTab,
    _AccountMode.code => context.l10n.accountCodeTab,
    _AccountMode.reset => context.l10n.accountResetTab,
  };

  String _modeHint() => switch (_mode) {
    _AccountMode.email => context.l10n.accountSignInSubtitle,
    _AccountMode.password => context.l10n.accountPasswordLoginHint,
    _AccountMode.register => context.l10n.accountRegisterHint,
    _AccountMode.code => context.l10n.accountCodeLoginHint,
    _AccountMode.reset => context.l10n.accountResetHint,
  };

  String _submitLabel() {
    if (_challenge == null &&
        _mode != _AccountMode.email &&
        _mode != _AccountMode.password) {
      return context.l10n.accountSendCode;
    }
    return switch (_mode) {
      _AccountMode.email => context.l10n.accountContinue,
      _AccountMode.password || _AccountMode.code => context.l10n.accountSignIn,
      _AccountMode.register => context.l10n.accountCreate,
      _AccountMode.reset => context.l10n.accountResetPassword,
    };
  }
}
