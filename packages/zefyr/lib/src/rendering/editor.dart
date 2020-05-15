import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

/// Parent data for use with [RenderEditor].
class EditorParentData extends ContainerBoxParentData<RenderBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

/// Displays its children sequentially along a given axis, forcing them to the
/// dimensions of the parent in the other axis.
class RenderEditor extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, EditorParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, EditorParentData> {
  /// Creates a render object that arranges its children sequentially along a
  /// given axis.
  ///
  /// By default, children are arranged along the vertical axis.
  RenderEditor({
    List<RenderBox> children,
    @required NotusDocument document,
    @required TextDirection textDirection,
    double maxHeight, // if null then expands, otherwise forces constraint
    double minHeight, // if null then ignored, otherwise forces constraint
    TextSelection selection,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
  })  : assert(document != null),
        assert(textDirection != null),
        _document = document {
    addAll(children);
  }

  NotusDocument _document;

  /// Returns preferred line height at specified [position] in text.
  double preferredLineHeight(int position) {
    LineNode line = _document.lookupLine(position).node;
    RenderBox child = firstChild;
    while (child != null) {
      EditorParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    throw UnimplementedError();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! EditorParentData) {
      child.parentData = EditorParentData();
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
    double mainAxisExtent = 0.0;
    RenderBox child = firstChild;
    final BoxConstraints innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final EditorParentData childParentData = child.parentData;
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
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final EditorParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final EditorParentData childParentData = child.parentData;
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

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
