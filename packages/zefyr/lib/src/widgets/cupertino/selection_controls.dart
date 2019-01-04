// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most of this code is copied from Flutter SDK due to implementations being
// hidden from public API.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

// Padding around the line at the edge of the text selection that has 0 width and
// the height of the text font.
const double _kHandlesPadding = 18.0;

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const Color _kHandlesColor = Color(0xFF136FE0);

/// Draws a single text selection handle with a bar and a ball.
///
/// Draws from a point of origin somewhere inside the size of the painter
/// such that the ball is below the point of origin and the bar is above the
/// point of origin.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.origin});

  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _kHandlesColor
      ..strokeWidth = 2.0;
    // Draw circle below the origin that slightly overlaps the bar.
    canvas.drawCircle(origin.translate(0.0, 4.0), 5.5, paint);
    // Draw up from origin leaving 10 pixels of margin on top.
    canvas.drawLine(
      origin,
      origin.translate(
        0.0,
        -(size.height - 2.0 * _kHandlesPadding),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) =>
      origin != oldPainter.origin;
}

class CupertinoTextSelectionHandle extends StatelessWidget {
  final TextSelectionHandleType type;
  final double textLineHeight;

  const CupertinoTextSelectionHandle(
      {Key key, @required this.type, @required this.textLineHeight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize =
        Size(2.0 * _kHandlesPadding, textLineHeight + 2.0 * _kHandlesPadding);
    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          // We give the painter a point of origin that's at the bottom baseline
          // of the selection cursor position.
          //
          // We give it in the form of an offset from the top left of the
          // SizedBox.
          origin: Offset(_kHandlesPadding, textLineHeight + _kHandlesPadding),
        ),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType
          .left: // The left handle is upside down on iOS.
        return Transform(
            transform: Matrix4.rotationZ(math.pi)
              ..translate(-_kHandlesPadding, -_kHandlesPadding),
            child: handle);
      case TextSelectionHandleType.right:
        return Transform(
            transform: Matrix4.translationValues(
                -_kHandlesPadding, -(textLineHeight + _kHandlesPadding), 0.0),
            child: handle);
      case TextSelectionHandleType
          .collapsed: // iOS doesn't draw anything for collapsed selections.
        return Container();
    }
    assert(type != null);
    return null;
  }
}
