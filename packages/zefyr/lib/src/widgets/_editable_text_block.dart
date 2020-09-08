import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_text_block.dart';
import '_cursor.dart';
import '_editable_text_line.dart';
import '_text_line.dart';

class EditableTextBlock extends StatelessWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;

  const EditableTextBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    @required this.cursorController,
    @required this.selection,
    @required this.selectionColor,
    @required this.enableInteractiveSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _EditableBlock(
      node: node,
      textDirection: textDirection,
      padding: EdgeInsets.only(left: 16, right: 16),
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    return node.children.map((child) {
      return EditableTextLine(
        node: child,
        padding: EdgeInsets.zero,
        leading: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 4.0, color: Colors.grey.shade300),
            ),
          ),
          padding: EdgeInsets.only(left: 16),
        ),
        body: TextLine(
          node: child,
          textDirection: textDirection,
        ),
        cursorController: cursorController,
        selection: selection,
        selectionColor: selectionColor,
        enableInteractiveSelection: enableInteractiveSelection,
      );
    }).toList(growable: false);
  }
}

class _EditableBlock extends MultiChildRenderObjectWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final EdgeInsets padding;

  _EditableBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    this.padding = EdgeInsets.zero,
    @required List<Widget> children,
  }) : super(key: key, children: children);

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: textDirection,
      padding: padding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
    renderObject.padding = padding;
  }
}
