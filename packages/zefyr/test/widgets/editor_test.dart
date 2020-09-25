// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/src/widgets/rich_text.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrEditor', () {
    testWidgets('allows merging attribute theme data', (tester) async {
      var delta = Delta()
        ..insert(
          'Website',
          NotusAttribute.link.fromString('https://github.com').toJson(),
        )
        ..insert('\n');
      var doc = NotusDocument.fromDelta(delta);
      var attributeTheme = AttributeTheme(link: TextStyle(color: Colors.red));
      var theme = ZefyrThemeData(attributeTheme: attributeTheme);
      var editor = EditorSandBox(tester: tester, document: doc, theme: theme);
      await editor.pumpAndTap();
      // TODO: figure out why this extra pump is needed here
      await tester.pumpAndSettle();
      final p =
          tester.widget(find.byType(ZefyrRichText).first) as ZefyrRichText;
      expect(p.text.children.first.style.color, Colors.red);
    });

    testWidgets('collapses selection when unfocused', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 0, extent: 3);
      expect(editor.findSelectionHandle(), findsNWidgets(2));
      await editor.tapHideKeyboardButton();
      expect(editor.findSelectionHandle(), findsNothing);
      expect(editor.selection, TextSelection.collapsed(offset: 3));
    });

    testWidgets('toggle enabled state', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 0, extent: 3);
      await editor.disable();
      final widget = tester.widget(find.byType(ZefyrEditor)) as ZefyrEditor;
      expect(widget.mode, ZefyrMode.view);
    });

    testWidgets('toggle toolbar between two editors', (tester) async {
      final sandbox = MultiEditorSandbox(tester: tester);
      await sandbox.pump();
      await sandbox.tapFirstEditor();
      expect(sandbox.firstFocusNode.hasFocus, isTrue);
      expect(sandbox.secondFocusNode.hasFocus, isFalse);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);

      await sandbox.tapButtonWithIcon(Icons.format_list_bulleted);
      var widget = sandbox.findFirstEditor();
      var line = widget.controller.document.root.children.first;
      expect(line, isInstanceOf<BlockNode>());
      BlockNode block = line;
      expect(block.style.contains(NotusAttribute.block.bulletList), isTrue);

      await sandbox.tapSecondEditor();
      expect(sandbox.firstFocusNode.hasFocus, isFalse);
      expect(sandbox.secondFocusNode.hasFocus, isTrue);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);

      await sandbox.tapButtonWithIcon(Icons.format_list_bulleted);
      widget = sandbox.findSecondEditor();
      line = widget.controller.document.root.children.first;
      expect(line, isInstanceOf<BlockNode>());
      block = line;
      expect(block.style.contains(NotusAttribute.block.bulletList), isTrue);
    });
  });
}
