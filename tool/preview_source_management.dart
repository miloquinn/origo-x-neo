import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/book_sources/controllers/book_source_management_controller.dart';
import 'package:xxread/pages/book_sources/widgets/book_source_management_list.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

// Native renderer fixture using the production list, cards, search and filters.
// flutter run -d <simulator> -t tool/preview_source_management.dart --no-pub
void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _scroll = ScrollController();
  final _search = TextEditingController();
  var _index = 0;
  static const _scenes = [
    'frosted-light',
    'frosted-dark',
    'liquid-light',
    'liquid-dark',
    'solid-light',
    'solid-dark',
    'high-contrast',
    'large-text',
    'group-selected',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final off = scene.startsWith('solid');
    final dark = scene.endsWith('dark');
    final large = scene == 'large-text';
    final style = scene.startsWith('liquid')
        ? GlassStyle.liquid
        : GlassStyle.frosted;
    GlassEffectConfig.setDisableAllGlassEffects(off);
    GlassEffectConfig.setGlassStyle(style);
    final size = Size(large ? 320 : 390, 844);
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppThemes.defaultAccentColor,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      extensions: [
        UiStyleThemeExtension(
          style: off ? AppUiStyle.material3 : AppUiStyle.glass,
          glassStyle: style,
        ),
      ],
    );
    final state = BookSourceManagementState(
      sources: _previewSources,
      loading: false,
      selectedGroup: scene == 'group-selected' ? '整理检验' : null,
      filter: scene == 'group-selected'
          ? BookSourceManagementFilter.requiresLogin
          : scene == 'liquid-dark'
          ? BookSourceManagementFilter.enabled
          : BookSourceManagementFilter.all,
    );
    return Center(
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: size,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: size,
                padding: const EdgeInsets.only(top: 44, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                highContrast: scene == 'high-contrast',
                textScaler: TextScaler.linear(large ? 2 : 1),
              ),
              child: child!,
            ),
            home: FloatingSubpageScaffold(
              title: '书源管理',
              onBack: () {},
              actions: [
                FloatingSubpageAction(
                  tooltip: '更多操作',
                  icon: Icons.tune_rounded,
                  onPressed: () {},
                ),
              ],
              body: BookSourceManagementList(
                state: state,
                visibleSources: state.visibleSources,
                availableGroups: state.availableGroups,
                searchController: _search,
                scrollController: _scroll,
                additionalProtocolsEnabled: true,
                onQueryChanged: (_) {},
                onClearQuery: _search.clear,
                onFilterChanged: (_) {},
                onChooseGroup: () {},
                onResetFilters: () {},
                onToggleSelectAll: () {},
                onEnableSelected: () {},
                onDisableSelected: () {},
                onCheckSelected: () {},
                onExportSelected: () {},
                exportInProgress: false,
                onGroupSelected: () {},
                onRemoveSelected: () {},
                onToggleSourceSelection: (_) {},
                onSourceEnabledChanged: (_, _) {},
                onSourceAction: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/source-management-previews',
    );
    await directory.create(recursive: true);
    for (var i = 0; i < _scenes.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      if (_scenes[i] == 'group-selected') {
        Element? group;
        void visit(Element element) {
          if (element.widget.key == const Key('bookSourceGroupFilter')) {
            group = element;
          }
          element.visitChildElements(visit);
        }

        visit(_boundary.currentContext! as Element);
        if (group != null) await Scrollable.ensureVisible(group!, alignment: 1);
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final screenshot = await boundary.toImage(pixelRatio: 2);
      final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      screenshot.dispose();
      await File(
        '${directory.path}/${_scenes[i]}.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    }
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'scenes': _scenes,
        'kind': 'production Flutter list component preview',
      }),
    );
    debugPrint('SOURCE_MANAGEMENT_PREVIEWS_COMPLETE ${directory.path}');
  }
}

final _previewSources = [
  _source(
    id: 'ecc6',
    name: 'E小说网6',
    description: 'm.ecc6.com',
    groups: const ['源仓库', '整理检验'],
    login: true,
    failed: true,
  ),
  _source(
    id: 'forum',
    name: 'FORUM Group — 一个名字很长的社区书源',
    description: '1、爬梯子，2、保持耐心，3、遇到限流稍后重试',
    groups: const ['有效'],
    failed: true,
  ),
  _source(
    id: 'lofter',
    name: 'Lofter',
    description: '// Error: Timeout while validating the reading chain',
    groups: const ['有效', '整理检验与名称很长仍然不能撑破卡片的分组'],
    login: true,
    failed: true,
  ),
];

RegisteredBookSource _source({
  required String id,
  required String name,
  required String description,
  required List<String> groups,
  bool login = false,
  bool failed = false,
}) => RegisteredBookSource(
  id: id,
  name: name,
  description: description,
  manifestUrl: Uri.parse('https://$id.example/source.json'),
  apiBaseUrl: Uri.parse('https://$id.example'),
  protocolVersion: 'reading-source-1',
  languages: const ['zh'],
  capabilities: const {'search', 'detail', 'catalog', 'content'},
  enabled: true,
  groups: groups,
  addedAt: DateTime.utc(2026, 9, 12),
  sourceProtocol: BookSourceProtocolKind.readingSource,
  sourceConfig: {
    if (login) 'loginUrl': 'https://$id.example/login',
    if (failed)
      '_openReadingHealthCheck': const {
        'checked': ['search', 'info', 'catalog', 'content'],
        'failed': ['content'],
        'checkedAt': '2026-09-12T00:00:00Z',
      },
  },
);
