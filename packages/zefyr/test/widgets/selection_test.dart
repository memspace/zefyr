// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_paragraph.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrSelectionOverlay', () {
    testWidgets('double tap caret shows toolbar', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.tapEditor();

      RenderEditableParagraph renderObject =
          tester.firstRenderObject(find.byType(EditableParagraph));
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
      await editor.tapEditor();
      await editor.updateSelection(base: 0, extent: 5);
      expect(editor.findSelectionHandle(), findsNWidgets(2));
      await editor.unfocus();
      expect(editor.findSelectionHandle(), findsNothing);
    });
  });
}
