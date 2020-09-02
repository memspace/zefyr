import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_box.dart';
import '_cursor.dart';
import '_text_line.dart';

/// Line of editable text in Zefyr editor.
///
/// This widget adds editing features to the otherwise static [TextLine] widget.
class EditableTextLine extends SingleChildRenderObjectWidget {
  final LineNode node;
  final EdgeInsetsGeometry padding;
  final TextDirection textDirection;
  final CursorController cursorController;
  final TextSelection selection;

  /// Creates an editable line of text represented by [node].
  EditableTextLine({
    Key key,
    @required this.node,
    @required this.padding,
    this.textDirection,
    @required TextLine child,
    @required this.cursorController,
    this.selection,
  })  : assert(node != null),
        assert(padding != null),
        assert(child != null),
        assert(cursorController != null),
        super(key: key, child: child);

  @override
  RenderSingleChildEditableBox createRenderObject(BuildContext context) {
    return RenderSingleChildEditableBox(
      node: node,
      padding: padding,
      textDirection: textDirection,
      cursorController: cursorController,
      selection: selection,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant RenderSingleChildEditableBox renderObject) {
    renderObject.node = node;
    renderObject.padding = padding;
    renderObject.textDirection = textDirection;
    renderObject.cursorController = cursorController;
    renderObject.selection = selection;
  }
}
