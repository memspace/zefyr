import 'package:flutter/rendering.dart';

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy({
    required TextStyle textStyle,
    RenderParagraph? child,
    EdgeInsets? padding,
  })  : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textDirection: TextDirection.ltr,
            strutStyle:
                StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true)),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) return;
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  EdgeInsets? _padding;
  set padding(EdgeInsets value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    // This doesn't seem to produce pixel perfect result when used by
    // InputDecorator and its hintText. The hint seems to be painted very
    // slightly above the actual text when user starts typing.
    // TODO: Investigate the discrepancy with input decorator hintText.
    final top = _padding?.top ?? 0.0;
    return _prototypePainter.computeDistanceToActualBaseline(baseline) + top;
  }

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}
