import 'package:flutter/material.dart';

import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/reader_core/ai/ai_error_translator.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';

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

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSettings;
    _provider = initial.provider;
    _protocol = initial.protocol;
    _preset =
        AIModelPresets.match(initial) ??
        AIModelPresets.defaultForProvider(
          _provider == AIProviderType.custom
              ? AIProviderType.openai
              : _provider,
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

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helper,
    Widget? suffix,
  }) {
    final palette = PageStyleHelper.palette(context);
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: palette.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final presets = _provider == AIProviderType.custom
        ? const <AIModelPreset>[]
        : AIModelPresets.byProvider(_provider);
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
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
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
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
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
            padding: floatingSubpagePadding(context, bottom: 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _copy(
                          '选择服务商，填写密钥并确认模型。预设参数也可以直接修改。',
                          'プロバイダーとキーを設定し、モデルを確認します。プリセットの内容も変更できます。',
                          'Choose a provider, enter its key, and confirm the model. Preset details remain editable.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(_copy('服务商', 'プロバイダー', 'Provider')),
                      DropdownButtonFormField<AIProviderType>(
                        key: ValueKey('provider-${_provider.value}'),
                        initialValue: _provider,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          label: l10n.settingsAiProviderLabel,
                          icon: Icons.hub_outlined,
                        ),
                        items: AIProviderType.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Row(
                                  children: [
                                    AiProviderLogo(
                                      asset:
                                          AIModelPresets.logoAssetForProvider(
                                            item,
                                          ),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item == AIProviderType.custom
                                            ? l10n.settingsAiCustomProvider
                                            : item.displayName,
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
                          setState(() {
                            _provider = value;
                            _protocol = null;
                            _isCustom = value == AIProviderType.custom;
                            if (value == AIProviderType.custom) {
                              final defaults = AIProviderSettings.defaults(
                                value,
                              );
                              _baseUrlController.text = defaults.baseUrl;
                              _modelController.text = defaults.model;
                              _apiKeyController.text = widget.knownApiKey(
                                value,
                                defaults.baseUrl,
                                _effectiveProtocol,
                              );
                              _invalidateModels();
                            } else {
                              _applyPreset(
                                AIModelPresets.defaultForProvider(value),
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('protocol-${_protocol?.value ?? 'auto'}'),
                        initialValue: _protocol?.value ?? 'auto',
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          label: l10n.settingsAiProtocolLabel,
                          icon: Icons.swap_calls_rounded,
                          helper: _protocol == null
                              ? _copy(
                                  '根据服务地址识别：${_protocolLabel(_effectiveProtocol)}',
                                  'URL から判定：${_protocolLabel(_effectiveProtocol)}',
                                  'Detected from URL: ${_protocolLabel(_effectiveProtocol)}',
                                )
                              : null,
                        ),
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
                      if (presets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<AIModelPreset>(
                          key: ValueKey(
                            'preset-${_provider.value}-${_preset.id}',
                          ),
                          initialValue: !_isCustom && presets.contains(_preset)
                              ? _preset
                              : null,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            label: l10n.settingsAiPresetModel,
                            icon: Icons.auto_awesome_outlined,
                          ),
                          selectedItemBuilder: (context) => presets
                              .map(
                                (preset) => Row(
                                  children: [
                                    AiProviderLogo(
                                      asset: preset.logoAsset,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        preset.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                                      const SizedBox(width: 10),
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
                      ],
                      const SizedBox(height: 20),
                      _sectionLabel(_copy('服务连接', '接続', 'Connection')),
                      TextFormField(
                        controller: _baseUrlController,
                        onChanged: _connectionChanged,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: _fieldDecoration(
                          label: _copy('服务地址', 'サービス URL', 'Base URL'),
                          icon: Icons.link_rounded,
                          helper: _baseUrlHint(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apiKeyController,
                        onChanged: _connectionChanged,
                        obscureText: _obscureApiKey,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: _fieldDecoration(
                          label: l10n.settingsAiApiKeyLabel,
                          icon: Icons.key_rounded,
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(_copy('模型', 'モデル', 'Model')),
                      TextFormField(
                        controller: _modelController,
                        onChanged: _markCustomized,
                        decoration: _fieldDecoration(
                          label: l10n.settingsAiModelNameLabel,
                          icon: Icons.smart_toy_outlined,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const ValueKey('fetch-ai-models'),
                          onPressed: _loadingModels ? null : _fetchModels,
                          icon: _loadingModels
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_download_outlined),
                          label: Text(
                            _copy('获取模型列表', 'モデル一覧を取得', 'Fetch model list'),
                          ),
                        ),
                      ),
                      if (_modelListNotice != null)
                        Text(
                          _modelListNotice!,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      if (_fetchedModels.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _chooseModel,
                          icon: const Icon(Icons.list_alt_rounded),
                          label: Text(
                            _copy(
                              '选择模型（${_fetchedModels.length} 个）',
                              'モデルを選択（${_fetchedModels.length}）',
                              'Choose model (${_fetchedModels.length})',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: Text(
                            _copy('更多选项', 'その他の設定', 'More options'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          children: [
                            TextFormField(
                              controller: _temperatureController,
                              onChanged: _markCustomized,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _fieldDecoration(
                                label: l10n.settingsAiTemperatureLabel,
                                icon: Icons.thermostat_rounded,
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
    return AlertDialog(
      title: Text(context.l10n.settingsAiModelNameLabel),
      content: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * 0.45,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: switch (Localizations.localeOf(
                  context,
                ).languageCode) {
                  'zh' => '搜索模型',
                  'ja' => 'モデルを検索',
                  _ => 'Search models',
                },
              ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}
