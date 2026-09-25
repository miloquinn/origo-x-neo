import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/sync/secure_sync_config.dart';
import 'package:xxread/services/sync/sync_models.dart';
import 'package:xxread/services/sync/webdav_client.dart';

import 'support/local_webdav_server.dart';

void main() {
  test('resolves relative DAV hrefs inside the listed collection', () async {
    final server = await LocalWebDavServer.start();
    addTearDown(server.close);
    server.relativeHrefs = true;
    final client = WebDavClient.standard(
      StoredSyncCredentials(
        WebDavSyncConfiguration(
          serverUrl: server.url,
          username: 'reader',
          rootPath: 'OrigoReader',
          allowInsecurePrivateHttp: true,
        ),
        'secret',
      ),
    );
    await client.ensureRootPath(['backups']);
    final collection = client.rootPath(['backups']);
    final item = File('${server.root.path}/OrigoReader/backups/snapshot.zip');
    await item.writeAsString('snapshot');

    final entries = await client.listEntries(collection);

    expect(entries, hasLength(1));
    expect(entries.single.uri, client.rootPath(['backups', 'snapshot.zip']));
    expect(entries.single.contentLength, 8);
  });
}
