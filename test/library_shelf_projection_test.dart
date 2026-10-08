import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_shelf_projection.dart';

void main() {
  ShelfFolder folder(String id, {String? parent}) => ShelfFolder(
    id: id,
    name: id,
    parentId: parent,
    createdAt: DateTime(2026),
  );
  Book book(int id, {String? folderId}) => Book(
    id: id,
    title: 'Book $id',
    filePath: '/book-$id.txt',
    format: 'TXT',
    shelfFolderId: folderId,
  );

  test(
    'direct members stay separate while ancestor previews include descendants',
    () {
      final projection = LibraryShelfProjection(
        [folder('parent'), folder('child', parent: 'parent')],
        [book(1), book(2, folderId: 'parent'), book(3, folderId: 'child')],
      );
      expect(projection.booksIn(null).map((b) => b.id), [1]);
      expect(projection.booksIn('parent').map((b) => b.id), [2]);
      expect(projection.bookCount('parent'), 2);
      expect(projection.previewOf('parent').map((b) => b.id), [2, 3]);
      expect(projection.childrenOf(null).map((f) => f.id), ['parent']);
      expect(projection.isWithin('child', 'parent'), isTrue);
      expect(projection.isWithin('parent', 'child'), isFalse);
    },
  );

  test(
    'cover previews stop at nine while total count and matching paths stay accurate',
    () {
      final projection = LibraryShelfProjection([
        folder('parent'),
        folder('child', parent: 'parent'),
      ], List.generate(100, (i) => book(i, folderId: 'child')));
      expect(projection.bookCount('parent'), 100);
      expect(projection.previewOf('parent').length, 9);
      expect(projection.previewOf('child').length, 9);
      expect(projection.foldersMatching((b) => b.id == 99), {
        'parent',
        'child',
      });
    },
  );

  test('invalid hierarchy or membership fails instead of hiding books', () {
    expect(
      () => LibraryShelfProjection([folder('a', parent: 'b')], []),
      throwsFormatException,
    );
    expect(
      () => LibraryShelfProjection([
        folder('a', parent: 'b'),
        folder('b', parent: 'a'),
      ], []),
      throwsFormatException,
    );
    expect(
      () => LibraryShelfProjection([folder('a'), folder('a')], []),
      throwsFormatException,
    );
    expect(
      () => LibraryShelfProjection([], [book(1, folderId: 'missing')]),
      throwsFormatException,
    );
  });
}
