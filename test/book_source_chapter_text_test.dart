import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_chapter_text.dart';

void main() {
  test(
    'plain source text preserves paragraph structure and existing indent',
    () {
      const content = BookSourceChapterContent(
        bookId: 'book',
        chapterId: 'chapter',
        title: 'Chapter',
        content: '  第一段\r\n\r\n\t第二段',
        contentType: 'text/plain',
      );

      expect(readableBookSourceChapterText(content), '  第一段\n\n\t第二段');
    },
  );

  test(
    'html extraction produces canonical paragraphs without visual indent',
    () {
      const content = BookSourceChapterContent(
        bookId: 'book',
        chapterId: 'chapter',
        title: 'Chapter',
        content: '<div><p>第一段</p><p>第二段<br>续行</p></div>',
        contentType: 'text/html',
      );

      expect(readableBookSourceChapterText(content), '第一段\n第二段\n续行');
    },
  );

  test('background html extraction matches the synchronous adapter', () async {
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '<article><h1>Chapter</h1><p>第一段</p><p>第二段</p></article>',
      contentType: 'text/html',
    );

    expect(
      await readableBookSourceChapterTextAsync(content),
      readableBookSourceChapterText(content),
    );
  });

  test('plain text mislabelled as html keeps paragraph breaks', () {
    // Regression: sources that declare `text/html` but return plain,
    // newline-separated text used to be routed through the HTML extractor,
    // which collapsed every paragraph separator into a single space. The
    // shared layout layer then saw one giant paragraph and could only indent
    // the very first line. Content sniffing must route this payload through
    // the plain-text path regardless of the declared content type.
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '第一段\n第二段\n第三段',
      contentType: 'text/html',
    );

    expect(readableBookSourceChapterText(content), '第一段\n第二段\n第三段');
  });

  test('plain and html source text recognize Unicode hard line breaks', () {
    const plain = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '第一段\u2028第二段\u2029第三段\u0085第四段',
      contentType: 'text/plain',
    );
    const html = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '<div>第一段\u2028第二段\u2029第三段</div>',
      contentType: 'text/html',
    );

    expect(readableBookSourceChapterText(plain), '第一段\n第二段\n第三段\n第四段');
    expect(readableBookSourceChapterText(html), '第一段\n第二段\n第三段');
  });

  test('html mislabelled as plain text is still extracted as html', () {
    // Symmetric regression: a source that declares `text/plain` but returns
    // real HTML must still be parsed as HTML, otherwise the tags would leak
    // into the rendered text.
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '<p>第一段</p><p>第二段</p>',
      contentType: 'text/plain',
    );

    expect(readableBookSourceChapterText(content), '第一段\n第二段');
  });

  test('html paragraphs separated only by a bare newline still split '
      'around a stray inline tag', () {
    // Regression: a chapter wrapped in a single tag (routing it through the
    // HTML extractor) but whose paragraphs are separated only by `\n`, with
    // one stray inline tag (e.g. an illustration) in the middle. Previously
    // the `\s+` collapse in flush() ate literal newlines just like any other
    // whitespace, merging every paragraph around the stray tag into one
    // line, so only the paragraphs next to a real block/`<br>` boundary got
    // indented by the reader.
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content: '<div>第一段\n第二段\n<img src="1.jpg"/>\n第三段\n第四段</div>',
      contentType: 'text/html',
    );

    expect(readableBookSourceChapterText(content), '第一段\n第二段\n第三段\n第四段');
  });

  test('removes a repeated plain-text chapter title only at the beginning', () {
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: '第一章 归来',
      content: '第一章　归来\n\n正文第一段\n正文提到第一章 归来但不能删除',
      contentType: 'text/plain',
    );

    expect(readableBookSourceChapterText(content), '正文第一段\n正文提到第一章 归来但不能删除');
  });

  test('uses the catalog title when chapter content omits its title field', () {
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: '',
      content: '# Chapter 8\nBody text',
      contentType: 'text/plain',
    );

    expect(
      readableBookSourceChapterText(content, fallbackTitle: 'Chapter 8'),
      'Body text',
    );
  });

  test('keeps a leading sentence that only contains the chapter title', () {
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: '第一章',
      content: '第一章的故事从这里开始。\n第二段',
      contentType: 'text/plain',
    );

    expect(readableBookSourceChapterText(content), '第一章的故事从这里开始。\n第二段');
  });

  test('projects Legado paragraph action without changing readable text', () {
    const script =
        r'''java.showBrowser("https://example.test", {"nested":{"label":"评价"}})''';
    final options =
        r'''{"style":"text","click":"java.showBrowser(\"https://example.test\", {\"nested\":{\"label\":\"评价\"}})"}''';
    final content = BookSourceChapterContent(
      bookId: 'source-book',
      chapterId: 'chapter-1',
      title: '第一章',
      content:
          '<p>第一章</p><p>第一😀段<img src="data:image/svg+xml;base64,AAAA,$options"></p><p>第二段</p>',
      contentType: 'text/html',
    );

    final projection = readableBookSourceChapterProjection(content);

    expect(projection.text, '第一😀段\n第二段');
    expect(projection.actions, hasLength(1));
    final action = projection.actions.single;
    expect(action.id, 'source-book:chapter-1:0');
    expect(action.startOffset, 0);
    expect(action.endOffset, '第一😀段'.length);
    expect(action.imageSource, 'data:image/svg+xml;base64,AAAA,$options');
    expect(action.script, script);
  });

  test('action result preserves HTML inside the original click script', () {
    const script = 'java.showBrowser("/comments", "<b>评论 & 正文</b>")';
    final options = jsonEncode({'style': 'text', 'click': script});
    final src = 'data:image/svg+xml;base64,AAAA,$options';
    final projection = readableBookSourceChapterProjection(
      BookSourceChapterContent(
        bookId: 'b',
        chapterId: 'c',
        title: '',
        content: '<p>正文<img src="$src"></p>',
        contentType: 'text/html',
      ),
    );
    expect(projection.actions.single.script, script);
    expect(projection.actions.single.imageSource, src);
    expect(projection.actions.single.paragraphText, '正文');
  });

  test('supports entity-encoded Legado image options after cache reload', () {
    final content = BookSourceChapterContent.fromJson({
      'bookId': 'book',
      'chapterId': 'cached',
      'title': 'Chapter',
      'content':
          '<p>Body<img src="https://a.test/bubble.png,{&quot;style&quot;:&quot;text&quot;,&quot;click&quot;:&quot;showCmt(1)&quot;}"></p>',
      'contentType': 'text/html',
    });

    final sync = readableBookSourceChapterProjection(content);

    expect(sync.text, 'Body');
    expect(sync.actions.single.imageSource, contains('{"style":"text"'));
    expect(sync.actions.single.script, 'showCmt(1)');
  });

  test('removed titles and repeated page markers discard their actions', () {
    String bubble(String id) =>
        '<img src="https://a.test/$id.png,{&quot;style&quot;:&quot;text&quot;,&quot;click&quot;:&quot;$id()&quot;}">';
    final content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content:
          '<p>Chapter${bubble('title')}</p>'
          '<p>1/3${bubble('page1')}</p>'
          '<p>正文${bubble('body')}</p>'
          '<p>2/3${bubble('page2')}</p>'
          '<p>3/3${bubble('page3')}</p>',
      contentType: 'text/html',
    );

    final projection = readableBookSourceChapterProjection(content);

    expect(projection.text, '正文');
    expect(projection.actions.map((action) => action.script), ['body()']);
    expect(projection.actions.single.startOffset, 0);
    expect(projection.actions.single.endOffset, 2);
  });

  test('background projection preserves action ids and UTF-16 offsets', () async {
    const content = BookSourceChapterContent(
      bookId: 'book',
      chapterId: 'chapter',
      title: 'Chapter',
      content:
          '<p>😀正文<img src="https://a.test/a.png,{&quot;style&quot;:&quot;text&quot;,&quot;click&quot;:&quot;open()&quot;}"></p>',
      contentType: 'text/html',
    );

    final projection = await readableBookSourceChapterProjectionAsync(content);

    expect(projection.text, '😀正文');
    expect(projection.actions.single.id, 'book:chapter:0');
    expect(projection.actions.single.endOffset, '😀正文'.length);
  });
}
