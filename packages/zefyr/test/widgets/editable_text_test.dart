// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrEditableText', () {
    testWidgets('user input', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.tapEditor();
      await enterText(tester, 'Test');
      expect(editor.document.toPlainText(), startsWith('Test'));
    });
  });
}

Future<Null> enterText(WidgetTester tester, String text) async {
  return TestAsyncUtils.guard(() async {
    tester.testTextInput.enterText(text);
    await tester.idle();
  });
}
