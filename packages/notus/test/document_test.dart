// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';
import 'matchers.dart';

NotusDocument dartconfDoc() {
  Delta delta = new Delta()..insert('DartConf\nLos Angeles\n');
  return new NotusDocument.fromDelta(delta);
}

NotusDocument dartconfEmbedDoc() {
  final hr = NotusAttribute.embed.horizontalRule.toJson();
  Delta delta = new Delta()
    ..insert('DartConf\n')
    ..insert(kZeroWidthSpace, hr)
    ..insert('\n')
    ..insert('Los Angeles\n');
  return new NotusDocument.fromDelta(delta);
}

final ul = NotusAttribute.ul.toJson();
final h1 = NotusAttribute.h1.toJson();

void main() {
  group('$NotusDocument', () {
    test('validates for doc delta', () {
      var badDelta = new Delta()
        ..insert('Text')
        ..retain(5)
        ..insert('\n');
      expect(() {
        new NotusDocument.fromDelta(badDelta);
      }, throwsArgumentError);
    });

    test('empty document contains single empty line', () {
      NotusDocument doc = new NotusDocument();
      expect(doc.toPlainText(), '\n');
    });

    test('json serialization', () {
      final original = dartconfDoc();
      final jsonData = json.encode(original);
      final doc = NotusDocument.fromJson(json.decode(jsonData) as List);
      expect(doc.toDelta(), original.toDelta());
      expect(json.encode(doc), jsonData);
    });

    test('length', () {
      final doc = dartconfDoc();
      expect(doc.length, 21);
    });

    test('toString', () {
      NotusDocument doc = dartconfDoc();
      expect(doc.toString(), doc.toString());
    });

    test('load non-empty document', () {
      NotusDocument doc = dartconfDoc();
      expect(doc.toPlainText(), 'DartConf\nLos Angeles\n');
    });

    test('document delta must end with line-break character', () {
      Delta delta = new Delta()..insert('DartConf\nLos Angeles');
      expect(() {
        new NotusDocument.fromDelta(delta);
      }, throwsA(const TypeMatcher<AssertionError>()));
    });

    test('lookupLine', () {
      final doc = dartconfDoc();
      doc.format(20, 1, NotusAttribute.bq);
      var line1 = doc.lookupLine(3);
      var line2 = doc.lookupLine(13);

      expect(line1.node, const TypeMatcher<LineNode>());
      expect(line1.node.toPlainText(), 'DartConf\n');
      expect(line2.node, const TypeMatcher<LineNode>());
      expect(line2.node.toPlainText(), 'Los Angeles\n');
    });

    test('format applies heuristics', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      expect(doc.root.children, hasLength(1));
      expect(doc.root.children.first, const TypeMatcher<BlockNode>());
    });

    test('format ignores empty changes', () async {
      NotusDocument doc = dartconfDoc();
      var changeList = doc.changes.toList();
      var change = doc.format(1, 0, NotusAttribute.bold);
      doc.close();
      var changes = await changeList;
      expect(change, isEmpty);
      expect(changes, isEmpty);
    });

    test('format returns actual change delta', () {
      NotusDocument doc = dartconfDoc();
      final change = doc.format(0, 15, NotusAttribute.ul);
      final expectedChange = new Delta()
        ..retain(8)
        ..retain(1, ul)
        ..retain(11)
        ..retain(1, ul);
      expect(change, expectedChange);
    });

    test('format updates document delta', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      final expectedDoc = new Delta()
        ..insert('DartConf')
        ..insert('\n', ul)
        ..insert('Los Angeles')
        ..insert('\n', ul);
      expect(doc.toDelta(), expectedDoc);
    });

    test('format allows zero-length updates', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.ul);
      final expectedDoc = new Delta()
        ..insert('DartConf')
        ..insert('\n', ul)
        ..insert('Los Angeles')
        ..insert('\n');
      expect(doc.toDelta(), expectedDoc);
    });

    test('insert applies heuristics', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      doc.insert(8, '\n');
      expect(doc.root.children, hasLength(1));
      expect(doc.root.children.first, const TypeMatcher<BlockNode>());
    });

    test('insert returns actual change delta', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      final change = doc.insert(8, '\n');
      final expectedChange = new Delta()
        ..retain(8)
        ..insert('\n', ul);
      expect(change, expectedChange);
    });

    test('insert updates document delta', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      doc.insert(8, '\n');
      final expectedDoc = new Delta()
        ..insert('DartConf')
        ..insert('\n\n', ul)
        ..insert('Los Angeles')
        ..insert('\n', ul);
      expect(doc.toDelta(), expectedDoc);
    });

    test('insert throws assert error if change is empty', () {
      NotusDocument doc = dartconfDoc();
      expect(() {
        doc.insert(8, '');
      }, throwsA(const TypeMatcher<AssertionError>()));
    });

    test('replace throws assert error if change is empty', () {
      NotusDocument doc = dartconfDoc();
      expect(() {
        doc.replace(8, 0, '');
      }, throwsA(const TypeMatcher<AssertionError>()));
    });

    test('compose throws assert error if change is empty', () {
      NotusDocument doc = dartconfDoc();
      expect(() {
        doc.compose(new Delta()..retain(1), ChangeSource.local);
      }, throwsA(const TypeMatcher<AssertionError>()));
    });

    test('replace applies heuristic rules', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.h1);
      doc.replace(8, 1, ' ');
      expect(doc.root.children, hasLength(1));
      LineNode line = doc.root.children.first;
      expect(line.style.get(NotusAttribute.heading), NotusAttribute.h1);
      expect(line.toPlainText(), 'DartConf Los Angeles\n');
    });

    test('delete applies heuristic rules', () {
      NotusDocument doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.h1);
      doc.delete(8, 1);
      expect(doc.root.children, hasLength(1));
      LineNode line = doc.root.children.first;
      expect(line.style.get(NotusAttribute.heading), NotusAttribute.h1);
    });

    test('delete which results in an empty change', () {
      // This test relies on a delete rule which ensures line-breaks around
      // and embed.
      NotusDocument doc = dartconfEmbedDoc();
      doc.delete(8, 1);
      expect(doc.toPlainText(), 'DartConf\n${kZeroWidthSpace}\nLos Angeles\n');
    });

    test('checks for closed state', () {
      final doc = dartconfDoc();
      expect(doc.isClosed, isFalse);
      doc.close();
      expect(doc.isClosed, isTrue);
      expect(() {
        doc.compose(new Delta()..insert('a'), ChangeSource.local);
      }, throwsAssertionError);
      expect(() {
        doc.insert(0, 'a');
      }, throwsAssertionError);
      expect(() {
        doc.format(0, 1, NotusAttribute.bold);
      }, throwsAssertionError);
      expect(() {
        doc.delete(0, 1);
      }, throwsAssertionError);
    });

    test('collectStyle', () {
      final doc = dartconfDoc();
      final style = doc.collectStyle(0, 10);
      expect(style, isNotNull);
    });

    test('insert embed after line-break', () {
      final doc = dartconfDoc();
      doc.format(9, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      expect(doc.root.first.toPlainText(), 'DartConf\n');
      expect(doc.root.last.toPlainText(), 'Los Angeles\n');
      LineNode line = doc.root.children.elementAt(1);
      EmbedNode embed = line.first;
      expect(embed.toPlainText(), EmbedNode.kPlainTextPlaceholder);
      final style = new NotusStyle().merge(NotusAttribute.embed.horizontalRule);
      expect(embed.style, style);
    });

    test('insert embed before line-break', () {
      final doc = dartconfDoc();
      doc.format(8, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      expect(doc.root.first.toPlainText(), 'DartConf\n');
      expect(doc.root.last.toPlainText(), 'Los Angeles\n');
      LineNode line = doc.root.children.elementAt(1);
      EmbedNode embed = line.first;
      expect(embed.toPlainText(), EmbedNode.kPlainTextPlaceholder);
      final style = new NotusStyle().merge(NotusAttribute.embed.horizontalRule);
      expect(embed.style, style);
    });

    test('insert embed in the middle of a line', () {
      final doc = dartconfDoc();
      doc.format(4, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(4));
      expect(doc.root.children.elementAt(0).toPlainText(), 'Dart\n');
      expect(doc.root.children.elementAt(1).toPlainText(),
          '${EmbedNode.kPlainTextPlaceholder}\n');
      expect(doc.root.children.elementAt(2).toPlainText(), 'Conf\n');
      expect(doc.root.children.elementAt(3).toPlainText(), 'Los Angeles\n');
      LineNode line = doc.root.children.elementAt(1);
      EmbedNode embed = line.first;
      expect(embed.toPlainText(), EmbedNode.kPlainTextPlaceholder);
      final style = new NotusStyle().merge(NotusAttribute.embed.horizontalRule);
      expect(embed.style, style);
    });

    test('delete embed', () {
      final doc = dartconfDoc();
      doc.format(8, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      doc.delete(9, 1);
      expect(doc.root.children, hasLength(3));
      LineNode line = doc.root.children.elementAt(1);
      expect(line, isEmpty);
    });

    test('insert text containing zero-width space', () {
      final doc = dartconfDoc();
      final change = doc.insert(0, EmbedNode.kPlainTextPlaceholder);
      expect(change, isEmpty);
      expect(doc.length, 21);
    });

    test('insert text before embed', () {
      final doc = dartconfDoc();
      doc.format(8, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      doc.insert(9, 'text');
      expect(doc.root.children, hasLength(4));
      expect(doc.root.children.elementAt(1).toPlainText(), 'text\n');
      expect(doc.root.children.elementAt(2).toPlainText(),
          '${EmbedNode.kPlainTextPlaceholder}\n');
    });

    test('insert text after embed', () {
      final doc = dartconfDoc();
      doc.format(8, 0, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      doc.insert(10, 'text');
      expect(doc.root.children, hasLength(4));
      expect(doc.root.children.elementAt(1).toPlainText(),
          '${EmbedNode.kPlainTextPlaceholder}\n');
      expect(doc.root.children.elementAt(2).toPlainText(), 'text\n');
    });

    test('replace text with embed', () {
      final doc = dartconfDoc();
      doc.format(4, 4, NotusAttribute.embed.horizontalRule);
      expect(doc.root.children, hasLength(3));
      expect(doc.root.children.elementAt(0).toPlainText(), 'Dart\n');
      expect(doc.root.children.elementAt(1).toPlainText(),
          '${EmbedNode.kPlainTextPlaceholder}\n');
      expect(doc.root.children.elementAt(2).toPlainText(), 'Los Angeles\n');
    });
  });
}
