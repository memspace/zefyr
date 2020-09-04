import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';

/// Parent data for use with [RenderEditor].
class EditorParentData extends ContainerBoxParentData<RenderEditableBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

/// Base interface for any editable render object.
abstract class RenderAbstractEditor {
  TextSelection selectWordAtPosition(TextPosition position);
  TextSelection selectLineAtPosition(TextPosition position);

  /// Returns preferred line height at specified `position` in text.
  double preferredLineHeightAtPosition(TextPosition position);

  Offset getOffsetForCaret(TextPosition position);
  TextPosition getPositionForOffset(Offset offset);

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection);
}

/// Displays its children sequentially along a given axis, forcing them to the
/// dimensions of the parent in the other axis.
class RenderEditor extends RenderBox
    with
        ContainerRenderObjectMixin<RenderEditableBox, EditorParentData>,
        RenderBoxContainerDefaultsMixin<RenderEditableBox, EditorParentData>
    implements RenderAbstractEditor {
  /// Creates a render object that arranges its children sequentially along a
  /// given axis.
  ///
  /// By default, children are arranged along the vertical axis.
  RenderEditor({
    List<RenderEditableBox> children,
    @required NotusDocument document,
    @required TextDirection textDirection,
    @required bool hasFocus,
    @required TextSelection selection,
    @required LayerLink startHandleLayerLink,
    @required LayerLink endHandleLayerLink,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
  })  : assert(document != null),
        assert(textDirection != null),
        assert(hasFocus != null),
        _document = document,
        _textDirection = textDirection,
        _hasFocus = hasFocus,
        _selection = selection,
        _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink {
    addAll(children);
  }

  NotusDocument _document;
  set document(NotusDocument value) {
    assert(value != null);
    if (_document == value) {
      return;
    }
    _document = value;
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

  /// Whether the editor is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value) {
      return;
    }
    _hasFocus = value;
    markNeedsSemanticsUpdate();
  }

  /// The region of text that is selected, if any.
  ///
  /// The caret position is represented by a collapsed selection.
  ///
  /// If [selection] is null, there is no selection and attempts to
  /// manipulate the selection will throw.
  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value) return;
    _selection = value;
    markNeedsPaint();
  }

  /// The [LayerLink] of start selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
  LayerLink get startHandleLayerLink => _startHandleLayerLink;
  LayerLink _startHandleLayerLink;
  set startHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value) return;
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The [LayerLink] of end selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
  LayerLink get endHandleLayerLink => _endHandleLayerLink;
  LayerLink _endHandleLayerLink;
  set endHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value) return;
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  /// Track whether position of the start of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "Hello", then scrolls so only "World" is visible, this will become false.
  /// If the user scrolls back so that the "H" is visible again, this will
  /// become true.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  /// Track whether position of the end of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "World", then scrolls so only "Hello" is visible, this will become
  /// 'false'. If the user scrolls back so that the "d" is visible again, this
  /// will become 'true'.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  @override
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    // _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);

    TextSelection localSelection(
        RenderEditableBox box, TextSelection selection) {
      final documentOffset = box.node.documentOffset;
      final base = math.max(selection.start - documentOffset, 0);
      final extent =
          math.min(selection.end - documentOffset, box.node.length - 1);
      return selection.copyWith(
        baseOffset: base,
        extentOffset: extent,
      );
    }

    if (selection.isCollapsed) {
      final child = childAtPosition(selection.extent);
      final localPosition = TextPosition(
          offset: selection.extentOffset - child.node.documentOffset);
      final localOffset = child.getOffsetForCaret(localPosition);
      final BoxParentData parentData = child.parentData;
      final start = Offset(0.0, child.preferredLineHeight) +
          localOffset +
          parentData.offset;
      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final startChild = childAtPosition(TextPosition(offset: selection.start));
      final startSelection = localSelection(startChild, selection);
      final BoxParentData startParentData = startChild.parentData;
      Offset start;
      TextDirection startDirection;
      if (startSelection.isCollapsed) {
        final localOffset = startChild.getOffsetForCaret(startSelection.extent);
        start = Offset(0.0, startChild.preferredLineHeight) +
            localOffset +
            startParentData.offset;
      } else {
        final startBoxes = startChild.getBoxesForSelection(startSelection);
        start = Offset(startBoxes.first.start, startBoxes.first.bottom) +
            startParentData.offset;
        startDirection = startBoxes.first.direction;
      }

      final endChild = childAtPosition(TextPosition(offset: selection.end));
      final BoxParentData endParentData = endChild.parentData;
      final endSelection = localSelection(endChild, selection);

      Offset end;
      TextDirection endDirection;
      if (endSelection.isCollapsed) {
        final localOffset = endChild.getOffsetForCaret(endSelection.extent);
        end = Offset(0.0, endChild.preferredLineHeight) +
            localOffset +
            endParentData.offset;
      } else {
        final endBoxes = endChild.getBoxesForSelection(endSelection);
        end = Offset(endBoxes.last.end, endBoxes.last.bottom) +
            endParentData.offset;
        endDirection = endBoxes.last.direction;
      }

      return <TextSelectionPoint>[
        TextSelectionPoint(start, startDirection),
        TextSelectionPoint(end, endDirection),
      ];
    }
  }

  // Start RenderBox implementation

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
//    _tap = TapGestureRecognizer(debugOwner: this)
//      ..onTapDown = _handleTapDown
//      ..onTap = _handleTap;
//    _longPress = LongPressGestureRecognizer(debugOwner: this)..onLongPress = _handleLongPress;
//    _offset.addListener(markNeedsPaint);
//    _showCursor.addListener(markNeedsPaint);
  }

  @override
  void detach() {
//    _tap.dispose();
//    _longPress.dispose();
//    _offset.removeListener(markNeedsPaint);
//    _showCursor.removeListener(markNeedsPaint);
    super.detach();
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
    _paintHandleLayers(context, getEndpointsForSelection(selection));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  void _paintHandleLayers(
      PaintingContext context, List<TextSelectionPoint> endpoints) {
    var startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink, offset: startPoint),
      super.paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      var endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink, offset: endPoint),
        super.paint,
        Offset.zero,
      );
    }
  }

  // RenderEditableObject interface implementation:

  @override
  TextSelection selectWordAtPosition(TextPosition position) {
//    assert(
//    _textLayoutLastMaxWidth == constraints.maxWidth &&
//        _textLayoutLastMinWidth == constraints.minWidth,
//    'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final child = childAtPosition(position);
    final documentOffset = child.node.documentOffset;
    final localPosition = TextPosition(
        offset: position.offset - documentOffset, affinity: position.affinity);
    final localWord = child.getWordBoundary(localPosition);
    final word = TextRange(
      start: localWord.start + documentOffset,
      end: localWord.end + documentOffset,
    );
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  @override
  TextSelection selectLineAtPosition(TextPosition position) {
//    assert(
//    _textLayoutLastMaxWidth == constraints.maxWidth &&
//        _textLayoutLastMinWidth == constraints.minWidth,
//    'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    final child = childAtPosition(position);
    final documentOffset = child.node.documentOffset;
    final localPosition = TextPosition(
        offset: position.offset - documentOffset, affinity: position.affinity);
    final localLineRange = child.getLineBoundary(localPosition);
    final line = TextRange(
      start: localLineRange.start + documentOffset,
      end: localLineRange.end + documentOffset,
    );

    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= line.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  RenderEditableBox childAtPosition(TextPosition position) {
    assert(firstChild != null);

    final line = _document.lookupLine(position.offset).node;

    var child = firstChild;
    RenderEditableBox renderObject;
    while (child != null) {
      if (child.node is LineNode) {
        final LineNode childLine = child.node;
        if (childLine == line) {
          renderObject = child;
          break;
        }
      } else {
        final BlockNode blockNode = child.node;
        if (line.parent == blockNode) {
          renderObject = child;
          break;
        }
      }
      child = childAfter(child);
    }
    assert(renderObject != null);
    return renderObject;
  }

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

  @override
  double preferredLineHeightAtPosition(TextPosition position) {
    return childAtPosition(position).preferredLineHeight;
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.node.documentOffset,
      affinity: position.affinity,
    );
    // TODO: this might need to shift the offset from the child's local coordinates.
    return childAtPosition(position).getOffsetForCaret(localPosition);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final local = globalToLocal(offset);
    final child = childAtOffset(local);

    final BoxParentData parentData = child.parentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);
    return TextPosition(
      offset: localPosition.offset + child.node.documentOffset,
      affinity: localPosition.affinity,
    );
  }
}
