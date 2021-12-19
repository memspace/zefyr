import 'package:flutter/rendering.dart';

import 'editable_box.dart';

/// Proxy to an arbitrary embeddable [RenderBox].
///
/// Computes necessary editing metrics based on the dimensions of the child
/// render box.
class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderEmbedProxy({RenderBox? child}) : super(child);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final left = selection.extentOffset == 0 ? 0.0 : size.width;
      final right = selection.extentOffset == 0 ? 0.0 : size.width;
      return <TextBox>[
        TextBox.fromLTRBD(left, 0.0, right, size.height, TextDirection.ltr)
      ];
    }
    return <TextBox>[
      TextBox.fromLTRBD(0.0, 0.0, size.width, size.height, TextDirection.ltr)
    ];
  }

  @override
  double getFullHeightForCaret(TextPosition position) {
    return preferredLineHeight;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(position.offset == 0 || position.offset == 1);
    return (position.offset == 0)
        ? Offset.zero
        : Offset(size.width - caretPrototype.width, 0.0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final position = (offset.dx > size.width / 2) ? 1 : 0;
    return TextPosition(offset: position);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return const TextRange(start: 0, end: 1);
  }

  @override
  double get preferredLineHeight => size.height;
}
