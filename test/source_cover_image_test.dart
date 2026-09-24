import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/source_cover_cache.dart';
import 'package:xxread/widgets/source_cover_image.dart';

class _Cache extends SourceCoverCache {
  final result = Completer<Uint8List>();
  @override
  Future<Uint8List> load(
    Uri uri, {
    Map<String, String> headers = const {},
    bool preferPlatform = false,
    SourceImageLoadPriority priority = SourceImageLoadPriority.visible,
  }) => result.future;
}

class _SyncCache extends SourceCoverCache {
  _SyncCache(this.bytes);

  final Uint8List bytes;

  @override
  Uint8List? peek(Uri uri, {Map<String, String> headers = const {}}) => bytes;

  @override
  Future<Uint8List> load(
    Uri uri, {
    Map<String, String> headers = const {},
    bool preferPlatform = false,
    SourceImageLoadPriority priority = SourceImageLoadPriority.visible,
  }) => throw StateError('A memory hit must not start a load.');
}

void main() {
  testWidgets('memory-cached cover skips the placeholder frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 100,
          height: 150,
          child: SourceCoverImage(
            url: Uri.parse('https://example.test/cached.png'),
            cache: _SyncCache(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
              ),
            ),
            width: 100,
            height: 150,
            fallback: const ColoredBox(key: Key('fallback'), color: Colors.grey),
          ),
        ),
      ),
    );

    // The bytes arrive synchronously, so the very first frame already builds
    // the image instead of painting the placeholder and swapping one frame
    // later.
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'cover retains fallback until decoded and fades once ($reduceMotion)',
      (tester) async {
        final cache = _Cache();
        const fallback = ColoredBox(key: Key('fallback'), color: Colors.grey);
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 100,
              height: 150,
              child: SourceCoverImage(
                url: Uri.parse('https://example.test/cover.png'),
                cache: cache,
                width: 100,
                height: 150,
                fallback: fallback,
              ),
            ),
          ),
        );
        expect(find.byKey(const Key('fallback')), findsOneWidget);
        cache.result.complete(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
          ),
        );
        await tester.pump();
        final image = tester.widget<Image>(find.byType(Image));
        final frameBuilder = image.frameBuilder!;
        // Drive decoder frame notifications explicitly so the test does not
        // depend on platform codec scheduling or wall-clock disk/network timing.
        Future<void> frame(int? frame, {bool synchronous = false}) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: Builder(
                  builder: (context) => Center(
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: frameBuilder(
                        context,
                        const ColoredBox(key: Key('image'), color: Colors.blue),
                        frame,
                        synchronous,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        await frame(null);
        expect(find.byKey(const Key('fallback')), findsOneWidget);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );
        await frame(0);
        expect(find.byKey(const Key('fallback')), findsOneWidget);
        final fade = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(fade.opacity, 1);
        expect(
          fade.duration,
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        );
        await tester.pump(const Duration(milliseconds: 90));
        if (!reduceMotion) {
          final opacity = tester
              .widget<FadeTransition>(find.byType(FadeTransition).last)
              .opacity
              .value;
          expect(opacity, greaterThan(0));
          expect(opacity, lessThan(1));
        }
        await tester.pump(const Duration(milliseconds: 180));
        await frame(1);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
        await frame(0, synchronous: true);
        expect(find.byType(AnimatedOpacity), findsNothing);
        expect(find.byKey(const Key('image')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
