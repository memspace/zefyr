// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';
import 'package:notus/convert.dart';

void main() {
  group('$NotusHTMLCodec.decode', () {
    test('decode Normal text', () {
      final delta = Delta()..insert('Some text\n');
      final html = "Some text\n";
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode unsupported HTML tag as normal text', () {
      final expected = Delta()
        ..insert('<unsupported foo="bar">piyo</unsupported>')
        ..insert('\n');
      final html = '<unsupported foo="bar" />piyo</unsupported>\n';
      final result = notusHTML.decode(html);
      expect(result, expected);
    });

    test('decode italic attribute', () {
      final i = NotusAttribute.italic.key;
      final attributes = {i: true};
      final delta = Delta()..insert('txt', attributes)..insert('\n');
      final html = '<i>txt</i>\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), delta.toString());
    });

    test('decode bold attribute', () {
      final b = NotusAttribute.bold.key;
      final attributes = {b: true};
      final delta = Delta()..insert('txt', attributes)..insert('\n');
      final html = '<b>txt</b>\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), delta.toString());
    });

//    test('decode multiple container attribute', () {
//      final b = NotusAttribute.bold.toJson();
//      final bc = Map<String, dynamic>.from(b);
//      bc.addAll(NotusAttribute.container.withValue({
//        "b": {"foo": "bar", "hidden": null}
//      }).toJson());
//      final delta = Delta()..insert('txt', bc)..insert('\n');
//      final html = '<b foo="bar" hidden>txt</b>\n';
//      final result = notusHTML.decode(html);
//      expect(result.toString(), delta.toString());
//    });

    test('empty text', () {
      final delta = Delta()..insert('\n');
      final html = "";
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode Bold tag', () {
      final b = NotusAttribute.bold.toJson();
      final delta = Delta()..insert('foo', b)..insert('\n');
      final html = "<b>foo</b>";
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('removeZeroWidthSpaceFromNonEmbed', () {
      final b = NotusAttribute.bold.toJson();
      final delta = Delta()..insert('foo', b)..insert('\n');
      final html = "<b>${String.fromCharCode(8203)}foo</b>";
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode intersecting inline ', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final bi = Map<String, dynamic>.from(b);
      bi.addAll(i);
      final delta = Delta()
        ..insert('This')
        ..insert('house', b)
        ..insert('is a', bi)
        ..insert('circus', b)
        ..insert('desu')
        ..insert('\n');
      final html = "This<b>house<i>is a</i>circus</b>desu\n";
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode a tag', () {
      final l = NotusAttribute.link.fromString('http://foo.com');
      final delta = Delta()..insert('a tag', l.toJson())..insert("\n");
      final html = '<a href="http://foo.com">a tag</a>\n';
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode br tag', () {
      final delta = Delta()..insert('\n')..insert("\n");
      final html = '<br>\n';
      final result = notusHTML.decode(html);
      expect(result, delta);
    });
    test('decode nested br tag ', () {
      final delta = Delta()..insert('<b>a<br></b>')..insert("\n");
      final html = '<b>a<br></b>\n';
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode plain text + inlined line attributes ', () {
      final doc =
          r'[{"insert":"foo"},{"insert":"\nhead text"},{"insert":"\n","attributes":{"heading":1}}]';
      final delta = Delta.fromJson(json.decode(doc));
      final html = 'foo<h1>head text</h1>\n';
      final result = notusHTML.decode(html);
      expect(result, delta);
    });

    test('decode consecutive a tag with image', () {
      final f = NotusAttribute.link.fromString('http://bar.com');
      final delta = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203) + '\n',
          "attributes": {
            "a": "http://foo.com",
            "embed": {"type": "image", "source": "http://foo.jpg"},
          }
        },
      ])
        ..insert('a tag', f.toJson())
        ..insert('\n');
      final html =
          '<a href="http://foo.com"><img src="http://foo.jpg" /></a><a href="http://bar.com">a tag</a>\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), delta.toString());
    });

    test('decode image', () {
      final delta = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203),
          "attributes": {
            "embed": {"type": "image", "source": "http://img.jpg"},
          }
        }
      ])
        ..insert('\n');
      final html = '<img src="http://img.jpg"/>\n';
      final result = notusHTML.decode(html);

      expect(result.toString(), delta.toString());
    });
    test('decode end with new line policy', () {
      final doc = r'[{"insert":"foo\n"}]';
      final delta = Delta.fromJson(json.decode(doc));
      final html = 'foo';
      final result = notusHTML.decode(html);
      expect(result, delta);
    });
    test('decode heading styles', () {
      runFor(NotusAttribute<int> attribute, String source, String html) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.decode(html);
        expect(result, delta);
      }

      runFor(NotusAttribute.h1, 'Title', '<h1>Title</h1>\n');
      runFor(NotusAttribute.h2, 'Title', '<h2>Title</h2>\n');
      runFor(NotusAttribute.h3, 'Title', '<h3>Title</h3>\n');
    });

    test('decode heading styles with container attribute', () {
      runFor(NotusAttribute<int> attribute, String source, String html) {
        final attr = attribute.toJson();
        final delta = Delta()..insert(source)..insert('\n', attr);
        final result = notusHTML.decode(html);
        expect(result.toString(), delta.toString());
      }

      runFor(NotusAttribute.h1, 'Title', '<h1 foo="bar">Title</h1>\n');
      runFor(NotusAttribute.h2, 'Title', '<h2 foo="bar">Title</h2>\n');
      runFor(NotusAttribute.h3, 'Title', '<h3 foo="bar">Title</h3>\n');
    });

    test('decode singe block with container: quote', () {
      runFor(NotusAttribute<String> attribute, String source, String html) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.decode(html);
        expect(result.toString(), delta.toString());
      }

      runFor(NotusAttribute.bq, 'item',
          '<blockquote foo="bar">\nitem\n</blockquote>\n');
    });

    test('decode singe block with container: list', () {
      runFor(NotusAttribute<String> attribute, String source, String html) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.decode(html);
        expect(result.toString(), delta.toString());
      }

      runFor(
          NotusAttribute.ul, 'item', '<ul foo="bar">\n<li>item</li>\n</ul>\n');
      runFor(
          NotusAttribute.ol, 'item', '<ol foo="bar">\n<li>item</li>\n</ol>\n');
    });

    test('decode singe block', () {
      runFor(NotusAttribute<String> attribute, String source, String html) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.decode(html);
        expect(result, delta);
      }

      runFor(NotusAttribute.ul, 'item', '<ul>\n<li>item</li>\n</ul>\n');
      runFor(NotusAttribute.ol, 'item', '<ol>\n<li>item</li>\n</ol>\n');
      runFor(NotusAttribute.bq, 'item', '<blockquote>\nitem\n</blockquote>\n');
      runFor(NotusAttribute.ul, 'item', '<ul><li>item</li></ul>\n');
    });

    test('decode multi line block', () {
      runFor(NotusAttribute<String> attribute, String source, String html) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson())
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = notusHTML.decode(html);
        expect(result, delta);
      }

      runFor(NotusAttribute.ul, 'item', '<ul>\n<li>item\nitem</li>\n</ul>\n');
      runFor(NotusAttribute.ol, 'item', '<ol>\n<li>item\nitem</li>\n</ol>\n');
      runFor(NotusAttribute.bq, 'item',
          '<blockquote>\nitem\nitem\n</blockquote>\n');
      runFor(NotusAttribute.code, 'item', '<pre>\nitem\nitem\n</pre>\n');
    });
    test('decode: img tag inside a tag', () {
      final expected = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203),
          "attributes": {
            "a": "https://foo.com",
            "embed": {"type": "image", "source": "http://img.jpg"},
          }
        },
      ])
        ..insert('\n');

      var html = '<a href="https://foo.com"><img src="http://img.jpg" /></a>\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), expected.toString());
    });

    test('decode: img tag + link text inside a tag', () {
      final expected = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203) + '\n',
          "attributes": {
            "a": "https://foo.com",
            "embed": {"type": "image", "source": "http://img.jpg"},
          }
        },
      ])
        ..insert(
            "bar", NotusAttribute.link.fromString('https://foo.com').toJson())
        ..insert('\n');

      var html =
          '<a href="https://foo.com"><img src="http://img.jpg" />bar</a>\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), expected.toString());
    });

    test('decode complex intersecting inline ', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final bi = Map<String, dynamic>.from(b);
      final bia = Map<String, dynamic>.from(b);
      final biaimage = Map<String, dynamic>.from(b);
      final l = NotusAttribute.link.fromString('https://github.com').toJson();
      bi.addAll(i);
      bia.addAll(i);
      bia.addAll(l);
      biaimage.addAll(i);
      biaimage.addAll(l);
      biaimage.addAll({
        "embed": {"type": "image", "source": "http://img.jpg"}
      });
      final ki = "insert";
      final ka = "attributes";
      final delta = Delta.fromJson([
        {ki: "c", ka: null},
        {ki: "d", ka: b},
        {ki: "e", ka: bi},
        {ki: "f\n", ka: bia},
        {ki: String.fromCharCode(8203) + "\n", ka: biaimage},
        {ki: "g", ka: bi},
        {ki: "h", ka: b},
        {ki: "k\n", ka: null},
      ]);
      final html =
          'c<b>d<i>e<a href="https://github.com">f<img src="http://img.jpg" /></a>g</i>h</b>k\n';
      final result = notusHTML.decode(html);
      expect(result.toString(), delta.toString());
    });
    test('decode multiple styles', () {
      final result = notusHTML.decode(expectedHTML);
      expect(result.toString(), delta.toString());
    });
    test('decode hr with container attribute', () {
      runFor(String html) {
        final expected = Delta.fromJson([
          {
            "insert": String.fromCharCode(8203),
            "attributes": {
              "embed": {"type": "hr"},
            },
          },
        ])
          ..insert('\n');
        final delta = notusHTML.decode(html);
        expect(delta.toString(), expected.toString());
      }

      runFor('<hr foo="bar"/>\n');
    });
  });

  group('$NotusHTMLCodec.encode', () {
    test('encode split adjacent paragraphs', () {
      final delta = Delta()..insert('First line\nSecond line\n');
      final result = notusHTML.encode(delta);
      expect(result, 'First line\nSecond line\n');
    });

    test('encode italic attribute', () {
      final i = NotusAttribute.italic.toJson();
      final ic = Map<String, dynamic>.from(i);
      final delta = Delta()..insert('txt', ic)..insert('\n');
      final expected = '<i>txt</i>\n';
      final result = notusHTML.encode(delta);
      expect(result.toString(), expected.toString());
    });

    test('encode bold attribute', () {
      final b = NotusAttribute.bold.toJson();
      final bc = Map<String, dynamic>.from(b);
      final delta = Delta()..insert('txt', bc)..insert('\n');
      final expected = '<b>txt</b>\n';
      final result = notusHTML.encode(delta);
      expect(result.toString(), expected.toString());
    });

//    test('encode bold with multiple container attribute', () {
//      final b = NotusAttribute.bold.toJson();
//      final bc = Map<String, dynamic>.from(b);
//      bc.addAll(NotusAttribute.container.withValue({
//        "b": {"foo": "bar", "hidden": null}
//      }).toJson());
//      final delta = Delta()..insert('txt', bc)..insert('\n');
//      final expected = '<b foo="bar" hidden>txt</b>\n';
//      final result = notusHTML.encode(delta);
//      expect(result.toString(), expected.toString());
//    });

    test('encode bold italic', () {
      runFor(NotusAttribute<bool> attribute, String expected) {
        final delta = Delta()
          ..insert('This ')
          ..insert('house', attribute.toJson())
          ..insert(' is a ')
          ..insert('circus', attribute.toJson())
          ..insert('\n');

        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.bold, 'This <b>house</b> is a <b>circus</b>\n');
      runFor(NotusAttribute.italic, 'This <i>house</i> is a <i>circus</i>\n');
    });

    test('encode intersecting inline styles', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final bi = Map<String, dynamic>.from(b);
      bi.addAll(i);

      final delta = Delta()
        ..insert('This ')
        ..insert('house', b)
        ..insert(' is a ', bi)
        ..insert('circus', b)
        ..insert('\n');

      final result = notusHTML.encode(delta);
      expect(result, 'This <b>house <i>is a</i> circus</b>\n');
    });

    test('encode intersecting inline styles 2', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final bi = Map<String, dynamic>.from(b);
      bi.addAll(i);

      final delta = Delta()..insert('e', bi)..insert('\n');

      final result = notusHTML.encode(delta);
      expect(result, '<b><i>e</i></b>\n');
    });

    test('encode intersecting inline styles 3', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final bia = Map<String, dynamic>.from(b);
      final a = NotusAttribute.link.fromString('https://foo.com').toJson();
      bia.addAll(i);
      bia.addAll(a);

      final delta = Delta()..insert('e', bia)..insert('\n');

      final result = notusHTML.encode(delta);
      expect(result, '<b><i><a href="https://foo.com">e</a></i></b>\n');
    });

    test('encode img tag inside a tag', () {
      final delta = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203),
          "attributes": {
            "a": "https://foo.com",
            "embed": {"type": "image", "source": "http://img.jpg"},
          }
        },
      ])
        ..insert('\n');

      final result = notusHTML.encode(delta);
      var expected =
          '<a href="https://foo.com"><img src="http://img.jpg" /></a>\n';
      expect(result, expected);
    });

    test('encode img tag + link text inside a tag', () {
      final delta = Delta.fromJson([
        {
          "insert": String.fromCharCode(8203),
          "attributes": {
            "a": "https://foo.com",
            "embed": {"type": "image", "source": "http://img.jpg"},
          }
        },
      ])
        ..insert(
            "bar", NotusAttribute.link.fromString('https://foo.com').toJson())
        ..insert('\n');

      final result = notusHTML.encode(delta);
      var expected =
          '<a href="https://foo.com"><img src="http://img.jpg" />bar</a>\n';
      expect(result, expected);
    });

    test('encode normalize inline styles', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', i)
        ..insert('\n');

      final result = notusHTML.encode(delta);
      expect(result, 'This <b>house</b> is a <i>circus</i> \n');
    });

    test('encode links', () {
      final b = NotusAttribute.bold.toJson();
      final link = NotusAttribute.link.fromString('https://github.com');
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', link.toJson())
        ..insert('\n');

      final result = notusHTML.encode(delta);
      expect(result,
          'This <b>house</b> is a <a href="https://github.com">circus</a> \n');
    });

    test('encode heading styles', () {
      runFor(NotusAttribute<int> attribute, String source, String expected) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.h1, 'Title', '<h1>Title</h1>\n');
      runFor(NotusAttribute.h2, 'Title', '<h2>Title</h2>\n');
      runFor(NotusAttribute.h3, 'Title', '<h3>Title</h3>\n');
    });
    test('encode heading styles', () {
      runFor(NotusAttribute<int> attribute, String source, String expected) {
        final attr = attribute.toJson();
        final delta = Delta()..insert(source)..insert('\n', attr);
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.h1, 'Title', '<h1>Title</h1>\n');
      runFor(NotusAttribute.h2, 'Title', '<h2>Title</h2>\n');
      runFor(NotusAttribute.h3, 'Title', '<h3>Title</h3>\n');
    });

    test('encode singe block', () {
      runFor(NotusAttribute<String> attribute, String source, String expected) {
        var attr = attribute.toJson();
        final delta = Delta()..insert(source)..insert('\n', attr);
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.ul, 'item', '<ul>\n<li>item</li>\n</ul>\n');
      runFor(NotusAttribute.ol, 'item', '<ol>\n<li>item</li>\n</ol>\n');
      runFor(NotusAttribute.bq, 'item', '<blockquote>item</blockquote>\n');
    });

    test('encode block styles: ol, ul', () {
      runFor(NotusAttribute<String> attribute, String source, String expected) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(
          NotusAttribute.ul, 'List item', '<ul>\n<li>List item</li>\n</ul>\n');
      runFor(
          NotusAttribute.ol, 'List item', '<ol>\n<li>List item</li>\n</ol>\n');
      runFor(NotusAttribute.bq, 'List item',
          '<blockquote>List item</blockquote>\n');
    });

    test('encode block styles: code, bq', () {
      runFor(NotusAttribute<String> attribute, String source, String expected) {
        List<String> items = source.split("\n");
        final delta = Delta()
          ..insert(items[0])
          ..insert('\n', attribute.toJson())
          ..insert(items[1])
          ..insert('\n', attribute.toJson());
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.code, 'item1\nitem2', '<pre>item1\nitem2</pre>\n');
      runFor(NotusAttribute.bq, 'item1\nitem2',
          '<blockquote>item1\nitem2</blockquote>\n');
    });

    test('encode image', () {
      runFor(String expected) {
        final delta = Delta.fromJson([
          {
            "insert": "",
            "attributes": {
              "embed": {"type": "image", "source": "http://images.jpg"},
            }
          }
        ])
          ..insert('\n');
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor('<img src="http://images.jpg" />\n');
    });
    test('encode hr', () {
      runFor(String expected) {
        final delta = Delta.fromJson([
          {
            "insert": "",
            "attributes": {
              "embed": {"type": "hr"}
            },
          },
        ])
          ..insert('\n');
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor('<hr />\n');
    });
    test('encode hr attribute', () {
      runFor(String expected) {
        final delta = Delta.fromJson([
          {
            "insert": "",
            "attributes": {
              "embed": {"type": "hr"},
            },
          },
        ])
          ..insert('\n');
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor('<hr />\n');
    });
    test('encode multiline blocks', () {
      runFor(NotusAttribute<String> attribute, String source, String expected) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson())
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = notusHTML.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.ul, 'text',
          '<ul>\n<li>text</li>\n<li>text</li>\n</ul>\n');
      runFor(NotusAttribute.ol, 'text',
          '<ol>\n<li>text</li>\n<li>text</li>\n</ol>\n');
      runFor(
          NotusAttribute.bq, 'text', '<blockquote>text\ntext</blockquote>\n');
    });

    test('encode multiple styles', () {
      final result = notusHTML.encode(delta);
      expect(result, expectedHTML);
    });
  });
}

final doc =
    r'[{"insert":"Zefyr"},{"insert":"\n","attributes":{"heading":1}},{"insert": "​","attributes": {"embed": {"type": "hr"}}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"i":true}},{"insert":"\nZefyr is an "},{"insert":"early preview","attributes":{"b":true}},{"insert":" open source library.\n"},{"insert":"Documentation"},{"insert":"\n","attributes":{"heading":3}},{"insert":"Quick Start"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Data format and Document Model"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Style attributes"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Heuristic rules"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"heading":2}},{"insert":"rich text editor is built with simplicity and flexibility in mind.\n"}]';
final delta = Delta.fromJson(json.decode(doc));

final expectedHTML = '''
<h1>Zefyr</h1>
<hr /><i>Soft and gentle rich text editing for Flutter applications.</i>
Zefyr is an <b>early preview</b> open source library.
<h3>Documentation</h3>
<ul>
<li>Quick Start</li>
<li>Data format and Document Model</li>
<li>Style attributes</li>
<li>Heuristic rules</li>
</ul>
<h2>Clean and modern look</h2>
rich text editor is built with simplicity and flexibility in mind.
''';
