import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy({
    RenderParagraph child,
    @required TextStyle textStyle,
    @required EdgeInsets padding,
  })  : _prototypePainter = TextPainter(
          text: TextSpan(text: ' ', style: textStyle),
          textDirection: TextDirection.ltr,
        ),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    assert(value != null);
    if (_prototypePainter.text.style == value) return;
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    assert(value != null);
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    final top = _padding?.top ?? 0.0;
    return _prototypePainter.computeDistanceToActualBaseline(baseline) + top;
  }

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}
