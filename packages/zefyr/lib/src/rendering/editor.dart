import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import 'text_line.dart';

// Experiment: instead of trying to create a very flexible multi-child
// container widget, let's try to create a widget similar to RenderParagraph
// but which can actually render the whole document.
// We can take similar approach to what is used in Flutter's TextSpan:
// instead of trying to use NotusDocument to describe widget tree we can
// introduce intermediate representation, e.g. ZefyrTextSpan, similar to
// TextSpan, with two special subclasses: ZefyrLineSpan - for regular paragraphs
// of text, and ZefyrWidgetSpan - for embedded content (images, etc).
// We can then follow the same pattern as in RenderParagraph, where all embed
// elements are added as children of RenderEditor.
// During layout we call layout on all embed children and save their dimensions.
// Then we go over all regular text spans, layout them, add paddings and such,
// and combine with embed dimensions to determine correct position offsets for
// each element.

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
    assert(firstChild != null);

    LineNode line = _document.lookupLine(position).node;
    final queue = Queue<RenderBox>();
    queue.add(this);
    RenderTextLine lineBox;
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      if (c is RenderTextLine) {
        if (c.node == line) {
          lineBox = c;
          break;
        }
      }
      c.visitChildren((child) {
        queue.addLast(child);
      });
    }
    assert(lineBox != null);
    return lineBox.preferredLineHeight();
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
    var mainAxisExtent = 0.0;
    var child = firstChild;
    final innerConstraints =
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
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final EditorParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    var extent = 0.0;
    var child = firstChild;
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
