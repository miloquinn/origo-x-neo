import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/models/book.dart';

/// Keeps reader tests outside the process-global application database.
class NoShelfBookSourceService extends BookSourceShelfService {
  NoShelfBookSourceService(BookSourceClient client) : super(client: client);

  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) async => null;
}
