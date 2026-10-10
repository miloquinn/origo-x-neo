import 'package:flutter/material.dart';

import '../../book_sources/models/registered_book_source.dart';
import '../../book_sources/services/book_source_client.dart';
import '../../book_sources/source_engine/source_browser_session.dart';
import '../../book_sources/source_engine/source_login_ui.dart';
import '../../book_sources/source_engine/source_transport.dart';
import '../../book_sources/protocol/book_source_protocol.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/side_toast.dart';

class SourceLoginPage extends StatefulWidget {
  const SourceLoginPage({super.key, required this.source, this.client});

  final RegisteredBookSource source;
  final BookSourceClient? client;

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  BookSourceClient? _ownedClient;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _choices = {};
  List<SourceLoginField> _fields = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  BookSourceClient get _client =>
      widget.client ?? (_ownedClient ??= BookSourceClient());

  Uri? get _browserLoginUri {
    final config = widget.source.sourceConfig;
    return config == null ? null : sourceBrowserLoginUri(config);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _ownedClient?.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fields = await _client.loadLoginFields(widget.source);
      if (!mounted) return;
      setState(() {
        _applyLoadedFields(fields, initialLoad: true);
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  Future<void> _login([SourceLoginField? button]) async {
    if (_submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final message = await _client.loginSource(widget.source, {
        for (final entry in _controllers.entries) entry.key: entry.value.text,
        ..._choices,
      }, action: button?.action);
      if (!mounted) return;
      await _reloadSavedFields();
      if (!mounted) return;
      if (message != null) {
        setState(() => _submitting = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(widget.source.name),
            content: SingleChildScrollView(child: SelectableText(message)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.confirm),
              ),
            ],
          ),
        );
        return;
      }
      showSideToast(
        context,
        context.l10n.sourceLoginSaved,
        kind: SideToastKind.success,
      );
    } on SourceBrowserCancelled {
      // Closing the browser is an expected way to leave sign-in unchanged.
    } on Object catch (error) {
      debugPrint('[SourceLoginPage] login failed: $error');
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _clear() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _client.clearSourceLogin(widget.source);
      if (!mounted) return;
      await _reloadSavedFields(resetToDefaults: true);
      if (!mounted) return;
      showSideToast(
        context,
        context.l10n.sourceLoginCleared,
        kind: SideToastKind.success,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reloadSavedFields({bool resetToDefaults = false}) async {
    final fields = await _client.loadLoginFields(widget.source);
    if (!mounted) return;
    setState(
      () => _applyLoadedFields(
        fields,
        initialLoad: false,
        resetToDefaults: resetToDefaults,
      ),
    );
  }

  void _applyLoadedFields(
    List<SourceLoginField> fields, {
    required bool initialLoad,
    bool resetToDefaults = false,
  }) {
    final previousFields = {for (final field in _fields) field.name: field};
    final inputNames = {
      for (final field in fields)
        if (field.isInput) field.name,
    };
    for (final name in _controllers.keys.toList()) {
      if (!inputNames.contains(name)) {
        _controllers.remove(name)?.dispose();
      }
    }

    final choiceNames = {
      for (final field in fields)
        if (!field.isInput &&
            (field.chars.isNotEmpty || field.type == 'toggle'))
          field.name,
    };
    _choices.removeWhere((name, _) => !choiceNames.contains(name));

    for (final field in fields) {
      final previous = previousFields[field.name];
      if (field.isInput) {
        final savedValue = field.defaultValue ?? '';
        final controller = _controllers[field.name];
        if (controller == null) {
          _controllers[field.name] = TextEditingController(text: savedValue);
        } else if (initialLoad ||
            resetToDefaults ||
            previous == null ||
            previous.defaultValue != field.defaultValue) {
          controller.value = TextEditingValue(
            text: savedValue,
            selection: TextSelection.collapsed(offset: savedValue.length),
          );
        }
      } else if (field.chars.isNotEmpty) {
        final savedValue = field.defaultValue ?? field.chars.first;
        final currentValue = _choices[field.name];
        if (initialLoad ||
            resetToDefaults ||
            previous == null ||
            previous.defaultValue != field.defaultValue ||
            currentValue == null ||
            !field.chars.contains(currentValue)) {
          _choices[field.name] = savedValue;
        }
      } else if (field.type == 'toggle') {
        if (initialLoad ||
            resetToDefaults ||
            previous == null ||
            previous.defaultValue != field.defaultValue ||
            !_choices.containsKey(field.name)) {
          _choices[field.name] = field.defaultValue ?? 'false';
        }
      }
    }
    _fields = fields;
  }

  String _message(Object error) {
    if (error is SourceConnectionException) {
      return context.l10n.sourceLoginConnectionFailed;
    }
    return error is BookSourceProtocolException
        ? error.message
        : context.l10n.sourceLoginFailed('$error');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final browserLoginUri = _browserLoginUri;
    return FloatingSubpageScaffold(
      title: context.l10n.sourceLoginTitle,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: floatingSubpagePadding(
              context,
              left: 20,
              top: 8,
              right: 20,
              bottom: 40,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.key_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.source.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.l10n.sourceLoginSecureStorageNotice,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (browserLoginUri != null) ...[
                  _buildBrowserLogin(browserLoginUri),
                  const SizedBox(height: 18),
                ],
                ..._buildForm(),
                if (_fields.isEmpty && browserLoginUri == null) ...[
                  Text(
                    context.l10n.sourceLoginNoForm,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 13),
                ],
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: scheme.error)),
                  const SizedBox(height: 13),
                ],
                if (_fields.isNotEmpty &&
                    !_fields.any(
                      (field) => field.isButton && !field.isSectionHeading,
                    )) ...[
                  FilledButton.icon(
                    onPressed: _submitting ? null : _login,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(context.l10n.sourceLoginSave),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton.icon(
                  key: const ValueKey('source-login-clear'),
                  onPressed: _submitting ? null : _clear,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.l10n.sourceLoginClear),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm() {
    if (_fields.any(
      (field) => field.flexBasisPercent != null || field.isSectionHeading,
    )) {
      return _buildOrderedForm();
    }
    final firstAction = _fields.indexWhere((field) => field.isButton);
    final inputs = firstAction < 0
        ? _fields
        : _fields.take(firstAction).toList();
    final actions = _fields.where((field) => field.isButton).toList();
    final extras = firstAction < 0
        ? <SourceLoginField>[]
        : _fields.skip(firstAction).where((field) => !field.isButton).toList();
    return [
      if (inputs.isNotEmpty) ...[
        _section(context.l10n.sourceLoginInfo, _fieldColumn(inputs)),
        const SizedBox(height: 16),
      ],
      if (actions.isNotEmpty) ...[
        _section(
          context.l10n.sourceLoginActions,
          LayoutBuilder(
            builder: (context, constraints) {
              // Use the actual space inside the card, not a font-scale cutoff.
              // Labels can wrap and buttons grow vertically at larger sizes.
              const minButtonWidth = 112.0;
              final singleColumn =
                  constraints.maxWidth < minButtonWidth * 2 + 10;
              final width = singleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return _actionWrap(
                actions,
                constraints.maxWidth,
                fallbackWidth: width,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (extras.isNotEmpty) ...[
        _card(
          ExpansionTile(
            key: const ValueKey('source-login-extra-settings'),
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              context.l10n.sourceLoginExtraSettings,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            leading: const Icon(Icons.tune_rounded, size: 20),
            children: [_fieldColumn(extras)],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  List<Widget> _buildOrderedForm() {
    final children = <Widget>[];
    var index = 0;
    while (index < _fields.length) {
      final field = _fields[index];
      if (children.isNotEmpty) children.add(const SizedBox(height: 16));
      if (field.isSectionHeading) {
        children.add(
          Text(
            _displayLabel(field),
            key: ValueKey('source-login-heading-${field.name}'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
        index++;
        continue;
      }
      if (field.isButton) {
        final actions = <SourceLoginField>[];
        while (index < _fields.length &&
            _fields[index].isButton &&
            !_fields[index].isSectionHeading) {
          actions.add(_fields[index]);
          index++;
        }
        children.add(
          LayoutBuilder(
            builder: (context, constraints) =>
                _actionWrap(actions, constraints.maxWidth),
          ),
        );
        continue;
      }
      children.add(_buildField(field));
      index++;
    }
    return [
      if (children.isNotEmpty) ...[
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  Widget _actionWrap(
    List<SourceLoginField> actions,
    double maxWidth, {
    double? fallbackWidth,
  }) {
    const spacing = 10.0;
    const minButtonWidth = 112.0;
    final defaultWidth =
        fallbackWidth ??
        (maxWidth < minButtonWidth * 2 + spacing
            ? maxWidth
            : (maxWidth - spacing) / 2);
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final field in actions)
          SizedBox(
            width: field.flexBasisPercent != null
                ? (maxWidth * field.flexBasisPercent! -
                          spacing * (1 - field.flexBasisPercent!))
                      .clamp(
                        maxWidth < minButtonWidth ? maxWidth : minButtonWidth,
                        maxWidth,
                      )
                : defaultWidth,
            child: FilledButton.tonal(
              key: ValueKey('source-login-action-${field.name}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : () => _login(field),
              child: Text(_displayLabel(field), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _card(Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _section(String title, Widget child) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _fieldColumn(List<SourceLoginField> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < fields.length; index++) ...[
        if (index > 0) const SizedBox(height: 16),
        _buildField(fields[index]),
      ],
    ],
  );

  Widget _buildBrowserLogin(Uri loginUri) {
    final scheme = Theme.of(context).colorScheme;
    final supported = const SourceBrowserSessionClient().isSupported;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.sourceLoginBrowserTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SelectableText(
            loginUri.toString(),
            key: const ValueKey('source-login-browser-url'),
            style: TextStyle(color: scheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            supported
                ? context.l10n.sourceLoginBrowserNotice
                : context.l10n.sourceLoginBrowserUnsupported,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('source-login-browser-open'),
              onPressed: supported && !_submitting ? _login : null,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_browser_rounded),
              label: Text(context.l10n.sourceLoginBrowserOpen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(SourceLoginField field) {
    final label = _displayLabel(field);
    final decoration = InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
    Widget labeled(Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Semantics(label: label, child: child),
      ],
    );
    if (field.chars.isNotEmpty) {
      return labeled(
        DropdownButtonFormField<String>(
          key: ValueKey(
            'source-login-choice-${field.name}-${_choices[field.name]}',
          ),
          isExpanded: true,
          initialValue: _choices[field.name],
          decoration: decoration,
          items: [
            for (final value in field.chars)
              DropdownMenuItem(value: value, child: Text(value)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _choices[field.name] = value);
          },
        ),
      );
    }
    if (field.type == 'toggle') {
      final enabled = _choices[field.name] == 'true';
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: enabled,
        onChanged: (value) =>
            setState(() => _choices[field.name] = value ? 'true' : 'false'),
      );
    }
    return labeled(
      TextField(
        key: ValueKey('source-login-field-${field.name}'),
        controller: _controllers[field.name],
        obscureText: field.type == 'password',
        enableSuggestions: field.type != 'password',
        autocorrect: false,
        decoration: decoration,
      ),
    );
  }

  String _displayLabel(SourceLoginField field) =>
      (field.viewName ?? field.name).trim();
}
