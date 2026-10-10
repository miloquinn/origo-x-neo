import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/source_engine/rules/source_rule_html.dart';

void main() {
  group('sourceHtmlMatches compatibility', () {
    test('matches attached elements like the existing parent traversal', () {
      final document = html_parser.parse('''
          <section id="catalog" class="shelf" data-kind="novel">
            <h2 class="title">Catalog</h2>
            <ol class="chapters">
              <li id="first" class="chapter featured" data-index="1"><a>One</a></li><li id="second" class="chapter" data-index="2"><a>Two</a><span></span></li><li id="third" class="chapter muted" data-index="3"><a>Three</a></li></ol>
            <p class="tail"></p>
          </section>
        ''');
      final first = document.querySelector('#first')!;
      final second = document.querySelector('#second')!;
      final third = document.querySelector('#third')!;

      final expectations = <(Element, String, bool)>[
        (second, 'li', true),
        (second, '.chapter', true),
        (second, '[data-index="2"]', true),
        (second, 'li.chapter[data-index^="2"]', true),
        (second, 'h1, li#second', true),
        (second, 'section.shelf li#second', true),
        (second, 'ol.chapters > li#second', true),
        (second, 'li#first + li#second', true),
        (second, 'li#first ~ li#second', true),
        (first, 'li:first-child', true),
        (third, 'li:last-child', true),
        (second, 'li:nth-child(2)', true),
        (second, 'li:not(.muted)', true),
        (second, 'div', false),
        (second, '.missing', false),
        (second, '[data-index="3"]', false),
        (second, 'h1, li#third', false),
        (second, 'section.other li', false),
        (second, 'ol.chapters > li#first', false),
        (second, 'li#third + li', false),
        (second, 'li:first-child', false),
        (second, 'li:last-child', false),
        (second, 'li:nth-child(3)', false),
        (second, 'li:not(.chapter)', false),
      ];

      for (final (element, selector, expected) in expectations) {
        final legacy = element.parent!
            .querySelectorAll(selector)
            .contains(element);
        expect(legacy, expected, reason: 'legacy result for $selector');
        expect(
          sourceHtmlMatches(element, selector),
          legacy,
          reason: 'sourceHtmlMatches parity for $selector',
        );
      }
    });

    test('keeps the detached root fallback behavior', () {
      final root = Element.tag('article')
        ..classes.add('featured')
        ..attributes['data-kind'] = 'chapter';

      expect(root.parent, isNull);
      expect(sourceHtmlMatches(root, '*'), isTrue);
      expect(sourceHtmlMatches(root, 'article'), isTrue);
      expect(sourceHtmlMatches(root, 'Article'), isFalse);
      expect(sourceHtmlMatches(root, '.featured'), isFalse);
      expect(sourceHtmlMatches(root, '[data-kind="chapter"]'), isFalse);
      expect(sourceHtmlMatches(root, 'article.featured'), isFalse);
    });

    test(
      'keeps documentElement on the detached fallback despite its Document parentNode',
      () {
        final document = html_parser.parse('<main>Chapter</main>');
        final root = document.documentElement!;

        expect(root.parent, isNull);
        expect(root.parentNode, same(document));
        expect(sourceHtmlMatches(root, '*'), isTrue);
        expect(sourceHtmlMatches(root, 'html'), isTrue);
        expect(sourceHtmlMatches(root, '.anything'), isFalse);
        expect(sourceHtmlMatches(root, 'html['), isFalse);
        expect(sourceHtmlMatches(root, 'html:hover'), isFalse);
      },
    );

    test(
      'observes live class and attribute mutations on attached elements',
      () {
        final document = html_parser.parse(
          '<ol><li id="row" class="draft" data-index="1"></li></ol>',
        );
        final row = document.querySelector('#row')!;
        const selector = 'li.chapter[data-index="7000"]';

        expect(sourceHtmlMatches(row, selector), isFalse);

        row.classes.add('chapter');
        row.attributes['data-index'] = '7000';
        expect(sourceHtmlMatches(row, selector), isTrue);

        row.classes.remove('chapter');
        expect(sourceHtmlMatches(row, selector), isFalse);

        row.classes.add('chapter');
        expect(sourceHtmlMatches(row, selector), isTrue);
      },
    );

    test('does not change the attached element or sibling topology', () {
      final document = html_parser.parse(
        '<section><p id="before"></p>gap<div id="target"></div><p id="after"></p></section>',
      );
      final parent = document.querySelector('section')!;
      final target = document.querySelector('#target')!;
      final parentNode = target.parentNode;
      final nodes = parent.nodes.toList(growable: false);
      final children = parent.children.toList(growable: false);
      final previous = target.previousElementSibling;
      final next = target.nextElementSibling;

      expect(sourceHtmlMatches(target, 'section > div#target'), isTrue);

      expect(target.parentNode, same(parentNode));
      expect(parent.nodes.length, nodes.length);
      for (var index = 0; index < nodes.length; index++) {
        expect(parent.nodes[index], same(nodes[index]), reason: 'node $index');
      }
      expect(parent.children.length, children.length);
      for (var index = 0; index < children.length; index++) {
        expect(
          parent.children[index],
          same(children[index]),
          reason: 'child $index',
        );
      }
      expect(target.previousElementSibling, same(previous));
      expect(target.nextElementSibling, same(next));
    });
  });

  group('source HTML selection behavior', () {
    test(
      'includeRoots changes only root inclusion and preserves tree order',
      () {
        final document = html_parser.parse('''
        <section id="catalog" class="shelf">
          <div><p id="first" class="entry">One</p></div>
          <p id="second" class="entry">Two</p>
          <div><p id="third" class="entry">Three</p></div>
        </section>
      ''');
        final root = document.querySelector('#catalog')!;
        const selector = 'section.shelf, p.entry';

        expect(
          selectSourceHtml(
            [root],
            selector,
            includeRoots: true,
            legacy: false,
          ).map((element) => element.id),
          ['catalog', 'first', 'second', 'third'],
        );
        expect(
          selectSourceHtml(
            [root],
            selector,
            includeRoots: false,
            legacy: false,
          ).map((element) => element.id),
          ['first', 'second', 'third'],
        );
      },
    );

    test('invalid CSS remains a protocol error through rule evaluation', () {
      final document = html_parser.parse('<main><div>Chapter</div></main>');

      expect(
        () => evaluateSourceHtmlRule(
          [document.body!],
          'main > div[',
          listMode: false,
        ),
        throwsA(isA<BookSourceProtocolException>()),
      );
    });

    test('unsupported CSS remains a protocol error through selection', () {
      final document = html_parser.parse('<main><div>Chapter</div></main>');
      final div = document.querySelector('div')!;

      expect(
        () => sourceHtmlMatches(div, 'div:hover'),
        throwsA(isA<UnimplementedError>()),
      );

      expect(
        () => selectSourceHtml(
          [document.body!],
          'div:hover',
          includeRoots: false,
          legacy: false,
        ),
        throwsA(isA<BookSourceProtocolException>()),
      );
    });

    test('JSoup compatibility markers leave the source DOM unchanged', () {
      final document = html_parser.parse('''
        <article id="root" data-code="chapter-7000" data-origo-x-compat-0="keep">
          <p id="match" data-code="chapter-7001">Chapter</p>
          <p id="other" data-code="appendix">Appendix</p>
        </article>
      ''');
      final root = document.querySelector('#root')!;
      final before = root.outerHtml;

      final selected = selectSourceHtml(
        [root],
        r'[data-code~=^chapter-\d+$]',
        includeRoots: true,
        legacy: false,
      );

      expect(selected.map((element) => element.id), ['root', 'match']);
      expect(root.outerHtml, before);
      expect(root.attributes['data-origo-x-compat-0'], 'keep');
      for (final element in [root, ...root.querySelectorAll('*')]) {
        expect(
          element.attributes.keys
              .map((name) => name.toString())
              .where(
                (name) =>
                    name.startsWith('data-origo-x-compat-') &&
                    name != 'data-origo-x-compat-0',
              ),
          isEmpty,
          reason: 'temporary marker on #${element.id}',
        );
      }
    });

    test('JSoup markers are removed when rewritten CSS is malformed', () {
      final document = html_parser.parse('''
        <section id="root">
          <div id="match" data-code="chapter">Chapter</div>
        </section>
      ''');
      final root = document.querySelector('#root')!;
      final before = root.outerHtml;

      expect(
        () => selectSourceHtml(
          [root],
          r'div[data-code~=^chapter$][',
          includeRoots: true,
          legacy: false,
        ),
        throwsA(isA<BookSourceProtocolException>()),
      );
      expect(root.outerHtml, before);
      for (final element in [root, ...root.querySelectorAll('*')]) {
        expect(
          element.attributes.keys
              .map((name) => name.toString())
              .where((name) => name.startsWith('data-origo-x-compat-')),
          isEmpty,
          reason: 'temporary marker on #${element.id}',
        );
      }
    });
  });

  test(
    'sourceHtmlMatches ignores unsupported selector branches after a direct match',
    () {
      final document = html_parser.parse('''
        <section>
          <div id="earlier"></div>
          <span id="target"></span>
        </section>
      ''');
      final target = document.querySelector('#target')!;

      expect(sourceHtmlMatches(target, '#target, div:hover'), isTrue);
    },
  );

  test(
    'sourceHtmlMatches evaluates one attached element without scanning its parent',
    () {
      final parent = _NoParentScanElement();
      final row = Element.tag('li')
        ..classes.add('chapter')
        ..attributes['data-index'] = '7000';
      parent.append(row);

      expect(sourceHtmlMatches(row, 'li.chapter[data-index="7000"]'), isTrue);
      expect(parent.querySelectorAllCalls, 0);
    },
  );
}

class _NoParentScanElement extends Element {
  _NoParentScanElement() : super.tag('ol');

  int querySelectorAllCalls = 0;

  @override
  List<Element> querySelectorAll(String selector) {
    querySelectorAllCalls++;
    throw StateError('sourceHtmlMatches scanned the parent subtree');
  }
}
