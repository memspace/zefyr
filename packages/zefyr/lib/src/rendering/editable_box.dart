import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

/// A common interface to render boxes which represent a piece of rich text
/// content.
///
/// See also:
///   * [RenderParagraphProxy] implementation of this interface which wraps
///     built-in [RenderParagraph]
///   * [RenderEmbedProxy] implementation of this interface which wraps
///     an arbitrary render box representing an embeddable object.
abstract class RenderContentProxyBox implements RenderBox {
  double get preferredLineHeight;

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);

  TextPosition getPositionForOffset(Offset offset);

  double? getFullHeightForCaret(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

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
/// [RenderContentProxyBox].
abstract class RenderEditableBox extends RenderBox {
  /// The document node represented by this render box.
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

  /// Returns the position relative to the [node] content
  ///
  /// The `position` must be within the [node] content
  TextPosition globalToLocalPosition(TextPosition position);

  /// Returns the position within the text which is on the line above the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the topmost
  /// line in the text already.
  TextPosition? getPositionAbove(TextPosition position);

  /// Returns the position within the text which is on the line below the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the bottommost
  /// line in the text already.
  TextPosition? getPositionBelow(TextPosition position);

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

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition position);

  /// Returns the [Rect] of the caret prototype at the given text
  /// position. [Rect] starts at origin.
  Rect getCaretPrototype(TextPosition position);
}

class EditableContainerParentData
    extends ContainerBoxParentData<RenderEditableBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

/// Multi-child render box of editable content.
///
/// Common ancestor for [RenderEditor] and [RenderEditableTextBlock].
class RenderEditableContainerBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderEditableBox,
            EditableContainerParentData>,
        RenderBoxContainerDefaultsMixin<RenderEditableBox,
            EditableContainerParentData> {
  RenderEditableContainerBox({
    List<RenderEditableBox>? children,
    required ContainerNode node,
    required TextDirection textDirection,
    required EdgeInsetsGeometry padding,
  })  : assert(padding.isNonNegative),
        _node = node,
        _textDirection = textDirection,
        _padding = padding {
    addAll(children);
  }

  ContainerNode get node => _node;
  ContainerNode _node;

  set node(ContainerNode value) {
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

  // Start padding implementation

  /// The amount to pad the children in each dimension.
  ///
  /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
  /// must not be null.
  EdgeInsetsGeometry get padding => _padding;
  EdgeInsetsGeometry _padding;

  set padding(EdgeInsetsGeometry value) {
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedsPaddingResolution();
  }

  EdgeInsets? get resolvedPadding => _resolvedPadding;
  EdgeInsets? _resolvedPadding;

  void resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
    _resolvedPadding = _resolvedPadding!.copyWith(left: _resolvedPadding!.left);

    assert(_resolvedPadding!.isNonNegative);
  }

  void _markNeedsPaddingResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  // End padding implementation

  /// Returns child of this container at specified `position` in text.
  ///
  /// The `position` parameter is expected to be relative to the [node] of
  /// this container.
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
    assert(targetChild != null, 'No child at position $position');
    return targetChild!;
  }

  /// Returns child of this container located at the specified local `offset`.
  ///
  /// If `offset` is above this container (offset.dy is negative) returns
  /// the first child. Likewise, if `offset` is below this container then
  /// returns the last child.
  RenderEditableBox childAtOffset(Offset offset) {
    assert(firstChild != null);
    resolvePadding();

    if (offset.dy <= _resolvedPadding!.top) return firstChild!;
    if (offset.dy >= size.height - _resolvedPadding!.bottom) return lastChild!;

    var child = firstChild;
    var dy = _resolvedPadding!.top;
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

  // Start RenderBox overrides

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
            'RenderEditableContainerBox must have unlimited space along its main axis.'),
        ErrorDescription(
            'RenderEditableContainerBox does not clip or resize its children, so it must be '
            'placed in a parent that does not constrain the main '
            'axis.'),
        ErrorHint(
            'You probably want to put the RenderEditableContainerBox inside a '
            'RenderViewport with a matching main axis.')
      ]);
    }());
    assert(() {
      if (constraints.hasBoundedWidth) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'RenderEditableContainerBox must have a bounded constraint for its cross axis.'),
        ErrorDescription(
            'RenderEditableContainerBox forces its children to expand to fit the RenderEditableContainerBox\'s container, '
            'so it must be placed in a parent that constrains the cross '
            'axis to a finite dimension.'),
      ]);
    }());

    resolvePadding();
    assert(_resolvedPadding != null);

    var mainAxisExtent = _resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth)
            .deflate(_resolvedPadding!);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = child.parentData as EditableContainerParentData;
      childParentData.offset = Offset(_resolvedPadding!.left, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += _resolvedPadding!.bottom;
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
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    return _getIntrinsicCrossAxis((RenderBox child) {
      final childHeight = math.max(0.0, height - verticalPadding);
      return child.getMinIntrinsicWidth(childHeight) + horizontalPadding;
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    return _getIntrinsicCrossAxis((RenderBox child) {
      final childHeight = math.max(0.0, height - verticalPadding);
      return child.getMaxIntrinsicWidth(childHeight) + horizontalPadding;
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    return _getIntrinsicMainAxis((RenderBox child) {
      final childWidth = math.max(0.0, width - horizontalPadding);
      return child.getMinIntrinsicHeight(childWidth) + verticalPadding;
    });
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    return _getIntrinsicMainAxis((RenderBox child) {
      final childWidth = math.max(0.0, width - horizontalPadding);
      return child.getMaxIntrinsicHeight(childWidth) + verticalPadding;
    });
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    resolvePadding();
    return defaultComputeDistanceToFirstActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }
}
