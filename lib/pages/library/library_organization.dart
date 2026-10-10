import '../../models/book.dart';
import '../../models/shelf_folder.dart';
import '../../models/library_sort.dart';

export '../../models/library_sort.dart';

/// One sibling in the shelf. Manual positions share a single sequence so a
/// folder can sit between books without changing any folder membership.
class LibraryShelfEntry {
  const LibraryShelfEntry.book(Book value) : book = value, folder = null;
  const LibraryShelfEntry.folder(ShelfFolder value)
    : folder = value,
      book = null;

  final Book? book;
  final ShelfFolder? folder;

  String get key =>
      folder != null ? 'folder:${folder!.id}' : 'book:${book!.id}';
  String get label => folder?.name ?? book!.title;
  int? get sortIndex => folder?.sortIndex ?? book?.shelfSortIndex;
  ({int? bookId, String? folderId}) get identity =>
      (bookId: book?.id, folderId: folder?.id);
}

List<LibraryShelfEntry> orderedLibraryEntries({
  required List<Book> books,
  required List<ShelfFolder> folders,
  required LibrarySortMode sort,
  bool descending = true,
}) {
  final entries = [
    ...folders.map(LibraryShelfEntry.folder),
    ...books.map(LibraryShelfEntry.book),
  ];
  int fallback(LibraryShelfEntry a, LibraryShelfEntry b) {
    if (a.folder != null && b.folder == null) return -1;
    if (a.folder == null && b.folder != null) return 1;
    final first = a.folder?.createdAt ?? a.book!.importDate;
    final second = b.folder?.createdAt ?? b.book!.importDate;
    final time = second.compareTo(first);
    return time != 0 ? time : a.key.compareTo(b.key);
  }

  int manual(LibraryShelfEntry a, LibraryShelfEntry b) {
    final first = a.sortIndex;
    final second = b.sortIndex;
    if (first == null && second != null) return 1;
    if (first != null && second == null) return -1;
    final position = first != null && second != null
        ? first.compareTo(second)
        : 0;
    return position != 0 ? position : fallback(a, b);
  }

  entries.sort((a, b) {
    if (sort == LibrarySortMode.manual) return manual(a, b);
    // Folders have no reading progress. Keep their relative manual order at
    // the top while the selected criterion sorts the books in this directory.
    if (a.folder != null || b.folder != null) {
      if (a.folder != null && b.folder != null) return manual(a, b);
      return a.folder != null ? -1 : 1;
    }
    final first = a.book!;
    final second = b.book!;
    int comparison;
    switch (sort) {
      case LibrarySortMode.recentRead:
        // Unknown history always comes last, including oldest-first sorting.
        if (first.lastReadAt == null && second.lastReadAt != null) return 1;
        if (first.lastReadAt != null && second.lastReadAt == null) return -1;
        comparison = first.lastReadAt != null && second.lastReadAt != null
            ? first.lastReadAt!.compareTo(second.lastReadAt!)
            : 0;
      case LibrarySortMode.recentAdded:
        comparison = first.importDate.compareTo(second.importDate);
      case LibrarySortMode.progress:
        comparison = first.progress.compareTo(second.progress);
      case LibrarySortMode.manual:
        return manual(a, b);
    }
    if (descending) comparison = -comparison;
    return comparison != 0 ? comparison : fallback(a, b);
  });
  return entries;
}
