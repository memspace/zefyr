// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:notus/notus.dart';
import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';

final ulAttrs = new NotusStyle().merge(NotusAttribute.ul);
final olAttrs = new NotusStyle().merge(NotusAttribute.ol);
final h1Attrs = new NotusStyle().merge(NotusAttribute.h1);

void main() {
  group('$BlockNode', () {
    ContainerNode root;
    setUp(() {
      root = new RootNode();
    });

    test('empty', () {
      BlockNode node = new BlockNode();
      expect(node, isEmpty);
      expect(node.length, 0);
      expect(node.style, new NotusStyle());
    });

    test('toString', () {
      LineNode line = new LineNode();
      line.add(new TextNode('London "Grammar"'));
      BlockNode block = new BlockNode();
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
      BlockNode block = root.first;
      LineNode line = block.children.elementAt(1);
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
      BlockNode block = root.first;
      expect(block.style.get(NotusAttribute.block),
          NotusAttribute.ul);
      expect(block.childCount, 1);
      expect(block.first, const TypeMatcher<LineNode>());

      LineNode line = block.first;
      Delta delta = new Delta()
        ..insert('Hello world')
        ..insert('\n', ulAttrs.toJson());
      expect(line.toDelta(), delta);
    });

    test('format second line as list', () {
      root.insert(0, 'Hello world\nAb cd ef!', null);
      root.retain(21, 1, ulAttrs);

      expect(root.childCount, 2);
      BlockNode block = root.last;
      expect(block.style.get(NotusAttribute.block),
          NotusAttribute.ul);
      expect(block.childCount, 1);
      expect(block.first, const TypeMatcher<LineNode>());
    });

    test('format two sibling lines as list', () {
      root.insert(0, 'Hello world\nAb cd ef!', null);
      root.retain(11, 1, ulAttrs);
      root.retain(21, 1, ulAttrs);

      expect(root.childCount, 1);
      BlockNode block = root.first;
      expect(block.style.get(NotusAttribute.block),
          NotusAttribute.ul);
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
      final expected = new Delta()
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
      final expected = new Delta()
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
      final expected = new Delta()
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

    test('insert line-break at the begining of the document', () {
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
