import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/src/rendering/cursor_painter.dart';

import '../widgets/_cursor.dart';
import '../widgets/selection_utils.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels

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
  List<ui.TextBox> getBoxesForSelection(TextSelection selection);
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

  /// Returns `true` if specified `offset` is within the content boundaries.
  ///
  /// The `offset` parameter must be local to this box coordinate system.
  bool offsetInsideContent(Offset offset);

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
  List<ui.TextBox> getBoxesForSelection(TextSelection selection);
}

class RenderSingleChildEditableBox extends RenderEditableBox
    with RenderObjectWithChildMixin<RenderEditableMetricsProvider> {
  /// Creates new editable paragraph render box.
  RenderSingleChildEditableBox({
    RenderEditableMetricsProvider child,
    @required LineNode node,
    @required EdgeInsetsGeometry padding,
    @required TextDirection textDirection,
    @required CursorController cursorController,
    @required TextSelection selection,
    @required Color selectionColor,
    @required bool enableInteractiveSelection,
    double devicePixelRatio = 1.0,
    // Not implemented fields are below:
    TextAlign textAlign = TextAlign.start,
    bool hasFocus,
    StrutStyle strutStyle,
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
        _selection = selection,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio {
    this.child = child;
  }

  //

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
  Color /*?*/ get selectionColor => _selectionColor;
  Color /*?*/ _selectionColor;
  set selectionColor(Color /*?*/ value) {
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
  bool /*?*/ get enableInteractiveSelection => _enableInteractiveSelection;
  bool /*?*/ _enableInteractiveSelection;
  set enableInteractiveSelection(bool /*?*/ value) {
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
    return enableInteractiveSelection ?? true;
  }

  bool get containsSelection {
    return intersectsWithSelection(_selection);
  }

  /// Returns `true` if this box intersects with document [selection].
  bool intersectsWithSelection(TextSelection selection) {
    final base = node.documentOffset;
    final extent = base + node.length;
    return selectionIntersectsWith(base, extent, selection);
  }

  /// Returns part of [documentSelection] local to this box. May return
  /// `null`.
  ///
  /// [documentSelection] must not be collapsed.
  TextSelection getLocalSelection(TextSelection documentSelection) {
    if (!intersectsWithSelection(documentSelection)) return null;

    final nodeBase = node.documentOffset;
    final nodeExtent = nodeBase + node.length;
    return selectionRestrict(nodeBase, nodeExtent, documentSelection);
  }

  // End selection implementation

  //

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
  double get preferredLineHeight => child.preferredLineHeight;

  /// The [position] parameter is expected to be relative to the [node]'s offset.
  @override
  ui.Offset getOffsetForCaret(ui.TextPosition position) {
    return child.getOffsetForCaret(position, caretPrototype) +
        _resolvedPadding.topLeft;
  }

  /// The [offset] parameter is expected to be local coordinates of this render
  /// object.
  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final shiftedOffset = offset - _resolvedPadding.topLeft;
    return child.getPositionForOffset(shiftedOffset);
  }

  @override
  bool offsetInsideContent(ui.Offset offset) {
    final shiftedOffset = offset - _resolvedPadding.topLeft;
    return child.size.contains(shiftedOffset);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return child.getWordBoundary(position);
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    // As a workaround we do not proxy this call to the child since
    // this render object already represents a single line of text, so
    // we can infer this value from the document node itself.
    // TODO: we can proxy this to the child when getLineBoundary is exposed on RenderParagraph
    return TextRange(start: 0, end: node.length - 1); // do not include "\n"
  }

  @override
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    final boxes = child.getBoxesForSelection(selection);
    return boxes.map((box) {
      return ui.TextBox.fromLTRBD(
        box.left + _resolvedPadding.left,
        box.top + _resolvedPadding.top,
        box.right + _resolvedPadding.left,
        box.bottom + _resolvedPadding.top,
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

  /// We cache containsCursor value because this method depends on the node
  /// state. In some cases the node gets detached from its document before this
  /// render object is detached from the render tree. This causes containsCursor
  /// to fail with an NPE when it's called from [detach].
  bool _containsCursor;
  bool get containsCursor {
    return _containsCursor ??=
        selection.isCollapsed && node.containsOffset(selection.baseOffset);
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

  //

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
    _selectionRects = null;

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

      if (selectionEnabled && containsSelection) {
        final localSelection = getLocalSelection(selection);
        _selectionRects ??= child.getBoxesForSelection(
          localSelection, /*, boxHeightStyle: _selectionHeightStyle, boxWidthStyle: _selectionWidthStyle*/
        );
        _paintSelection(context, effectiveOffset);
      }

      if (containsCursor && !_cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }

      context.paintChild(child, effectiveOffset);

      if (containsCursor && _cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }
    }
  }

  void _paintSelection(PaintingContext context, Offset effectiveOffset) {
    // assert(_textLayoutLastMaxWidth == constraints.maxWidth &&
    //     _textLayoutLastMinWidth == constraints.minWidth,
    // 'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
    assert(_selectionRects != null);
    final paint = Paint()..color = _selectionColor /*!*/;
    for (final box in _selectionRects /*!*/) {
      context.canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
    }
  }

  void _paintCursor(PaintingContext context, Offset effectiveOffset) {
    final cursorOffset = effectiveOffset.translate(-_kCaretGap, 0);
    final position = TextPosition(
      offset: selection.baseOffset - node.documentOffset,
      affinity: selection.base.affinity,
    );
    _cursorPainter.paint(context.canvas, cursorOffset, position);
  }

  // End render box overrides
}

// For multi-child render objects (blocks).
class RenderContainerEditableBox {}
