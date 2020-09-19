// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../testing.dart';

void main() {
  group('ZefyrEditableText', () {
    testWidgets('user input', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      final currentValue = editor.document.toPlainText();
      await enterText(tester, 'Added $currentValue');
      expect(editor.document.toPlainText(), 'Added This House Is A Circus\n');
    });

    testWidgets('autofocus', (tester) async {
      final editor = EditorSandBox(tester: tester, autofocus: true);
      await editor.pump();
      expect(editor.focusNode.hasFocus, isTrue);
    });

    testWidgets('no autofocus', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pump();
      expect(editor.focusNode.hasFocus, isFalse);
    });
  });
}

Future<Null> enterText(WidgetTester tester, String text) async {
  return TestAsyncUtils.guard(() async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    await tester.idle();
  });
}
