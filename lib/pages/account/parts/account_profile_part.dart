part of '../account_page.dart';

class _AccountProfilePage extends StatefulWidget {
  const _AccountProfilePage({required this.onChangeAvatar});
  final Future<void> Function() onChangeAvatar;
  @override
  State<_AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<_AccountProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _name;
  late String _savedUsername;
  late String _savedName;
  String? _error;
  bool _leaving = false;
  bool _confirming = false;
  bool _saving = false;
  bool get _dirty =>
      _username.text != _savedUsername || _name.text != _savedName;

  @override
  void initState() {
    super.initState();
    final user = context.read<MemberAccountController>().user;
    _savedUsername = user?.username ?? '';
    _savedName = user?.displayName ?? '';
    _username = TextEditingController(text: _savedUsername)
      ..addListener(_changed);
    _name = TextEditingController(text: _savedName)..addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_confirming || _saving || !mounted) return;
    if (_dirty) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.accountDiscardChanges),
          content: Text(context.l10n.accountUnsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.accountDiscardChanges),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true || !mounted) return;
    }
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final username = _username.text.trim();
    final displayName = _name.text.trim();
    try {
      await context.read<MemberAccountController>().updateProfile(
        username: username,
        displayName: displayName,
      );
      if (!mounted) return;
      setState(() {
        _username.text = username;
        _name.text = displayName;
        _savedUsername = username;
        _savedName = displayName;
      });
      showSideToast(context, context.l10n.accountSaveProfile);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<MemberAccountController>();
    final user = account.user;
    return PopScope(
      canPop: !_saving && (!_dirty || _leaving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: FloatingSubpageScaffold(
        title: context.l10n.accountEditProfile,
        onBack: _leave,
        body: user == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 440,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: FloatingSubpageScaffold.headerExtentOf(context),
                    ),
                    child: ListView(
                      padding: floatingSubpagePadding(
                        context,
                        left: 24,
                        right: 24,
                        includeHeader: false,
                        top: 28,
                        bottom: 24,
                      ),
                      children: [
                        Center(child: _MemberAvatar(user: user, size: 76)),
                        TextButton(
                          onPressed: account.loading
                              ? null
                              : widget.onChangeAvatar,
                          child: Text(context.l10n.accountChangeAvatar),
                        ),
                        if (user.avatarUrl != null)
                          TextButton(
                            onPressed: account.loading
                                ? null
                                : account.deleteAvatar,
                            child: Text(context.l10n.accountRemoveAvatar),
                          ),
                        const SizedBox(height: 24),
                        Form(
                          key: _form,
                          child: Column(
                            children: [
                              TextFormField(
                                key: const ValueKey('account-profile-name'),
                                controller: _name,
                                enabled: !account.loading,
                                maxLength: 50,
                                decoration: InputDecoration(
                                  labelText: context.l10n.accountDisplayName,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) => (value?.length ?? 0) > 50
                                    ? context.l10n.accountDisplayName
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('account-profile-username'),
                                controller: _username,
                                enabled: !account.loading,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: context.l10n.accountUsername,
                                  helperText: context.l10n.accountUsernameHint,
                                  helperMaxLines: 3,
                                  errorMaxLines: 3,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) =>
                                    RegExp(
                                      r'^[a-z0-9_]{3,30}$',
                                    ).hasMatch(value?.trim() ?? '')
                                    ? null
                                    : context.l10n.accountUsernameHint,
                              ),
                            ],
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('account-profile-save'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: _saving || account.loading || !_dirty
                              ? null
                              : _save,
                          child: Text(context.l10n.accountSaveProfile),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
