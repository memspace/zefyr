// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrCode', () {
    testWidgets('format as code', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.code);

      BlockNode block = editor.document.root.children.first;
      expect(block.style.get(NotusAttribute.block), NotusAttribute.block.code);
    });
  });
}
