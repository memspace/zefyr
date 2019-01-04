// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most of this code is copied from Flutter SDK due to implementations being
// hidden from public API.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = size.width / 2.0;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class MaterialTextSelectionHandle extends StatelessWidget {
  static const double kHandleSize = 22.0;

  final TextSelectionHandleType type;

  const MaterialTextSelectionHandle({Key key, @required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget handle = Padding(
      padding: const EdgeInsets.only(right: 26.0, bottom: 26.0),
      child: SizedBox(
        width: kHandleSize,
        height: kHandleSize,
        child: CustomPaint(
          painter: _TextSelectionHandlePainter(
              color: Theme.of(context).textSelectionHandleColor),
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform(
            transform: Matrix4.rotationZ(math.pi / 2.0), child: handle);
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return Transform(
            transform: Matrix4.rotationZ(math.pi / 4.0), child: handle);
    }
    assert(type != null);
    return null;
  }
}
