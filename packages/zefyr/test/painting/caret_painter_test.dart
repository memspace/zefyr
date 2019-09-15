// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/caret.dart';

void main() {
  group('$CursorPainter', () {
    test('prototype is null before layout', () {
      var painter = CursorPainter(Colors.black);
      expect(painter.prototype, isNull);
    });

    test('prototype is set after layout', () {
      var painter = CursorPainter(Colors.black);
      painter.layout(16.0);
      expect(painter.prototype, Rect.fromLTWH(0.0, 0.0, 1.0, 14.0));
    });
  });
}
