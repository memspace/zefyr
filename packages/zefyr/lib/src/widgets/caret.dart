// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';

class CaretPainter {
  static const double _kCaretHeightOffset = 2.0; // pixels
  static const double _kCaretWidth = 1.0; // pixels

  Rect _prototype;

  Rect get prototype => _prototype;

  void layout(double lineHeight) {
    _prototype = new Rect.fromLTWH(
        0.0, 0.0, _kCaretWidth, lineHeight - _kCaretHeightOffset);
  }

  void paint(Canvas canvas, Offset offset) {
    final Paint paint = new Paint()..color = Colors.black;
    final Rect caretRect = _prototype.shift(offset);
    canvas.drawRect(caretRect, paint);
  }
}
