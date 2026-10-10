import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../book_sources/protocol/book_source_protocol.dart';
import '../../book_sources/services/book_source_client.dart';
import '../../book_sources/services/book_source_shelf_service.dart';
import '../../services/library/download_task_controller.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/book_details_header.dart';
import '../../widgets/generated_book_cover.dart';
import '../../widgets/side_toast.dart';
import '../../widgets/source_cover_image.dart';
import '../reader/book_settings_page.dart';
import 'models/sourced_book.dart';
import 'widgets/book_source_text_normalizer.dart';
import 'widgets/sourced_book_cards.dart';
import 'widgets/sourced_book_details_controller.dart';
import 'widgets/sourced_book_details_sheet.dart';

/// Keeps book information and actions available across shelf and reader flows.
class SourcedBookDetailsPage extends StatelessWidget {
  const SourcedBookDetailsPage({
    super.key,
    required this.result,
    required this.gateway,
    required this.shelfService,
    required this.onRead,
    required this.onDownloadContinuesInBackground,
  });

  final SourcedBook result;
  final BookSourceGateway gateway;
  final BookSourceShelfService shelfService;
  final Future<void> Function(BuildContext context, BookSourceBook book) onRead;
  final VoidCallback onDownloadContinuesInBackground;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        SourcedBookDetailsController(
            initialResult: result,
            gateway: gateway,
            shelf: BookSourceShelfPortAdapter(shelfService),
            downloads: DownloadTaskPortAdapter(
              context.read<DownloadTaskController>(),
              shelfService,
            ),
          )
          ..loadDetails()
          ..loadShelfStatus(),
    child: _DetailsPageContent(
      gateway: gateway,
      onRead: onRead,
      onDownloadContinuesInBackground: onDownloadContinuesInBackground,
    ),
  );
}

class _DetailsPageContent extends StatelessWidget {
  const _DetailsPageContent({
    required this.gateway,
    required this.onRead,
    required this.onDownloadContinuesInBackground,
  });

  final BookSourceGateway gateway;
  final Future<void> Function(BuildContext context, BookSourceBook book) onRead;
  final VoidCallback onDownloadContinuesInBackground;

  String _copy(BuildContext context, String zh, String en, String ja) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'ja' => ja,
        _ => zh,
      };

  Future<void> _openBookSettings(
    BuildContext context,
    SourcedBookDetailsState state,
    BookSourceGateway gateway,
  ) async {
    final book = state.result.book;
    final fallback = GeneratedBookCover(title: book.title, author: book.author);
    await Navigator.of(context).push<BookSettingsAction>(
      MaterialPageRoute(
        builder: (_) => BookSettingsPage(
          title: book.title,
          author: book.author,
          format: 'online',
          description: book.description,
          showReaderActions: false,
          cover: book.coverUrl == null
              ? fallback
              : SourceCoverImage(
                  url: book.coverUrl!,
                  headers: book.coverHeaders,
                  fallback: fallback,
                ),
          source: state.result.source,
          client: gateway is BookSourceClient ? gateway : null,
        ),
      ),
    );
  }

  Future<void> _read(
    BuildContext context,
    SourcedBookDetailsController controller,
  ) async {
    if (controller.state.step == SourcedBookDetailsStep.openingReader) return;
    controller.showDetails();
    final book = controller.beginOpeningReader();
    if (book == null) return;
    try {
      await onRead(context, book);
    } catch (_) {
      if (context.mounted) {
        showSideToast(context, context.l10n.bookSourceDetailsReadFailed);
      }
    } finally {
      if (context.mounted) {
        controller.showDetails();
        await controller.loadShelfStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SourcedBookDetailsController>();
    final state = controller.state;
    final book = state.result.book;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = normalizeBookSourceDescription(book.description);
    final busy =
        state.step == SourcedBookDetailsStep.submitting ||
        state.step == SourcedBookDetailsStep.openingReader;
    final downloading =
        state.downloadTask?.state == DownloadTaskState.queued ||
        state.downloadTask?.state == DownloadTaskState.downloading;

    return FloatingSubpageScaffold(
      key: const Key('bookSourceDetailsPage'),
      title: context.l10n.bookSourceDetailsTitle,
      maxHeaderWidth: 800,
      extendBody: true,
      actions: [
        FloatingSubpageMenuButton<_BookDetailsMenuAction>(
          key: const Key('bookSourceDetailsMoreButton'),
          icon: Icons.more_horiz_rounded,
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          items: [
            FloatingSubpageMenuItem(
              value: _BookDetailsMenuAction.settings,
              itemKey: const Key('bookSourceDetailsSettingsMenuItem'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded),
                  const SizedBox(width: 12),
                  Text(_copy(context, '书籍设置', 'Book settings', '書籍設定')),
                ],
              ),
            ),
          ],
          onSelected: (_) => _openBookSettings(context, state, gateway),
        ),
      ],
      body: Builder(
        builder: (bodyContext) => SingleChildScrollView(
          key: const Key('bookSourceDetailsScroll'),
          padding: floatingSubpagePadding(
            bodyContext,
            left: 20,
            right: 20,
            top: 20,
          ).copyWith(bottom: 32 + MediaQuery.paddingOf(bodyContext).bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 752),
              child: Column(
                key: const Key('bookSourceDetailsContent'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BookIdentity(result: state.result),
                  const SizedBox(height: 28),
                  if (state.isLoadingDetails) ...[
                    LinearProgressIndicator(
                      key: const Key('bookSourceDetailsLoading'),
                      semanticsLabel: context.l10n.loading,
                      minHeight: 2,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (state.detailError != null) ...[
                    _RetryMessage(
                      message: context.l10n.bookSourceDetailsLoadFailed,
                      onRetry: controller.loadDetails,
                      retryKey: const Key('bookSourceDetailsRetryButton'),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    context.l10n.bookSourceDetailsDescription,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    description.isEmpty
                        ? context.l10n.bookSourceDetailsNoDescription
                        : description,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.75,
                      color: description.isEmpty
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                  if (book.latestChapter?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.bookSourceDetailsLatestChapter,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(book.latestChapter!, style: textTheme.bodyLarge),
                    if (book.updatedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(book.updatedAt!.toLocal()),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const Key('bookSourceDownloadLocalOption'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_for_offline_outlined),
                    title: Text(context.l10n.bookSourceDownloadLocal),
                    subtitle: Text(context.l10n.bookSourceDownloadLocalHint),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    enabled: !busy && !downloading,
                    onTap: controller.startDownload,
                  ),
                  if (state.downloadTask != null)
                    SourcedBookDownloadView(
                      task: state.downloadTask,
                      onCancel: controller.cancelDownload,
                      onBackground: () {
                        Navigator.of(context).pop();
                        onDownloadContinuesInBackground();
                      },
                      onRetry: controller.startDownload,
                      onBack: controller.dismissDownload,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          key: const Key('bookSourceFloatingActions'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 752),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.step == SourcedBookDetailsStep.addFailed) ...[
                    Material(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _RetryMessage(
                          key: const Key('bookSourceAddFailed'),
                          message: context.l10n.bookSourceDetailsAddFailed,
                          onRetry: controller.addOnline,
                          retryKey: const Key('bookSourceAddRetryButton'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.step == SourcedBookDetailsStep.submitting) ...[
                    LinearProgressIndicator(
                      semanticsLabel: context.l10n.bookSourceAddToShelf,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Builder(
                    builder: (context) {
                      final shelf = OutlinedButton.icon(
                        key: const Key('bookSourceAddToShelfButton'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHigh,
                          elevation: 3,
                          shadowColor: scheme.shadow.withValues(alpha: 0.18),
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        onPressed:
                            busy ||
                                downloading ||
                                state.checkingShelf ||
                                state.hasShelfBook
                            ? null
                            : controller.addOnline,
                        icon: Icon(
                          state.hasShelfBook
                              ? Icons.check_rounded
                              : Icons.add_to_photos_outlined,
                        ),
                        label: Text(
                          state.hasShelfBook
                              ? context.l10n.bookSourceDetailsOnShelf
                              : context.l10n.bookSourceAddToShelf,
                          key: state.hasShelfBook
                              ? const Key('bookSourceOnShelf')
                              : null,
                          textAlign: TextAlign.center,
                        ),
                      );
                      final read = FilledButton.icon(
                        key: const Key('bookSourceReadButton'),
                        style: FilledButton.styleFrom(
                          elevation: 3,
                          shadowColor: scheme.shadow.withValues(alpha: 0.18),
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        onPressed: busy || downloading
                            ? null
                            : () => _read(context, controller),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: Text(
                          context.l10n.reading,
                          textAlign: TextAlign.center,
                        ),
                      );
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: shelf),
                            const SizedBox(width: 12),
                            Expanded(child: read),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _BookDetailsMenuAction { settings }

class _BookIdentity extends StatelessWidget {
  const _BookIdentity({required this.result});

  final SourcedBook result;

  @override
  Widget build(BuildContext context) => BookDetailsHeader(
    title: result.book.title,
    author: result.book.author,
    sourceLabel: result.source.name,
    status: result.book.status,
    categories: result.book.categories,
    cover: SourcedBookCoverThumb(
      book: result.book,
      width: 112,
      height: 160,
      radius: 16,
    ),
  );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Key retryKey;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton.icon(
          key: retryKey,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}
