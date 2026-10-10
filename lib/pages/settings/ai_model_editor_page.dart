import 'package:flutter/material.dart';

import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/reader_core/ai/ai_error_translator.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_dialog.dart';

class AiModelEditorResult {
  const AiModelEditorResult({required this.settings, required this.isCustom});

  final AIProviderSettings settings;
  final bool isCustom;
}

class AiModelEditorPage extends StatefulWidget {
  const AiModelEditorPage({
    super.key,
    required this.initialSettings,
    required this.initialIsCustom,
    required this.isEditing,
    required this.aiService,
    required this.knownApiKey,
  });

  final AIProviderSettings initialSettings;
  final bool initialIsCustom;
  final bool isEditing;
  final ReaderHttpAIService aiService;
  final String Function(
    AIProviderType provider,
    String baseUrl,
    AIProtocolType protocol,
  )
  knownApiKey;

  @override
  State<AiModelEditorPage> createState() => _AiModelEditorPageState();
}

class _AiModelEditorPageState extends State<AiModelEditorPage> {
  late AIProviderType _provider;
  AIProtocolType? _protocol;
  late AIModelPreset _preset;
  late bool _isCustom;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _temperatureController;

  bool _obscureApiKey = true;
  bool _loadingModels = false;
  bool _saving = false;
  int _connectionRevision = 0;
  String? _modelListNotice;
  List<String> _fetchedModels = const [];
  String? _errorText;
  String? _focusedField;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSettings;
    _provider = initial.provider;
    _protocol = initial.protocol;
    final logo = AIModelPresets.logoAssetForSettings(initial);
    _preset =
        AIModelPresets.match(initial) ??
        AIModelPresets.all.firstWhere(
          (preset) => preset.logoAsset == logo && preset.provider == _provider,
          orElse: () => AIModelPresets.defaultForProvider(
            _provider == AIProviderType.custom
                ? AIProviderType.openai
                : _provider,
          ),
        );
    _isCustom = widget.initialIsCustom;
    _apiKeyController = TextEditingController(text: initial.apiKey);
    _baseUrlController = TextEditingController(text: initial.baseUrl);
    _modelController = TextEditingController(text: initial.model);
    _temperatureController = TextEditingController(
      text: initial.temperature.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  String _protocolLabel(AIProtocolType value) => switch (value) {
    AIProtocolType.openai => context.l10n.settingsAiProtocolOpenAi,
    AIProtocolType.anthropic => context.l10n.settingsAiProtocolAnthropic,
    AIProtocolType.gemini => 'Gemini',
  };

  String? _baseUrlHint() {
    return switch (_effectiveProtocol) {
      AIProtocolType.openai => context.l10n.settingsAiBaseUrlHintOpenAi,
      AIProtocolType.anthropic => context.l10n.settingsAiBaseUrlHintAnthropic,
      AIProtocolType.gemini => null,
    };
  }

  AIProtocolType get _effectiveProtocol => AIProviderSettings(
    provider: _provider,
    protocol: _protocol,
    apiKey: '',
    baseUrl: _baseUrlController.text,
    model: '',
    temperature: 0.7,
  ).effectiveProtocol;

  void _invalidateModels() {
    _connectionRevision++;
    _fetchedModels = const [];
    _modelListNotice = null;
    _errorText = null;
    _loadingModels = false;
  }

  void _connectionChanged([String? _]) {
    setState(() {
      _isCustom = true;
      _invalidateModels();
    });
  }

  void _applyPreset(AIModelPreset preset) {
    final previousProvider = _provider;
    final previousProtocol = _effectiveProtocol;
    final previousBaseUrl = normalizeAIBaseUrl(
      previousProvider,
      _baseUrlController.text,
      protocol: previousProtocol,
    );
    final previousApiKey = _apiKeyController.text;
    _preset = preset;
    _provider = preset.provider;
    _protocol = preset.toSettings().protocol;
    _baseUrlController.text = preset.baseUrl;
    _modelController.text = preset.model;
    _temperatureController.text = preset.temperature.toStringAsFixed(2);
    final nextBaseUrl = normalizeAIBaseUrl(
      _provider,
      preset.baseUrl,
      protocol: _protocol,
    );
    _apiKeyController.text =
        previousProvider == _provider &&
            previousProtocol == _effectiveProtocol &&
            previousBaseUrl == nextBaseUrl
        ? previousApiKey
        : widget.knownApiKey(_provider, preset.baseUrl, _effectiveProtocol);
    _isCustom = false;
    _invalidateModels();
  }

  void _markCustomized([String? _]) {
    setState(() => _isCustom = true);
  }

  String _describeError(Object error) => error is AIServiceException
      ? translateAIServiceException(context, error)
      : '$error';

  Future<void> _chooseModel() async {
    final model = await showDialog<String>(
      context: context,
      builder: (context) => _AiModelPicker(
        models: _fetchedModels,
        selected: _modelController.text.trim(),
      ),
    );
    if (!mounted || model == null) return;
    setState(() {
      _modelController.text = model;
      _isCustom = true;
    });
  }

  Future<void> _fetchModels() async {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (apiKey.isEmpty || baseUrl.isEmpty) {
      setState(() => _errorText = context.l10n.settingsAiFillBaseUrlAndApiKey);
      return;
    }
    final revision = _connectionRevision;
    setState(() {
      _modelListNotice = null;
      _loadingModels = true;
      _errorText = null;
    });
    try {
      final models = await widget.aiService.fetchAvailableModels(
        _buildSettings(),
      );
      if (!mounted || revision != _connectionRevision) return;
      setState(() {
        if (models.isEmpty) {
          _modelListNotice = _copy(
            '接口未返回可用模型，可以直接填写模型 ID。',
            'モデルが返されませんでした。モデル ID を直接入力できます。',
            'No models returned. You can enter a model ID manually.',
          );
        }
        _fetchedModels = models;
        _loadingModels = false;
      });
    } catch (error) {
      if (!mounted || revision != _connectionRevision) return;
      setState(() {
        _loadingModels = false;
        _errorText = _describeError(error);
      });
    }
  }

  AIProviderSettings _buildSettings() => AIProviderSettings(
    provider: _provider,
    protocol: _protocol,
    apiKey: _apiKeyController.text.trim(),
    baseUrl: _baseUrlController.text.trim(),
    model: _modelController.text.trim(),
    temperature: double.tryParse(_temperatureController.text.trim()) ?? 0.7,
  ).normalized();

  Future<void> _save() async {
    final settings = _buildSettings();
    final validation = validateAIProviderSettings(settings);
    if (validation != null) {
      setState(
        () => _errorText = translateAIServiceException(
          context,
          AIServiceException(code: validation),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.aiService.saveSettings(settings);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(AiModelEditorResult(settings: settings, isCustom: _isCustom));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = _describeError(error);
      });
    }
  }

  Widget _field({
    required String label,
    required Widget child,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
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
            focusColor: _focusedField == label
                ? Theme.of(context).colorScheme.primary
                : null,
            child: child,
          ),
        ),
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

  Widget _selector<T>({
    required Key key,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? helper,
    DropdownButtonBuilder? selectedItemBuilder,
  }) => _field(
    label: label,
    helper: helper,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: key,
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(20),
          menuMaxHeight: MediaQuery.sizeOf(context).height * .55,
          icon: const Icon(Icons.expand_more_rounded),
          items: items,
          selectedItemBuilder: selectedItemBuilder,
          onChanged: onChanged,
        ),
      ),
    ),
  );

  String _copy(String zh, String ja, String en) =>
      switch (Localizations.localeOf(context).languageCode) {
        'zh' => zh,
        'ja' => ja,
        _ => en,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brand = _provider == AIProviderType.custom ? 'custom' : _preset.brand;
    final presets = AIModelPresets.all
        .where((preset) => preset.brand == brand)
        .toList();
    final brands = <String, AIModelPreset>{};
    for (final preset in AIModelPresets.all) {
      brands.putIfAbsent(preset.brand, () => preset);
    }
    return PopScope(
      canPop: !_saving,
      child: FloatingSubpageScaffold(
        title: widget.isEditing
            ? l10n.settingsAiEditModelTitle
            : l10n.settingsAiAddModel,
        canPop: !_saving,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorText != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorText!,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      GlassTextButton(
                        minimumHeight: 52,
                        highlighted: true,
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isEditing
                                    ? l10n.settingsAiSaveAndEnable
                                    : l10n.settingsAiAddAndEnable,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: floatingSubpagePadding(
              context,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _selector<String>(
                        key: ValueKey('provider-$brand'),
                        label: l10n.settingsAiProviderLabel,
                        value: brand,
                        items: [
                          for (final preset in brands.values)
                            DropdownMenuItem(
                              value: preset.brand,
                              child: Row(
                                children: [
                                  AiProviderLogo(
                                    asset: preset.logoAsset,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      aiProviderDisplayName(
                                        context,
                                        preset.logoAsset,
                                        fallback: preset.vendor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text(l10n.settingsAiCustomProvider),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            if (value == 'custom') {
                              _provider = AIProviderType.custom;
                              _protocol = null;
                              _isCustom = true;
                              final defaults = AIProviderSettings.defaults(
                                _provider,
                              );
                              _baseUrlController.text = defaults.baseUrl;
                              _modelController.text = defaults.model;
                              _apiKeyController.text = widget.knownApiKey(
                                _provider,
                                defaults.baseUrl,
                                _effectiveProtocol,
                              );
                              _invalidateModels();
                            } else {
                              _applyPreset(brands[value]!);
                            }
                          });
                        },
                      ),
                      if (presets.isNotEmpty)
                        _selector<AIModelPreset>(
                          key: ValueKey(
                            'preset-${_provider.value}-${_preset.id}',
                          ),
                          label: l10n.settingsAiPresetModel,
                          // Custom edits keep the source preset visible as a starting point.
                          value: presets.contains(_preset)
                              ? _preset
                              : presets.first,
                          selectedItemBuilder: (_) => presets
                              .map(
                                (preset) => Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    preset.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          items: presets
                              .map(
                                (preset) => DropdownMenuItem(
                                  value: preset,
                                  child: Row(
                                    children: [
                                      AiProviderLogo(
                                        asset: preset.logoAsset,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${preset.vendor} · ${preset.label}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _applyPreset(value));
                          },
                        ),
                      _field(
                        label: _copy('服务地址', 'サービス URL', 'Base URL'),
                        helper: _provider == AIProviderType.custom
                            ? _baseUrlHint()
                            : null,
                        child: TextFormField(
                          controller: _baseUrlController,
                          onChanged: _connectionChanged,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(hint: 'https://…'),
                        ),
                      ),
                      _selector<String>(
                        key: ValueKey('protocol-${_protocol?.value ?? 'auto'}'),
                        label: l10n.settingsAiProtocolLabel,
                        value: _protocol?.value ?? 'auto',
                        helper: _protocol == null
                            ? _copy(
                                '根据服务地址识别：${_protocolLabel(_effectiveProtocol)}',
                                'URL から判定：${_protocolLabel(_effectiveProtocol)}',
                                'Detected from URL: ${_protocolLabel(_effectiveProtocol)}',
                              )
                            : null,
                        items: [
                          DropdownMenuItem(
                            value: 'auto',
                            child: Text(_copy('自动识别', '自動判定', 'Automatic')),
                          ),
                          for (final item in AIProtocolType.values)
                            DropdownMenuItem(
                              value: item.value,
                              child: Text(_protocolLabel(item)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _protocol = value == 'auto'
                                ? null
                                : AIProtocolTypeX.fromValue(
                                    value,
                                    fallback: AIProtocolType.openai,
                                  );
                            _isCustom = true;
                            _invalidateModels();
                          });
                        },
                      ),
                      _field(
                        label: l10n.settingsAiApiKeyLabel,
                        child: TextFormField(
                          controller: _apiKeyController,
                          onChanged: _connectionChanged,
                          obscureText: _obscureApiKey,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: _copy(
                              '填写 API Key',
                              'API Key を入力',
                              'Enter API Key',
                            ),
                            suffix: IconButton(
                              tooltip: _obscureApiKey
                                  ? _copy(
                                      '显示 API Key',
                                      'API Key を表示',
                                      'Show API Key',
                                    )
                                  : _copy(
                                      '隐藏 API Key',
                                      'API Key を隠す',
                                      'Hide API Key',
                                    ),
                              onPressed: () => setState(
                                () => _obscureApiKey = !_obscureApiKey,
                              ),
                              icon: Icon(
                                _obscureApiKey
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _field(
                        label: l10n.settingsAiModelNameLabel,
                        child: TextFormField(
                          controller: _modelController,
                          onChanged: _markCustomized,
                          decoration: _inputDecoration(
                            hint: _copy(
                              '填写模型 ID',
                              'モデル ID を入力',
                              'Enter model ID',
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          GlassTextButton(
                            key: const ValueKey('fetch-ai-models'),
                            onPressed: _loadingModels ? null : _fetchModels,
                            child: _loadingModels
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _copy(
                                      '获取模型列表',
                                      'モデル一覧を取得',
                                      'Fetch model list',
                                    ),
                                  ),
                          ),
                          if (_fetchedModels.isNotEmpty)
                            GlassTextButton(
                              onPressed: _chooseModel,
                              child: Text(
                                _copy(
                                  '选择模型（${_fetchedModels.length} 个）',
                                  'モデルを選択（${_fetchedModels.length}）',
                                  'Choose model (${_fetchedModels.length})',
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_modelListNotice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _modelListNotice!,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          childrenPadding: const EdgeInsets.only(top: 8),
                          title: Text(
                            _copy('更多选项', 'その他の設定', 'More options'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          children: [
                            _field(
                              label: l10n.settingsAiTemperatureLabel,
                              child: TextFormField(
                                controller: _temperatureController,
                                onChanged: _markCustomized,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiModelPicker extends StatefulWidget {
  const _AiModelPicker({required this.models, required this.selected});
  final List<String> models;
  final String selected;

  @override
  State<_AiModelPicker> createState() => _AiModelPickerState();
}

class _AiModelPickerState extends State<_AiModelPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final models = widget.models
        .where((model) => model.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return GlassDialog(
      title: Text(context.l10n.settingsAiModelNameLabel),
      content: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * 0.45,
        child: Column(
          children: [
            PillSearchField(
              autofocus: true,
              hintText: switch (Localizations.localeOf(context).languageCode) {
                'zh' => '搜索模型',
                'ja' => 'モデルを検索',
                _ => 'Search models',
              },
              onChanged: (query) => setState(() => _query = query),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(models[index]),
                  trailing: widget.selected == models[index]
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(models[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        GlassTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}
