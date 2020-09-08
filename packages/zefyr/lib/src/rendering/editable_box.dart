import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import '../widgets/selection_utils.dart';

abstract class RenderEditableMetricsProvider implements RenderBox {
  double get preferredLineHeight;

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);
  TextPosition getPositionForOffset(Offset offset);
  double /*?*/ getFullHeightForCaret(
      TextPosition position, Rect caretPrototype);

  TextRange getWordBoundary(TextPosition position);
  TextRange getLineBoundary(TextPosition position);

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  List<TextBox> getBoxesForSelection(TextSelection selection);
}

/// Base class for render boxes of editable content.
///
/// Implementations of this class usually work as a wrapper around
/// regular (non-editable) render boxes which implement
/// [RenderEditableMetricsProvider].
abstract class RenderEditableBox extends RenderBox {
  ContainerNode get node;

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double preferredLineHeight(TextPosition position);

  /// Returns the offset at which to paint the caret.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position);

  /// Returns the position within the text for the given pixel offset.
  ///
  /// The `offset` parameter must be local to this box coordinate system.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset);

  /// Returns the position within the text which is on the line above the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the topmost
  /// line in the text already.
  TextPosition getPositionAbove(TextPosition position);

  /// Returns the position within the text which is on the line below the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the bottommost
  /// line in the text already.
  TextPosition getPositionBelow(TextPosition position);

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  TextRange getWordBoundary(TextPosition position);

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline, if any, is included in the range.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  TextRange getLineBoundary(TextPosition position);

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  // List<TextBox> getBoxesForSelection(TextSelection selection);

  /// Returns a point for the base selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection);

  /// Returns a point for the extent selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection);
}

class EditableContainerParentData
    extends ContainerBoxParentData<RenderEditableBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

/// Multi-child render box of editable content.
class RenderEditableContainerBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderEditableBox,
            EditableContainerParentData>,
        RenderBoxContainerDefaultsMixin<RenderEditableBox,
            EditableContainerParentData> {
  RenderEditableContainerBox({
    List<RenderEditableBox> children,
    @required ContainerNode node,
    @required TextDirection textDirection,
  })  : assert(node != null),
        assert(textDirection != null),
        _node = node,
        _textDirection = textDirection {
    addAll(children);
  }

  ContainerNode get node => _node;
  ContainerNode _node;
  set node(ContainerNode value) {
    assert(value != null);
    if (_node == value) return;
    _node = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! EditableContainerParentData) {
      child.parentData = EditableContainerParentData();
    }
  }

  @override
  void performLayout() {
    assert(() {
      if (!constraints.hasBoundedHeight) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'RenderEditor must have unlimited space along its main axis.'),
        ErrorDescription(
            'RenderEditor does not clip or resize its children, so it must be '
            'placed in a parent that does not constrain the main '
            'axis.'),
        ErrorHint('You probably want to put the RenderEditor inside a '
            'RenderViewport with a matching main axis.')
      ]);
    }());
    assert(() {
      if (constraints.hasBoundedWidth) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'RenderEditor must have a bounded constraint for its cross axis.'),
        ErrorDescription(
            'RenderEditor forces its children to expand to fit the RenderEditor\'s container, '
            'so it must be placed in a parent that constrains the cross '
            'axis to a finite dimension.'),
      ]);
    }());
    var mainAxisExtent = 0.0;
    var child = firstChild;
    final innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final EditableContainerParentData childParentData = child.parentData;
      childParentData.offset = Offset(0.0, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
//    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final EditableContainerParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final EditableContainerParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicMainAxis(
        (RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicMainAxis(
        (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  RenderEditableBox childAtPosition(TextPosition position) {
    assert(firstChild != null);

    final targetNode = node.lookup(position.offset).node;

    var targetChild = firstChild;
    while (targetChild != null) {
      if (targetChild.node == targetNode) {
        break;
      }
      targetChild = childAfter(targetChild);
    }
    assert(targetChild != null);
    return targetChild;
  }

  /// Returns child of this container located at the specified local `offset`.
  ///
  /// If `offset` is above this container (offset.dy is negative) returns
  /// the first child. Likewise, if `offset` is below this container then
  /// returns the last child.
  RenderEditableBox childAtOffset(Offset offset) {
    assert(firstChild != null);

    if (offset.dy <= 0) return firstChild;
    if (offset.dy >= size.height) return lastChild;

    var child = firstChild;
    var dy = 0.0;
    var dx = -offset.dx;
    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }
      dy += child.size.height;
      child = childAfter(child);
    }
    throw StateError('No child at offset $offset.');
  }
}

class RenderEditableTextBlock extends RenderEditableContainerBox
    implements RenderEditableBox {
  ///
  RenderEditableTextBlock({
    List<RenderEditableBox> children,
    @required BlockNode node,
    @required TextDirection textDirection,
  })  : assert(node != null),
        assert(textDirection != null),
        super(
          children: children,
          node: node,
          textDirection: textDirection,
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
    final localPosition = child.getPositionForOffset(offset);
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
    // final paint = Paint()..color = Colors.pink.shade50;
    // final rect = ui.Rect.fromPoints(Offset.zero, size.bottomRight(Offset.zero));
    // context.canvas.drawRect(rect.shift(offset), paint);
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
