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
      child: SettingsAccountCard(quiet: true, showMembershipSection: true),
    ),
    const SizedBox(height: 28),
    _buildMyPageMenu(l10n),
    const SizedBox(height: 100),
  ];

  Widget _buildMyPageWide(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildSettingsTopRow(l10n),
      const SizedBox(height: 24),
      Row(
        key: const ValueKey('settings-wide-layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              key: const ValueKey('settings-primary-column'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SettingsAccountCard(quiet: true, showMembershipSection: true),
              ],
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
    final scheme = Theme.of(context).colorScheme;
    final backup = context.watch<WebDavBackupController>();
    final dataSummary = backup.busy
        ? l10n.settingsWebDavWorking
        : backup.isConfigured
        ? l10n.settingsWebDavConfigured
        : l10n.settingsDataSyncSubtitle;
    final entries = [
      (
        SettingsCategory.preferences,
        Icons.tune_rounded,
        l10n.settingsPreferencesSubtitle,
      ),
      (SettingsCategory.dataSync, Icons.cloud_sync_outlined, dataSummary),
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
                InkWell(
                  key: ValueKey('settings-category-${entries[i].$1.name}'),
                  onTap: () => _openCategory(entries[i].$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            entries[i].$2,
                            size: 19,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryTitle(l10n, entries[i].$1),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entries[i].$3,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(
    ThemeNotifier themeNotifier,
    AppSettingsNotifier appSettings,
  ) {
    final l10n = context.l10n;
    final webDavSync = context.watch<WebDavBackupController>();
    final children = switch (widget.category!) {
      SettingsCategory.preferences => <Widget>[
        _buildAppearanceSettingsSection(l10n, themeNotifier, appSettings),
        const SizedBox(height: 20),
        _buildReadingSettingsSection(l10n),
        const SizedBox(height: 20),
        _buildGeneralSettingsSection(l10n, appSettings),
      ],
      SettingsCategory.dataSync => <Widget>[
        _buildDataSyncSettingsSection(l10n, webDavSync),
      ],
      SettingsCategory.contentServices => <Widget>[
        _buildContentServicesSection(l10n),
        if (appSettings.advancedFeaturesUnlocked) ...[
          const SizedBox(height: 20),
          _buildAdvancedSettingsSection(l10n, appSettings),
        ],
      ],
      SettingsCategory.aboutSupport => <Widget>[
        _buildSupportSettingsSection(l10n),
        const SizedBox(height: 20),
        _buildAboutCard(),
      ],
    };
    return ListView(
      controller: _scrollController,
      padding: floatingSubpagePadding(context, bottom: 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
