import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:xxread/utils/app_skin_licenses.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/app_skin_icon.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';

class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({
    this.appVersion = '',
    this.title,
    this.prioritizeAssets = false,
    super.key,
  });

  final String appVersion;
  final String? title;
  final bool prioritizeAssets;

  static const _fontLicenses = [
    _BundledLicense(
      name: 'Phosphor Icons',
      assetPath: 'assets/fonts/licenses/Phosphor-MIT.txt',
      subtitle: 'MIT License',
    ),
    _BundledLicense(
      name: 'Noto Serif SC / Source Han Serif',
      assetPath: 'assets/fonts/licenses/NotoSerifSC-OFL.txt',
      subtitle: 'SIL Open Font License 1.1',
    ),
    _BundledLicense(
      name: 'Source Han Sans CN',
      assetPath: 'assets/fonts/licenses/SourceHanSans-OFL.txt',
      subtitle: 'SIL Open Font License 1.1',
    ),
    _BundledLicense(
      name: 'Instrument Sans',
      assetPath: 'assets/fonts/licenses/InstrumentSans-OFL.txt',
      subtitle: 'SIL Open Font License 1.1',
    ),
    _BundledLicense(
      name: 'Newsreader',
      assetPath: 'assets/fonts/licenses/Newsreader-OFL.txt',
      subtitle: 'SIL Open Font License 1.1',
    ),
    _BundledLicense(
      name: 'JetBrains Mono',
      assetPath: 'assets/fonts/licenses/JetBrainsMono-OFL.txt',
      subtitle: 'SIL Open Font License 1.1',
    ),
    _BundledLicense(
      name: 'HarmonyOS Sans',
      assetPath: 'assets/fonts/licenses/HarmonyOSSans-License.txt',
      subtitle: 'HarmonyOS Sans Fonts License Agreement',
    ),
  ];

  static const _bundledCodeLicenses = [
    _BundledLicense(
      name: 'Lobe Icons',
      assetPath: 'assets/ai_providers/LICENSE-MIT.txt',
      subtitle: 'MIT License',
    ),
    _BundledLicense(
      name: 'Provider brand artwork',
      assetPath: 'assets/ai_providers/BRAND-NOTICE.txt',
      subtitle: 'Third-party service marks',
      keyName: 'provider-brand-notice',
      zhName: '服务名称与品牌声明',
      jaName: 'プロバイダーブランド素材',
      zhSubtitle: '第三方服务标识使用说明',
      jaSubtitle: '第三者サービスマークに関する注意事項',
    ),
    _BundledLicense(
      name: 'App skin artwork',
      assetPath: 'assets/skins/APP_CREDITS.txt',
      subtitle: 'Artwork credits and licenses',
      keyName: 'skin-artwork-credits',
      zhName: '应用皮肤素材',
      jaName: 'アプリスキン素材',
      zhSubtitle: '素材来源与许可',
      jaSubtitle: '素材のクレジットとライセンス',
    ),
    _BundledLicense(
      name: 'IconPark graphics',
      assetPath: 'assets/skins/LICENSE-ICONPARK-APACHE-2.0.txt',
      subtitle: 'Apache License 2.0',
      keyName: 'iconpark-license',
      zhName: 'IconPark 图形素材',
      jaName: 'IconPark グラフィック',
    ),
    _BundledLicense(
      name: 'The Met Open Access',
      assetPath: 'assets/purchase/ARTWORK-NOTICE.txt',
      subtitle: 'Public domain · CC0',
    ),
    _BundledLicense(
      name: 'Dart QR encoder adaptation',
      assetPath: 'assets/fonts/licenses/DartQr-BSD-3-Clause.txt',
      subtitle: 'BSD 3-Clause License',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    registerAppSkinLicenses();
    final l10n = context.l10n;
    return FloatingSubpageScaffold(
      title: title ?? l10n.openSourceLicensesTitle,
      body: ListView(
        padding: floatingSubpagePadding(context),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntroCard(text: l10n.openSourceLicensesIntro),
                  const SizedBox(height: 22),
                  _SectionTitle(title: l10n.openSourceProjectSection),
                  const SizedBox(height: 8),
                  _LicenseEntryCard(
                    key: const ValueKey('origo-x-agpl-license'),
                    title: 'Origo X',
                    subtitle: 'GNU Affero General Public License v3.0',
                    icon: Icons.code_rounded,
                    onTap: () => _openBundledLicense(
                      context,
                      title: 'Origo X · AGPL-3.0',
                      assetPath: 'LICENSE',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LicenseEntryCard(
                    title: l10n.openSourceLegacyLicenseTitle,
                    subtitle: 'MIT License · v1.0.0 and earlier',
                    icon: Icons.history_rounded,
                    onTap: () => _openBundledLicense(
                      context,
                      title: '${l10n.openSourceLegacyLicenseTitle} · MIT',
                      assetPath: 'LICENSE-MIT-LEGACY',
                    ),
                  ),
                  if (prioritizeAssets) ..._dependencySection(context),
                  ..._fontSection(context),
                  if (!prioritizeAssets) ..._dependencySection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fontSection(BuildContext context) {
    final l10n = context.l10n;
    return [
      const SizedBox(height: 22),
      _SectionTitle(title: l10n.openSourceFontsSection),
      const SizedBox(height: 8),
      for (var index = 0; index < _fontLicenses.length; index++) ...[
        _LicenseEntryCard(
          key: ValueKey('font-license-${_fontLicenses[index].name}'),
          title: _fontLicenses[index].name,
          subtitle: _fontLicenses[index].subtitle,
          icon: Icons.font_download_outlined,
          onTap: () => _openBundledLicense(
            context,
            title: _fontLicenses[index].name,
            assetPath: _fontLicenses[index].assetPath,
          ),
        ),
        if (index != _fontLicenses.length - 1) const SizedBox(height: 10),
      ],
    ];
  }

  List<Widget> _dependencySection(BuildContext context) {
    final l10n = context.l10n;
    return [
      const SizedBox(height: 22),
      _SectionTitle(title: l10n.openSourceDependenciesSection),
      const SizedBox(height: 8),
      for (final license in _bundledCodeLicenses) ...[
        _LicenseEntryCard(
          key: ValueKey(
            license.keyName ?? 'bundled-code-license-${license.name}',
          ),
          title: license.displayName(context),
          subtitle: license.displaySubtitle(context),
          icon: Icons.data_object_rounded,
          onTap: () => _openBundledLicense(
            context,
            title: license.displayName(context),
            assetPath: license.assetPath,
          ),
        ),
        const SizedBox(height: 10),
      ],
      _LicenseEntryCard(
        key: const ValueKey('flutter-package-licenses'),
        title: l10n.openSourceDependenciesTitle,
        subtitle: l10n.openSourceDependenciesSubtitle,
        icon: Icons.widgets_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                _RegistryLicenseDirectoryPage(appVersion: appVersion),
          ),
        ),
      ),
    ];
  }

  void _openBundledLicense(
    BuildContext context, {
    required String title,
    required String assetPath,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LicenseTextPage(title: title, assetPath: assetPath),
      ),
    );
  }
}

class _RegistryLicenseDirectoryPage extends StatefulWidget {
  const _RegistryLicenseDirectoryPage({required this.appVersion});

  final String appVersion;

  @override
  State<_RegistryLicenseDirectoryPage> createState() =>
      _RegistryLicenseDirectoryPageState();
}

class _RegistryLicenseDirectoryPageState
    extends State<_RegistryLicenseDirectoryPage> {
  late final Future<List<_PackageLicenses>> _packages = _loadPackages();
  String _query = '';

  Future<List<_PackageLicenses>> _loadPackages() async {
    registerAppSkinLicenses();
    final byPackage = <String, List<_RegistryNotice>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final paragraphs = [
        for (final paragraph in entry.paragraphs)
          _RegistryParagraph(text: paragraph.text, indent: paragraph.indent),
      ];
      final notice = _RegistryNotice(paragraphs: paragraphs);
      for (final package in entry.packages) {
        byPackage.putIfAbsent(package, () => []).add(notice);
      }
    }
    final packages = [
      for (final entry in byPackage.entries)
        _PackageLicenses(name: entry.key, notices: entry.value),
    ];
    packages.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return packages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FloatingSubpageScaffold(
      title: l10n.openSourceDependenciesTitle,
      tools: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: PillSearchField(
            textFieldKey: const ValueKey('license-search-field'),
            hintText: _creditsCopy(
              context,
              zh: '搜索软件包',
              en: 'Search packages',
              ja: 'パッケージを検索',
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
      ),
      body: FutureBuilder<List<_PackageLicenses>>(
        future: _packages,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.openSourceLicenseLoadFailed));
          }
          final query = _query.toLowerCase();
          final packages = (snapshot.data ?? const <_PackageLicenses>[])
              .where(
                (package) =>
                    query.isEmpty || package.name.toLowerCase().contains(query),
              )
              .toList();
          return ListView.separated(
            key: const ValueKey('license-registry-list'),
            padding: floatingSubpagePadding(
              context,
              top: 16,
              includeHeader: false,
            ),
            itemCount: packages.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        [
                          l10n.openSourceLicenseLegalese,
                          if (widget.appVersion.trim().isNotEmpty)
                            '${l10n.settingsVersionLabel} ${widget.appVersion}',
                        ].join('\n'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                );
              }
              final package = packages[index - 1];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _LicenseEntryCard(
                    key: ValueKey('license-registry-entry-${package.name}'),
                    title: package.name,
                    subtitle: _creditsCopy(
                      context,
                      zh: '${package.notices.length} 份许可声明',
                      en: package.notices.length == 1
                          ? '1 license notice'
                          : '${package.notices.length} license notices',
                      ja: '${package.notices.length} 件のライセンス通知',
                    ),
                    icon: Icons.inventory_2_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _RegistryLicenseDetailPage(package: package),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RegistryLicenseDetailPage extends StatelessWidget {
  const _RegistryLicenseDetailPage({required this.package});

  final _PackageLicenses package;

  @override
  Widget build(BuildContext context) {
    return FloatingSubpageScaffold(
      title: package.name,
      body: ListView(
        key: const ValueKey('license-registry-detail'),
        padding: floatingSubpagePadding(context),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: GlassSurface(
                role: GlassSurfaceRole.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var noticeIndex = 0;
                        noticeIndex < package.notices.length;
                        noticeIndex++
                      ) ...[
                        if (package.notices.length > 1) ...[
                          Text(
                            _creditsCopy(
                              context,
                              zh: '许可声明 ${noticeIndex + 1}',
                              en: 'License notice ${noticeIndex + 1}',
                              ja: 'ライセンス通知 ${noticeIndex + 1}',
                            ),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                        ],
                        for (
                          var paragraphIndex = 0;
                          paragraphIndex <
                              package.notices[noticeIndex].paragraphs.length;
                          paragraphIndex++
                        ) ...[
                          _RegistryParagraphText(
                            paragraph: package
                                .notices[noticeIndex]
                                .paragraphs[paragraphIndex],
                            textKey: ValueKey(
                              'license-paragraph-$noticeIndex-$paragraphIndex',
                            ),
                          ),
                          if (paragraphIndex !=
                              package.notices[noticeIndex].paragraphs.length -
                                  1)
                            const SizedBox(height: 12),
                        ],
                        if (noticeIndex != package.notices.length - 1) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistryParagraphText extends StatelessWidget {
  const _RegistryParagraphText({
    required this.paragraph,
    required this.textKey,
  });

  final _RegistryParagraph paragraph;
  final Key textKey;

  @override
  Widget build(BuildContext context) {
    final centered = paragraph.indent == LicenseParagraph.centeredIndent;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep enough line width for large text on narrow screens while
        // retaining Flutter's paragraph indentation for ordinary notices.
        final availableIndent = (constraints.maxWidth - 160).clamp(
          0.0,
          double.infinity,
        );
        final startPadding = centered
            ? 0.0
            : (paragraph.indent * 16.0).clamp(0.0, availableIndent);
        return Padding(
          padding: EdgeInsetsDirectional.only(start: startPadding),
          child: SelectableText(
            paragraph.text,
            key: textKey,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.55),
          ),
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      role: GlassSurfaceRole.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkinIcon.adapt(
              Icon(Icons.balance_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _LicenseEntryCard extends StatelessWidget {
  const _LicenseEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return GlassSurface(
      role: GlassSurfaceRole.control,
      shape: shape,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 13, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppSkinIcon.adapt(
                    Icon(icon, size: 21, color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AppSkinIcon.adapt(
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
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

class _LicenseTextPage extends StatefulWidget {
  const _LicenseTextPage({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  State<_LicenseTextPage> createState() => _LicenseTextPageState();
}

class _LicenseTextPageState extends State<_LicenseTextPage> {
  late final Future<String> _licenseText = rootBundle.loadString(
    widget.assetPath,
  );

  @override
  Widget build(BuildContext context) {
    return FloatingSubpageScaffold(
      title: widget.title,
      body: FutureBuilder<String>(
        future: _licenseText,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.openSourceLicenseLoadFailed),
              ),
            );
          }
          return SingleChildScrollView(
            padding: floatingSubpagePadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: GlassSurface(
                  role: GlassSurfaceRole.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      snapshot.data ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.55),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _creditsCopy(
  BuildContext context, {
  required String zh,
  required String en,
  String? ja,
}) {
  final locale = context.l10n.localeName.toLowerCase();
  if (locale.startsWith('zh')) return zh;
  if (locale.startsWith('ja')) return ja ?? en;
  return en;
}

class _BundledLicense {
  const _BundledLicense({
    required this.name,
    required this.assetPath,
    required this.subtitle,
    this.keyName,
    this.zhName,
    this.jaName,
    this.zhSubtitle,
    this.jaSubtitle,
  });

  final String name;
  final String assetPath;
  final String subtitle;
  final String? keyName;
  final String? zhName;
  final String? jaName;
  final String? zhSubtitle;
  final String? jaSubtitle;

  String displayName(BuildContext context) =>
      _creditsCopy(context, zh: zhName ?? name, en: name, ja: jaName ?? name);

  String displaySubtitle(BuildContext context) => _creditsCopy(
    context,
    zh: zhSubtitle ?? subtitle,
    en: subtitle,
    ja: jaSubtitle ?? subtitle,
  );
}

class _PackageLicenses {
  const _PackageLicenses({required this.name, required this.notices});

  final String name;
  final List<_RegistryNotice> notices;
}

class _RegistryNotice {
  const _RegistryNotice({required this.paragraphs});

  final List<_RegistryParagraph> paragraphs;
}

class _RegistryParagraph {
  const _RegistryParagraph({required this.text, required this.indent});

  final String text;
  final int indent;
}
