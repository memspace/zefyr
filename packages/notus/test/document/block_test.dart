// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

final ulAttrs = NotusStyle().merge(NotusAttribute.ul);
final olAttrs = NotusStyle().merge(NotusAttribute.ol);
final h1Attrs = NotusStyle().merge(NotusAttribute.h1);

void main() {
  group('$BlockNode', () {
    late ContainerNode root;
    setUp(() {
      root = RootNode();
    });

    test('empty', () {
      final node = BlockNode();
      expect(node, isEmpty);
      expect(node.length, 0);
      expect(node.style, NotusStyle());
    });

    test('toString', () {
      final line = LineNode();
      line.add(TextNode('London "Grammar"'));
      final block = BlockNode();
      block.applyAttribute(NotusAttribute.ul);
      block.add(line);
      final expected = '§ {ul}\n  └ ¶ ⟨London "Grammar"⟩ ⏎';
      expect('$block', expected);
    });

    test('unwrapLine from first block', () {
      root.insert(0, 'One\nTwo\nThree', null);
      root.retain(3, 1, ulAttrs);
      root.retain(7, 1, ulAttrs);
      root.retain(13, 1, ulAttrs);
      expect(root.childCount, 1);
      final block = root.first as BlockNode;
      final line = block.children.elementAt(1) as LineNode;
      block.unwrapLine(line);
      expect(root.children, hasLength(3));
      expect(root.children.elementAt(0), const TypeMatcher<BlockNode>());
      expect(root.children.elementAt(1), line);
      expect(root.children.elementAt(2), block);
    });

    test('format first line as list', () {
      root.insert(0, 'Hello world', null);
      root.retain(11, 1, ulAttrs);

      expect(root.childCount, 1);
      final block = root.first as BlockNode;
      expect(block.style.get(NotusAttribute.block), NotusAttribute.ul);
      expect(block.childCount, 1);
      expect(block.first, const TypeMatcher<LineNode>());

      final line = block.first as LineNode;
      final delta = Delta()
        ..insert('Hello world')
        ..insert('\n', ulAttrs.toJson());
      expect(line.toDelta(), delta);
    });

    test('format second line as list', () {
      root.insert(0, 'Hello world\nAb cd ef!', null);
      root.retain(21, 1, ulAttrs);

      expect(root.childCount, 2);
      final block = root.last as BlockNode;
      expect(block.style.get(NotusAttribute.block), NotusAttribute.ul);
      expect(block.childCount, 1);
      expect(block.first, const TypeMatcher<LineNode>());
    });

    test('format two sibling lines as list', () {
      root.insert(0, 'Hello world\nAb cd ef!', null);
      root.retain(11, 1, ulAttrs);
      root.retain(21, 1, ulAttrs);

      expect(root.childCount, 1);
      final block = root.first as BlockNode;
      expect(block.style.get(NotusAttribute.block), NotusAttribute.ul);
      expect(block.childCount, 2);
      expect(block.first, const TypeMatcher<LineNode>());
      expect(block.last, const TypeMatcher<LineNode>());
    });

    test('format to split first line from block', () {
      root.insert(
          0, 'London Grammar Songs\nHey now\nStrong\nIf You Wait', null);
      root.retain(20, 1, h1Attrs);
      root.retain(28, 1, ulAttrs);
      root.retain(35, 1, ulAttrs);
      root.retain(47, 1, ulAttrs);
      expect(root.childCount, 2);
      root.retain(28, 1, olAttrs);
      expect(root.childCount, 3);
      final expected = Delta()
        ..insert('London Grammar Songs')
        ..insert('\n', NotusAttribute.h1.toJson())
        ..insert('Hey now')
        ..insert('\n', NotusAttribute.ol.toJson())
        ..insert('Strong')
        ..insert('\n', ulAttrs.toJson())
        ..insert('If You Wait')
        ..insert('\n', ulAttrs.toJson());
      expect(root.toDelta(), expected);
    });

    test('format to split last line from block', () {
      root.insert(
          0, 'London Grammar Songs\nHey now\nStrong\nIf You Wait', null);
      root.retain(20, 1, h1Attrs);
      root.retain(28, 1, ulAttrs);
      root.retain(35, 1, ulAttrs);
      root.retain(47, 1, ulAttrs);
      expect(root.childCount, 2);
      root.retain(47, 1, olAttrs);
      expect(root.childCount, 3);
      final expected = Delta()
        ..insert('London Grammar Songs')
        ..insert('\n', NotusAttribute.h1.toJson())
        ..insert('Hey now')
        ..insert('\n', ulAttrs.toJson())
        ..insert('Strong')
        ..insert('\n', ulAttrs.toJson())
        ..insert('If You Wait')
        ..insert('\n', NotusAttribute.ol.toJson());
      expect(root.toDelta(), expected);
    });

    test('format to split middle line from block', () {
      root.insert(
          0, 'London Grammar Songs\nHey now\nStrong\nIf You Wait', null);
      root.retain(20, 1, h1Attrs);
      root.retain(28, 1, ulAttrs);
      root.retain(35, 1, ulAttrs);
      root.retain(47, 1, ulAttrs);
      expect(root.childCount, 2);
      root.retain(35, 1, olAttrs);
      expect(root.childCount, 4);
      final expected = Delta()
        ..insert('London Grammar Songs')
        ..insert('\n', NotusAttribute.h1.toJson())
        ..insert('Hey now')
        ..insert('\n', ulAttrs.toJson())
        ..insert('Strong')
        ..insert('\n', NotusAttribute.ol.toJson())
        ..insert('If You Wait')
        ..insert('\n', ulAttrs.toJson());
      expect(root.toDelta(), expected);
    });

    test('insert line-break at the beginning of the document', () {
      root.insert(
          0, 'London Grammar Songs\nHey now\nStrong\nIf You Wait', null);
      root.retain(20, 1, ulAttrs);
      root.retain(28, 1, ulAttrs);
      root.retain(35, 1, ulAttrs);
      root.retain(47, 1, ulAttrs);
      expect(root.childCount, 1);
      root.insert(0, '\n', null);
      expect(root.childCount, 2);
    });
  });
}
