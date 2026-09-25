import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/core/custom_font_service.dart';
import 'package:xxread/services/core/online_font_service.dart';
import 'package:xxread/utils/font_catalog_helper.dart';

class _BurstOnlineFontService extends OnlineFontService {
  OnlineFontDownloadProgress? _currentProgress;
  bool _downloaded = false;

  @override
  Future<void> initialize() async {}

  @override
  bool get isSupported => true;

  @override
  bool isDownloaded(String fontId) => _downloaded;

  @override
  OnlineFontDownloadProgress? progressFor(String fontId) => _currentProgress;

  @override
  Future<OnlineFontRecord> download({
    required String fontId,
    required String family,
    required List<OnlineFontFile> files,
    OnlineFontProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);
    for (var index = 1; index <= 100; index++) {
      _emit(
        OnlineFontDownloadProgress(
          fontId: fontId,
          status: OnlineFontDownloadStatus.downloading,
          downloadedBytes: totalBytes * index ~/ 100,
          totalBytes: totalBytes,
          totalFiles: files.length,
        ),
        onProgress,
      );
    }
    for (final status in <OnlineFontDownloadStatus>[
      OnlineFontDownloadStatus.verifying,
      OnlineFontDownloadStatus.registering,
    ]) {
      _emit(
        OnlineFontDownloadProgress(
          fontId: fontId,
          status: status,
          downloadedFiles: files.length,
          totalFiles: files.length,
          downloadedBytes: totalBytes,
          totalBytes: totalBytes,
        ),
        onProgress,
      );
    }
    _downloaded = true;
    _emit(
      OnlineFontDownloadProgress(
        fontId: fontId,
        status: OnlineFontDownloadStatus.completed,
        downloadedFiles: files.length,
        totalFiles: files.length,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
      ),
      onProgress,
    );
    return OnlineFontRecord(
      id: fontId,
      files: const <OnlineFontFileRecord>[],
      downloadedAt: DateTime.now().toUtc(),
    );
  }

  void _emit(
    OnlineFontDownloadProgress progress,
    OnlineFontProgressCallback? onProgress,
  ) {
    _currentProgress = progress;
    onProgress?.call(progress);
  }
}

class _StaleOnlineFontService extends OnlineFontService {
  bool downloaded = true;
  int discarded = 0;
  int retried = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool get isSupported => true;

  @override
  bool isDownloaded(String fontId) => downloaded;

  @override
  Future<bool> ensureLoaded(
    String fontId, {
    required List<OnlineFontFile> files,
    required String family,
  }) async => false;

  @override
  Future<void> deleteDownload(String fontId) async {
    downloaded = false;
    discarded++;
  }

  @override
  Future<OnlineFontRecord> download({
    required String fontId,
    required String family,
    required List<OnlineFontFile> files,
    OnlineFontProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    retried++;
    throw const OnlineFontException(OnlineFontErrorCode.networkFailed);
  }
}

Uint8List _customVariableTtfBytes() {
  final bytes = Uint8List(68);
  final data = ByteData.sublistView(bytes);
  bytes.setAll(0, const <int>[0, 1, 0, 0]);
  data.setUint16(4, 1, Endian.big);
  bytes.setAll(12, 'fvar'.codeUnits);
  data.setUint32(20, 32, Endian.big);
  data.setUint32(24, 36, Endian.big);
  data.setUint16(32, 1, Endian.big);
  data.setUint16(36, 16, Endian.big);
  data.setUint16(40, 1, Endian.big);
  data.setUint16(42, 20, Endian.big);
  bytes.setAll(48, 'wght'.codeUnits);
  data.setInt32(52, 200 << 16, Endian.big);
  data.setInt32(56, 400 << 16, Endian.big);
  data.setInt32(60, 900 << 16, Endian.big);
  return bytes;
}

Future<AppSettingsNotifier> _loadNotifier({
  CustomFontService? customFontService,
  OnlineFontService? onlineFontService,
}) async {
  final notifier = AppSettingsNotifier(
    customFontService: customFontService,
    onlineFontService: onlineFontService,
  );
  if (notifier.isInitialized) return notifier;

  final initialized = Completer<void>();
  void listener() {
    if (notifier.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  notifier.addListener(listener);
  listener();
  await initialized.future;
  notifier.removeListener(listener);
  return notifier;
}

/// 预置在线字体清单与占位文件，模拟"用户此前已下载完成"的磁盘状态，
/// 使 AppSettingsNotifier 恢复选择时无需真实网络下载即可 ensureLoaded 成功。
Future<OnlineFontService> _seededOnlineFontService(
  List<FontOption> alreadyDownloaded, {
  bool failRegistration = false,
}) async {
  final sandbox = await Directory.systemTemp.createTemp(
    'online-font-settings-test-',
  );
  addTearDown(() => sandbox.delete(recursive: true));

  final fontsRoot = Directory(path.join(sandbox.path, 'online_fonts'));
  await fontsRoot.create(recursive: true);

  final records = <Map<String, Object?>>[];
  for (final option in alreadyDownloaded) {
    final fontDir = Directory(path.join(fontsRoot.path, option.id));
    await fontDir.create(recursive: true);
    final fileRecords = <Map<String, Object?>>[];
    for (final file in option.downloadFiles) {
      await File(
        path.join(fontDir.path, file.fileName),
      ).writeAsBytes(const <int>[0, 1, 0, 0]);
      fileRecords.add(<String, Object?>{
        'fileName': file.fileName,
        'sha256': 'test',
        'size': 4,
      });
    }
    records.add(<String, Object?>{
      'id': option.id,
      'files': fileRecords,
      'downloadedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
  await File(
    path.join(fontsRoot.path, 'manifest.json'),
  ).writeAsString(jsonEncode(records));

  return OnlineFontService(
    supportDirectory: () async => sandbox,
    registrar: (family, bytes, style) async {
      if (failRegistration) throw StateError('font registration failed');
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh install defaults EPUB to book font and TXT to system', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.appFontId, FontCatalog.systemId);
    expect(notifier.appFontFamily, isNull);
    expect(notifier.readerFontId, FontCatalog.systemId);
    expect(notifier.readerFont.family, isNull);
    expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);
    expect(
      FontCatalog.readerFontForId(FontCatalog.bookEmbeddedId).id,
      FontCatalog.systemId,
    );
  });

  test('EPUB selection persists independently from TXT selection', () async {
    final onlineFontService = await _seededOnlineFontService([
      FontCatalog.newsreader,
    ]);
    final notifier = await _loadNotifier(onlineFontService: onlineFontService);
    addTearDown(notifier.dispose);

    await notifier.setEpubReaderFontId(FontCatalog.systemId);
    expect(notifier.epubReaderFontId, FontCatalog.systemId);
    expect(notifier.readerFontId, FontCatalog.systemId);

    await notifier.setReaderFontId(FontCatalog.newsreaderId);
    expect(notifier.epubReaderFontId, FontCatalog.systemId);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('epub_reader_font_id_v1'), FontCatalog.systemId);

    final restored = await _loadNotifier(onlineFontService: onlineFontService);
    addTearDown(restored.dispose);
    expect(restored.epubReaderFontId, FontCatalog.systemId);
    expect(restored.readerFontId, FontCatalog.newsreaderId);
  });

  test('EPUB font download does not change TXT font', () async {
    final onlineFontService = await _seededOnlineFontService([
      FontCatalog.newsreader,
    ]);
    final notifier = await _loadNotifier(onlineFontService: onlineFontService);
    addTearDown(notifier.dispose);

    await notifier.downloadOnlineFont(
      FontCatalog.newsreaderId,
      domain: FontDomain.epubReader,
    );

    expect(notifier.epubReaderFontId, FontCatalog.newsreaderId);
    expect(notifier.readerFontId, FontCatalog.systemId);
  });

  test('invalid EPUB font selection returns to book font', () async {
    SharedPreferences.setMockInitialValues({
      'epub_reader_font_id_v1': 'missing-font',
      'reader_font_id_v2': FontCatalog.systemId,
    });
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);
    expect(notifier.readerFontId, FontCatalog.systemId);
  });

  test('a downloaded font that cannot load is never selected', () async {
    SharedPreferences.setMockInitialValues({
      'reader_font_id_v2': FontCatalog.newsreaderId,
      'epub_reader_font_id_v1': FontCatalog.newsreaderId,
    });
    final service = await _seededOnlineFontService([
      FontCatalog.newsreader,
    ], failRegistration: true);
    final notifier = await _loadNotifier(onlineFontService: service);
    addTearDown(notifier.dispose);

    expect(notifier.readerFontId, FontCatalog.systemId);
    expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);

    await notifier.setEpubReaderFontId(FontCatalog.newsreaderId);
    expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);
  });

  test('retrying a stale font discards its broken download', () async {
    final service = _StaleOnlineFontService();
    final notifier = await _loadNotifier(onlineFontService: service);
    addTearDown(notifier.dispose);

    await notifier.downloadOnlineFont(
      FontCatalog.newsreaderId,
      domain: FontDomain.epubReader,
    );

    expect(service.discarded, 1);
    expect(service.retried, 1);
    expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);
  });

  test('font selections persist as stable ids once downloaded', () async {
    final onlineFontService = await _seededOnlineFontService([
      FontCatalog.instrumentSans,
      FontCatalog.newsreader,
    ]);
    final notifier = await _loadNotifier(onlineFontService: onlineFontService);
    addTearDown(notifier.dispose);

    await notifier.setAppFontId(FontCatalog.instrumentSansId);
    await notifier.setReaderFontId(FontCatalog.newsreaderId);

    expect(notifier.appFontId, FontCatalog.instrumentSansId);
    expect(notifier.readerFontId, FontCatalog.newsreaderId);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_font_id_v2'), FontCatalog.instrumentSansId);
    expect(prefs.getString('reader_font_id_v2'), FontCatalog.newsreaderId);
  });

  test('selecting an undownloaded online font is a no-op', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    await notifier.setAppFontId(FontCatalog.instrumentSansId);

    expect(notifier.appFontId, FontCatalog.systemId);
  });

  test(
    'online font progress stays local and is throttled before app-wide changes',
    () async {
      final notifier = await _loadNotifier(
        onlineFontService: _BurstOnlineFontService(),
      );
      addTearDown(notifier.dispose);
      var globalNotifications = 0;
      var progressNotifications = 0;
      notifier.addListener(() => globalNotifications++);
      notifier.onlineFontProgressListenable.addListener(
        () => progressNotifications++,
      );

      await notifier.downloadOnlineFont(FontCatalog.instrumentSansId);

      expect(
        notifier.isOnlineFontDownloaded(FontCatalog.instrumentSansId),
        isTrue,
      );
      expect(globalNotifications, 0);
      expect(progressNotifications, greaterThan(0));
      expect(progressNotifications, lessThan(10));

      await notifier.downloadOnlineFont(
        FontCatalog.instrumentSansId,
        domain: FontDomain.app,
      );

      expect(notifier.appFontId, FontCatalog.instrumentSansId);
      expect(globalNotifications, 1);
    },
  );

  test(
    'legacy app font family migrates to the matching id when downloaded',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_font_family': 'SourceHanSansCN',
      });
      final onlineFontService = await _seededOnlineFontService([
        FontCatalog.sourceHanSans,
      ]);

      final notifier = await _loadNotifier(
        onlineFontService: onlineFontService,
      );
      addTearDown(notifier.dispose);

      expect(notifier.appFontId, FontCatalog.sourceHanSansId);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_font_id_v2'), FontCatalog.sourceHanSansId);
    },
  );

  test(
    'legacy app font family falls back to system when not yet downloaded',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_font_family': 'SourceHanSansCN',
      });

      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.appFontId, FontCatalog.systemId);
    },
  );

  test('invalid stored ids fall back within their own domain', () async {
    SharedPreferences.setMockInitialValues({
      'app_font_id_v2': 'missing-app-font',
      'reader_font_id_v2': 'missing-reader-font',
    });

    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.appFontId, FontCatalog.defaultAppFont.id);
    expect(notifier.readerFontId, FontCatalog.defaultReaderFont.id);
  });

  test('app and reader catalogs expose distinct curated choices', () {
    expect(FontCatalog.appFonts.first, FontCatalog.defaultAppFont);
    expect(FontCatalog.readerFonts.first, FontCatalog.defaultReaderFont);
    expect(
      FontCatalog.readerFonts.map((font) => font.id),
      contains(FontCatalog.newsreaderId),
    );
    expect(
      FontCatalog.appFonts.map((font) => font.id),
      contains(FontCatalog.instrumentSansId),
    );
    expect(
      FontCatalog.appFonts.map((font) => font.id),
      contains(FontCatalog.harmonyOSSansId),
    );
    expect(
      FontCatalog.readerFonts.map((font) => font.id),
      contains(FontCatalog.harmonyOSSansId),
    );
  });

  test('catalog distinguishes real variable weights from synthesized bold', () {
    expect(FontCatalog.sourceHanSerif.supportsVariableWeight, isTrue);
    expect(FontCatalog.sourceHanSans.supportsVariableWeight, isTrue);
    expect(FontCatalog.instrumentSans.supportsVariableWeight, isTrue);
    expect(FontCatalog.newsreader.supportsVariableWeight, isTrue);
    expect(FontCatalog.jetBrainsMono.supportsVariableWeight, isFalse);
    expect(FontCatalog.harmonyOSSans.supportsVariableWeight, isFalse);
  });

  test('Newsreader keeps CJK fallback in the same serif family', () {
    expect(FontCatalog.newsreader.fallbackFamilies, <String>[
      'SourceHanSerifCN',
      'serif',
    ]);
  });

  test('PingFang is offered only on Apple reader platforms', () {
    expect(
      FontCatalog.readerFontsForPlatform(
        TargetPlatform.iOS,
      ).map((font) => font.id),
      contains(FontCatalog.pingFangScId),
    );
    expect(
      FontCatalog.readerFontsForPlatform(
        TargetPlatform.macOS,
      ).map((font) => font.id),
      contains(FontCatalog.pingFangScId),
    );
    expect(
      FontCatalog.readerFontsForPlatform(
        TargetPlatform.android,
      ).map((font) => font.id),
      isNot(contains(FontCatalog.pingFangScId)),
    );
  });

  test(
    'an imported font is shared by both domains but applied independently',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'font-settings-test-',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final bytes = _customVariableTtfBytes();
      final service = CustomFontService(
        supportDirectory: () async => sandbox,
        filePicker: () async => FilePickerResult(<PlatformFile>[
          PlatformFile(
            name: 'Reader Custom.ttf',
            size: bytes.length,
            bytes: bytes,
          ),
        ]),
        registrar: (family, bytes) async {},
      );
      final notifier = await _loadNotifier(customFontService: service);
      addTearDown(notifier.dispose);

      final result = await notifier.importCustomFont(FontDomain.reader);
      final customId = result.font!.id;

      expect(notifier.readerFontId, customId);
      expect(notifier.appFontId, FontCatalog.defaultAppFont.id);
      expect(
        notifier.appFontOptions.map((font) => font.id),
        contains(customId),
      );
      expect(
        notifier.readerFontOptions.map((font) => font.id),
        contains(customId),
      );
      final customOption = notifier.readerFontOptions.singleWhere(
        (font) => font.id == customId,
      );
      expect(customOption.supportsVariableWeight, isTrue);
      expect(customOption.variableWeightMin, 200);
      expect(customOption.variableWeightMax, 900);

      await notifier.setAppFontId(customId);
      await notifier.setEpubReaderFontId(customId);
      await notifier.setReaderFontId(FontCatalog.systemId);
      expect(notifier.appFontId, customId);
      expect(notifier.epubReaderFontId, customId);
      expect(notifier.isReaderFont(customId), isTrue);
      await notifier.deleteCustomFont(customId);
      expect(notifier.appFontId, FontCatalog.defaultAppFont.id);
      expect(notifier.readerFontId, FontCatalog.defaultReaderFont.id);
      expect(notifier.epubReaderFontId, FontCatalog.bookEmbeddedId);
    },
  );
}
