import 'package:flutter/rendering.dart';

import 'editable_box.dart';

/// Proxy to built-in [RenderParagraph] so that it can be used inside Zefyr
/// editor.
class RenderParagraphProxy extends RenderProxyBox
    implements RenderEditableMetricsProvider {
  RenderParagraphProxy({RenderParagraph child}) : super(child);

  @override
  RenderParagraph get child => super.child;

  // TODO: submit a PR to Flutter to expose RenderParagraph.preferredLineHeight
  // TODO: replace with RenderParagraph.preferredLineHeight when exposed
  @override
  double get preferredLineHeight => child.preferredLineHeight;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    return child.getOffsetForCaret(position, caretPrototype);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return child.getPositionForOffset(offset);
  }

  @override
  double getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
    return child.getFullHeightForCaret(position, caretPrototype);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return child.getWordBoundary(position);
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    throw UnimplementedError();
  }
}
