import 'package:flutter/widgets.dart';

import '../rendering/paragraph_proxy.dart';

class ZefyrParagraph extends LeafRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  ZefyrParagraph(
    this.text, {
    this.textStyle,
    required this.textDirection,
    this.textScaleFactor = 1.0,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super();

  final TextSpan text;
  final TextStyle? textStyle;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
      text,
      textStyle: textStyle,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject.text = text;
    renderObject.textStyle = textStyle;
    renderObject.textDirection = textDirection;
    renderObject.textScaleFactor = textScaleFactor;
    renderObject.locale = locale;
    renderObject.strutStyle = strutStyle;
    renderObject.textWidthBasis = textWidthBasis;
    renderObject.textHeightBehavior = textHeightBehavior;
  }
}
