// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:notus/notus.dart';
import 'package:test/test.dart';

void main() {
  group('$Node', () {
    RootNode root;
    setUp(() {
      root = RootNode();
    });

    test('mounted', () {
      final line = LineNode();
      final text = TextNode();
      expect(text.mounted, isFalse);
      line.add(text);
      expect(text.mounted, isTrue);
    });

    test('offset', () {
      root.insert(0, 'First line\nSecond line', null);
      expect(root.children.first.offset, 0);
      expect(root.children.elementAt(1).offset, 11);
    });

    test('documentOffset', () {
      root.insert(0, 'First line\nSecond line', null);
      LineNode line = root.children.last;
      TextNode text = line.first;
      expect(line.documentOffset, 11);
      expect(text.documentOffset, 11);
    });

    test('containsOffset', () {
      root.insert(0, 'First line\nSecond line', null);
      LineNode line = root.children.last;
      TextNode text = line.first;
      expect(line.containsOffset(10), isFalse);
      expect(line.containsOffset(12), isTrue);
      expect(text.containsOffset(10), isFalse);
      expect(text.containsOffset(12), isTrue);
    });
  });
}
