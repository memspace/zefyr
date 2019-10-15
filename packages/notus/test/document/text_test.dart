// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';

final boldStyle = NotusStyle().merge(NotusAttribute.bold);
final boldUnsetStyle = NotusStyle().put(NotusAttribute.bold.unset);
final italicStyle = NotusStyle().merge(NotusAttribute.italic);

void main() {
  group('$TextNode', () {
    LineNode line;
    TextNode node;

    setUp(() {
      line = LineNode();
      node = TextNode('London "Grammar"');
      line.add(node);
    });

    test('new empty text', () {
      final node = TextNode();
      expect(node.value, isEmpty);
      expect(node.length, 0);
      expect(node.style, NotusStyle());
      expect(node.toDelta(), isEmpty);
    });

    test('toString', () {
      node.applyAttribute(NotusAttribute.bold);
      node.applyAttribute(NotusAttribute.link.fromString('link'));
      expect('$node', '⟨London "Grammar"⟩ab');
    });

    test('new text with contents', () {
      expect(node.value, isNotEmpty);
      expect(node.length, 16);
      expect(node.toDelta().toList(), [Operation.insert('London "Grammar"')]);
    });

    test('insert at the end', () {
      node.insert(16, '!!!', null);
      expect(node.value, 'London "Grammar"!!!');
    });

    test('delete tail', () {
      node.delete(6, 10);
      expect(node.value, 'London');
    });

    test('format substring', () {
      node.retain(8, 7, boldStyle);
      expect(line.children, hasLength(3));
      expect(line.children.elementAt(0), hasLength(8));
      expect(line.children.elementAt(1), hasLength(7));
      expect(line.children.elementAt(2), hasLength(1));
    });

    test('format full segment', () {
      node.retain(0, 16, boldStyle);
      expect(line.childCount, 1);
      expect(node.value, 'London "Grammar"');
      expect(node.style.values, [NotusAttribute.bold]);
    });

    test('format with multiple styles', () {
      line.retain(0, 6, boldStyle);
      line.retain(0, 6, italicStyle);
      expect(line.childCount, 2);
    });

    test('format to remove attribute', () {
      line.retain(0, 6, boldStyle);
      line.retain(0, 6, boldUnsetStyle);
      expect(line.childCount, 1);

      expect(node.value, 'London "Grammar"');
      expect(node.style, isEmpty);
    });

    test('format intersecting nodes', () {
      line.retain(0, 6, boldStyle);
      line.retain(3, 10, italicStyle);
      expect(line.childCount, 4);
      expect(line.children.elementAt(0), hasLength(3));
      expect(line.children.elementAt(1), hasLength(3));
      expect(line.children.elementAt(2), hasLength(7));
      expect(line.children.elementAt(3), hasLength(3));
    });

    test('insert in formatted node', () {
      line.retain(0, 6, boldStyle);
      expect(line.childCount, 2);
      line.insert(3, 'don', null);
      expect(line.childCount, 4);
      final b = boldStyle.toJson();
      expect(
        line.children.elementAt(0).toDelta(),
        Delta()..insert('Lon', b),
      );
      expect(
        line.children.elementAt(1).toDelta(),
        Delta()..insert('don'),
      );
      expect(
        line.children.elementAt(2).toDelta(),
        Delta()..insert('don', b),
      );
    });
  });
}
