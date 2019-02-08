// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/rich_text.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrSelectionOverlay', () {
    testWidgets('double tap caret shows toolbar', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();

      RenderZefyrParagraph renderObject =
          tester.firstRenderObject(find.byType(ZefyrRichText));
      var offset = renderObject.localToGlobal(Offset.zero);
      offset += Offset(5.0, 5.0);
      await tester.tapAt(offset);
      await tester.pumpAndSettle();
      await tester.tapAt(offset);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
    });

    testWidgets('hides when editor lost focus', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 0, extent: 5);
      expect(editor.findSelectionHandle(), findsNWidgets(2));
      await editor.unfocus();
      expect(editor.findSelectionHandle(), findsNothing);
    });

    testWidgets('tap on padding area finds closest paragraph', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      editor.controller
          .updateSelection(new TextSelection.collapsed(offset: 10));
      await tester.pumpAndSettle();
      expect(editor.controller.selection.extentOffset, 10);

      RenderZefyrParagraph renderObject =
          tester.firstRenderObject(find.byType(ZefyrRichText));
      var offset = renderObject.localToGlobal(Offset.zero);
      offset += Offset(-5.0, 5.0);
      await tester.tapAt(offset);
      await tester.pumpAndSettle();
      expect(editor.controller.selection.isCollapsed, isTrue);
      expect(editor.controller.selection.extentOffset, 0);
    });

    testWidgets('tap on empty space finds closest paragraph', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      editor.controller.replaceText(10, 1, '\n',
          selection: new TextSelection.collapsed(offset: 0));
      await tester.pumpAndSettle();
      expect(editor.controller.document.toPlainText(),
          'This House\nIs A Circus\n');
      expect(editor.controller.selection.extentOffset, 0);

      RenderBox renderObject =
          tester.firstRenderObject(find.byType(ZefyrEditableText));
      var offset = renderObject.localToGlobal(Offset.zero);
      offset += Offset(50.0, renderObject.size.height - 500.0);
      await tester.tapAt(offset);
      await tester.pumpAndSettle();
      expect(editor.controller.selection.isCollapsed, isTrue);
      expect(editor.controller.selection.extentOffset,
          13); // Note that this is probably too fragile.

      offset = renderObject.localToGlobal(Offset.zero) + Offset(50.0, 1.0);
      await tester.tapAt(offset);
      await tester.pumpAndSettle();
      expect(editor.controller.selection.isCollapsed, isTrue);
      expect(editor.controller.selection.extentOffset,
          2); // Note that this is probably too fragile.
    });
  });
}
