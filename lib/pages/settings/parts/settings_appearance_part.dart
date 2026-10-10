part of '../settings_page.dart';

extension _SettingsAppearancePart on _SettingsPageState {
  Widget _buildThemeToggle(ThemeNotifier themeNotifier) {
    final mode = themeNotifier.themeMode;
    final l10n = context.l10n;
    return _buildActionSetting(
      title: l10n.settingsDarkModeTitle,
      subtitle: l10n.settingsCurrentValue(_themeModeLabel(mode)),
      onTap: () => _showThemeModeModal(themeNotifier),
      icon: _themeModeIcon(mode),
    );
  }

  Widget _buildUiStyleSelector(ThemeNotifier themeNotifier) {
    final l10n = context.l10n;
    return _buildSwitchSetting(
      title: l10n.settingsUiStyleTitle,
      subtitle: l10n.settingsGlassEffectSubtitle,
      value: themeNotifier.isGlassEffectsEnabled,
      onChanged: themeNotifier.setGlassEffectsEnabled,
      icon: Icons.blur_on_rounded,
      persistPageSettings: false,
    );
  }

  Widget _buildGlassStyleVisibility(ThemeNotifier themeNotifier) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final child = themeNotifier.isGlassEffectsEnabled
        ? KeyedSubtree(
            key: const ValueKey('settings-glass-style'),
            child: _buildActionSetting(
              title: context.l10n.settingsGlassStyleTitle,
              subtitle: _glassStyleLabel(themeNotifier.glassStyle),
              onTap: () => _showGlassStyleModal(themeNotifier),
              icon: Icons.water_drop_outlined,
            ),
          )
        : const SizedBox.shrink();
    if (disableAnimations) return child;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildLiquidGlassOpacityVisibility(ThemeNotifier themeNotifier) {
    final child =
        themeNotifier.isGlassEffectsEnabled &&
            themeNotifier.glassStyle == GlassStyle.liquid
        ? _buildLiquidGlassOpacitySetting(themeNotifier)
        : const SizedBox.shrink();
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildLiquidGlassOpacitySetting(ThemeNotifier themeNotifier) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('settings-liquid-glass-opacity'),
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.opacity_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.settingsLiquidGlassOpacityTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsLiquidGlassOpacityHelper,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                trackHeight: 4,
                activeTrackColor: scheme.primary,
                inactiveTrackColor: scheme.outlineVariant,
                thumbColor: scheme.primary,
                overlayColor: scheme.primary.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                key: const ValueKey('liquid-glass-opacity-slider'),
                value: themeNotifier.liquidGlassOpacity.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()}%',
                onChanged: (value) => unawaited(
                  themeNotifier.setLiquidGlassOpacity(value, persist: false),
                ),
                onChangeEnd: (value) =>
                    unawaited(themeNotifier.setLiquidGlassOpacity(value)),
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settingsLiquidGlassOpacityTransparent,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.settingsLiquidGlassOpacityOpaque,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _glassStyleLabel(GlassStyle style) {
    return switch (style) {
      GlassStyle.frosted => context.l10n.settingsGlassStyleFrostedTitle,
      GlassStyle.liquid => context.l10n.settingsGlassStyleLiquidTitle,
    };
  }

  void _showGlassStyleModal(ThemeNotifier themeNotifier) {
    final l10n = context.l10n;
    final options =
        <({GlassStyle style, String label, String hint, IconData icon})>[
          (
            style: GlassStyle.frosted,
            label: l10n.settingsGlassStyleFrostedTitle,
            hint: l10n.settingsGlassStyleFrostedSubtitle,
            icon: Icons.blur_on_rounded,
          ),
          (
            style: GlassStyle.liquid,
            label: l10n.settingsGlassStyleLiquidTitle,
            hint: l10n.settingsGlassStyleLiquidSubtitle,
            icon: Icons.water_drop_outlined,
          ),
        ];

    showGlassBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(modalContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        color: Theme.of(modalContext).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.settingsGlassStyleTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(modalContext).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final item in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('glass-style-${item.style.name}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          unawaited(themeNotifier.setGlassStyle(item.style));
                          Navigator.of(modalContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: themeNotifier.glassStyle == item.style
                                  ? Theme.of(modalContext).colorScheme.primary
                                  : Theme.of(modalContext).colorScheme.outline
                                        .withValues(alpha: 0.35),
                              width: themeNotifier.glassStyle == item.style
                                  ? 1.6
                                  : 1,
                            ),
                            color: themeNotifier.glassStyle == item.style
                                ? Theme.of(
                                    modalContext,
                                  ).colorScheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: themeNotifier.glassStyle == item.style
                                    ? Theme.of(modalContext).colorScheme.primary
                                    : Theme.of(modalContext)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            themeNotifier.glassStyle ==
                                                item.style
                                            ? Theme.of(
                                                modalContext,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                modalContext,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.hint,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(modalContext)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.62),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (themeNotifier.glassStyle == item.style)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(
                                    modalContext,
                                  ).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    final l10n = context.l10n;
    switch (mode) {
      case ThemeMode.system:
        return l10n.systemMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.light:
        return l10n.lightMode;
    }
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
    }
  }

  void _showThemeModeModal(ThemeNotifier themeNotifier) {
    final l10n = context.l10n;
    final options =
        <({ThemeMode mode, String label, String hint, IconData icon})>[
          (
            mode: ThemeMode.system,
            label: l10n.systemMode,
            hint: l10n.settingsThemeModeSystemHint,
            icon: Icons.brightness_auto,
          ),
          (
            mode: ThemeMode.light,
            label: l10n.lightMode,
            hint: l10n.settingsThemeModeLightHint,
            icon: Icons.light_mode,
          ),
          (
            mode: ThemeMode.dark,
            label: l10n.darkMode,
            hint: l10n.settingsThemeModeDarkHint,
            icon: Icons.dark_mode,
          ),
        ];

    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
                  child: Row(
                    children: [
                      Icon(
                        _themeModeIcon(themeNotifier.themeMode),
                        color: Theme.of(modalContext).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.settingsDarkModeTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(modalContext).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                ...options.map((item) {
                  final selected = themeNotifier.themeMode == item.mode;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          themeNotifier.setThemeMode(item.mode);
                          Navigator.of(modalContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(modalContext).colorScheme.primary
                                  : Theme.of(modalContext).colorScheme.outline
                                        .withValues(alpha: 0.35),
                              width: selected ? 1.6 : 1,
                            ),
                            color: selected
                                ? Theme.of(
                                    modalContext,
                                  ).colorScheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: selected
                                    ? Theme.of(modalContext).colorScheme.primary
                                    : Theme.of(modalContext)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Theme.of(
                                                modalContext,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                modalContext,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.hint,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(modalContext)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.62),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(
                                    modalContext,
                                  ).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppFontSelector(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final selected = appSettings.appFont;
    return _buildActionSetting(
      title: l10n.appFont,
      subtitle:
          '${FontCatalog.labelFor(l10n, selected)} · ${l10n.appFontDescription}',
      icon: Icons.font_download_outlined,
      onTap: () => _showFontModal(
        appSettings: appSettings,
        domain: FontDomain.app,
        title: l10n.appFont,
        description: l10n.appFontDescription,
      ),
    );
  }

  Widget _buildAppTextSizeSelector(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    return _buildActionSetting(
      title: l10n.appTextSize,
      subtitle:
          '${(appSettings.appTextScaleFactor * 100).round()}% · '
          '${l10n.appTextSizeDescription}',
      icon: Icons.format_size_rounded,
      onTap: () => showGlassBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AppTextSizeSheet(),
      ),
    );
  }

  Widget _buildReaderFontSelector(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final selected = appSettings.readerFont;
    return _buildActionSetting(
      title: l10n.readerFont,
      subtitle:
          '${FontCatalog.labelFor(l10n, selected)} · ${l10n.readerFontDescription}',
      icon: Icons.chrome_reader_mode_outlined,
      onTap: () => _showFontModal(
        appSettings: appSettings,
        domain: FontDomain.reader,
        title: l10n.readerFont,
        description: l10n.readerFontDescription,
      ),
    );
  }

  Widget _buildEpubReaderFontSelector(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final selected = appSettings.epubReaderFont;
    return _buildActionSetting(
      title: '${l10n.readerFont} · EPUB',
      subtitle:
          '${FontCatalog.labelFor(l10n, selected)} · ${l10n.readerFontSelectionDescription}',
      icon: Icons.menu_book_outlined,
      onTap: () => _showFontModal(
        appSettings: appSettings,
        domain: FontDomain.epubReader,
        title: '${l10n.readerFont} · EPUB',
        description: l10n.readerFontSelectionDescription,
      ),
    );
  }

  Widget _buildCustomFontsManager(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final count = appSettings.customFonts.length;
    return _buildActionSetting(
      title: l10n.customFonts,
      subtitle: count == 0
          ? l10n.customFontsEmpty
          : l10n.customFontsCount(count),
      icon: Icons.folder_copy_outlined,
      onTap: () async {
        if (!await ensureAccountReaderFeatureAccess(context)) return;
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CustomFontsPage()),
        );
      },
    );
  }

  Future<void> _showFontModal({
    required AppSettingsNotifier appSettings,
    required FontDomain domain,
    required String title,
    required String description,
  }) async {
    final l10n = context.l10n;
    await appSettings.prepareCustomFontPreviews();
    if (!mounted) return;
    final importStatus = await showGlassBottomSheet<CustomFontImportStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FontSelectionSheet(
        settings: appSettings,
        domain: domain,
        title: title,
        description: description,
      ),
    );
    if (importStatus == null || !mounted) return;
    final message = importStatus == CustomFontImportStatus.duplicate
        ? l10n.customFontAlreadyImported
        : domain == FontDomain.app
        ? l10n.customFontAppliedToApp
        : l10n.customFontAppliedToReader;
    showSideToast(context, message, kind: SideToastKind.success);
  }

  Widget _buildLanguageSelector(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final currentCode = appSettings.localeCode;
    final currentLabel = _languageLabel(l10n, currentCode);

    return _buildActionSetting(
      title: l10n.language,
      subtitle: currentLabel,
      icon: Icons.translate,
      onTap: () => _showLanguageModal(appSettings),
    );
  }

  String _languageLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'zh':
      case 'zh-CN':
      case 'zh_CN':
        return l10n.languageChinese;
      case 'zh-TW':
      case 'zh_TW':
      case 'zh-Hant':
      case 'zh_Hant':
        return l10n.languageTraditionalChinese;
      case 'ja':
      case 'ja-JP':
      case 'ja_JP':
        return l10n.languageJapanese;
      case 'en':
      case 'en-US':
      case 'en_US':
        return l10n.languageEnglish;
      case 'de':
      case 'de-DE':
      case 'de_DE':
        return l10n.languageGerman;
      case 'es':
      case 'es-ES':
      case 'es_ES':
        return l10n.languageSpanish;
      case 'fr':
      case 'fr-FR':
      case 'fr_FR':
        return l10n.languageFrench;
      case 'it':
      case 'it-IT':
      case 'it_IT':
        return l10n.languageItalian;
      case 'pt':
      case 'pt-BR':
      case 'pt_BR':
      case 'pt-PT':
      case 'pt_PT':
        return l10n.languagePortuguese;
      case 'ru':
      case 'ru-RU':
      case 'ru_RU':
        return l10n.languageRussian;
      default:
        return l10n.languageSystem;
    }
  }

  void _showLanguageModal(AppSettingsNotifier appSettings) {
    final l10n = context.l10n;
    final options = [
      _LanguageOption(code: 'system', label: l10n.languageSystem),
      _LanguageOption(code: 'zh', label: l10n.languageChinese),
      _LanguageOption(code: 'zh-TW', label: l10n.languageTraditionalChinese),
      _LanguageOption(code: 'en', label: l10n.languageEnglish),
      _LanguageOption(code: 'ja', label: l10n.languageJapanese),
      _LanguageOption(code: 'de', label: l10n.languageGerman),
      _LanguageOption(code: 'es', label: l10n.languageSpanish),
      _LanguageOption(code: 'fr', label: l10n.languageFrench),
      _LanguageOption(code: 'it', label: l10n.languageItalian),
      _LanguageOption(code: 'pt', label: l10n.languagePortuguese),
      _LanguageOption(code: 'ru', label: l10n.languageRussian),
    ];

    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.language,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(
                    bottom: 8 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    for (final option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: appSettings.localeCode == option.code
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          appSettings.setLocaleCode(option.code);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
