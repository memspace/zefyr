import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:notus/notus.dart';

import '../widgets/selection_utils.dart';
import 'editable_box.dart';

class RenderEditableTextBlock extends RenderEditableContainerBox
    implements RenderEditableBox {
  ///
  RenderEditableTextBlock({
    List<RenderEditableBox> children,
    @required BlockNode node,
    @required TextDirection textDirection,
    @required EdgeInsetsGeometry padding,
  })  : assert(node != null),
        assert(textDirection != null),
        super(
          children: children,
          node: node,
          textDirection: textDirection,
          padding: padding,
        );

  @override
  TextRange getLineBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final positionInChild = TextPosition(
      offset: position.offset - child.node.offset,
      affinity: position.affinity,
    );
    final rangeInChild = child.getLineBoundary(positionInChild);
    return TextRange(
      start: rangeInChild.start + child.node.offset,
      end: rangeInChild.end + child.node.offset,
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.node.offset,
      affinity: position.affinity,
    );
    final BoxParentData parentData = child.parentData;
    return child.getOffsetForCaret(localPosition) + parentData.offset;
  }

  /// This method unlike [RenderEditor.getPositionForOffset] expects the
  /// `offset` parameter to be local to the coordinate system of this render
  /// object.
  @override
  TextPosition getPositionForOffset(Offset offset) {
    final child = childAtOffset(offset);
    final BoxParentData parentData = child.parentData;
    final localOffset = offset - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);
    return TextPosition(
      offset: localPosition.offset + child.node.offset,
      affinity: localPosition.affinity,
    );
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition =
        TextPosition(offset: position.offset - child.node.offset);
    return child.getWordBoundary(localPosition);
  }

  @override
  TextPosition getPositionAbove(TextPosition position) {
    assert(position.offset < node.length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.node.offset);
    // ignore: omit_local_variable_types
    TextPosition result = child.getPositionAbove(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.node.offset);
    }

    final sibling = childBefore(child);
    if (sibling == null) {
      return null; // There is no more text above `position` in this block.
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testPosition = TextPosition(offset: sibling.node.length - 1);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    final siblingLocalPosition = sibling.getPositionForOffset(finalOffset);
    return TextPosition(
        offset: sibling.node.offset + siblingLocalPosition.offset);
  }

  @override
  TextPosition getPositionBelow(TextPosition position) {
    assert(position.offset < node.length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.node.offset);
    // ignore: omit_local_variable_types
    TextPosition result = child.getPositionBelow(childLocalPosition);
    if (result != null) {
      return TextPosition(offset: result.offset + child.node.offset);
    }

    final sibling = childAfter(child);
    if (sibling == null) {
      return null; // There is no more text below `position` in this block.
    }

    final caretOffset = child.getOffsetForCaret(childLocalPosition);
    final testPosition = TextPosition(offset: 0);
    final testOffset = sibling.getOffsetForCaret(testPosition);
    final finalOffset = Offset(caretOffset.dx, testOffset.dy);
    final siblingLocalPosition = sibling.getPositionForOffset(finalOffset);
    return TextPosition(
        offset: sibling.node.offset + siblingLocalPosition.offset);
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition =
        TextPosition(offset: position.offset - child.node.offset);
    return child.preferredLineHeight(localPosition);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final localOffset = getOffsetForCaret(selection.extent);
      final point =
          Offset(0.0, preferredLineHeight(selection.extent)) + localOffset;
      return TextSelectionPoint(point, null);
    }

    final baseNode = node.lookup(selection.start).node;
    var baseChild = firstChild;
    while (baseChild != null) {
      if (baseChild.node == baseNode) {
        break;
      }
      baseChild = childAfter(baseChild);
    }
    assert(baseChild != null);

    final BoxParentData baseParentData = baseChild.parentData;
    final baseSelection =
        localSelection(baseChild.node, selection, fromParent: true);
    var basePoint = baseChild.getBaseEndpointForSelection(baseSelection);
    return TextSelectionPoint(
        basePoint.point + baseParentData.offset, basePoint.direction);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final localOffset = getOffsetForCaret(selection.extent);
      final point =
          Offset(0.0, preferredLineHeight(selection.extent)) + localOffset;
      return TextSelectionPoint(point, null);
    }

    final extentNode = node.lookup(selection.end).node;

    var extentChild = firstChild;
    while (extentChild != null) {
      if (extentChild.node == extentNode) {
        break;
      }
      extentChild = childAfter(extentChild);
    }
    assert(extentChild != null);

    final BoxParentData extentParentData = extentChild.parentData;
    final extentSelection =
        localSelection(extentChild.node, selection, fromParent: true);
    var extentPoint =
        extentChild.getExtentEndpointForSelection(extentSelection);
    return TextSelectionPoint(
        extentPoint.point + extentParentData.offset, extentPoint.direction);
  }

  // End RenderEditableBox implementation

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
