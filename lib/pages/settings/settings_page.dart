import 'package:xxread/pages/legal/agreement_summary.dart';
import 'package:xxread/pages/legal/legal_copy.dart';
import 'package:xxread/pages/legal/legal_documents_page.dart';
import 'package:xxread/pages/onboarding/reading_welcome_page.dart';
// 文件说明：设置页面，负责应用主题、语言、同步、备份和外观设置。
// 技术要点：Flutter UI、Icons Plus、Package Info、Provider、SharedPreferences、URL Launcher。

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:xxread/core/reader/reader_keep_screen_on.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/core/reader/reader_system_ui.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/book_sources/book_source_management_page.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/pages/home/home_shell_page.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/pages/settings/about/changelog_page.dart';
import 'package:xxread/pages/settings/about/open_source_licenses_page.dart';
import 'package:xxread/pages/settings/ai_settings_page.dart';
import 'package:xxread/pages/settings/cloud_tts_settings_page.dart';
import 'package:xxread/pages/support/feedback_copy.dart';
import 'package:xxread/pages/support/feedback_page.dart';
import 'package:xxread/services/diagnostics/diagnostics_controller.dart';
import 'package:xxread/services/reader_aloud_service.dart';
import 'package:xxread/pages/settings/cache_management_page.dart';
import 'package:xxread/pages/settings/font_selection_sheet.dart';
import 'package:xxread/pages/settings/floating_navigation_settings_page.dart';
import 'package:xxread/pages/settings/library_layout_settings_page.dart';
import 'package:xxread/pages/settings/replace_rules_page.dart';
import 'package:xxread/pages/settings/backup/webdav_backup_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/core/app_build_info.dart';
import 'package:xxread/services/core/core_services.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/pages/settings/backup/backup_copy.dart';
import 'package:xxread/services/backup/webdav_backup_controller.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/app_themes_translator.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/utils/layout_helper.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/system_ui_helper.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/app_brand_icon.dart';
import 'package:xxread/widgets/accent_color_picker_sheet.dart';
import 'package:xxread/widgets/developer_support_card.dart';
import 'package:xxread/widgets/reader_settings_controls.dart';
import 'package:xxread/widgets/settings_account_card.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/side_toast.dart';
import 'package:xxread/widgets/update_check_gate.dart';

import 'app_text_size_sheet.dart';
import 'custom_fonts_page.dart';
import '../activities/activity_center_page.dart';

part 'parts/settings_appearance_part.dart';
part 'parts/settings_about_part.dart';
part 'parts/settings_layout_part.dart';
part 'parts/settings_hub_part.dart';

enum SettingsCategory { preferences, dataSync, contentServices, aboutSupport }

class SettingsPageController extends ChangeNotifier {
  int _supportRevealRequest = 0;

  int get supportRevealRequest => _supportRevealRequest;

  void revealSupportSection() {
    _supportRevealRequest += 1;
    notifyListeners();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.controller,
    this.libraryController,
    this.libraryUsesRailLayout,
    this.category,
    this.cacheManager,
    this.preferencesStore,
    this.aiService,
  });

  final SettingsPageController? controller;
  final LibraryPageController? libraryController;
  final bool? libraryUsesRailLayout;
  final SettingsCategory? category;
  final AppCacheManager? cacheManager;
  final SettingsPagePreferencesStore? preferencesStore;
  final ConfigurableAIService? aiService;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  late final AppCacheManager _cacheManager;
  late final SettingsPagePreferencesStore _preferencesStore;
  late final ConfigurableAIService _aiService;

  bool _enableAutoSave = true;
  bool _keepScreenOn = false;
  SettingsPagePreferences? _loadedPreferences;

  // 阅读设置
  bool _enableVolumeKeyTurn = false;
  bool _autoResumeReading = false;
  bool _closeReaderToLibrary = true;
  ReaderTopBarStyle _readerTopBarStyle = ReaderTopBarStyle.reader;
  String _appVersion = '0.9.1';
  bool _isCheckingForUpdates = false;
  AIProviderSettings? _activeAiSettings;
  int _lastSupportRevealRequest = 0;
  AppCacheUsage? _cacheUsage;
  bool _loadingCacheUsage = true;

  void _mutate(VoidCallback update) => setState(update);

  @override
  void initState() {
    super.initState();
    _cacheManager = widget.cacheManager ?? AppCacheManager();
    _preferencesStore =
        widget.preferencesStore ??
        SharedPreferencesSettingsPagePreferencesStore();
    _aiService = widget.aiService ?? ReaderHttpAIService();
    if (widget.category == SettingsCategory.aboutSupport) {
      unawaited(_loadAppVersion());
    }
    if (widget.category == SettingsCategory.dataSync) {
      unawaited(_refreshCacheUsage());
    }
    if (widget.category == SettingsCategory.preferences) {
      unawaited(_loadPreferences());
    }
    if (widget.category == SettingsCategory.contentServices) {
      unawaited(_loadAiSettings());
    }
    _attachSettingsController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_handleSupportRevealRequest);
    _attachSettingsController(widget.controller);
  }

  void _attachSettingsController(SettingsPageController? controller) {
    _lastSupportRevealRequest = controller?.supportRevealRequest ?? 0;
    controller?.addListener(_handleSupportRevealRequest);
    if (_lastSupportRevealRequest > 0) {
      _scheduleSupportSectionReveal();
    }
  }

  void _handleSupportRevealRequest() {
    final request = widget.controller?.supportRevealRequest ?? 0;
    if (request == _lastSupportRevealRequest) return;
    _lastSupportRevealRequest = request;
    _scheduleSupportSectionReveal();
  }

  void _scheduleSupportSectionReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openCategory(SettingsCategory.aboutSupport);
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleSupportRevealRequest);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedPreferences = preferences;
      _enableAutoSave = preferences.enableAutoSave;
      _keepScreenOn = preferences.keepScreenOn;
      _enableVolumeKeyTurn = preferences.enableVolumeKeyTurn;
      _autoResumeReading = preferences.autoResumeReading;
      _closeReaderToLibrary = preferences.closeReaderToLibrary;
      _readerTopBarStyle = preferences.readerTopBarStyle;
    });
  }

  Future<void> _loadAiSettings() async {
    final active = await _aiService.loadSettings();
    if (!mounted) return;
    setState(() => _activeAiSettings = active);
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final buildNumber = await readAppReleaseBuildNumber(info);
      if (!mounted) {
        return;
      }
      setState(() {
        _appVersion = version.isNotEmpty
            ? (buildNumber.isNotEmpty ? '$version ($buildNumber)' : version)
            : '0.9.1';
      });
    } catch (_) {
      // Keep default version fallback.
    }
  }

  Future<void> _refreshCacheUsage() async {
    try {
      final usage = await _cacheManager.usage();
      if (!mounted) return;
      setState(() {
        _cacheUsage = usage;
        _loadingCacheUsage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCacheUsage = false);
    }
  }

  Future<void> _openCacheManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CacheManagementPage(cacheManager: _cacheManager),
      ),
    );
    if (mounted) await _refreshCacheUsage();
  }

  Future<void> _openAiSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()));
    if (!mounted) return;
    await _loadAiSettings();
  }

  Future<void> _saveSettings() async {
    final previous = _loadedPreferences;
    if (previous == null) return;
    // Preserve settings owned by other features without mirroring them in UI state.
    final preferences = SettingsPagePreferences(
      enableAutoSave: _enableAutoSave,
      keepScreenOn: _keepScreenOn,
      autoSaveInterval: previous.autoSaveInterval,
      enableAutoExtractCover: previous.enableAutoExtractCover,
      enableVolumeKeyTurn: _enableVolumeKeyTurn,
      autoResumeReading: _autoResumeReading,
      closeReaderToLibrary: _closeReaderToLibrary,
      readerTopBarStyle: _readerTopBarStyle,
      enableFullscreen: previous.enableFullscreen,
      enableDeveloperMode: previous.enableDeveloperMode,
      enableDebugLogging: previous.enableDebugLogging,
      enablePerformanceMonitor: previous.enablePerformanceMonitor,
      enableMemoryStats: previous.enableMemoryStats,
      showFPS: previous.showFPS,
    );
    _loadedPreferences = preferences;
    await _preferencesStore.save(preferences);
  }

  void _setKeepScreenOn(bool value) {
    setState(() => _keepScreenOn = value);
    unawaited(ReaderKeepScreenOnController.setPreference(value));
  }

  String _readerTopBarStyleTitle(ReaderTopBarStyle style) => switch (style) {
    ReaderTopBarStyle.system => context.l10n.readerTopBarStyleSystem,
    ReaderTopBarStyle.reader => context.l10n.readerTopBarStyleReader,
    ReaderTopBarStyle.floating => context.l10n.readerTopBarStyleFloating,
    ReaderTopBarStyle.hidden => context.l10n.readerTopBarStyleHidden,
  };

  String _readerTopBarStyleHint(ReaderTopBarStyle style) => switch (style) {
    ReaderTopBarStyle.system => context.l10n.readerTopBarStyleSystemHint,
    ReaderTopBarStyle.reader => context.l10n.readerTopBarStyleReaderHint,
    ReaderTopBarStyle.floating => context.l10n.readerTopBarStyleFloatingHint,
    ReaderTopBarStyle.hidden => context.l10n.readerTopBarStyleHiddenHint,
  };

  Future<void> _showReaderTopBarStylePicker() async {
    final prefs = await SharedPreferences.getInstance();
    final palette = ReaderThemes.byId(
      prefs.getString(ReaderSettingsStore.themeKey) ??
          ReaderSettings.defaultThemeId,
    );
    if (!mounted) return;
    final selected = await showModalBottomSheet<ReaderTopBarStyle>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ReaderTopBarStyleSheet(
        palette: palette,
        title: context.l10n.readerTopBarStyleTitle,
        selectedStyle: _readerTopBarStyle,
        titleFor: _readerTopBarStyleTitle,
        hintFor: _readerTopBarStyleHint,
        onSelected: (style) => Navigator.of(sheetContext).pop(style),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _readerTopBarStyle = selected);
    await ReaderSystemUiController.savePreference(selected);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category != null) {
      return FloatingSubpageScaffold(
        title: _categoryTitle(context.l10n, widget.category!),
        body: _buildCategoryContent(),
      );
    }

    final themeStyle = context.select<ThemeNotifier, (AppUiStyle, GlassStyle)>(
      (theme) => (theme.uiStyle, theme.glassStyle),
    );
    final isMaterial3Style = themeStyle.$1 == AppUiStyle.material3;
    // 检查是否在侧边导航栏模式下
    final navContext = NavigationContext.of(context);
    final useRailNavigation = navContext?.useRailNavigation ?? false;

    // 在侧边导航栏模式下，不显示 Scaffold 和 AppBar
    if (useRailNavigation) {
      return _buildContent(context);
    }

    // 手机模式：显示完整的 Scaffold + AppBar
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isMaterial3Style
            ? Theme.of(context).colorScheme.surface
            : Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // 关闭系统AppBar，使用自绘毛玻璃顶栏
        systemOverlayStyle: SystemUiHelper.overlayStyleForBrightness(
          Theme.of(context).brightness,
        ),
      ),
      body: _buildContent(context),
    );
  }

  // 提取页面内容部分，在两种模式下共用
  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final useRailNavigation =
        NavigationContext.of(context)?.useRailNavigation ?? false;
    final useTabletLayout = LayoutHelper.usesTabletLayout(context);
    final mobileChrome = HomeMobileChromeScope.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final horizontalPadding = useTabletLayout
        ? LayoutHelper.tabletPagePadding
        : useRailNavigation
        ? 28.0
        : 16.0;
    return Container(
      decoration: BoxDecoration(
        gradient: PageStyleHelper.backgroundGradient(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = (constraints.maxWidth - horizontalPadding * 2)
              .clamp(
                0.0,
                LayoutHelper.tabletContentMaxWidth -
                    (useTabletLayout ? 2 * LayoutHelper.tabletPagePadding : 0),
              )
              .toDouble();
          final useTwoColumns = availableWidth >= 840;
          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              useRailNavigation
                  ? viewPadding.top + 8
                  : mobileChrome.pageTopPadding,
              horizontalPadding,
              useRailNavigation
                  ? viewPadding.bottom + 24
                  : mobileChrome.pageBottomPadding,
            ),
            children: [
              if (useTwoColumns)
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: availableWidth,
                    child: _buildMyPageWide(l10n),
                  ),
                )
              else
                ..._buildMyPageSingleColumn(l10n),
            ],
          );
        },
      ),
    );
  }

  void _openBookSourceManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BookSourceManagementPage()),
    );
  }

  void _openReplaceRules() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReplaceRulesPage(service: context.read<ReplaceRuleService>()),
      ),
    );
  }

  Widget _buildSwitchSetting({
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    bool enabled = true,
    bool persistPageSettings = true,
  }) {
    final settingEnabled =
        enabled && (!persistPageSettings || _loadedPreferences != null);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: settingEnabled
              ? () {
                  onChanged(!value);
                  if (persistPageSettings) {
                    unawaited(_saveSettings());
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: settingEnabled
                      ? (newValue) {
                          onChanged(newValue);
                          if (persistPageSettings) {
                            unawaited(_saveSettings());
                          }
                        }
                      : null,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String label;

  const _LanguageOption({required this.code, required this.label});
}

String _hexColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
