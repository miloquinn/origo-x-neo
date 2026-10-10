import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/comic/comic_reader_page.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';

void main() {
  tearDown(() {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
  });

  testWidgets('normal account cannot open a local comic route', (tester) async {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    await ComicReaderPage.open(
      context,
      Book(
        title: 'locked comic',
        filePath: '/does/not/matter.cbz',
        format: 'cbz',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ComicReaderPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
