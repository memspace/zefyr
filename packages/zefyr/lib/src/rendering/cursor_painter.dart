// ignore_for_file: omit_local_variable_types

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../widgets/cursor.dart';
import 'editable_box.dart';

const double _kCaretHeightOffset = 2.0; // pixels

/// Paints editing cursor.
class CursorPainter {
  final RenderContentProxyBox editable;
  final CursorStyle style;
  final Rect cursorPrototype;
  final Color effectiveColor;
  final double devicePixelRatio;

  CursorPainter({
    required this.editable,
    required this.style,
    required this.cursorPrototype,
    required this.effectiveColor,
    required this.devicePixelRatio,
  });

  /// Paints cursor on [canvas] at specified [textPosition].
  void paint(Canvas canvas, Offset effectiveOffset, TextPosition textPosition) {
    final paint = Paint()..color = effectiveColor;
    final Offset caretOffset =
        editable.getOffsetForCaret(textPosition, cursorPrototype) +
            effectiveOffset;
    Rect caretRect = cursorPrototype.shift(caretOffset);
    if (style.offset != null) caretRect = caretRect.shift(style.offset!);

    if (caretRect.left < 0.0) {
      // For iOS the cursor may get clipped by the scroll view when
      // it's located at a beginning of a line. We ensure that this
      // does not happen here. This may result in the cursor being painted
      // closer to the character on the right, but it's arguably better
      // then painting clipped cursor (or even cursor completely hidden).
      caretRect = caretRect.shift(Offset(-caretRect.left, 0.0));
    }

    final double? caretHeight = editable.getFullHeightForCaret(textPosition);
    if (caretHeight != null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          final double heightDiff = caretHeight - caretRect.height;
          // Center the caret vertically along the text.
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top + heightDiff / 2,
            caretRect.width,
            caretRect.height,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Override the height to take the full height of the glyph at the TextPosition
          // when not on iOS. iOS has special handling that creates a taller caret.
          // TODO(garyq): See the TODO for _computeCaretPrototype().
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top - _kCaretHeightOffset,
            caretRect.width,
            caretHeight,
          );
          break;
      }
    }

    caretRect = caretRect.shift(_getPixelPerfectCursorOffset(caretRect));

    if (style.radius == null) {
      canvas.drawRect(caretRect, paint);
    } else {
      final RRect caretRRect =
          RRect.fromRectAndRadius(caretRect, style.radius!);
      canvas.drawRRect(caretRRect, paint);
    }
  }

  Offset _getPixelPerfectCursorOffset(Rect caretRect) {
    final Offset caretPosition = editable.localToGlobal(caretRect.topLeft);
    final double pixelMultiple = 1.0 / devicePixelRatio;
    final double pixelPerfectOffsetX = caretPosition.dx.isFinite
        ? (caretPosition.dx / pixelMultiple).round() * pixelMultiple -
            caretPosition.dx
        : caretPosition.dx;
    final double pixelPerfectOffsetY = caretPosition.dy.isFinite
        ? (caretPosition.dy / pixelMultiple).round() * pixelMultiple -
            caretPosition.dy
        : caretPosition.dy;
    return Offset(pixelPerfectOffsetX, pixelPerfectOffsetY);
  }
}
