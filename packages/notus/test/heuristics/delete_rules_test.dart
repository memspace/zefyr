// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

final ul = NotusAttribute.ul.toJson();
final bold = NotusAttribute.bold.toJson();

void main() {
  group('$PreserveLineStyleOnMergeRule', () {
    final rule = PreserveLineStyleOnMergeRule();
    test('preserves block style', () {
      final ul = NotusAttribute.ul.toJson();
      final doc = Delta()
        ..insert('Title\nOne')
        ..insert('\n', ul)
        ..insert('Two\n');
      final actual = rule.apply(doc, 9, 1);
      final expected = Delta()
        ..retain(9)
        ..delete(1)
        ..retain(3)
        ..retain(1, ul);
      expect(actual, expected);
    });

    test('resets block style', () {
      final unsetUl = NotusAttribute.block.unset.toJson();
      final doc = Delta()
        ..insert('Title\nOne')
        ..insert('\n', NotusAttribute.ul.toJson())
        ..insert('Two\n');
      final actual = rule.apply(doc, 5, 1);
      final expected = Delta()
        ..retain(5)
        ..delete(1)
        ..retain(3)
        ..retain(1, unsetUl);
      expect(actual, expected);
    });
  });

  group('$CatchAllDeleteRule', () {
    final rule = CatchAllDeleteRule();

    test('applies change as-is', () {
      final doc = Delta()..insert('Document\n');
      final actual = rule.apply(doc, 3, 5);
      final expected = Delta()
        ..retain(3)
        ..delete(5);
      expect(actual, expected);
    });
  });

  group('$EnsureEmbedLineRule', () {
    final rule = EnsureEmbedLineRule();

    test('ensures line-break before embed', () {
      final doc = Delta()
        ..insert('Document\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\n');
      final actual = rule.apply(doc, 8, 1);
      final expected = Delta()..retain(8);
      expect(actual, expected);
    });

    test('ensures line-break after embed', () {
      final doc = Delta()
        ..insert('Document\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\n');
      final actual = rule.apply(doc, 10, 1);
      final expected = Delta()..retain(11);
      expect(actual, expected);
    });

    test('still deletes everything between embeds', () {
      final doc = Delta()
        ..insert('Document\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\nSome text\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\n');
      final actual = rule.apply(doc, 10, 11);
      final expected = Delta()
        ..retain(11)
        ..delete(9);
      expect(actual, expected);
    });

    test('allows deleting empty line after embed', () {
      final doc = Delta()
        ..insert('Document\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\n')
        ..insert('\n', NotusAttribute.block.bulletList.toJson())
        ..insert('Text')
        ..insert('\n');
      final actual = rule.apply(doc, 10, 1);
      final expected = Delta()
        ..retain(11)
        ..delete(1);
      expect(actual, expected);
    });

    test('allows deleting empty line(s) before embed', () {
      final doc = Delta()
        ..insert('Document\n')
        ..insert('\n')
        ..insert('\n')
        ..insert(BlockEmbed.horizontalRule)
        ..insert('\n')
        ..insert('Text')
        ..insert('\n');
      final actual = rule.apply(doc, 11, 1);
      expect(actual, isNull);
    });
  });

  group('$UnsetMentionRule', () {
    final rule = UnsetMentionRule();

    test('no mention attribute overlaps with deletion range', () {
      final doc = Delta()
        ..insert('Text')
        ..insert('@User', NotusAttribute.mention.fromString('1').toJson());
      final actual = rule.apply(doc, 1, 2);
      expect(actual, null);
    });

    test('mention attribute is inside deletion range', () {
      final doc = Delta()
        ..insert('Text')
        ..insert('@User', NotusAttribute.mention.fromString('1').toJson())
        ..insert('Text');
      final actual = rule.apply(doc, 2, 8);
      expect(actual, null);
    });

    test('part of mention attribute is before deletion range', () {
      final doc = Delta()
        ..insert('@User', NotusAttribute.mention.fromString('1').toJson())
        ..insert('Text');
      final actual = rule.apply(doc, 4, 4);
      expect(
          actual,
          Delta()
            ..retain(4, {NotusAttribute.mention.key: null})
            ..delete(4));
    });

    test('part of mention attribute is after deletion range', () {
      final doc = Delta()
        ..insert('Text')
        ..insert('@User', NotusAttribute.mention.fromString('1').toJson());
      final actual = rule.apply(doc, 3, 3);
      expect(
          actual,
          Delta()
            ..retain(3)
            ..delete(3)
            ..retain(3, {NotusAttribute.mention.key: null}));
    });
  });
}
