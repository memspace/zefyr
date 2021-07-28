// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/src/widgets/paragraph.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$RawEditor', () {
    testWidgets('allows merging attribute theme data', (tester) async {
      var delta = Delta()
        ..insert(
          'Website',
          NotusAttribute.link.fromString('https://github.com').toJson(),
        )
        ..insert('\n');
      var doc = NotusDocument.fromDelta(delta);
      var theme = ZefyrThemeData(link: TextStyle(color: Colors.red));
      var editor = EditorSandBox(tester: tester, document: doc, theme: theme);
      await editor.pumpAndTap();
      final p =
          tester.widget<ZefyrParagraph>(find.byType(ZefyrParagraph).first);
      expect(p.text.children?.first.style?.color, Colors.red);
    });

    // TODO: Add Icon.keyboard_hide
    testWidgets('collapses selection when unfocused', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 0, extent: 3);
      // expect(editor.findSelectionHandle(), findsNWidgets(2));
      await editor.tapHideKeyboardButton();
      // expect(editor.findSelectionHandle(), findsNothing);
      expect(editor.selection, TextSelection.collapsed(offset: 3));
    }, skip: true);

    testWidgets('toggle enabled state', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 0, extent: 3);
      await editor.disable();
      final widget = tester.widget(find.byType(ZefyrField)) as ZefyrField;
      expect(widget.readOnly, true);
    });
  });
}
