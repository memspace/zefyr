import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/src/rendering/editable_box.dart';

class TextBlock extends StatelessWidget {
  final BlockNode node;
  final TextDirection textDirection;

  const TextBlock({Key key, this.node, this.textDirection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _EditableBlock(
      node: node,
      textDirection: textDirection,
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    throw UnimplementedError();
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
  RenderEditableBlockBox createRenderObject(BuildContext context) {
    return RenderEditableBlockBox(
      node: node,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableBlockBox renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
  }
}
