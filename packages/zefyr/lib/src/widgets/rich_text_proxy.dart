import 'package:flutter/widgets.dart';

import '../rendering/paragraph_proxy.dart';

class RichTextProxy extends SingleChildRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  const RichTextProxy({
    Key? key,
    required RichText child,
    required this.textStyle,
    required this.locale,
    required this.strutStyle,
    required this.textAlign,
    this.textScaleFactor = 1.0,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key, child: child);

  final TextStyle textStyle;
  final TextAlign textAlign;
  final double textScaleFactor;
  final Locale? locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
      textStyle: textStyle,
      textDirection: Directionality.of(context),
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
    renderObject.textStyle = textStyle;
    renderObject.textDirection = Directionality.of(context);
    renderObject.textAlign = textAlign;
    renderObject.textScaleFactor = textScaleFactor;
    renderObject.locale = locale;
    renderObject.strutStyle = strutStyle;
    renderObject.textWidthBasis = textWidthBasis;
    renderObject.textHeightBehavior = textHeightBehavior;
  }
}
