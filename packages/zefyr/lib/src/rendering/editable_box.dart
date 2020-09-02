import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/src/rendering/cursor_painter.dart';

import '../widgets/_cursor.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels

abstract class RenderEditableMetricsProvider implements RenderBox {
  double get preferredLineHeight;

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype);
  TextPosition getPositionForOffset(Offset offset);
  double /*?*/ getFullHeightForCaret(
      TextPosition position, Rect caretPrototype);
}

/// Base class for render boxes of editable content.
///
/// Implementations of this class usually work as a wrapper around
/// regular (non-editable) render boxes which implement
/// [RenderEditableMetricsProvider].
abstract class RenderEditableBox extends RenderBox {
  Node get node;
  double get preferredLineHeight;
  Rect get caretPrototype;

  Offset getOffsetForCaret(TextPosition position);
  TextPosition getPositionForOffset(Offset offset);
}

class RenderSingleChildEditableBox extends RenderEditableBox
    with RenderObjectWithChildMixin<RenderEditableMetricsProvider> {
  /// Creates new editable paragraph render box.
  RenderSingleChildEditableBox({
    RenderEditableMetricsProvider child,
    @required LineNode node,
    @required EdgeInsetsGeometry padding,
    @required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    @required CursorController cursorController,
    TextSelection selection,
    double devicePixelRatio = 1.0,
    // TODO fields are below:
    bool hasFocus,
    StrutStyle strutStyle,
    Color selectionColor,
    double textScaleFactor = 1.0,
//    this.onSelectionChanged,
//    this.onCaretChanged,
//    this.ignorePointer = false,
    bool readOnly = false,
    bool forceLine = true,
    TextHeightBehavior textHeightBehavior,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    Locale locale,
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    bool enableInteractiveSelection,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
    Clip clipBehavior = Clip.hardEdge,
//    @required this.textSelectionDelegate,
//    @required LayerLink startHandleLayerLink,
//    @required LayerLink endHandleLayerLink,
//    TextRange promptRectRange,
//    Color promptRectColor,
  })  : assert(node != null),
        assert(padding != null),
        assert(padding.isNonNegative),
        assert(cursorController != null),
        assert(devicePixelRatio != null),
        _textDirection = textDirection,
        _padding = padding,
        _node = node,
        _cursorController = cursorController,
        _devicePixelRatio = devicePixelRatio,
        _selection = selection {
    this.child = child;
  }

  // Start RenderEditableBox implementation

  @override
  LineNode get node => _node;
  LineNode _node;
  set node(LineNode value) {
    assert(value != null);
    if (_node == value) {
      return;
    }
    _node = value;
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

  @override
  double get preferredLineHeight => child.preferredLineHeight;

  @override
  ui.Offset getOffsetForCaret(ui.TextPosition position) {
    return child.getOffsetForCaret(position, caretPrototype) +
        _resolvedPadding.topLeft;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final shiftedOffset = offset - _resolvedPadding.topLeft;
    return child.getPositionForOffset(shiftedOffset);
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
    assert(value != null);
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedsPaddingResolution();
  }

  EdgeInsets _resolvedPadding;

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
    _resolvedPadding =
        _resolvedPadding.copyWith(left: _resolvedPadding.left + _caretMargin);

    assert(_resolvedPadding.isNonNegative);
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
    assert(value != null);
    if (_cursorController == value) return;
    // TODO: unsubscribe from old controller updates
//    if (attached) _showCursor.removeListener(_markNeedsPaintIfContainsCursor);
    _cursorController = value;
    // TODO: subscribe to new controller updates
//    if (attached) _showCursor.addListener(_markNeedsPaintIfContainsCursor);
    markNeedsLayout();
  }

  double get _caretMargin => _kCaretGap + cursorWidth;
  double get cursorWidth => _cursorController.style.width;
  double get cursorHeight =>
      _cursorController.style.height ?? preferredLineHeight;

  bool get containsCursor {
    return selection.isCollapsed && node.containsOffset(selection.baseOffset);
  }

  @override
  Rect get caretPrototype => _caretPrototype;
  /*late*/ Rect _caretPrototype;

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
    assert(defaultTargetPlatform != null);
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
        _caretPrototype = Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth,
            cursorHeight - 2.0 * _kCaretHeightOffset);
        break;
    }
  }

  // End caret implementation

  // Start selection implementation

  List<ui.TextBox> _selectionRects;

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
    if (attached && containsCursor) {
      _cursorController.removeListener(markNeedsLayout);
      _cursorController.cursorColor.removeListener(markNeedsPaint);
    }
    _selection = value;
    _selectionRects = null;
    if (attached && containsCursor) {
      _cursorController.addListener(markNeedsLayout);
      _cursorController.cursorColor.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  // End selection implementation

  // Start render box overrides

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    if (containsCursor) {
      _cursorController.addListener(markNeedsLayout);
      _cursorController.cursorColor.addListener(markNeedsPaint);
    }
  }

  @override
  void detach() {
    if (containsCursor) {
      _cursorController.removeListener(markNeedsLayout);
      _cursorController.cursorColor.removeListener(markNeedsPaint);
    }
    super.detach();
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();
    final totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final totalVerticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null) {
      return child.getMaxIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    }
    return totalHorizontalPadding;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    final totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final totalVerticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null) {
      return child.getMinIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    }
    return totalVerticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    final totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final totalVerticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null) {
      return child.getMaxIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    }
    return totalVerticalPadding;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _resolvePadding();
    assert(_resolvedPadding != null);
    if (child == null) {
      size = constraints.constrain(Size(
        _resolvedPadding.left + _resolvedPadding.right,
        _resolvedPadding.top + _resolvedPadding.bottom,
      ));
      return;
    }
    final innerConstraints = constraints.deflate(_resolvedPadding);
    child.layout(innerConstraints, parentUsesSize: true);
    final childParentData = child.parentData as BoxParentData;
    childParentData.offset =
        Offset(_resolvedPadding.left, _resolvedPadding.top);
    size = constraints.constrain(Size(
      _resolvedPadding.left + child.size.width + _resolvedPadding.right,
      _resolvedPadding.top + child.size.height + _resolvedPadding.bottom,
    ));
    _computeCaretPrototype();
  }

  CursorPainter get _cursorPainter => CursorPainter(
        editable: child,
        style: _cursorController.style,
        cursorPrototype: _caretPrototype,
        effectiveColor: _cursorController.cursorColor.value,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final childParentData = child.parentData as BoxParentData;
      final effectiveOffset = offset + childParentData.offset;

      if (containsCursor && !_cursorController.style.paintAboveText) {
        final cursorOffset = effectiveOffset.translate(-_kCaretGap, 0);
        final position = TextPosition(
          offset: selection.baseOffset - node.documentOffset,
          affinity: selection.base.affinity,
        );
        _cursorPainter.paint(context.canvas, cursorOffset, position);
      }

      context.paintChild(child, effectiveOffset);

      if (containsCursor && _cursorController.style.paintAboveText) {
        final cursorOffset = effectiveOffset.translate(-_kCaretGap, 0);
        final position = TextPosition(
          offset: selection.baseOffset - node.documentOffset,
          affinity: selection.base.affinity,
        );
        _cursorPainter.paint(context.canvas, cursorOffset, position);
      }
    }
  }

  // End render box overrides
}

// For multi-child render objects (blocks).
class RenderContainerEditableBox {}
