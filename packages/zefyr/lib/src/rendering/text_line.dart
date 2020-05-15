import 'package:flutter/rendering.dart';

/// Base class for rendering a line of text in Zefyr editor.
abstract class RenderTextLine extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {}
