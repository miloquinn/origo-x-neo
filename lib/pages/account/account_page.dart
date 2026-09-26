import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/account_avatar_image.dart';
import '../../widgets/app_brand_icon.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/qr_code_view.dart';
import '../../widgets/side_toast.dart';
import '../../widgets/store_reader_account_entry.dart';
import 'avatar_crop_page.dart';
import 'premium_membership_page.dart';
import 'premium_policy_page.dart';

part 'parts/account_auth_part.dart';
part 'parts/account_auth_form_part.dart';
part 'parts/account_profile_part.dart';
part 'parts/account_membership_part.dart';
part 'parts/account_security_part.dart';
part 'parts/account_shared_widgets_part.dart';

enum _AccountMode { email, password, register, code, reset }

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const _avatarProcessor = AvatarImageProcessor();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _username = TextEditingController();
  final _code = TextEditingController();
  final _mfaLoginCode = TextEditingController();
  _AccountMode _mode = _AccountMode.email;
  MemberEmailChallenge? _challenge;
  DeviceAuthorization? _deviceAuthorization;
  bool _polling = false;
  bool _openingExternal = false;
  bool _obscurePassword = true;
  bool _registerDetails = false;
  final _authForm = GlobalKey<FormState>();
  final _authScroll = ScrollController();
  final _authFocus = <String, FocusNode>{};
  String? _authError;
  DateTime? _resendAfter;
  Timer? _resendTimer;
  int _authGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initializeAccount());
    });
  }

  Future<void> _initializeAccount({bool force = false}) async {
    final account = context.read<MemberAccountController>();
    try {
      await account.initialize(force: force);
      if (!mounted) return;
      _syncProfile(account.user);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _authScroll.dispose();
    for (final focus in _authFocus.values) {
      focus.dispose();
    }
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _username.dispose();
    _code.dispose();
    _mfaLoginCode.dispose();
    super.dispose();
  }

  void _syncProfile(MemberUser? user) {
    if (user == null) return;
    _username.text = user.username;
  }

  void _showError(Object error) {
    if (!mounted) return;
    showSideToast(context, error.toString(), kind: SideToastKind.error);
  }

  void _updateAuth(VoidCallback update) => setState(update);

  void _resetAuthViewport() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_authScroll.hasClients) _authScroll.jumpTo(0);
  }

  void _switchMode(_AccountMode mode) {
    if (context.read<MemberAccountController>().loading || _openingExternal) {
      return;
    }
    _authGeneration++;
    _resendTimer?.cancel();
    _resendAfter = null;
    _resetAuthViewport();
    context.read<MemberAccountController>().clearError();
    setState(() {
      _mode = mode;
      _challenge = null;
      _registerDetails = false;
      _authError = null;
      _code.clear();
      _password.clear();
      _confirmPassword.clear();
      if (mode == _AccountMode.register) _username.clear();
    });
  }

  void _backAuth() {
    final account = context.read<MemberAccountController>();
    if (!_polling && (account.loading || _openingExternal)) return;
    if (_polling) {
      _authGeneration++;
      unawaited(
        account.cancelPendingDeviceAuthorization().catchError(_showError),
      );
      setState(() {
        _openingExternal = false;
        _polling = false;
        _deviceAuthorization = null;
      });
    } else if (_registerDetails) {
      _resetAuthViewport();
      setState(() {
        _registerDetails = false;
        _authError = null;
        _password.clear();
        _confirmPassword.clear();
      });
    } else if (_challenge != null) {
      _switchMode(_mode);
    } else {
      _switchMode(_AccountMode.email);
    }
  }

  bool _validateAuthForm() {
    final invalid = _authForm.currentState?.validateGranularly();
    if (invalid == null) return false;
    if (invalid.isEmpty) return true;
    final field = invalid.first;
    final key = field.widget.key;
    if (key is ValueKey<String>) {
      _authFocus[key.value.replaceFirst('account-auth-', '')]?.requestFocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (field.mounted) {
        Scrollable.ensureVisible(
          field.context,
          alignment: .15,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
    return false;
  }

  void _continueWithEmail() {
    if (!_validateAuthForm()) return;
    _switchMode(_AccountMode.password);
  }

  Future<void> _requestCode({bool resend = false}) async {
    final account = context.read<MemberAccountController>();
    final generation = _authGeneration;
    final email = _email.text.trim();
    final purpose = switch (_mode) {
      _AccountMode.register => MemberEmailCodePurpose.registration,
      _AccountMode.reset => MemberEmailCodePurpose.passwordReset,
      _ => MemberEmailCodePurpose.login,
    };
    try {
      final challenge = await account.requestCode(email, purpose);
      if (!mounted || generation != _authGeneration) return;
      _resetAuthViewport();
      setState(() {
        _challenge = challenge;
        _authError = null;
        if (resend) _code.clear();
      });
    } catch (error) {
      if (!mounted || generation != _authGeneration) return;
      if (error is MemberAccountException && error.retryAfter != null) {
        _resendAfter = DateTime.now().add(Duration(seconds: error.retryAfter!));
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {});
          if (_resendSeconds == 0) timer.cancel();
        });
      }
      setState(() => _authError = error.toString());
    }
  }

  int get _resendSeconds {
    final milliseconds =
        _resendAfter?.difference(DateTime.now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  void _completeSignIn(MemberAccountController account) {
    if (!mounted) return;
    _password.clear();
    _confirmPassword.clear();
    _code.clear();
    _syncProfile(account.user);
    if (account.mfaRequired) return;
    TextInput.finishAutofillContext();
    showSideToast(context, context.l10n.settingsAccountVerified);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final account = context.read<MemberAccountController>();
    if (account.loading || !_validateAuthForm()) {
      return;
    }
    final generation = _authGeneration;
    setState(() => _authError = null);
    if (_mode == _AccountMode.email) {
      _continueWithEmail();
      return;
    }
    if (_mode != _AccountMode.password && _challenge == null) {
      await _requestCode();
      return;
    }
    if (_mode == _AccountMode.register && !_registerDetails) {
      _resetAuthViewport();
      setState(() => _registerDetails = true);
      return;
    }
    try {
      switch (_mode) {
        case _AccountMode.email:
          return;
        case _AccountMode.password:
          await account.loginPassword(_email.text.trim(), _password.text);
        case _AccountMode.code:
          await account.verifyEmailCode(
            email: _email.text.trim(),
            challengeId: _challenge!.id,
            code: _code.text.trim(),
          );
        case _AccountMode.register:
          await account.registerPassword(
            email: _email.text.trim(),
            challengeId: _challenge!.id,
            code: _code.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
          );
        case _AccountMode.reset:
          await account.resetPassword(
            email: _email.text.trim(),
            challengeId: _challenge!.id,
            code: _code.text.trim(),
            password: _password.text,
          );
      }
      if (!mounted || generation != _authGeneration) return;
      _completeSignIn(account);
    } catch (error) {
      if (!mounted || generation != _authGeneration) return;
      if (_mode == _AccountMode.register &&
          error is MemberAccountException &&
          error.code == 'codeInvalid') {
        _resetAuthViewport();
        _registerDetails = false;
        _password.clear();
        _confirmPassword.clear();
      }
      setState(() => _authError = error.toString());
    }
  }

  Future<void> _externalLogin(MemberExternalAuthMethod method) async {
    if (_openingExternal || _polling) return;
    final generation = ++_authGeneration;
    final account = context.read<MemberAccountController>();
    setState(() => _openingExternal = true);
    try {
      if (method == MemberExternalAuthMethod.passkey) {
        await account.loginPasskey();
        if (!mounted || generation != _authGeneration) return;
        _completeSignIn(account);
        return;
      }
      final authorization = await account.beginExternalLogin(method);
      if (!mounted || generation != _authGeneration) return;
      final uri =
          authorization.verificationUriComplete ??
          authorization.verificationUri;
      if (!await _openExternalLoginUri(uri)) {
        if (generation == _authGeneration) {
          await account.cancelPendingDeviceAuthorization();
        }
        return;
      }
      if (!mounted || generation != _authGeneration) return;
      setState(() {
        _deviceAuthorization = authorization;
        _polling = true;
      });
      final deadline = DateTime.now().add(
        Duration(seconds: authorization.expiresIn),
      );
      while (mounted &&
          _polling &&
          generation == _authGeneration &&
          DateTime.now().isBefore(deadline)) {
        await Future.any<void>([
          Future<void>.delayed(Duration(seconds: authorization.interval)),
          account.waitForAuthCallback(
            Duration(seconds: authorization.interval),
          ),
        ]);
        if (!mounted || !_polling || generation != _authGeneration) return;
        var complete = false;
        try {
          complete = await account.pollDeviceAuthorization(authorization);
        } on MemberAccountException catch (error) {
          if (error.code != 'slow_down') rethrow;
          account.clearError();
          await Future<void>.delayed(
            Duration(seconds: error.retryAfter ?? authorization.interval),
          );
          continue;
        }
        if (!complete) continue;
        if (!mounted || generation != _authGeneration) return;
        _syncProfile(account.user);
        setState(() {
          _polling = false;
          _deviceAuthorization = null;
        });
        _completeSignIn(account);
        return;
      }
      if (mounted && _polling && generation == _authGeneration) {
        setState(() {
          _polling = false;
          _deviceAuthorization = null;
          _authError = context.l10n.accountAuthorizationExpired;
        });
      }
    } catch (error) {
      if (!mounted || generation != _authGeneration) return;
      if (mounted) {
        setState(() {
          _polling = false;
          _deviceAuthorization = null;
        });
      }
      _showError(error);
    } finally {
      if (mounted && generation == _authGeneration) {
        if (!_polling && account.pendingDeviceAuthorization != null) {
          await account.cancelPendingDeviceAuthorization();
        }
      }
      if (mounted && generation == _authGeneration) {
        setState(() => _openingExternal = false);
      }
    }
  }

  /// Presents the GitHub/Google device-authorization URL. On iOS/macOS this
  /// uses `ASWebAuthenticationSession` (via flutter_web_auth_2) so sign-in
  /// stays inside the app instead of switching to the system browser (App
  /// Store Guideline 4). The `xxread` scheme is already registered for this
  /// purpose, so the sheet dismisses itself once the backend redirects to
  /// it, racing the same way `account.waitForAuthCallback` already does for
  /// the polling loop below. Returns false if the user cancelled.
  Future<bool> _openExternalLoginUri(Uri uri) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await FlutterWebAuth2.authenticate(
          url: uri.toString(),
          callbackUrlScheme: 'xxread',
        );
        return true;
      } on PlatformException catch (error) {
        if (error.code == 'CANCELED') return false;
        rethrow;
      }
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const MemberAccountException('无法打开安全登录页面');
    }
    return true;
  }

  Future<void> _loginWithApple() async {
    final account = context.read<MemberAccountController>();
    try {
      await account.loginWithApple();
      if (!mounted) return;
      _completeSignIn(account);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _verifyMfaLogin() async {
    try {
      final account = context.read<MemberAccountController>();
      await account.verifyMfa(_mfaLoginCode.text);
      if (!mounted) return;
      _completeSignIn(account);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _changeAvatar() async {
    final account = context.read<MemberAccountController>();
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    try {
      final imageInfo = await _avatarProcessor.inspect(bytes);
      if (!mounted) return;
      final cropRect = await Navigator.of(context).push<ui.Rect>(
        MaterialPageRoute(
          builder: (_) => AvatarCropPage(bytes: bytes, imageInfo: imageInfo),
        ),
      );
      if (cropRect == null) return;
      final upload = await _avatarProcessor.cropAndCompress(
        bytes,
        sourceRect: cropRect,
      );
      await account.uploadAvatar(upload);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<MemberAccountController>();
    final user = account.user;
    final isAuth = user == null || account.mfaRequired;
    final internalBack =
        isAuth &&
        !account.mfaRequired &&
        (_mode != _AccountMode.email || _polling);
    final authBusy =
        isAuth && (account.loading || _openingExternal) && !_polling;
    return PopScope(
      canPop: !internalBack && !authBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && internalBack) _backAuth();
      },
      child: FloatingSubpageScaffold(
        title: isAuth ? '' : context.l10n.accountPageTitle,
        onBack: authBusy
            ? () {}
            : internalBack
            ? _backAuth
            : null,
        body: account.initialized
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: isAuth ? 440 : 520,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: FloatingSubpageScaffold.headerExtentOf(context),
                    ),
                    child: ListView(
                      controller: _authScroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: floatingSubpagePadding(
                        context,
                        left: 24,
                        right: 24,
                        includeHeader: false,
                        top: 24,
                        bottom: 24,
                      ),
                      children: [
                        if (account.mfaRequired)
                          ..._buildMfaChallenge(account)
                        else if (user == null)
                          ..._buildSignedOut(account)
                        else
                          ..._buildSignedIn(account, user),
                        if (AppDistribution.isStore &&
                            !account.mfaRequired &&
                            !_polling &&
                            (user != null || _mode == _AccountMode.email)) ...[
                          const SizedBox(height: 16),
                          StoreReaderAccountEntry(
                            key: const ValueKey('account-reader-license'),
                            account: account,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          key: const ValueKey('account-privacy-link'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const PremiumPolicyPage(
                                policy: PremiumPolicy.privacy,
                              ),
                            ),
                          ),
                          child: Text(context.l10n.premiumPrivacyPolicy),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<Widget> _buildSignedOut(MemberAccountController account) => [
    if (account.error != null && _authError == null && !account.loading) ...[
      _AccountLoadError(
        message: account.error!,
        onRetry: () => unawaited(_initializeAccount(force: true)),
      ),
      const SizedBox(height: 16),
    ],
    if (_polling) ...[
      _authHeading(
        context.l10n.accountAuthorizationTitle,
        context.l10n.accountExternalHint,
      ),
      _AuthorizationProgress(
        authorization: _deviceAuthorization,
        onCancel: _backAuth,
      ),
      if (_deviceAuthorization != null)
        TextButton(
          onPressed: () => _openExternalLoginUri(
            _deviceAuthorization!.verificationUriComplete ??
                _deviceAuthorization!.verificationUri,
          ),
          child: Text(context.l10n.accountReopenAuthorization),
        ),
    ] else ...[
      if (_openingExternal) const LinearProgressIndicator(),
      AbsorbPointer(absorbing: _openingExternal, child: _formCard(account)),
    ],
  ];

  List<Widget> _buildMfaChallenge(MemberAccountController account) => [
    _authHeading(
      context.l10n.accountMfaChallengeTitle,
      context.l10n.accountMfaChallengeHint,
    ),
    _accountTextField(
      _mfaLoginCode,
      context.l10n.accountMfaOrRecoveryCode,
      Icons.password_rounded,
    ),
    const SizedBox(height: 20),
    FilledButton(
      key: const ValueKey('account-mfa-verify'),
      onPressed: account.loading ? null : _verifyMfaLogin,
      child: Text(context.l10n.accountMfaVerify),
    ),
    TextButton(
      onPressed: account.loading ? null : account.logout,
      child: Text(context.l10n.accountSignOut),
    ),
  ];

  List<Widget> _buildSignedIn(
    MemberAccountController account,
    MemberUser user,
  ) => [
    _SignedInHeader(
      user: user,
      supporter:
          account.hasPremiumAccess &&
          (!AppDistribution.isStore || account.hasPermanentReaderAccess),
    ),
    const SizedBox(height: 16),
    _AccountActionsCard(
      user: user,
      onEditProfile: _openProfileEditor,
      onOpenSecurity: _openAccountSecurity,
      onOpenReferral: _openReferral,
      onOpenSupport: _openSupport,
    ),
    const SizedBox(height: 20),
    TextButton.icon(
      onPressed: account.loading
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.l10n.accountSignOut),
                  content: Text(context.l10n.accountSignOutHint),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.accountSignOut),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await account.logout();
              if (mounted) _switchMode(_AccountMode.email);
            },
      icon: const Icon(Icons.logout_rounded),
      label: Text(context.l10n.accountSignOut),
    ),
  ];

  Future<void> _openProfileEditor() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AccountProfilePage(onChangeAvatar: _changeAvatar),
      ),
    );
  }

  Future<void> _openAccountSecurity() async {
    final account = context.read<MemberAccountController>();
    if (account.mfaStatus == null) {
      try {
        await account.loadMfaStatus();
      } catch (error) {
        _showError(error);
        return;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _AccountSecurityPage()),
    );
  }

  Future<void> _openReferral() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _AccountReferralPage()),
    );
  }

  Future<void> _openSupport() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PremiumMembershipPage(
          account: context.read<MemberAccountController>(),
        ),
      ),
    );
  }
}
