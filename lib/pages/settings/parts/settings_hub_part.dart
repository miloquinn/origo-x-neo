part of '../settings_page.dart';

extension _SettingsHubPart on _SettingsPageState {
  String _categoryTitle(AppLocalizations l10n, SettingsCategory category) =>
      switch (category) {
        SettingsCategory.preferences => l10n.settingsPreferencesTitle,
        SettingsCategory.dataSync => l10n.settingsDataSyncTitle,
        SettingsCategory.contentServices => l10n.settingsContentServicesTitle,
        SettingsCategory.aboutSupport => l10n.settingsSectionAboutSupport,
      };

  void _openCategory(SettingsCategory category) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          category: category,
          cacheManager: _cacheManager,
          preferencesStore: _preferencesStore,
          aiService: _aiService,
        ),
      ),
    );
  }

  List<Widget> _buildMyPageSingleColumn(AppLocalizations l10n) => [
    if (NavigationContext.of(context)?.useRailNavigation ?? false) ...[
      _buildSettingsTopRow(l10n),
      const SizedBox(height: 24),
    ],
    const KeyedSubtree(
      key: ValueKey('settings-single-column-layout'),
      child: SettingsAccountCard(),
    ),
    const SizedBox(height: 28),
    _buildMyPageMenu(l10n),
    const SizedBox(height: 100),
  ];

  Widget _buildMyPageWide(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (NavigationContext.of(context)?.useRailNavigation ?? false) ...[
        _buildSettingsTopRow(l10n),
        const SizedBox(height: 24),
      ],
      Row(
        key: const ValueKey('settings-wide-layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              key: const ValueKey('settings-primary-column'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [SettingsAccountCard()],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: KeyedSubtree(
              key: const ValueKey('settings-secondary-column'),
              child: _buildMyPageMenu(l10n),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildMyPageMenu(AppLocalizations l10n) {
    final palette = PageStyleHelper.palette(context);
    final entries = [
      (
        SettingsCategory.preferences,
        Icons.tune_rounded,
        l10n.settingsPreferencesSubtitle,
      ),
      (
        SettingsCategory.dataSync,
        Icons.cloud_sync_outlined,
        l10n.settingsDataSyncSubtitle,
      ),
      (
        SettingsCategory.contentServices,
        Icons.auto_stories_outlined,
        l10n.settingsContentServicesSubtitle,
      ),
      (
        SettingsCategory.aboutSupport,
        Icons.info_outline_rounded,
        l10n.settingsAboutSupportSubtitle,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            l10n.settingsManagementTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 62, color: palette.border),
                if (entries[i].$1 == SettingsCategory.dataSync)
                  Selector<WebDavBackupController, (bool, bool)>(
                    selector: (_, backup) => (backup.busy, backup.isConfigured),
                    builder: (_, status, _) => _buildMyPageMenuRow(
                      l10n,
                      entries[i].$1,
                      entries[i].$2,
                      status.$1
                          ? l10n.settingsWebDavWorking
                          : status.$2
                          ? l10n.settingsWebDavConfigured
                          : l10n.settingsDataSyncSubtitle,
                    ),
                  )
                else
                  _buildMyPageMenuRow(
                    l10n,
                    entries[i].$1,
                    entries[i].$2,
                    entries[i].$3,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyPageMenuRow(
    AppLocalizations l10n,
    SettingsCategory category,
    IconData icon,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      key: ValueKey('settings-category-${category.name}'),
      onTap: () => _openCategory(category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryTitle(l10n, category),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    final l10n = context.l10n;
    final themeNotifier = context.read<ThemeNotifier>();
    final appSettings = context.read<AppSettingsNotifier>();
    if (widget.category == SettingsCategory.preferences) {
      context.select(
        (ThemeNotifier theme) => (
          theme.themeMode,
          theme.accentColor,
          theme.uiStyle,
          theme.glassStyle,
        ),
      );
      // Project displayed values, not freshly allocated FontOption instances.
      context.select(
        (AppSettingsNotifier settings) => (
          FontCatalog.labelFor(l10n, settings.appFont),
          FontCatalog.labelFor(l10n, settings.readerFont),
          FontCatalog.labelFor(l10n, settings.epubReaderFont),
          settings.customFonts.length,
          settings.appTextScaleFactor,
          settings.libraryLayoutMode,
          settings.localeCode,
          settings.powerSavingMode,
        ),
      );
    } else if (widget.category == SettingsCategory.contentServices) {
      context.select(
        (AppSettingsNotifier settings) => (
          settings.advancedFeaturesUnlocked,
          settings.additionalSourceProtocolsEnabled,
          settings.privateBookSourceNetworkEnabled,
        ),
      );
    }
    final sections = switch (widget.category!) {
      SettingsCategory.preferences => <WidgetBuilder>[
        (_) =>
            _buildAppearanceSettingsSection(l10n, themeNotifier, appSettings),
        (_) => _buildReadingSettingsSection(l10n),
        (_) => _buildGeneralSettingsSection(l10n, appSettings),
      ],
      SettingsCategory.dataSync => <WidgetBuilder>[
        (_) => _buildDataSyncSettingsSection(l10n),
      ],
      SettingsCategory.contentServices => <WidgetBuilder>[
        (_) => _buildContentServicesSection(l10n),
        if (appSettings.advancedFeaturesUnlocked)
          (_) => _buildAdvancedSettingsSection(l10n, appSettings),
      ],
      SettingsCategory.aboutSupport => <WidgetBuilder>[
        (_) => _buildSupportSettingsSection(l10n),
        (_) => _buildAboutCard(),
      ],
    };
    return ListView.separated(
      controller: _scrollController,
      padding: floatingSubpagePadding(context, bottom: 40),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: sections[index](context),
        ),
      ),
    );
  }
}
