import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_box.dart';
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
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    return node.children.map((child) {
      return EditableTextLine(
        node: child,
        padding: EdgeInsets.zero,
        leading: VerticalDivider(
          color: Colors.grey.shade200,
          width: 16,
          thickness: 4,
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

  _EditableBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    @required List<Widget> children,
  }) : super(key: key, children: children);

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
  }
}
