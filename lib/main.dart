// 文件说明：应用启动入口，负责初始化数据库、依赖注入、主题、国际化与全局服务。
// 技术要点：Flutter Localizations、Provider、SharedPreferences、SQLite FFI、Path Provider。

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart' as provider;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'l10n/app_localizations.dart';
import 'book_sources/caching/book_source_chapter_cache.dart';
import 'book_sources/caching/book_source_response_cache.dart';
import 'book_sources/caching/source_cover_cache.dart';
import 'book_sources/services/book_source_client.dart';
import 'book_sources/services/book_source_registry.dart';
import 'book_sources/services/book_source_maintenance_coordinator.dart';
import 'book_sources/services/book_source_shelf_service.dart';
import 'book_sources/source_engine/source_interaction_coordinator.dart';
import 'models/book.dart';
import 'pages/home/home_shell_page.dart';
import 'pages/reader/book_reader_launcher.dart';
import 'pages/reader/native/native_reader_page.dart';
import 'pages/library/import_book/import_book_page.dart';
import 'pages/legal/user_agreement_page.dart';
import 'pages/legal/legal_agreement_gate.dart';
import 'pages/legal/legal_document_page.dart';
import 'pages/support/diagnostics_consent_dialog.dart';
import 'services/legal/legal_document_repository.dart';
import 'pages/reader/book_source/online_reader_factory.dart';
import 'pages/book_sources/source_verification_page.dart';
import 'services/books/book_services.dart';
import 'services/books/book_format_support.dart';
import 'services/ai/ai_chat_history_store.dart';
import 'services/reading/reading_resume_service.dart';
import 'services/reading/reading_account_scope.dart';
import 'services/reading/reading_cloud_controller.dart';
import 'services/reader/replace_rule_service.dart';
import 'services/core/app_distribution.dart';
import 'services/core/legacy_reader_access.dart';
import 'services/core/app_update_download_service.dart';
import 'services/core/background_download_notifier.dart';
import 'services/core/app_settings_service.dart';
import 'services/core/theme_notifier.dart';
import 'services/core/display_refresh_rate_controller.dart';
import 'services/core/desktop_window_service.dart';
import 'services/library/download_task_controller.dart';
import 'services/backup/webdav_backup_controller.dart';
import 'utils/app_themes.dart';
import 'utils/book_open_transition.dart';
import 'services/tts_service.dart';
import 'services/reader_aloud_service.dart';
import 'services/reader_aloud_session.dart';
import 'services/account/account.dart';
import 'services/diagnostics/diagnostics_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/localization_extension.dart';
import 'utils/font_catalog_helper.dart';
import 'utils/reader_themes.dart';
import 'utils/ui_style.dart';
import 'widgets/app_brand_icon.dart';
import 'widgets/app_text_scale.dart';
import 'widgets/restartable_app.dart';
import 'widgets/side_toast.dart';
import 'widgets/update_check_gate.dart';
import 'widgets/store_reader_access_gate.dart';

void main(List<String> arguments) async {
  // 确保可以在 runApp 前安全调用 SystemChrome
  WidgetsFlutterBinding.ensureInitialized();
  await AppDistribution.initialize();
  await LegacyReaderAccess.initialize();
  // Large imported source libraries used to live in one SharedPreferences
  // value. Move that blob before any global preference cache is warmed so a
  // multi-thousand-source library cannot make startup consume ~1 GB or ANR.
  if (!kIsWeb) await WebDavBackupController.recoverPendingRestore();
  await BookSourceRegistry().prepareStorage();
  // Warm the reader palette while the app shell is starting so tapping a book
  // does not have to wait for SharedPreferences and custom-theme decoding.
  unawaited(ReaderThemes.loadSavedPalette());

  // 按用户偏好选择 60Hz 省电模式或设备支持的最高刷新率。
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: '开元阅读',
        primaryColor: 0xFF1976D2,
      ),
    );
    await DisplayRefreshRateController.applySavedPreference();
  }

  // 在桌面平台上初始化 sqflite_common_ffi
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 设置基础系统UI样式 - 透明背景
  // 注意：不在这里设置SystemUiMode，让各页面根据需要自行控制
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // iOS: 状态栏图标为深色(适合白色背景)
      statusBarBrightness: Brightness.light, // iOS: 状态栏背景为浅色
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await ReadingAccountScope.instance.restore();

  runApp(
    RestartableApp(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          provider.ChangeNotifierProvider(
            create: (_) => BookSourceMaintenanceCoordinator(),
          ),
          provider.ChangeNotifierProvider(
            create: (_) => MemberAccountController(networkAllowed: false),
          ),
          provider.ChangeNotifierProvider(
            lazy: false,
            create: (context) {
              final account = provider.Provider.of<MemberAccountController>(
                context,
                listen: false,
              );
              final diagnostics = DiagnosticsController(account: account)
                ..setNetworkAllowed(account.networkAllowed);
              unawaited(diagnostics.initialize());
              return diagnostics;
            },
          ),
          provider.ChangeNotifierProvider(
            lazy: false,
            create: (context) => ReadingCloudController(
              networkAllowed: false,
              account: provider.Provider.of<MemberAccountController>(
                context,
                listen: false,
              ),
            ),
          ),
          provider.ChangeNotifierProvider(
            lazy: false,
            create: (context) => AppSettingsNotifier(
              account: provider.Provider.of<MemberAccountController>(
                context,
                listen: false,
              ),
            ),
          ),
          provider.ChangeNotifierProvider(
            create: (_) => ReplaceRuleService()..load(),
          ),
          provider.ChangeNotifierProvider(create: (_) => AiChatHistoryStore()),
          provider.ChangeNotifierProvider(create: (_) => TtsService()),
          provider.ChangeNotifierProxyProvider<TtsService, ReaderAloudService>(
            create: (context) => ReaderAloudService(
              systemEngine: provider.Provider.of<TtsService>(
                context,
                listen: false,
              ),
            ),
            update: (context, tts, service) =>
                service ?? ReaderAloudService(systemEngine: tts),
          ),
          provider.ChangeNotifierProvider(create: (_) => ReaderAloudSession()),
          provider.ChangeNotifierProvider(
            create: (_) => DownloadTaskController(),
          ),
          provider.ChangeNotifierProvider(
            create: (_) => WebDavBackupController(),
          ),
        ],
        child: StoreReaderEntitlementListener(
          child: XxReadApp(
            initialFilePaths: _supportedDesktopFileArguments(arguments),
          ),
        ),
      ),
    ),
  );
}

List<String> _supportedDesktopFileArguments(List<String> arguments) {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) return const [];
  final paths = <String>[];
  for (final argument in arguments) {
    var candidate = argument;
    final uri = Uri.tryParse(argument);
    if (uri != null && uri.scheme == 'file') {
      try {
        candidate = uri.toFilePath();
      } catch (_) {
        continue;
      }
    }
    final file = File(candidate);
    if (!file.existsSync()) continue;
    final extension = BookFormatRegistry.normalizeExtension(
      path.extension(candidate),
    );
    if (BookFormatRegistry.pickerExtensions.contains(extension)) {
      paths.add(file.absolute.path);
    }
  }
  return List<String>.unmodifiable(paths.toSet());
}

class XxReadApp extends StatefulWidget {
  const XxReadApp({
    super.key,
    this.initialFilePaths = const [],
    this.sourceInteractionCoordinator,
    this.legalRepository,
  });

  final List<String> initialFilePaths;
  final SourceInteractionCoordinator? sourceInteractionCoordinator;
  final LegalDocumentRepository? legalRepository;

  LegalDocumentRepository get _legalRepository =>
      legalRepository ?? LegalDocumentRepository.instance;

  SourceInteractionCoordinator get _coordinator =>
      sourceInteractionCoordinator ?? SourceInteractionCoordinator.instance;

  @override
  State<XxReadApp> createState() => _XxReadAppState();
}

class _XxReadAppState extends State<XxReadApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _legalNavigationObserver = LegalAgreementNavigationObserver();
  bool? _hasAcceptedAgreement;
  bool _requiresUpdatedAgreement = false;
  bool _isBootstrapped = false;
  bool _showFirstHomeSupportAfterAgreement = false;
  bool _pendingFirstHomeSupportAfterDiagnostics = false;
  _BootstrapError? _bootstrapError;
  StreamSubscription<BackgroundDownloadTap>? _notificationTapSubscription;
  StreamSubscription<SourceInteractionTicket>? _sourceInteractionSubscription;
  final List<SourceInteractionTicket> _pendingSourceInteractions = [];
  bool _showingSourceInteraction = false;
  bool _diagnosticsConsentPromptActive = false;
  BackgroundDownloadTap? _pendingNotificationTap;
  bool _resumeReadingHandled = false;
  late final IncomingBookService _incomingBookService;

  @override
  void initState() {
    super.initState();
    DesktopWindowService.initialize(_navigatorKey);
    WidgetsBinding.instance.addObserver(this);
    _incomingBookService = IncomingBookService(
      bridge: IncomingBookPlatformBridge(),
      materializer: IncomingBookMaterializer(),
      importer: BookImportService(),
      openBook: _openIncomingBook,
      openImportQueue: _openIncomingImportQueue,
      onFailure: _showIncomingBookFailure,
      onProcessing: (processing) {
        if (processing) _showIncomingBookProcessing();
      },
    );
    unawaited(
      _incomingBookService.start().catchError((Object error) {
        debugPrint('入站书籍通道初始化失败: $error');
      }),
    );
    _enqueueInitialDesktopBooks();
    _notificationTapSubscription = BackgroundDownloadNotifier.taps.listen(
      _handleNotificationTap,
    );
    _sourceInteractionSubscription = widget._coordinator.requests.listen(
      _queueSourceInteraction,
    );
    unawaited(BackgroundDownloadNotifier.initialize());
    _bootstrapServices();
    _checkAgreementStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DesktopWindowService.dispose();
    _notificationTapSubscription?.cancel();
    _sourceInteractionSubscription?.cancel();
    widget._coordinator.cancelAll();
    unawaited(_incomingBookService.dispose());
    super.dispose();
  }

  void _queueSourceInteraction(SourceInteractionTicket ticket) {
    _pendingSourceInteractions.add(ticket);
    _showNextSourceInteraction();
  }

  Future<void> _showNextSourceInteraction() async {
    if (!_isBootstrapped || _hasAcceptedAgreement != true) return;
    if (_showingSourceInteraction || _pendingSourceInteractions.isEmpty) return;
    final context = _navigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showNextSourceInteraction(),
      );
      return;
    }
    _showingSourceInteraction = true;
    final ticket = _pendingSourceInteractions.removeAt(0);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SourceVerificationPage(
            ticket: ticket,
            coordinator: widget._coordinator,
          ),
        ),
      );
    } finally {
      _showingSourceInteraction = false;
      _showNextSourceInteraction();
    }
  }

  void _enqueueInitialDesktopBooks() {
    if (widget.initialFilePaths.isEmpty) return;
    final requestId =
        'desktop:${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    _incomingBookService.addRequest(
      IncomingBookRequest(
        requestId: requestId,
        action: IncomingBookAction.open,
        items: [
          for (var index = 0; index < widget.initialFilePaths.length; index++)
            IncomingBookItem(
              id: '$requestId:$index',
              displayName: path.basename(widget.initialFilePaths[index]),
              localPath: widget.initialFilePaths[index],
            ),
        ],
      ),
    );
  }

  void _syncIncomingBookReadiness() {
    final ready = _isBootstrapped && _hasAcceptedAgreement == true;
    if (!ready) {
      unawaited(_incomingBookService.setReady(false));
      return;
    }
    if (_navigatorKey.currentContext != null) {
      unawaited(_incomingBookService.setReady(true));
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncIncomingBookReadiness();
    });
  }

  Future<void> _openIncomingBook(Book book) async {
    // 外部打开文件是显式意图，本次启动不再自动恢复上次阅读。
    _resumeReadingHandled = true;
    final context = _navigatorKey.currentContext;
    if (!mounted || context == null) {
      throw StateError('Navigator is not ready for an incoming book');
    }
    // Wait for repair and successful route insertion, but do not hold the
    // incoming-request FIFO until the reader is closed.
    await BookReaderLauncher.openBook(context, book, waitForReaderClose: false);
  }

  Future<void> _openIncomingImportQueue(List<BookImportSource> sources) async {
    _resumeReadingHandled = true;
    final context = _navigatorKey.currentContext;
    if (!mounted || context == null) {
      throw StateError('Navigator is not ready for incoming books');
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ImportBookPage(initialSources: sources),
      ),
    );
  }

  void _showIncomingBookProcessing() {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      showSideToast(context, context.l10n.incomingBooksImporting);
    }
  }

  void _showIncomingBookFailure(IncomingBookFailure failure) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('入站书籍失败: ${failure.code}');
      return;
    }
    final message = switch (failure.code) {
      'no_book_file' => context.l10n.incomingBooksNoBookFile,
      'permission_expired' => context.l10n.incomingBooksPermissionExpired,
      'unsupported_format' => context.l10n.incomingBooksUnsupportedFormat,
      'file_too_large' => context.l10n.incomingBooksFileTooLarge,
      'too_many_files' => context.l10n.incomingBooksTooManyFiles,
      'content_mismatch' => context.l10n.incomingBooksContentMismatch,
      'partial_failure' => context.l10n.incomingBooksSomeFilesSkipped,
      _ => context.l10n.incomingBooksImportFailed,
    };
    showSideToast(context, message, kind: SideToastKind.error);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_resumeAuthorizedServices());
    }
  }

  Future<void> _resumeAuthorizedServices() async {
    if (_hasAcceptedAgreement != true) return;
    // Native sign-in and permission sheets also resume the app. Revalidation
    // does not revoke accepted consent: doing so invalidates their in-flight
    // account requests even when the policy has not changed. The refresh path
    // closes all network gates only after confirming a new consent version.
    await _refreshAgreementStatus();
    if (!mounted || _hasAcceptedAgreement != true) return;
    await _startAuthorizedServices();
  }

  Future<void> _startAuthorizedServices() async {
    if (!mounted || _hasAcceptedAgreement != true) {
      return;
    }
    final cloud = provider.Provider.of<ReadingCloudController>(
      context,
      listen: false,
    );
    final account = provider.Provider.of<MemberAccountController>(
      context,
      listen: false,
    );
    account.setNetworkAllowed(true);
    final diagnostics = provider.Provider.of<DiagnosticsController>(
      context,
      listen: false,
    );
    diagnostics.setNetworkAllowed(true);
    cloud.setNetworkAllowed(true);
    await diagnostics.initialize();
    if (!mounted || _hasAcceptedAgreement != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeOfferDiagnosticsConsent(diagnostics));
    });
    await account.synchronize();
    if (!mounted || _hasAcceptedAgreement != true || !cloud.networkAllowed) {
      return;
    }
    await cloud.initialize();
  }

  Future<void> _maybeOfferDiagnosticsConsent(
    DiagnosticsController diagnostics,
  ) async {
    if (!mounted || _hasAcceptedAgreement != true) return;
    if (!diagnostics.shouldOfferConsent) {
      _releaseFirstHomeSupport();
      return;
    }
    if (_diagnosticsConsentPromptActive ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    final promptContext = _navigatorKey.currentContext;
    if (promptContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_maybeOfferDiagnosticsConsent(diagnostics));
      });
      return;
    }
    _diagnosticsConsentPromptActive = true;
    try {
      final enable = await showDiagnosticsConsentDialog(
        promptContext,
        onOpenPrivacy: () => _openDiagnosticsPrivacy(promptContext),
        onAnswer: diagnostics.answerConsentPrompt,
      );
      if (!mounted || _hasAcceptedAgreement != true) return;
      debugPrint('性能与耗电统计选择：${enable ? "已开启" : "暂不开启"}');
      _releaseFirstHomeSupport();
    } finally {
      _diagnosticsConsentPromptActive = false;
    }
  }

  void _releaseFirstHomeSupport() {
    if (!mounted || !_pendingFirstHomeSupportAfterDiagnostics) return;
    setState(() {
      _pendingFirstHomeSupportAfterDiagnostics = false;
      _showFirstHomeSupportAfterAgreement = true;
    });
  }

  Future<void> _openDiagnosticsPrivacy(BuildContext context) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final snapshot = await widget._legalRepository.load(locale: locale);
    if (!context.mounted) return;
    final privacy = snapshot.catalog.document('privacy');
    final navigator = _navigatorKey.currentState;
    if (privacy == null || navigator == null) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(
          document: privacy,
          repository: widget._legalRepository,
          source: snapshot.source,
          checkedAt: snapshot.checkedAt,
        ),
      ),
    );
  }

  @override
  void didHaveMemoryPressure() {
    // Keep disk caches and user data intact. These are all reconstructable
    // process-memory caches, so releasing them is safe even while a reader is
    // open; the active page retains the content it is currently displaying.
    clearNativeReaderMemoryCaches();
    BookSourceChapterCache.releaseMemory();
    BookSourceResponseCache.instance.clearMemory();
    SourceCoverCache.instance.clearMemory();
    SourceCoverCache.imagePageInstance.clearMemory();
    AccountAvatarCache.instance.clearMemory();
    BookImageManager().clearMemoryCache();
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  Future<void> _bootstrapServices() async {
    setState(() {
      _isBootstrapped = false;
      _bootstrapError = null;
    });
    _syncIncomingBookReadiness();

    // 浏览器没有 path_provider 的文件系统目录。Web 端的图片与书籍
    // 持久化需要单独的浏览器存储实现，不应让本地文件系统的初始化
    // 阻塞整个 Web 应用启动。
    if (!kIsWeb) {
      // 初始化图片管理器
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        await BookImageManager().initialize(appDocDir.path);
      } catch (e) {
        debugPrint('图片管理器初始化失败: $e');
        if (mounted) {
          setState(() => _bootstrapError = _BootstrapError.imageManager);
        }
        return;
      }
    }

    if (!mounted) return;
    try {
      final sync = provider.Provider.of<WebDavBackupController>(
        context,
        listen: false,
      );
      await sync.initialize();
    } catch (error) {
      // WebDAV 是可选能力，安全存储或远端初始化失败不能阻塞本地阅读。
      debugPrint('WebDAV 同步初始化失败（已忽略）: $error');
    }

    if (!mounted) return;
    setState(() {
      _isBootstrapped = true;
      _bootstrapError = null;
    });
    _syncIncomingBookReadiness();
    unawaited(_openPendingNotificationTap());
    _scheduleResumeLastReading();
  }

  /// 检查用户是否已同意协议
  Future<void> _checkAgreementStatus() async {
    var hasAccepted = await UserAgreementService.hasUserAcceptedAgreement(
      repository: widget._legalRepository,
    );
    var needsUpdatedAgreement = false;
    if (hasAccepted) {
      final latest = await widget._legalRepository.refresh(locale: 'en');
      hasAccepted = await UserAgreementService.hasUserAcceptedAgreement(
        catalog: latest.catalog,
      );
      needsUpdatedAgreement = !hasAccepted;
    }
    if (!mounted) return;
    setState(() {
      _hasAcceptedAgreement = hasAccepted;
      _requiresUpdatedAgreement = needsUpdatedAgreement;
    });
    _legalNavigationObserver.required = needsUpdatedAgreement;
    _syncIncomingBookReadiness();
    unawaited(_openPendingNotificationTap());
    _scheduleResumeLastReading();
    debugPrint('📋 协议状态检查: ${hasAccepted ? "已同意" : "未同意"}');
    if (hasAccepted) {
      unawaited(_startAuthorizedServices());
    }
  }

  Future<void> _refreshAgreementStatus() async {
    final latest = await widget._legalRepository.refresh(locale: 'en');
    if (!mounted || _hasAcceptedAgreement != true || latest.refreshError) {
      return;
    }
    final accepted = await UserAgreementService.hasUserAcceptedAgreement(
      catalog: latest.catalog,
    );
    if (!mounted || _hasAcceptedAgreement != true || accepted) return;
    setState(() {
      _hasAcceptedAgreement = false;
      _requiresUpdatedAgreement = true;
    });
    _legalNavigationObserver.required = true;
    provider.Provider.of<MemberAccountController>(
      context,
      listen: false,
    ).setNetworkAllowed(false);
    provider.Provider.of<DiagnosticsController>(
      context,
      listen: false,
    ).setNetworkAllowed(false);
    provider.Provider.of<ReadingCloudController>(
      context,
      listen: false,
    ).setNetworkAllowed(false);
    _syncIncomingBookReadiness();
  }

  /// 处理用户同意协议
  void _onAgreementAccepted() {
    _legalNavigationObserver.required = false;
    setState(() {
      _hasAcceptedAgreement = true;
      if (!_requiresUpdatedAgreement) {
        _pendingFirstHomeSupportAfterDiagnostics = true;
      }
      _requiresUpdatedAgreement = false;
    });
    _syncIncomingBookReadiness();
    unawaited(_openPendingNotificationTap());
    _scheduleResumeLastReading();
    unawaited(_showNextSourceInteraction());
    unawaited(_startAuthorizedServices());
    debugPrint('✅ 用户协议已同意，进入主应用');
  }

  void _handleNotificationTap(BackgroundDownloadTap tap) {
    _pendingNotificationTap = tap;
    unawaited(_openPendingNotificationTap());
  }

  Future<void> _openPendingNotificationTap() async {
    if (!_isBootstrapped || _hasAcceptedAgreement != true) return;
    final tap = _pendingNotificationTap;
    if (tap == null) return;
    _pendingNotificationTap = null;
    // 用户点通知进来，意图明确，本次启动不再自动恢复上次阅读。
    _resumeReadingHandled = true;
    if (tap.kind == BackgroundDownloadKind.update) {
      final apkPath = tap.apkPath;
      final buildNumber = tap.expectedBuildNumber;
      if (apkPath != null && buildNumber != null) {
        try {
          await AppUpdateDownloadService.installDownloadedApk(
            apkPath,
            expectedBuildNumber: buildNumber,
          );
        } catch (error) {
          debugPrint('open downloaded update failed: $error');
        }
      }
      return;
    }
    final bookId = tap.bookId;
    final context = _navigatorKey.currentContext;
    if (bookId == null || context == null) return;
    final book = await BookDao().getBookById(bookId);
    if (!mounted || _hasAcceptedAgreement != true) {
      _pendingNotificationTap ??= tap;
      return;
    }
    if (book == null || _navigatorKey.currentContext == null) {
      return;
    }
    await BookReaderLauncher.openBook(_navigatorKey.currentContext!, book);
  }

  /// 启动后自动回到上次阅读。
  ///
  /// 仅当「阅读中退出应用」留下的会话记录存在且设置开关开启时触发；
  /// 通知点击、外部文件打开等显式意图优先，命中时本次启动不再自动恢复。
  void _scheduleResumeLastReading() {
    if (!_isBootstrapped || _hasAcceptedAgreement != true) return;
    if (_resumeReadingHandled) return;
    if (_navigatorKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleResumeLastReading();
      });
      return;
    }
    unawaited(_resumeLastReading());
  }

  Future<void> _resumeLastReading() async {
    if (_resumeReadingHandled) return;
    _resumeReadingHandled = true;
    // 桌面端带文件参数启动时，交给入站书籍通道打开目标文件。
    if (widget.initialFilePaths.isNotEmpty) return;
    try {
      final resume = await ReadingResumeService.takePendingResume();
      if (resume == null) return;
      final persistedBook = await BookDao().getBookById(resume.bookId);
      if (persistedBook == null || !mounted) return;
      final book = resume.applyTo(persistedBook);
      debugPrint(
        '[reader-resume] book=${resume.bookId} '
        'chapter=${resume.chapterIndex ?? book.currentPage} '
        'hasCanonical=${resume.canonicalLocator?.isNotEmpty ?? false}',
      );
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      if (book.isOnline) {
        final client = BookSourceClient();
        final shelfService = BookSourceShelfService(client: client);
        try {
          final replaceRules = provider.Provider.of<ReplaceRuleService>(
            context,
            listen: false,
          );
          final route = BookOpenTransition.createRoute<void>(
            (_) => buildOnlineReader(
              shelfBook: book,
              replaceRuleService: replaceRules,
              client: client,
              shelfService: shelfService,
            ),
            waitForReaderReady: true,
          );
          await BookOpenTransition.push<void>(context, route);
        } finally {
          shelfService.close();
          client.close();
        }
      } else {
        await BookReaderLauncher.openBook(context, book);
      }
    } catch (error) {
      // 自动恢复失败不打扰用户，停留首页即可。
      debugPrint('自动恢复上次阅读失败（已忽略）: $error');
    }
  }

  /// 处理用户拒绝协议
  void _onAgreementRejected() {
    // 退出应用
    debugPrint('❌ 用户拒绝协议，退出应用');
    // 这里可以调用 SystemNavigator.pop() 或其他退出逻辑
    // SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) =>
          provider.Selector<AppSettingsNotifier, (String?, Locale?)>(
            selector: (_, appSettings) =>
                (appSettings.appFontFamily, appSettings.locale),
            builder: (context, appAppearance, child) {
              final (appFontFamily, locale) = appAppearance;
              // 不在这里更新系统UI，让各页面自行控制
              // 避免与阅读页面的全屏模式冲突
              return MaterialApp(
                navigatorKey: _navigatorKey,
                navigatorObservers: [_legalNavigationObserver],
                onGenerateTitle: (context) => context.l10n.appTitle,
                debugShowCheckedModeBanner: false,
                // 🚀 启用高性能渲染，支持120Hz高刷新率
                scrollBehavior: const MaterialScrollBehavior().copyWith(
                  physics: const BouncingScrollPhysics(),
                ),
                theme: _buildLightTheme(
                  themeNotifier.currentAppTheme,
                  appFontFamily,
                  themeNotifier.uiStyle,
                  themeNotifier.glassStyle,
                  themeNotifier.liquidGlassOpacity,
                  themeNotifier.currentSkin,
                ),
                darkTheme: _buildDarkTheme(
                  themeNotifier.currentAppTheme,
                  appFontFamily,
                  themeNotifier.uiStyle,
                  themeNotifier.glassStyle,
                  themeNotifier.liquidGlassOpacity,
                  themeNotifier.currentSkin,
                ),
                themeMode: themeNotifier.themeMode,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(builder: (context) => _buildHome(context)),
                builder: (context, child) => AppTextScale(
                  child: LegalAgreementGate(
                    required: _requiresUpdatedAgreement,
                    navigationObserver: _legalNavigationObserver,
                    repository: widget._legalRepository,
                    onAgreed: _onAgreementAccepted,
                    onDisagreed: _onAgreementRejected,
                    child: child!,
                  ),
                ),
              );
            },
          ),
    );
  }

  // 已移除未使用的 _getEffectiveThemeMode 方法

  /// 根据协议状态决定显示哪个页面
  Widget _buildHome(BuildContext context) {
    if (_bootstrapError != null) {
      return _buildBootstrapErrorPage(context);
    }

    // 如果还在初始化，显示加载页面
    if (!_isBootstrapped) {
      return _buildLoadingPage(context);
    }

    // 如果还在检查协议状态，显示加载页面
    if (_hasAcceptedAgreement == null) {
      return _buildLoadingPage(context);
    }

    // 如果未同意协议，显示协议页面
    if (!_hasAcceptedAgreement! && !_requiresUpdatedAgreement) {
      return UserAgreementPage(
        repository: widget._legalRepository,
        onAgreed: _onAgreementAccepted,
        onDisagreed: _onAgreementRejected,
      );
    }

    // 已同意协议，显示主页面
    return UpdateCheckGate(
      child: HomeShellPage(
        aiChatHistoryStore: provider.Provider.of<AiChatHistoryStore>(
          context,
          listen: false,
        ),
        showFirstHomeSupport: _showFirstHomeSupportAfterAgreement,
      ),
    );
  }

  Widget _buildBootstrapErrorPage(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.initializationFailed,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _bootstrapError == _BootstrapError.imageManager
                    ? context.l10n.bootstrapImageManagerFailed
                    : context.l10n.unknownError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _bootstrapServices,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载页面
  Widget _buildLoadingPage(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const AppBrandIcon(size: 56, borderRadius: 13),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme(
    AppTheme appTheme,
    String? appFontFamily,
    AppUiStyle uiStyle,
    GlassStyle glassStyle,
    double liquidGlassOpacity,
    AppSkin skin,
  ) {
    return _buildThemeData(
      colorScheme: appTheme.lightColorScheme,
      brightness: Brightness.light,
      appFontFamily: appFontFamily,
      uiStyle: uiStyle,
      glassStyle: glassStyle,
      liquidGlassOpacity: liquidGlassOpacity,
      skin: skin,
    );
  }

  ThemeData _buildDarkTheme(
    AppTheme appTheme,
    String? appFontFamily,
    AppUiStyle uiStyle,
    GlassStyle glassStyle,
    double liquidGlassOpacity,
    AppSkin skin,
  ) {
    return _buildThemeData(
      colorScheme: appTheme.darkColorScheme,
      brightness: Brightness.dark,
      appFontFamily: appFontFamily,
      uiStyle: uiStyle,
      glassStyle: glassStyle,
      liquidGlassOpacity: liquidGlassOpacity,
      skin: skin,
    );
  }

  ThemeData _buildThemeData({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required String? appFontFamily,
    required AppUiStyle uiStyle,
    required GlassStyle glassStyle,
    required double liquidGlassOpacity,
    required AppSkin skin,
  }) {
    final isDark = brightness == Brightness.dark;
    final isMaterial3Style = uiStyle == AppUiStyle.material3;
    final appBarColor = isMaterial3Style
        ? colorScheme.surface
        : Colors.transparent;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: isMaterial3Style
          ? colorScheme.surfaceContainerLow
          : colorScheme.surface.withValues(alpha: isDark ? 0.82 : 0.9),
      dialogTheme: DialogThemeData(
        backgroundColor: isMaterial3Style
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface.withValues(alpha: isDark ? 0.9 : 0.96),
      ),
      fontFamily: appFontFamily,
      fontFamilyFallback: FontCatalog.appFallbacks(appFontFamily),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(
          alpha: isMaterial3Style ? 0.32 : 0.18,
        ),
        thickness: 0.7,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSkinTheme(skin: skin),
        UiStyleThemeExtension(
          style: uiStyle,
          glassStyle: glassStyle,
          liquidGlassOpacity: liquidGlassOpacity,
        ),
      ],
    );
  }
}

/// 启动初始化失败的类型，文案在 build 时按当前语言解析。
enum _BootstrapError { imageManager }
