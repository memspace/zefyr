import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';
import 'editable_keyboard_listener.dart';

/// Parent data for use with [RenderEditor].
class EditorParentData extends ContainerBoxParentData<RenderEditableBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

/// Base interface for any editable render object.
abstract class RenderAbstractEditor {
  TextSelection get selection;

  TextSelection selectWordAtPosition(TextPosition position);
  TextSelection selectLineAtPosition(TextPosition position);

  /// Returns preferred line height at specified [position] in text.
  double preferredLineHeightAtPosition(TextPosition position);

  Offset getOffsetForCaret(TextPosition position);
  TextPosition getPositionForOffset(Offset offset);
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
    bool hasFocus,
    TextSelection selection,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
  })  : assert(document != null),
        _document = document,
        _selection = selection {
    addAll(children);
    _keyboardListener = EditableKeyboardListener(
        editable: this, onSelectionChanged: _handleKeyboardSelectionChange);
  }

  EditableKeyboardListener _keyboardListener;

  void _handleKeyboardSelectionChange(TextSelection newSelection) {}

  @override
  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    assert(value != null);
    if (_selection == value) {
      return;
    }
    _selection = value;
    markNeedsPaint();
  }

  set document(NotusDocument value) {
    assert(value != null);
    if (_document == value) {
      return;
    }
    _document = value;
    markNeedsLayout();
  }

  NotusDocument _document;

  /// Whether the editor is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value) {
      return;
    }
    _hasFocus = value;
    if (_hasFocus) {
      _keyboardListener.attach();
    } else {
      _keyboardListener.detach();
    }
    markNeedsSemanticsUpdate();
  }

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
    if (_keyboardListener.isAttached) {
      _keyboardListener.detach();
    }
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
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  // RenderEditableObject interface implementation:

  @override
  TextSelection selectWordAtPosition(TextPosition position) {
//    assert(
//    _textLayoutLastMaxWidth == constraints.maxWidth &&
//        _textLayoutLastMinWidth == constraints.minWidth,
//    'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
//    final TextRange word = _textPainter.getWordBoundary(position);
//     When long-pressing past the end of the text, we want a collapsed cursor.
//    if (position.offset >= word.end) {
//      return TextSelection.fromPosition(position);
//    }
    // If text is obscured, the entire sentence should be treated as one word.
//    if (obscureText) {
//      return TextSelection(baseOffset: 0, extentOffset: _plainText.length);
//    }
//    return TextSelection(baseOffset: word.start, extentOffset: word.end);
    throw UnimplementedError();
  }

  @override
  TextSelection selectLineAtPosition(TextPosition position) {
//    assert(
//    _textLayoutLastMaxWidth == constraints.maxWidth &&
//        _textLayoutLastMinWidth == constraints.minWidth,
//    'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).');
//    final TextRange line = _textPainter.getLineBoundary(position);
//    if (position.offset >= line.end)
//      return TextSelection.fromPosition(position);
//    // If text is obscured, the entire string should be treated as one line.
//    if (obscureText) {
//      return TextSelection(baseOffset: 0, extentOffset: _plainText.length);
//    }
//    return TextSelection(baseOffset: line.start, extentOffset: line.end);
    throw UnimplementedError();
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

    var child = firstChild;
    var dy = 0.0;
    while (child != null) {
      if (child.size.contains(offset.translate(0, -dy))) {
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
    return childAtPosition(position).getOffsetForCaret(localPosition);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final child = childAtOffset(offset);
    final BoxParentData parentData = child.parentData;
    final localOffset = offset - parentData.offset;
    return childAtOffset(offset).getPositionForOffset(localOffset);
  }
}
