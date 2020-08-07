// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:notus/convert.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('$NotusMarkdownCodec.encode', () {
    test('paragraphs', () {
      final markdown = 'First line\n\nSecond line\n\n';
      final delta = notusMarkdown.decode(markdown);
      expect(delta.elementAt(0).data, 'First line\nSecond line\n');
      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('italics', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'italics');
        expect(delta.elementAt(0).attributes["i"], true);
        expect(delta.elementAt(0).attributes["b"], null);
        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor('_italics_\n\n', true);
      runFor('*italics*\n\n', false);
    });

    test('multi-word italics', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'Okay, ');
        expect(delta.elementAt(0).attributes, null);

        expect(delta.elementAt(1).data, 'this is in italics');
        expect(delta.elementAt(1).attributes["i"], true);
        expect(delta.elementAt(1).attributes["b"], null);

        expect(delta.elementAt(3).data, 'so is all of _ this');
        expect(delta.elementAt(3).attributes["i"], true);

        expect(delta.elementAt(4).data, ' but this is not\n');
        expect(delta.elementAt(4).attributes, null);
        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor(
          'Okay, _this is in italics_ and _so is all of _ this_ but this is not\n\n',
          true);
      runFor(
          'Okay, *this is in italics* and *so is all of _ this* but this is not\n\n',
          false);
    });

    test('bold', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'bold');
        expect(delta.elementAt(0).attributes["b"], true);
        expect(delta.elementAt(0).attributes["i"], null);
        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor('**bold**\n\n', true);
      runFor('__bold__\n\n', false);
    });

    test('multi-word bold', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'Okay, ');
        expect(delta.elementAt(0).attributes, null);

        expect(delta.elementAt(1).data, 'this is bold');
        expect(delta.elementAt(1).attributes["b"], true);
        expect(delta.elementAt(1).attributes["i"], null);

        expect(delta.elementAt(3).data, 'so is all of __ this');
        expect(delta.elementAt(3).attributes["b"], true);

        expect(delta.elementAt(4).data, ' but this is not\n');
        expect(delta.elementAt(4).attributes, null);
        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor(
          'Okay, **this is bold** and **so is all of __ this** but this is not\n\n',
          true);
      runFor(
          'Okay, __this is bold__ and __so is all of __ this__ but this is not\n\n',
          false);
    });

    test('intersecting inline styles', () {
      var markdown = 'This **house _is a_ circus**\n\n';
      final delta = notusMarkdown.decode(markdown);
      expect(delta.elementAt(1).data, 'house ');
      expect(delta.elementAt(1).attributes["b"], true);
      expect(delta.elementAt(1).attributes["i"], null);

      expect(delta.elementAt(2).data, 'is a');
      expect(delta.elementAt(2).attributes["b"], true);
      expect(delta.elementAt(2).attributes["i"], true);

      expect(delta.elementAt(3).data, ' circus');
      expect(delta.elementAt(3).attributes["b"], true);
      expect(delta.elementAt(3).attributes["i"], null);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('bold and italics', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'this is bold and italic');
        expect(delta.elementAt(0).attributes["b"], true);
        expect(delta.elementAt(0).attributes["i"], true);

        expect(delta.elementAt(1).data, '\n');
        expect(delta.length, 2);

        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor('**_this is bold and italic_**\n\n', true);
      runFor('_**this is bold and italic**_\n\n', true);
      runFor('***this is bold and italic***\n\n', false);
      runFor('___this is bold and italic___\n\n', false);
    });

    test('bold and italics combinations', () {
      runFor(String markdown, bool testEncode) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'this is bold');
        expect(delta.elementAt(0).attributes["b"], true);
        expect(delta.elementAt(0).attributes["i"], null);

        expect(delta.elementAt(2).data, 'this is in italics');
        expect(delta.elementAt(2).attributes["b"], null);
        expect(delta.elementAt(2).attributes["i"], true);

        expect(delta.elementAt(4).data, 'this is both');
        expect(delta.elementAt(4).attributes["b"], true);
        expect(delta.elementAt(4).attributes["i"], true);

        if (testEncode) {
          final andBack = notusMarkdown.encode(delta);
          expect(andBack, markdown);
        }
      }

      runFor('**this is bold** _this is in italics_ and **_this is both_**\n\n',
          true);
      runFor('**this is bold** *this is in italics* and ***this is both***\n\n',
          false);
      runFor('__this is bold__ _this is in italics_ and ___this is both___\n\n',
          false);
    });

    test('link', () {
      var markdown = 'This **house** is a [circus](https://github.com)\n\n';
      final delta = notusMarkdown.decode(markdown);

      expect(delta.elementAt(1).data, 'house');
      expect(delta.elementAt(1).attributes["b"], true);
      expect(delta.elementAt(1).attributes["a"], null);

      expect(delta.elementAt(3).data, 'circus');
      expect(delta.elementAt(3).attributes["b"], null);
      expect(delta.elementAt(3).attributes["a"], 'https://github.com');

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('style around link', () {
      var markdown = 'This **house** is a **[circus](https://github.com)**\n\n';
      final delta = notusMarkdown.decode(markdown);

      expect(delta.elementAt(1).data, 'house');
      expect(delta.elementAt(1).attributes["b"], true);
      expect(delta.elementAt(1).attributes["a"], null);

      expect(delta.elementAt(3).data, 'circus');
      expect(delta.elementAt(3).attributes["b"], true);
      expect(delta.elementAt(3).attributes["a"], 'https://github.com');

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('style within link', () {
      var markdown = 'This **house** is a [**circus**](https://github.com)\n\n';
      final delta = notusMarkdown.decode(markdown);

      expect(delta.elementAt(1).data, 'house');
      expect(delta.elementAt(1).attributes["b"], true);
      expect(delta.elementAt(1).attributes["a"], null);

      expect(delta.elementAt(2).data, ' is a ');
      expect(delta.elementAt(2).attributes, null);

      expect(delta.elementAt(3).data, 'circus');
      expect(delta.elementAt(3).attributes["b"], true);
      expect(delta.elementAt(3).attributes["a"], 'https://github.com');

      expect(delta.elementAt(4).data, '\n');
      expect(delta.length, 5);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('heading styles', () {
      runFor(String markdown, int level) {
        final delta = notusMarkdown.decode(markdown);
        expect(delta.elementAt(0).data, 'This is an H$level\n');
        expect(delta.elementAt(0).attributes['heading'], level);
        final andBack = notusMarkdown.encode(delta);
        expect(andBack, markdown);
      }

      runFor('# This is an H1\n\n', 1);
      runFor('## This is an H2\n\n', 2);
      runFor('### This is an H3\n\n', 3);
    });

    test('ul', () {
      var markdown = '* a bullet point\n* another bullet point\n\n';
      final delta = notusMarkdown.decode(markdown);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('ol', () {
      var markdown = '1. 1st point\n1. 2nd point\n\n';
      final delta = notusMarkdown.decode(markdown);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('simple bq', () {
//      var markdown = '> quote\n> > nested\n>#Heading\n>**bold**\n>_italics_\n>* bullet\n>1. 1st point\n>1. 2nd point\n\n';
      var markdown =
          '> quote\n> # Heading in Quote\n> # **Styled** heading in _block quote_\n> **bold text**\n> _text in italics_\n\n';
      final delta = notusMarkdown.decode(markdown);

      expect(delta.elementAt(0).data, 'quote\n');
      expect(delta.elementAt(0).attributes['block'], 'quote');
      expect(delta.elementAt(0).attributes.length, 1);

      expect(delta.elementAt(1).data, 'Heading in Quote\n');
      expect(delta.elementAt(1).attributes['block'], 'quote');
      expect(delta.elementAt(1).attributes['heading'], 1);
      expect(delta.elementAt(1).attributes.length, 2);

      expect(delta.elementAt(2).data, 'Styled');
      expect(delta.elementAt(2).attributes['block'], 'quote');
      expect(delta.elementAt(2).attributes['heading'], 1);
      expect(delta.elementAt(2).attributes['b'], true);
      expect(delta.elementAt(2).attributes.length, 3);

      expect(delta.elementAt(3).data, ' heading in ');
      expect(delta.elementAt(3).attributes['block'], 'quote');
      expect(delta.elementAt(3).attributes['heading'], 1);
      expect(delta.elementAt(3).attributes.length, 2);

      expect(delta.elementAt(4).data, 'block quote');
      expect(delta.elementAt(4).attributes['block'], 'quote');
      expect(delta.elementAt(4).attributes['heading'], 1);
      expect(delta.elementAt(4).attributes['i'], true);
      expect(delta.elementAt(4).attributes.length, 3);

      expect(delta.elementAt(6).data, 'bold text');
      expect(delta.elementAt(6).attributes['block'], 'quote');
      expect(delta.elementAt(6).attributes['b'], true);
      expect(delta.elementAt(6).attributes.length, 2);

      expect(delta.elementAt(8).data, 'text in italics');
      expect(delta.elementAt(8).attributes['block'], 'quote');
      expect(delta.elementAt(8).attributes['i'], true);
      expect(delta.elementAt(8).attributes.length, 2);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    /*test('nested bq', () {
      var markdown = '> > nested\n>* bullet\n>1. 1st point\n>1. 2nd point\n\n';
      final delta = notusMarkdown.decode(markdown);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });

    test('code in bq', () {
      var markdown = '> ```\n> print("Hello world!")\n> ```\n\n';
      final delta = notusMarkdown.decode(markdown);

      final andBack = notusMarkdown.encode(delta);
      expect(andBack, markdown);
    });*/

    test('multiple styles', () {
      final delta = notusMarkdown.decode(expectedMarkdown);
//      expect(delta, doc);
      final andBack = notusMarkdown.encode(delta);
      expect(andBack, expectedMarkdown);
    });
  });

  group('$NotusMarkdownCodec.encode', () {
    test('split adjacent paragraphs', () {
      final delta = Delta()..insert('First line\nSecond line\n');
      final result = notusMarkdown.encode(delta);
      expect(result, 'First line\n\nSecond line\n\n');
    });

    test('bold italic', () {
      void runFor(NotusAttribute<bool> attribute, String expected) {
        final delta = Delta()
          ..insert('This ')
          ..insert('house', attribute.toJson())
          ..insert(' is a ')
          ..insert('circus', attribute.toJson())
          ..insert('\n');

        final result = notusMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.bold, 'This **house** is a **circus**\n\n');
      runFor(NotusAttribute.italic, 'This _house_ is a _circus_\n\n');
    });

    test('intersecting inline styles', () {
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

      final result = notusMarkdown.encode(delta);
      expect(result, 'This **house _is a_ circus**\n\n');
    });

    test('normalize inline styles', () {
      final b = NotusAttribute.bold.toJson();
      final i = NotusAttribute.italic.toJson();
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', i)
        ..insert('\n');

      final result = notusMarkdown.encode(delta);
      expect(result, 'This **house** is a _circus_ \n\n');
    });

    test('links', () {
      final b = NotusAttribute.bold.toJson();
      final link = NotusAttribute.link.fromString('https://github.com');
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', link.toJson())
        ..insert('\n');

      final result = notusMarkdown.encode(delta);
      expect(result, 'This **house** is a [circus](https://github.com) \n\n');
    });

    test('heading styles', () {
      void runFor(
          NotusAttribute<int> attribute, String source, String expected) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.h1, 'Title', '# Title\n\n');
      runFor(NotusAttribute.h2, 'Title', '## Title\n\n');
      runFor(NotusAttribute.h3, 'Title', '### Title\n\n');
    });

    test('block styles', () {
      void runFor(
          NotusAttribute<String> attribute, String source, String expected) {
        final delta = Delta()..insert(source)..insert('\n', attribute.toJson());
        final result = notusMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.ul, 'List item', '* List item\n\n');
      runFor(NotusAttribute.ol, 'List item', '1. List item\n\n');
      runFor(NotusAttribute.bq, 'List item', '> List item\n\n');
      runFor(NotusAttribute.code, 'List item', '```\nList item\n```\n\n');
    });

    test('multiline blocks', () {
      void runFor(
          NotusAttribute<String> attribute, String source, String expected) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson())
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = notusMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(NotusAttribute.ul, 'text', '* text\n* text\n\n');
      runFor(NotusAttribute.ol, 'text', '1. text\n1. text\n\n');
      runFor(NotusAttribute.bq, 'text', '> text\n> text\n\n');
      runFor(NotusAttribute.code, 'text', '```\ntext\ntext\n```\n\n');
    });

    test('multiple styles', () {
      final result = notusMarkdown.encode(delta);
      expect(result, expectedMarkdown);
    });
  });
}

final doc =
    r'[{"insert":"Zefyr"},{"insert":"\n","attributes":{"heading":1}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"i":true}},{"insert":"\nZefyr is an "},{"insert":"early preview","attributes":{"b":true}},{"insert":" open source library.\nDocumentation"},{"insert":"\n","attributes":{"heading":3}},{"insert":"Quick Start"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Data format and Document Model"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Style attributes"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Heuristic rules"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"heading":2}},{"insert":"Zefyr’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nimport ‘package:flutter/material.dart’;"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"import ‘package:notus/notus.dart’;"},{"insert":"\n\n","attributes":{"block":"code"}},{"insert":"void main() {"},{"insert":"\n","attributes":{"block":"code"}},{"insert":" print(“Hello world!”);"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"}"},{"insert":"\n","attributes":{"block":"code"}}]';
final delta = Delta.fromJson(json.decode(doc) as List);

final expectedMarkdown = '''
# Zefyr

_Soft and gentle rich text editing for Flutter applications._

Zefyr is an **early preview** open source library.

### Documentation

* Quick Start
* Data format and Document Model
* Style attributes
* Heuristic rules

## Clean and modern look

Zefyr’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.

```
import ‘package:flutter/material.dart’;
import ‘package:notus/notus.dart’;

void main() {
 print(“Hello world!”);
}
```

''';
