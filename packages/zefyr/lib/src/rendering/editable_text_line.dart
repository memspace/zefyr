import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import '../widgets/cursor.dart';
import '../widgets/selection_utils.dart';
import 'cursor_painter.dart';
import 'editable_box.dart';

const double _kCursorHeightOffset = 2.0; // pixels

enum TextLineSlot { leading, body }

class RenderEditableTextLine extends RenderEditableBox {
  /// Creates new editable paragraph render box.
  RenderEditableTextLine({
    // RenderEditableMetricsProvider child,
    required LineNode node,
    required EdgeInsetsGeometry padding,
    required TextDirection textDirection,
    required CursorController cursorController,
    required TextSelection selection,
    required Color selectionColor,
    required bool enableInteractiveSelection,
    required bool hasFocus,
    double devicePixelRatio = 1.0,
    // Not implemented fields are below:
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
//    TextRange promptRectRange,
//    Color promptRectColor,
  })  : assert(padding.isNonNegative),
        _textDirection = textDirection,
        _padding = padding,
        _node = node,
        _cursorController = cursorController,
        _selection = selection,
        _selectionColor = selectionColor,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio,
        _hasFocus = hasFocus;

  //

  // Start selection implementation

  List<TextBox>? _selectionRects;

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
    final hadSelection = containsSelection;
    if (attached && containsCursor) {
      _cursorController.removeListener(markNeedsLayout);
      _cursorController.cursorColor.removeListener(markNeedsPaint);
    }
    _selection = value;
    _selectionRects = null;
    _containsCursor = null;
    if (attached && containsCursor) {
      _cursorController.addListener(markNeedsLayout);
      _cursorController.cursorColor.addListener(markNeedsPaint);
    }

    if (hadSelection || containsSelection) {
      markNeedsPaint();
    }
  }

  /// The color to use when painting the selection.
  Color get selectionColor => _selectionColor;
  Color _selectionColor;

  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    if (containsSelection) markNeedsPaint();
  }

  /// Whether to allow the user to change the selection.
  ///
  /// Since this render object does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// This field is used by [selectionEnabled] (which then controls
  /// the accessibility hints mentioned above).
  bool get enableInteractiveSelection => _enableInteractiveSelection;
  bool _enableInteractiveSelection;

  set enableInteractiveSelection(bool value) {
    if (_enableInteractiveSelection == value) return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate(); // TODO: should probably update semantics on the RenderEditor instead.
  }

  /// Whether interactive selection are enabled based on the value of
  /// [enableInteractiveSelection].
  ///
  /// If [enableInteractiveSelection] is not set then defaults to `true`.
  bool get selectionEnabled {
    return enableInteractiveSelection;
  }

  bool get containsSelection {
    return intersectsWithSelection(node, _selection);
  }

  // End selection implementation

  //

  /// Whether the editor is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;

  set hasFocus(bool value) {
    if (_hasFocus == value) {
      return;
    }
    _hasFocus = value;
  }

  /// The pixel ratio of the current device.
  ///
  /// Should be obtained by querying MediaQuery for the devicePixelRatio.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  set devicePixelRatio(double value) {
    if (devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsTextLayout();
  }

  final Map<TextLineSlot, RenderBox> children = <TextLineSlot, RenderBox>{};

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading!;
    }
    if (_body != null) {
      yield _body!;
    }
  }

  RenderBox? get leading => _leading;
  RenderBox? _leading;

  set leading(RenderBox? value) {
    _leading = _updateChild(_leading, value, TextLineSlot.leading);
  }

  RenderContentProxyBox? get body => _body;
  RenderContentProxyBox? _body;

  set body(RenderContentProxyBox? value) {
    _body =
        _updateChild(_body, value, TextLineSlot.body) as RenderContentProxyBox?;
  }

  RenderBox? _updateChild(
      RenderBox? oldChild, RenderBox? newChild, TextLineSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      children.remove(slot);
    }
    if (newChild != null) {
      children[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  // Start RenderEditableBox implementation

  @override
  LineNode get node => _node;
  LineNode _node;

  set node(LineNode value) {
    if (_node == value) {
      return;
    }
    _node = value;
    _containsCursor = null;
    markNeedsLayout();
  }

  /// The text direction with which to resolve [padding].
  ///
  /// This may be changed to null, but only after the [padding] has been changed
  /// to a value that does not depend on the direction.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedsPaddingResolution();
  }

  @override
  double preferredLineHeight(TextPosition position) {
    // For single line nodes this value is constant because we're using the same
    // text painter.
    return body!.preferredLineHeight;
  }

  /// The [position] parameter is expected to be relative to the [node] content.
  @override
  Offset getOffsetForCaret(TextPosition position) {
    final parentData = body!.parentData as BoxParentData;
    return body!.getOffsetForCaret(position, _caretPrototype) +
        parentData.offset;
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final caretOffset = getOffsetForCaret(position);
    var rect =
        Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight).shift(caretOffset);
    final cursorOffset = _cursorController.style.offset;
    // Add additional cursor offset (generally only if on iOS).
    if (cursorOffset != null) rect = rect.shift(cursorOffset);
    return rect;
  }

  @override
  TextPosition globalToLocalPosition(TextPosition position) {
    assert(node.containsOffset(position.offset),
        'The provided text position is not in the current node');
    return TextPosition(
      offset: position.offset - node.documentOffset,
      affinity: position.affinity,
    );
  }

  /// The [offset] parameter is expected to be local coordinates of this render
  /// object.
  @override
  TextPosition getPositionForOffset(Offset offset) {
    final parentData = body!.parentData as BoxParentData;
    final shiftedOffset = offset - parentData.offset;
    return body!.getPositionForOffset(shiftedOffset);
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    assert(position.offset < node.length);
    final parentData = body!.parentData as BoxParentData;

    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point.
    final caretOffset = getOffsetForCaret(position);
    final dy = -0.5 * preferredLineHeight(position);
    final abovePositionOffset = caretOffset.translate(0, dy);
    if (!body!.size.contains(abovePositionOffset - parentData.offset)) {
      // We're outside of the body so there is no text above to check.
      return null;
    }
    return getPositionForOffset(abovePositionOffset);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < node.length);
    final parentData = body!.parentData as BoxParentData;

    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line below is 1.5 lines below that
    // point.
    final caretOffset = getOffsetForCaret(position);
    final dy = 1.5 * preferredLineHeight(position);
    final belowPositionOffset = caretOffset.translate(0, dy);
    if (!body!.size.contains(belowPositionOffset - parentData.offset)) {
      // We're outside of the body so there is no text below to check.
      return null;
    }
    return getPositionForOffset(belowPositionOffset);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return body!.getWordBoundary(position);
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    // getOffsetForCaret returns top-left corner of the caret. To find all
    // selection boxes on the same line we shift caret offset by 0.5 of
    // preferredLineHeight so that it's in the middle of the line and filter out
    // boxes which do not include this offset on the Y axis.
    final caret = getOffsetForCaret(position);
    final lineDy = caret.translate(0.0, 0.5 * preferredLineHeight(position)).dy;
    final boxes = getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: node.length - 1));
    final lineBoxes = boxes
        .where((element) => element.top < lineDy && element.bottom > lineDy)
        .toList(growable: false);
    final start = getPositionForOffset(Offset(lineBoxes.first.left, lineDy));
    final end = getPositionForOffset(Offset(lineBoxes.last.right, lineDy));
    return TextRange(start: start.offset, end: end.offset);
  }

  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final localOffset = getOffsetForCaret(selection.extent);
      final point =
          Offset(0.0, preferredLineHeight(selection.extent)) + localOffset;
      return TextSelectionPoint(point, null);
    }
    final boxes = getBoxesForSelection(selection);
    assert(boxes.isNotEmpty);
    return TextSelectionPoint(
        Offset(boxes.first.start, boxes.first.bottom), boxes.first.direction);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final localOffset = getOffsetForCaret(selection.extent);
      final point =
          Offset(0.0, preferredLineHeight(selection.extent)) + localOffset;
      return TextSelectionPoint(point, null);
    }
    final boxes = getBoxesForSelection(selection);
    assert(boxes.isNotEmpty);
    return TextSelectionPoint(
        Offset(boxes.last.end, boxes.last.bottom), boxes.last.direction);
  }

  List<TextBox> getBoxesForSelection(TextSelection selection) {
    final parentData = body!.parentData as BoxParentData;
    final boxes = body!.getBoxesForSelection(selection);
    return boxes.map((box) {
      return TextBox.fromLTRBD(
        box.left + parentData.offset.dx,
        box.top + parentData.offset.dy,
        box.right + parentData.offset.dx,
        box.bottom + parentData.offset.dy,
        box.direction,
      );
    }).toList(growable: false);
  }

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
//    _textLayoutLastMaxWidth = null;
//    _textLayoutLastMinWidth = null;
    markNeedsLayout();
  }

  // End RenderEditableBox implementation

  //

  // Start padding implementation

  /// The amount to pad the child in each dimension.
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

  EdgeInsets? _resolvedPadding;

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
    assert(_resolvedPadding!.isNonNegative);
  }

  void _markNeedsPaddingResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  // End padding implementation

  //

  // Start cursor implementation

  CursorController _cursorController;

  set cursorController(CursorController value) {
    if (_cursorController == value) return;
    // TODO: unsubscribe from old controller updates
//    if (attached) _showCursor.removeListener(_markNeedsPaintIfContainsCursor);
    _cursorController = value;
    // TODO: subscribe to new controller updates
//    if (attached) _showCursor.addListener(_markNeedsPaintIfContainsCursor);
    markNeedsLayout();
  }

  double get cursorWidth => _cursorController.style.width;

  double get cursorHeight =>
      _cursorController.style.height ??
      // hard code position to 0 here but it really doesn't matter since it's
      // the same for the entire paragraph of text.
      preferredLineHeight(TextPosition(offset: 0));

  /// We cache containsCursor value because this method depends on the node
  /// state. In some cases the node gets detached from its document before this
  /// render object is detached from the render tree. This causes containsCursor
  /// to fail with an NPE when it's called from [detach].
  bool? _containsCursor;

  bool get containsCursor {
    return _containsCursor ??=
        selection.isCollapsed && node.containsOffset(selection.baseOffset);
  }

  late Rect _caretPrototype;

  // TODO(garyq): This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  /// On iOS, the cursor is taller than the cursor on Android. The height
  /// of the cursor for iOS is approximate and obtained through an eyeball
  /// comparison.
  void _computeCaretPrototype() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _caretPrototype =
            Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight + 2);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _caretPrototype = Rect.fromLTWH(0.0, _kCursorHeightOffset, cursorWidth,
            cursorHeight - 2.0 * _kCursorHeightOffset);
        break;
    }
  }

  // End caret implementation

  //

  // Start render box overrides

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
    if (containsCursor) {
      _cursorController.addListener(markNeedsLayout);
      _cursorController.cursorColor.addListener(markNeedsPaint);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
    if (containsCursor) {
      _cursorController.removeListener(markNeedsLayout);
      _cursorController.cursorColor.removeListener(markNeedsPaint);
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final value = <DiagnosticsNode>[];
    void add(RenderBox? child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(leading, 'leading');
    add(body, 'body');
    return value;
  }

  @override
  bool get sizedByParent => false;

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = leading == null
        ? 0
        : leading!.getMinIntrinsicWidth(height - verticalPadding);
    final bodyWidth = body == null
        ? 0
        : body!.getMinIntrinsicWidth(math.max(0.0, height - verticalPadding));
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = leading == null
        ? 0
        : leading!.getMaxIntrinsicWidth(height - verticalPadding);
    final bodyWidth = body == null
        ? 0
        : body!.getMaxIntrinsicWidth(math.max(0.0, height - verticalPadding));
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (body != null) {
      return body!
              .getMinIntrinsicHeight(math.max(0.0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (body != null) {
      return body!
              .getMaxIntrinsicHeight(math.max(0.0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    // The baseline of this widget is the baseline of the body.
    return body!.getDistanceToActualBaseline(baseline)! + _resolvedPadding!.top;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _selectionRects = null;

    _resolvePadding();
    assert(_resolvedPadding != null);

    if (body == null && leading == null) {
      size = constraints.constrain(Size(
        _resolvedPadding!.left + _resolvedPadding!.right,
        _resolvedPadding!.top + _resolvedPadding!.bottom,
      ));
      return;
    }
    final innerConstraints = constraints.deflate(_resolvedPadding!);

    final indentWidth = textDirection == TextDirection.ltr
        ? _resolvedPadding!.left
        : _resolvedPadding!.right;

    body!.layout(innerConstraints, parentUsesSize: true);
    final bodyParentData = body!.parentData as BoxParentData;
    bodyParentData.offset =
        Offset(_resolvedPadding!.left, _resolvedPadding!.top);

    if (leading != null) {
      final leadingConstraints = innerConstraints.copyWith(
          minWidth: indentWidth,
          maxWidth: indentWidth,
          maxHeight: body!.size.height);
      leading!.layout(leadingConstraints, parentUsesSize: true);
      final parentData = leading!.parentData as BoxParentData;
      parentData.offset = Offset(0.0, _resolvedPadding!.top);
    }

    size = constraints.constrain(Size(
      _resolvedPadding!.left + body!.size.width + _resolvedPadding!.right,
      _resolvedPadding!.top + body!.size.height + _resolvedPadding!.bottom,
    ));

    _computeCaretPrototype();
  }

  CursorPainter get _cursorPainter => CursorPainter(
        editable: body!,
        style: _cursorController.style,
        cursorPrototype: _caretPrototype,
        effectiveColor: _cursorController.cursorColor.value,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (leading != null) {
      final parentData = leading!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      context.paintChild(leading!, effectiveOffset);
    }

    if (body != null) {
      final parentData = body!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      if (selectionEnabled && containsSelection) {
        final local = localSelection(node, selection);
        _selectionRects ??= body!.getBoxesForSelection(
          local, /*, boxHeightStyle: _selectionHeightStyle, boxWidthStyle: _selectionWidthStyle*/
        );
        _paintSelection(context, effectiveOffset);
      }

      if (hasFocus &&
          _cursorController.showCursor.value &&
          containsCursor &&
          !_cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }

      context.paintChild(body!, effectiveOffset);

      if (hasFocus &&
          _cursorController.showCursor.value &&
          containsCursor &&
          _cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }
    }
  }

  void _paintSelection(PaintingContext context, Offset effectiveOffset) {
    // assert(_textLayoutLastMaxWidth == constraints.maxWidth &&
    //     _textLayoutLastMinWidth == constraints.minWidth,
    // 'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    assert(_selectionRects != null);
    final paint = Paint()..color = _selectionColor;
    for (final box in _selectionRects!) {
      context.canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
    }
  }

  void _paintCursor(PaintingContext context, Offset effectiveOffset) {
    final position = TextPosition(
      offset: selection.extentOffset - node.documentOffset,
      affinity: selection.base.affinity,
    );
    _cursorPainter.paint(context.canvas, effectiveOffset, position);
  }

// End render box overrides
}
