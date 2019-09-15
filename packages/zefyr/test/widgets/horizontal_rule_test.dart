// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrHorizontalRule', () {
    testWidgets('format as horizontal rule', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.remove);

      LineNode line = editor.document.root.children.last;
      expect(line.hasEmbed, isTrue);
    });

    testWidgets('tap left side of horizontal rule puts caret before it',
        (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.remove);
      await editor.updateSelection(base: 0, extent: 0);

      await tester.tapAt(tester.getTopLeft(find.byType(ZefyrHorizontalRule)));
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.isCollapsed, isTrue);
      expect(editor.selection.extentOffset, embed.documentOffset);
    });

    testWidgets('tap right side of horizontal rule puts caret after it',
        (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.remove);
      await editor.updateSelection(base: 0, extent: 0);

      final hr = find.byType(ZefyrHorizontalRule);
      final offset = tester.getBottomRight(hr) - Offset(1.0, 1.0);
      await tester.tapAt(offset);
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.isCollapsed, isTrue);
      expect(editor.selection.extentOffset, embed.documentOffset + 1);
    });

    testWidgets('selects on long press', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.remove);
      await editor.updateSelection(base: 0, extent: 0);

      final hr = find.byType(ZefyrHorizontalRule);
      await tester.longPress(hr);
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.baseOffset, embed.documentOffset);
      expect(editor.selection.extentOffset, embed.documentOffset + 1);
    });
  });
}
