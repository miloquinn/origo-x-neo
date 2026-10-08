import 'package:flutter/widgets.dart';

/// Small UI-only labels for legal navigation.
///
/// The legal text itself always comes from [LegalCatalog]. Keeping these labels
/// here lets the online catalog evolve without coupling it to the app ARB files.
class LegalCopy {
  const LegalCopy._({required this.isChinese});

  factory LegalCopy.of(BuildContext context) =>
      LegalCopy.forLocale(Localizations.localeOf(context));

  factory LegalCopy.forLocale(Locale locale) =>
      LegalCopy._(isChinese: locale.languageCode.toLowerCase() == 'zh');

  final bool isChinese;

  String get hubTitle => isChinese ? '协议与隐私' : 'Agreements & privacy';
  String get hubSubtitle => isChinese
      ? '查看使用协议、隐私政策、书源边界与其他重要条款。'
      : 'Read the terms, privacy policy, source boundaries, and other important notices.';
  String get agreementTitle => isChinese ? '重要条款' : 'Important terms';
  String get agreementSubtitle => isChinese
      ? '请在同意前阅读以下简介，可点击查看完整内容。'
      : 'Review these summaries before accepting. Open any item for the full text.';
  String get loading => isChinese ? '正在载入条款…' : 'Loading legal documents…';
  String get loadFailed => isChinese
      ? '暂时无法读取条款，请重试。'
      : 'Legal documents could not be loaded. Please try again.';
  String get retry => isChinese ? '重试' : 'Retry';
  String get refresh => isChinese ? '检查更新' : 'Check for updates';
  String get refreshing => isChinese ? '正在检查更新…' : 'Checking for updates…';
  String get openDetails => isChinese ? '查看详情' : 'View details';
  String get contents => isChinese ? '目录' : 'Contents';
  String get version => isChinese ? '版本' : 'Version';
  String get effectiveDate => isChinese ? '生效日期' : 'Effective';
  String get updatedDate => isChinese ? '更新日期' : 'Updated';
  String get lastChecked => isChinese ? '最近校验' : 'Last checked';
  String get changes => isChinese ? '本次更新' : 'What changed';
  String get officialCopy => isChinese ? '官网版本' : 'Official web copy';
  String get bundledCopy => isChinese
      ? '当前显示 App 内置版本，可离线阅读。联网后会检查是否有更新。'
      : 'Showing the copy bundled with the app for offline reading. Updates are checked when online.';
  String get cachedCopy => isChinese
      ? '当前显示上次成功缓存的版本，可离线阅读。'
      : 'Showing the last successfully cached copy, available offline.';
  String get onlineCopy => isChinese
      ? '当前显示已校验的在线版本，并已保存供离线阅读。'
      : 'Showing a verified online copy that has been saved for offline reading.';
  String get refreshFailed => isChinese
      ? '未能联网确认最新版本，已继续显示可用的离线内容。'
      : 'The latest copy could not be confirmed online. The available offline copy remains visible.';
  String get fallbackLanguage => isChinese
      ? '当前语言的正文尚未提供，此处显示英文版本。'
      : 'This document is shown in English because a localized copy is not yet available.';
  String get updateAvailable => isChinese
      ? '已发现新版本。当前页面仍保留你开始阅读时的内容。'
      : 'A newer version is available. This page is keeping the copy you started reading.';
  String get showUpdate => isChinese ? '显示新版本' : 'Show new version';
  String get noChanges =>
      isChinese ? '未列出具体更新项。' : 'No change summary was provided.';
  String get sectionLinks => isChinese ? '相关链接' : 'Related links';
}
