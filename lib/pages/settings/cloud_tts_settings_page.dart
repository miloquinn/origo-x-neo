import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/reader_aloud_session.dart';

import '../../services/reader_aloud_service.dart';
import '../../widgets/ai_provider_logo.dart';
import '../../widgets/cloud_tts_provider_logo.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/glass_buttons.dart';
import '../../widgets/glass_dialog.dart';
import '../../widgets/pill_dropdown.dart';
import '../../widgets/pill_input_surface.dart';
import '../../widgets/pill_search_field.dart';

String cloudTtsCopy(BuildContext context, String zh, String en, String ja) =>
    switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'ja' => ja,
      _ => zh,
    };

/// Shared by app settings and the audiobook player's quick settings.
class CloudTtsEditorPage extends StatefulWidget {
  const CloudTtsEditorPage({
    super.key,
    required this.service,
    this.pauseBook,
    this.profile,
    this.preset,
  });

  final ReaderAloudCloudProfile? profile;
  final ReaderAloudProviderPreset? preset;
  final ReaderAloudService service;
  final Future<void> Function()? pauseBook;

  @override
  State<CloudTtsEditorPage> createState() => _CloudTtsEditorPageState();
}

class _CloudTtsEditorPageState extends State<CloudTtsEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _editingId;
  bool _hasProfileKey = false;
  bool _previewing = false;
  int _previewGeneration = 0;
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _voice = TextEditingController();
  final _apiKey = TextEditingController();
  ReaderAloudCloudProvider _provider = ReaderAloudCloudProvider.openai;
  bool _advancedExpanded = false;
  bool _loaded = false;
  bool _saving = false;
  bool _obscureKey = true;
  bool _clearKey = false;
  bool _fallback = true;
  String _format = 'mp3';
  String? _error;
  String? _focusedField;

  String _copy(String zh, String en, String ja) =>
      cloudTtsCopy(context, zh, en, ja);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await widget.service.initialize();
      if (!mounted) return;
      _editingId = widget.profile?.id;
      _hasProfileKey = !widget.service.supportsProfiles
          ? widget.service.hasCloudApiKey
          : _editingId != null &&
                await widget.service.profileHasKey(_editingId!);
      if (!mounted) return;
      final settings =
          widget.profile?.settings ??
          widget.preset?.settings ??
          widget.service.cloudSettings;
      _provider = settings.provider;
      _advancedExpanded = widget.preset?.url == '';
      _name.text = widget.profile?.name ?? widget.preset?.name ?? 'Cloud TTS';
      _baseUrl.text = settings.baseUrl;
      _model.text = settings.model;
      _voice.text = settings.voice;
      setState(() {
        _format = settings.responseFormat;
        _fallback = settings.fallbackToSystem;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _copy(
            '加载失败，请重试',
            'Could not load. Retry.',
            '読み込みに失敗しました',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    ++_previewGeneration;
    unawaited(widget.service.stopPreview());
    _name.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _voice.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? _copy('请填写此项', 'This field is required', '入力してください')
      : null;

  String? _validateUrl(String? value) {
    try {
      readerAloudCloudEndpoint(value ?? '');
      return null;
    } on ReaderAloudCloudException {
      return _copy(
        '请使用有效的 HTTPS 地址，不含账号、查询参数或片段',
        'Use a valid HTTPS URL without credentials, query or fragment',
        '認証情報・クエリ・フラグメントのない HTTPS URL を入力してください',
      );
    }
  }

  bool _validateForm() {
    final valid = _formKey.currentState!.validate();
    if (!valid && !_advancedExpanded) {
      setState(() => _advancedExpanded = true);
    }
    return valid;
  }

  Future<void> _save() async {
    if (_saving || !_validateForm()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final settings = ReaderAloudCloudSettings(
        provider: _provider,
        baseUrl: _baseUrl.text,
        model: _model.text,
        voice: _voice.text,
        responseFormat: _format,
        fallbackToSystem: _fallback,
      ).normalized();
      validateReaderAloudCloudSettings(settings);
      await _stopPreview();
      if (widget.service.supportsProfiles) {
        await _pauseBook();
        final id = _editingId ??= DateTime.now().microsecondsSinceEpoch
            .toString();
        await widget.service.saveCloudProfile(
          ReaderAloudCloudProfile(
            id: id,
            name: _name.text.trim(),
            settings: settings,
          ),
          apiKey: _apiKey.text,
          clearKey: _clearKey,
        );
        await widget.service.selectCloudProfile(id);
        await widget.service.setEngineType(ReaderAloudEngineType.cloud);
      } else {
        // Blank input retains the existing key.
        if (_apiKey.text.trim().isNotEmpty) {
          await widget.service.saveCloudApiKey(_apiKey.text);
        } else if (_clearKey) {
          await widget.service.clearCloudApiKey();
        }
        await widget.service.updateCloudSettings(settings);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _copy(
            '未能完成保存，请检查系统存储后重试。输入内容已保留。',
            'Could not finish saving. Check device storage and retry. Your input is kept.',
            '保存できませんでした。端末のストレージを確認して再試行してください。入力は保持されています。',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pauseBook() async {
    if (widget.pauseBook != null) {
      await widget.pauseBook!();
    } else {
      await context.read<ReaderAloudSession?>()?.controller?.pause();
    }
  }

  Future<void> _stopPreview() async {
    ++_previewGeneration;
    await widget.service.stopPreview();
    if (mounted) setState(() => _previewing = false);
  }

  Future<void> _preview() async {
    if (!_validateForm()) return;
    final generation = ++_previewGeneration;
    setState(() {
      _previewing = true;
      _error = null;
    });
    try {
      await _pauseBook();
      if (!mounted || generation != _previewGeneration) return;
      await widget.service.previewCloudVoice(
        settings: ReaderAloudCloudSettings(
          provider: _provider,
          baseUrl: _baseUrl.text,
          model: _model.text,
          voice: _voice.text,
          responseFormat: _format,
          fallbackToSystem: false,
        ).normalized(),
        profileId: _editingId,
        apiKey: _apiKey.text,
        useSavedKey:
            !_clearKey &&
            (_editingId != null || !widget.service.supportsProfiles),
        text: _copy(
          '夜色渐深，窗外的风轻轻翻过书页。愿每一个故事，都能陪你走过一段美好的时光。',
          'The evening breeze gently turns the pages. Let each story accompany you on a wonderful journey.',
          '夜が更け、窓の外の風が静かにページをめくります。物語とともに、穏やかな時間を過ごしましょう。',
        ),
      );
    } catch (error) {
      if (mounted && generation == _previewGeneration) {
        setState(
          () => _error = error is ReaderAloudCloudException
              ? error.message
              : _copy(
                  '试听失败，请检查连接与密钥后重试',
                  'Preview failed. Check the connection and API key.',
                  '接続と API キーを確認してください',
                ),
        );
      }
    } finally {
      if (mounted && generation == _previewGeneration) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: Text(_copy('删除此语音配置？', 'Delete this voice?', 'この音声を削除しますか？')),
        content: Text(
          _copy(
            '同时移除本机保存的密钥。',
            'Also removes its saved key from this device.',
            '保存したキーも削除されます。',
          ),
        ),
        actions: [
          GlassTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          GlassTextButton(
            highlighted: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(_copy('删除', 'Delete', '削除')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _stopPreview();
      if (_editingId == widget.service.activeProfileId) await _pauseBook();
      await widget.service.deleteCloudProfile(_editingId!);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _copy(
            '删除失败，请重试',
            'Could not delete. Retry.',
            '削除できませんでした',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ReaderAloudProviderPreset get _preset =>
      widget.preset ??
      readerAloudProviderPresets.firstWhere((p) => p.provider == _provider);

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        isDense: true,
      );

  Widget _labeledField({
    required String label,
    required Widget child,
    String? helper,
    bool inputSurface = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (inputSurface)
          Focus(
            canRequestFocus: false,
            onFocusChange: (focused) => setState(() {
              if (focused) {
                _focusedField = label;
              } else if (_focusedField == label) {
                _focusedField = null;
              }
            }),
            child: PillInputSurface(
              enabled: !_saving,
              focusColor: _focusedField == label
                  ? Theme.of(context).colorScheme.primary
                  : null,
              child: child,
            ),
          )
        else
          child,
        if (helper != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _chooseVoice() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TtsVoicePicker(
        title: _copy('音色', 'Voice', '声'),
        options: _preset.voices,
        selected: _voice.text,
      ),
    );
    if (value != null && mounted) {
      await _stopPreview();
      if (mounted) setState(() => _voice.text = value);
    }
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    bool url = false,
    ValueChanged<String>? onChanged,
  }) => _labeledField(
    label: label,
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_saving,
      validator: url ? _validateUrl : _required,
      autocorrect: false,
      onChanged: onChanged,
      decoration: _inputDecoration(),
    ),
  );

  Widget _selector({
    required Key key,
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) => _labeledField(
    label: label,
    inputSurface: false,
    child: PillDropdown<String>(
      key: key,
      semanticLabel: label,
      value: value,
      items: items,
      onChanged: _saving ? null : onChanged,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasKey = _hasProfileKey && !_clearKey;
    final modelItems = <String, String>{
      if (_model.text.isNotEmpty && !_preset.models.containsKey(_model.text))
        _model.text: _model.text,
      ..._preset.models,
    };
    final formats = {_format, ...readerAloudCloudFormats(_provider)};
    return PopScope(
      canPop: !_saving,
      child: FloatingSubpageScaffold(
        title: widget.preset?.name ?? _name.text,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: !_loaded
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    12 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SizedBox(
                          width: double.infinity,
                          child: GlassTextButton(
                            key: const ValueKey('cloud-tts-save'),
                            highlighted: true,
                            onPressed: _saving ? null : _save,
                            child: Text(
                              _saving
                                  ? _copy('正在保存…', 'Saving…', '保存中…')
                                  : _copy('保存并使用', 'Save and use', '保存して使用'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        body: !_loaded
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: _load, child: Text(_error!)),
              )
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: floatingSubpagePadding(context),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (widget.preset?.url == '')
                                const AiProviderLogo(size: 44)
                              else
                                CloudTtsProviderLogo(
                                  provider: _provider,
                                  size: 44,
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _preset.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _copy(
                                        '填入 API Key 后即可试听并保存。',
                                        'Enter an API key to preview and save.',
                                        'API キーを入力して試聴・保存できます。',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _selector(
                            key: const ValueKey('cloud-tts-model-selector'),
                            label: _copy('语音模型', 'Speech model', '音声モデル'),
                            value: _model.text,
                            items: modelItems.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              await _stopPreview();
                              if (mounted) {
                                setState(() => _model.text = value);
                              }
                            },
                          ),
                          _labeledField(
                            label: _copy('音色', 'Voice', '声'),
                            inputSurface: false,
                            child: PillInputSurface(
                              enabled: !_saving,
                              child: InkWell(
                                key: const ValueKey('cloud-tts-voice-selector'),
                                onTap: _saving ? null : _chooseVoice,
                                customBorder: PillInputSurface.shape,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          18,
                                          4,
                                          14,
                                          4,
                                        ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _preset.voices[_voice.text] ??
                                                _voice.text,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _labeledField(
                            label: 'API Key',
                            helper: hasKey
                                ? _copy(
                                    '已保存，留空保留',
                                    'Saved; leave blank to keep',
                                    '保存済み・空欄で維持',
                                  )
                                : _copy(
                                    '密钥保存在本机安全存储中',
                                    'Stored securely on this device',
                                    '端末に安全に保存',
                                  ),
                            child: TextFormField(
                              key: const ValueKey('cloud-tts-key'),
                              controller: _apiKey,
                              enabled: !_saving,
                              obscureText: _obscureKey,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: _inputDecoration(
                                hint: hasKey ? '••••••••' : null,
                                suffix: IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(
                                          () => _obscureKey = !_obscureKey,
                                        ),
                                  tooltip: _copy(
                                    '显示或隐藏密钥',
                                    'Toggle key visibility',
                                    'キーの表示切替',
                                  ),
                                  icon: Icon(
                                    _obscureKey
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: GlassTextButton(
                              key: const ValueKey('cloud-tts-preview'),
                              onPressed: _saving
                                  ? null
                                  : (_previewing ? _stopPreview : _preview),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _previewing
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _previewing
                                          ? _copy(
                                              '停止试听',
                                              'Stop preview',
                                              '試聴を停止',
                                            )
                                          : _copy(
                                              '试听当前音色',
                                              'Preview voice',
                                              '音声を試聴',
                                            ),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _copy(
                              '试听会暂停听书，并使用当前语速。服务商可能计费。',
                              'Preview pauses the book and uses the current speed. Provider charges may apply.',
                              '試聴時は読書を一時停止します。料金が発生する場合があります。',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_provider == ReaderAloudCloudProvider.mimo)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _copy(
                                  'MiMo 通过指令调整语速，实际倍速可能略有差异。',
                                  'MiMo adjusts pace through instructions; actual speed may vary.',
                                  'MiMo は指示で話速を調整するため、実際の速度は異なる場合があります。',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 18),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _saving
                                  ? null
                                  : () => setState(
                                      () => _advancedExpanded =
                                          !_advancedExpanded,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _copy(
                                              '高级自定义',
                                              'Advanced customization',
                                              '詳細設定',
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _copy(
                                              '名称、地址与自定义模型 / 音色',
                                              'Name, endpoint and custom model / voice',
                                              '名前・URL・カスタム音声',
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _advancedExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _advancedExpanded,
                            maintainState: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                _field(
                                  'cloud-tts-name',
                                  _name,
                                  _copy('配置名称', 'Name', '設定名'),
                                ),
                                _field(
                                  'cloud-tts-url',
                                  _baseUrl,
                                  _copy('服务地址', 'Service URL', 'サービス URL'),
                                  url: true,
                                ),
                                _field(
                                  'cloud-tts-model',
                                  _model,
                                  _copy(
                                    '自定义模型 ID',
                                    'Custom model ID',
                                    'モデル ID',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                _field(
                                  'cloud-tts-voice',
                                  _voice,
                                  _copy('自定义音色 ID', 'Custom voice ID', '音声 ID'),
                                  onChanged: (_) => setState(() {}),
                                ),
                                _selector(
                                  key: const ValueKey(
                                    'cloud-tts-format-selector',
                                  ),
                                  label: _copy('音频格式', 'Audio format', '音声形式'),
                                  value: _format,
                                  items: formats
                                      .map(
                                        (format) => DropdownMenuItem(
                                          value: format,
                                          child: Text(format.toUpperCase()),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _format = value);
                                    }
                                  },
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  title: Text(
                                    _copy(
                                      '失败时使用系统语音',
                                      'Use system voice on failure',
                                      '失敗時にシステム音声',
                                    ),
                                  ),
                                  value: _fallback,
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                            setState(() => _fallback = value),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (_hasProfileKey)
                                      GlassTextButton(
                                        onPressed: _saving
                                            ? null
                                            : () => setState(
                                                () => _clearKey = !_clearKey,
                                              ),
                                        child: Text(
                                          _clearKey
                                              ? _copy(
                                                  '保留原密钥',
                                                  'Keep saved key',
                                                  '保存キーを維持',
                                                )
                                              : _copy(
                                                  '移除已保存的密钥',
                                                  'Remove saved key',
                                                  '保存キーを削除',
                                                ),
                                        ),
                                      ),
                                    if (_editingId != null &&
                                        widget.service.cloudProfiles.length > 1)
                                      GlassTextButton(
                                        onPressed: _saving ? null : _delete,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        child: Text(
                                          _copy(
                                            '删除配置',
                                            'Delete voice',
                                            '設定を削除',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _TtsVoicePicker extends StatefulWidget {
  const _TtsVoicePicker({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final Map<String, String> options;
  final String selected;

  @override
  State<_TtsVoicePicker> createState() => _TtsVoicePickerState();
}

class _TtsVoicePickerState extends State<_TtsVoicePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allOptions = <String, String>{
      if (widget.selected.isNotEmpty &&
          !widget.options.containsKey(widget.selected))
        widget.selected: widget.selected,
      ...widget.options,
    };
    final options = allOptions.entries
        .where(
          (entry) => '${entry.key} ${entry.value}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return GlassDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * .52,
        child: Column(
          children: [
            PillSearchField(
              autofocus: true,
              hintText: cloudTtsCopy(context, '搜索', 'Search', '検索'),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final entry = options[index];
                  return ListTile(
                    title: Text(entry.value),
                    trailing: entry.key == widget.selected
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(context).pop(entry.key),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cloudTtsCopy(
                context,
                '其他音色可在高级自定义中输入。',
                'Enter other voice IDs under Advanced customization.',
                'その他の音声 ID は詳細設定で入力できます。',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        GlassTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

/// Saved configurations are separate from the editor, shared by settings and player.
class CloudTtsSettingsPage extends StatefulWidget {
  const CloudTtsSettingsPage({
    super.key,
    required this.service,
    this.pauseBook,
  });
  final ReaderAloudService service;
  final Future<void> Function()? pauseBook;
  @override
  State<CloudTtsSettingsPage> createState() => _CloudTtsSettingsPageState();
}

class _CloudTtsSettingsPageState extends State<CloudTtsSettingsPage> {
  bool _loaded = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await widget.service.initialize();
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = cloudTtsCopy(
            context,
            '加载失败，请重试',
            'Could not load. Retry.',
            '読み込みに失敗しました',
          ),
        );
      }
    }
  }

  Future<void> _edit({
    ReaderAloudCloudProfile? profile,
    ReaderAloudProviderPreset? preset,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CloudTtsEditorPage(
          service: widget.service,
          pauseBook: widget.pauseBook,
          profile: profile,
          preset: preset,
        ),
      ),
    );
    if (mounted) {
      if (saved == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {});
      }
    }
  }

  static const _customPreset = ReaderAloudProviderPreset(
    'Cloud TTS',
    ReaderAloudCloudProvider.openai,
    '',
    {'': '自定义'},
    {'': '自定义'},
  );

  ReaderAloudProviderPreset _presetFor(ReaderAloudCloudProvider provider) =>
      readerAloudProviderPresets.firstWhere(
        (preset) => preset.provider == provider,
      );

  Widget _sectionLabel(String label) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _providerRow(ReaderAloudProviderPreset preset) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey('cloud-tts-preset-${preset.provider.name}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _edit(preset: preset),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            CloudTtsProviderLogo(provider: preset.provider, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.models.values.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );

  Widget _profileRow(ReaderAloudCloudProfile profile) {
    final preset = _presetFor(profile.settings.provider);
    final active = profile.id == widget.service.activeProfileId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('cloud-tts-profile-${profile.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _edit(profile: profile),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              CloudTtsProviderLogo(
                provider: profile.settings.provider,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.voices[profile.settings.voice] ??
                          profile.settings.voice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FloatingSubpageScaffold(
    title: cloudTtsCopy(context, '云端 TTS', 'Cloud TTS', 'クラウド TTS'),
    body: !_loaded
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : TextButton(onPressed: _load, child: Text(_error!)),
          )
        : ListView(
            padding: floatingSubpagePadding(context),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        cloudTtsCopy(
                          context,
                          '选择语音服务并保存喜欢的音色，也可以连接兼容服务。',
                          'Choose a speech provider and save favorite voices, or connect a compatible service.',
                          '音声サービスとお気に入りの声を選ぶか、互換サービスを接続できます。',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(
                        cloudTtsCopy(context, '语音服务', 'Providers', '音声サービス'),
                      ),
                      const SizedBox(height: 8),
                      for (final preset in readerAloudProviderPresets)
                        _providerRow(preset),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GlassTextButton(
                          key: const ValueKey('cloud-tts-add'),
                          onPressed: () => _edit(preset: _customPreset),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  cloudTtsCopy(
                                    context,
                                    '添加自定义兼容服务',
                                    'Add custom compatible service',
                                    'カスタム互換サービスを追加',
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.service.cloudProfiles.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _sectionLabel(
                          cloudTtsCopy(
                            context,
                            '已保存的语音',
                            'Saved voices',
                            '保存した音声',
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final profile in widget.service.cloudProfiles)
                          _profileRow(profile),
                      ],
                      if (!widget.service.supportsProfiles) ...[
                        const SizedBox(height: 24),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _edit(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cloudTtsCopy(
                                        context,
                                        '当前配置',
                                        'Current settings',
                                        '現在の設定',
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}
