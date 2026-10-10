import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_organization.dart';

DateTime _day(int day) => DateTime.utc(2026, 10, day);

Book _book(
  int id, {
  int addedDay = 1,
  int? readDay,
  int? rank,
  int currentPage = 0,
  int totalPages = 100,
  double? readingProgress,
}) => Book(
  id: id,
  title: 'Book $id',
  filePath: '/books/$id.txt',
  format: 'txt',
  importDate: _day(addedDay),
  lastReadAt: readDay == null ? null : _day(readDay),
  shelfSortIndex: rank,
  currentPage: currentPage,
  totalPages: totalPages,
  readingProgress: readingProgress,
);

ShelfFolder _folder(String id, {int createdDay = 1, int? rank}) => ShelfFolder(
  id: id,
  name: 'Folder $id',
  parentId: null,
  createdAt: _day(createdDay),
  sortIndex: rank,
);

List<String> _orderedKeys({
  List<Book> books = const [],
  List<ShelfFolder> folders = const [],
  LibrarySortMode sort = LibrarySortMode.manual,
  bool descending = true,
}) => orderedLibraryEntries(
  books: books,
  folders: folders,
  sort: sort,
  descending: descending,
).map((entry) => entry.key).toList();

void main() {
  group('manual organization', () {
    test('books and folders share one manual sequence', () {
      final books = [_book(2, rank: 2), _book(1, rank: 0)];
      final folders = [_folder('b', rank: 3), _folder('a', rank: 1)];

      for (final descending in [true, false]) {
        expect(
          _orderedKeys(books: books, folders: folders, descending: descending),
          ['book:1', 'folder:a', 'book:2', 'folder:b'],
        );
      }
    });

    test('new entries without a rank follow all manually placed entries', () {
      expect(
        _orderedKeys(
          books: [
            _book(3, addedDay: 10),
            _book(2, addedDay: 9, rank: 3),
            _book(1, rank: 0),
          ],
          folders: [_folder('new', createdDay: 10), _folder('saved', rank: 2)],
        ),
        ['book:1', 'folder:saved', 'book:2', 'folder:new', 'book:3'],
      );
    });

    test('legacy entries retain folders first and newest additions first', () {
      expect(
        _orderedKeys(
          books: [_book(1), _book(3, addedDay: 3), _book(2, addedDay: 2)],
          folders: [_folder('old'), _folder('new', createdDay: 2)],
        ),
        ['folder:new', 'folder:old', 'book:3', 'book:2', 'book:1'],
      );
    });

    test(
      'duplicate manual positions retain every sibling deterministically',
      () {
        final books = [_book(3, rank: 1), _book(1, rank: 1), _book(2, rank: 1)];
        final folders = [_folder('b', rank: 1), _folder('a', rank: 1)];
        final first = _orderedKeys(books: books, folders: folders);
        final reversed = _orderedKeys(
          books: books.reversed.toList(),
          folders: folders.reversed.toList(),
        );

        expect(first, ['folder:a', 'folder:b', 'book:1', 'book:2', 'book:3']);
        expect(reversed, first);
        expect(first.toSet(), hasLength(books.length + folders.length));
      },
    );
  });

  for (final sort in LibrarySortMode.values.where(
    (mode) => mode != LibrarySortMode.manual,
  )) {
    for (final descending in [true, false]) {
      test(
        '${sort.name} keeps folders first in their manual order ($descending)',
        () {
          final ordered = _orderedKeys(
            books: [_book(1, rank: 0), _book(2, rank: 2)],
            folders: [
              _folder('new', createdDay: 10),
              _folder('last', rank: 9),
              _folder('first', rank: 1),
            ],
            sort: sort,
            descending: descending,
          );

          expect(ordered.take(3), [
            'folder:first',
            'folder:last',
            'folder:new',
          ]);
          expect(ordered.skip(3).toSet(), {'book:1', 'book:2'});
        },
      );
    }
  }

  group('automatic book sorting', () {
    test(
      'recent reading uses actual reading time and places unread books last',
      () {
        final books = [
          _book(1, addedDay: 10),
          _book(2, addedDay: 9, readDay: 2),
          _book(3, readDay: 8),
          _book(4, addedDay: 8),
        ];

        expect(_orderedKeys(books: books, sort: LibrarySortMode.recentRead), [
          'book:3',
          'book:2',
          'book:1',
          'book:4',
        ]);
        expect(
          _orderedKeys(
            books: books,
            sort: LibrarySortMode.recentRead,
            descending: false,
          ),
          ['book:2', 'book:3', 'book:1', 'book:4'],
        );
      },
    );

    test('recent additions support newest and oldest first', () {
      final books = [_book(2, addedDay: 5), _book(1), _book(3, addedDay: 10)];

      expect(_orderedKeys(books: books, sort: LibrarySortMode.recentAdded), [
        'book:3',
        'book:2',
        'book:1',
      ]);
      expect(
        _orderedKeys(
          books: books,
          sort: LibrarySortMode.recentAdded,
          descending: false,
        ),
        ['book:1', 'book:2', 'book:3'],
      );
    });

    test('progress sorts by normalized progress with legacy page fallback', () {
      final books = [
        _book(1, currentPage: 99, readingProgress: 0.1),
        _book(2, currentPage: 1, readingProgress: 0.8),
        _book(3, currentPage: 50),
      ];

      expect(_orderedKeys(books: books, sort: LibrarySortMode.progress), [
        'book:2',
        'book:3',
        'book:1',
      ]);
      expect(
        _orderedKeys(
          books: books,
          sort: LibrarySortMode.progress,
          descending: false,
        ),
        ['book:1', 'book:3', 'book:2'],
      );
    });

    test(
      'progress uses Book.progress bounds and unknown page count semantics',
      () {
        final books = [
          _book(4, readingProgress: 1.5),
          _book(3, currentPage: 250),
          _book(2, currentPage: 25, totalPages: 0),
          _book(1, readingProgress: -0.5),
        ];

        expect(_orderedKeys(books: books, sort: LibrarySortMode.progress), [
          'book:3',
          'book:4',
          'book:1',
          'book:2',
        ]);
        expect(
          _orderedKeys(
            books: books,
            sort: LibrarySortMode.progress,
            descending: false,
          ),
          ['book:1', 'book:2', 'book:3', 'book:4'],
        );
      },
    );

    for (final sort in LibrarySortMode.values.where(
      (mode) => mode != LibrarySortMode.manual,
    )) {
      test('${sort.name} ties retain books and survive input permutations', () {
        final books = [
          _book(3, addedDay: 2, readDay: 4, readingProgress: 0.5),
          _book(1, addedDay: 2, readDay: 4, readingProgress: 0.5),
          _book(2, readDay: 4, readingProgress: 0.5),
        ];
        final first = _orderedKeys(books: books, sort: sort);
        final reversed = _orderedKeys(
          books: books.reversed.toList(),
          sort: sort,
        );

        expect(first, ['book:1', 'book:3', 'book:2']);
        expect(reversed, first);
        expect(first.toSet(), hasLength(books.length));
      });
    }
  });

  for (final sort in LibrarySortMode.values) {
    test('${sort.name} leaves caller lists and models unchanged', () {
      final books = List<Book>.unmodifiable([
        _book(2, addedDay: 3, readDay: 4, rank: 2, readingProgress: 0.7),
        _book(1, rank: 0),
      ]);
      final folders = List<ShelfFolder>.unmodifiable([
        _folder('b', rank: 3),
        _folder('a', rank: 1),
      ]);
      final originalBooks = books.map((book) => book.toMap()).toList();
      final originalFolders = folders.map((folder) => folder.toMap()).toList();

      final entries = orderedLibraryEntries(
        books: books,
        folders: folders,
        sort: sort,
      );

      expect(entries, hasLength(4));
      expect(books.map((book) => book.toMap()).toList(), originalBooks);
      expect(folders.map((folder) => folder.toMap()).toList(), originalFolders);
      expect(
        entries.where((entry) => entry.book != null).map((entry) => entry.book),
        containsAll(books),
      );
      expect(
        entries
            .where((entry) => entry.folder != null)
            .map((entry) => entry.folder),
        containsAll(folders),
      );
    });
  }

  test('book and folder drag identities cannot collide', () {
    final book = LibraryShelfEntry.book(_book(1));
    final folder = LibraryShelfEntry.folder(_folder('1'));

    expect(book.key, 'book:1');
    expect(folder.key, 'folder:1');
    expect(book.identity, (bookId: 1, folderId: null));
    expect(folder.identity, (bookId: null, folderId: '1'));
    expect(book.label, 'Book 1');
    expect(folder.label, 'Folder 1');
  });
}
