// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

final boldStyle = NotusStyle().merge(NotusAttribute.bold);
final boldUnsetStyle = NotusStyle().put(NotusAttribute.bold.unset);
final italicStyle = NotusStyle().merge(NotusAttribute.italic);

void main() {
  group('TextNode', () {
    late LineNode line;
    late TextNode node;

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

    test('toPlainText', () {
      final node = TextNode('London');
      expect(node.toPlainText(), 'London');
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

  group('EmbeddableObject', () {
    test('equality', () {
      final embed1 = EmbeddableObject('hr', inline: false);
      final embed2 = EmbeddableObject('hr', inline: false);
      final embed3 = EmbeddableObject('image', inline: false);
      expect(embed1, embed2);
      expect(embed1, isNot(equals(embed3)));
    });

    test('hashCode', () {
      final embed1 = EmbeddableObject('hr', inline: false);
      final embed2 = EmbeddableObject('hr', inline: false);
      final embed3 = EmbeddableObject('image', inline: false);
      final set = <EmbeddableObject>{};
      set.addAll([embed1, embed2, embed3]);
      expect(set, hasLength(2));
      expect(set, contains(embed1));
      expect(set, contains(embed2));
      expect(set, contains(embed3));
    });

    test('json serialization', () {
      final embed = EmbeddableObject('hr', inline: false);
      final json = jsonEncode(embed);
      expect(json, '{"_type":"hr","_inline":false}');
      expect(EmbeddableObject.fromJson(jsonDecode(json)), embed);
    });
  });

  group('EmbedNode', () {
    late LineNode line;
    late EmbedNode node;

    setUp(() {
      line = LineNode();
      line.insert(0, EmbeddableObject('hr', inline: false), null);
      node = line.children.first as EmbedNode;
    });

    test('toPlainText', () {
      expect(node.toPlainText(), EmbedNode.kObjectReplacementCharacter);
    });

    test('length', () {
      expect(node.length, 1);
    });

    test('toDelta', () {
      expect(node.toDelta(),
          Delta()..insert(EmbeddableObject('hr', inline: false).toJson()));
    });

    test('splitAt', () {
      expect(node.splitAt(0), node);
      expect(node.splitAt(1), isNull);
    });

    test('cutAt', () {
      expect(node.cutAt(0), node);
      line.insert(0, EmbeddableObject('hr', inline: false), null);
      node = line.children.first as EmbedNode;
      expect(node.cutAt(1), isNull);
    });

    test('isolate', () {
      expect(node.isolate(0, 1), node);
    });
  });

  group('LeafNode', () {
    test('factory constructor', () {
      final embed = LeafNode(EmbeddableObject('hr', inline: false));
      final text = LeafNode('Text');
      expect(embed, isA<EmbedNode>());
      expect(text, isA<TextNode>());
    });

    test('applyStyle allows inline styles only', () {
      final text = LeafNode('Text');
      final style = NotusStyle().put(NotusAttribute.block.numberList);

      expect(() => text.applyStyle(style),
          throwsA(const TypeMatcher<AssertionError>()));
    });
  });
}
