import '../../models/book.dart';
import '../../models/shelf_folder.dart';

/// A shelf snapshot indexes hierarchy and bounded cover previews once per load.
class LibraryShelfProjection {
  LibraryShelfProjection(List<ShelfFolder> folders, List<Book> books) {
    for (final folder in folders) {
      if (_folders.containsKey(folder.id)) {
        throw const FormatException('Duplicate shelf folder');
      }
      _folders[folder.id] = folder;
      (_children[folder.parentId] ??= []).add(folder);
    }
    for (final folder in folders) {
      final ancestors = <String>{};
      String? id = folder.id;
      while (id != null) {
        if (!ancestors.add(id) || !_folders.containsKey(id)) {
          throw const FormatException('Invalid shelf hierarchy');
        }
        id = _folders[id]!.parentId;
      }
    }
    for (final book in books) {
      String? id = book.shelfFolderId;
      if (id != null && !_folders.containsKey(id)) {
        throw const FormatException('Invalid book shelf folder');
      }
      (_books[book.shelfFolderId] ??= []).add(book);
      while (id != null) {
        _counts[id] = (_counts[id] ?? 0) + 1;
        final preview = _previews[id] ??= [];
        if (preview.length < 9) preview.add(book);
        id = _folders[id]!.parentId;
      }
    }
    for (final children in _children.values) {
      children.sort((a, b) {
        final time = b.createdAt.compareTo(a.createdAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    }
  }

  final _folders = <String, ShelfFolder>{};
  final _children = <String?, List<ShelfFolder>>{};
  final _books = <String?, List<Book>>{};
  final _previews = <String, List<Book>>{};
  final _counts = <String, int>{};

  ShelfFolder? folder(String? id) => _folders[id];
  List<ShelfFolder> childrenOf(String? id) => _children[id] ?? const [];
  List<Book> booksIn(String? id) => _books[id] ?? const [];
  List<Book> previewOf(String id) => _previews[id] ?? const [];
  int bookCount(String id) => _counts[id] ?? 0;

  bool isWithin(String? id, String ancestor) {
    while (id != null) {
      if (id == ancestor) return true;
      id = _folders[id]?.parentId;
    }
    return false;
  }

  /// Mark matching books and their ancestors, retaining paths through subfolders.
  Set<String> foldersMatching(bool Function(Book) matches) {
    final result = <String>{};
    for (final entry in _books.entries) {
      if (!entry.value.any(matches)) continue;
      String? id = entry.key;
      while (id != null && result.add(id)) {
        id = _folders[id]!.parentId;
      }
    }
    return result;
  }
}
