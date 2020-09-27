import 'package:flutter/material.dart';

import '../rendering/baseline_proxy.dart';

class BaselineProxy extends SingleChildRenderObjectWidget {
  final TextStyle textStyle;
  final EdgeInsets padding;

  BaselineProxy({Key key, Widget child, this.textStyle, this.padding})
      : super(key: key, child: child);

  @override
  RenderBaselineProxy createRenderObject(BuildContext context) {
    return RenderBaselineProxy(
      textStyle: textStyle,
      padding: padding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderBaselineProxy renderObject) {
    renderObject
      ..textStyle = textStyle
      ..padding = padding;
  }
}
