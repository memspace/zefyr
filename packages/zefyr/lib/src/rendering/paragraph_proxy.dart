import 'package:flutter/rendering.dart';

import 'editable_box.dart';

/// Proxy to built-in [RenderParagraph] so that it can be used inside Zefyr
/// editor.
class RenderParagraphProxy extends RenderParagraph
    implements RenderContentProxyBox {
  RenderParagraphProxy(
    TextSpan text, {
    TextStyle? textStyle,
    required TextDirection textDirection,
    required double textScaleFactor,
    StrutStyle? strutStyle,
    Locale? locale,
    required TextWidthBasis textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  })  : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textAlign: TextAlign.left,
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            strutStyle: strutStyle,
            locale: locale,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior),
        super(
          text,
          textDirection: textDirection,
          locale: locale,
          overflow: TextOverflow.clip,
          strutStyle: strutStyle,
          textScaleFactor: textScaleFactor,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        );

  final TextPainter _prototypePainter;

  set textStyle(TextStyle? value) {
    if (_prototypePainter.text!.style == value) return;
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  @override
  set textDirection(TextDirection value) {
    if (_prototypePainter.textDirection == value) return;
    _prototypePainter.textDirection = value;
    super.textDirection = value;
  }

  @override
  set textScaleFactor(double value) {
    if (_prototypePainter.textScaleFactor == value) return;
    _prototypePainter.textScaleFactor = value;
    super.textScaleFactor = value;
  }

  @override
  set strutStyle(StrutStyle? value) {
    if (_prototypePainter.strutStyle == value) return;
    _prototypePainter.strutStyle = value;
    super.strutStyle = value;
  }

  @override
  set locale(Locale? value) {
    if (_prototypePainter.locale == value) return;
    _prototypePainter.locale = value;
    super.locale = value;
  }

  @override
  set textWidthBasis(TextWidthBasis value) {
    if (_prototypePainter.textWidthBasis == value) return;
    _prototypePainter.textWidthBasis = value;
    super.textWidthBasis = value;
  }

  @override
  set textHeightBehavior(TextHeightBehavior? value) {
    if (_prototypePainter.textHeightBehavior == value) return;
    _prototypePainter.textHeightBehavior = value;
    super.textHeightBehavior = value;
  }

  @override
  double get preferredLineHeight => _prototypePainter.preferredLineHeight;

}
