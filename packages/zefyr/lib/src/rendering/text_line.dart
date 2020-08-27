import 'package:flutter/rendering.dart';
import 'package:zefyr/zefyr.dart';

/// Base class for rendering a line of text in Zefyr editor.
abstract class RenderTextLine extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {
  LineNode get node => _node;
  LineNode _node;

  double preferredLineHeight();
}
