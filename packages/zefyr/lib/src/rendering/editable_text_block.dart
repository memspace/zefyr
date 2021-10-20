import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import '../widgets/selection_utils.dart';
import 'editable_box.dart';

// TODO: Move contentPadding to RenderEditableContainerBox as having it here is a bit  messy.
class RenderEditableTextBlock extends RenderEditableContainerBox
    implements RenderEditableBox {
  ///
  RenderEditableTextBlock({
    List<RenderEditableBox>? children,
    required BlockNode node,
    required TextDirection textDirection,
    required EdgeInsetsGeometry padding,
    required Decoration decoration,
    ImageConfiguration configuration = ImageConfiguration.empty,
    EdgeInsets contentPadding = EdgeInsets.zero,
  })  : _decoration = decoration,
        _configuration = configuration,
        _savedPadding = padding,
        _contentPadding = contentPadding,
        super(
          children: children,
          node: node,
          textDirection: textDirection,
          padding: padding.add(contentPadding),
        );

  EdgeInsetsGeometry _savedPadding;
  EdgeInsets _contentPadding;

  set contentPadding(EdgeInsets value) {
    if (_contentPadding == value) return;
    _contentPadding = value;
    super.padding = _savedPadding.add(_contentPadding);
  }

  @override
  set padding(EdgeInsetsGeometry value) {
    super.padding = value.add(_contentPadding);
    _savedPadding = value;
  }

  BoxPainter? _painter;

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  Decoration get decoration => _decoration;
  Decoration _decoration;

  set decoration(Decoration value) {
    if (value == _decoration) return;
    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  /// The settings to pass to the decoration when painting, so that it can
  /// resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ///
  /// The [ImageConfiguration.textDirection] field is also used by
  /// direction-sensitive [Decoration]s for painting and hit-testing.
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;

  set configuration(ImageConfiguration value) {
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

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
    final parentData = child.parentData as BoxParentData;
    return child.getOffsetForCaret(localPosition) + parentData.offset;
  }

  @override
  Rect getLocalRectForCaret(TextPosition position) {
    final child = childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - child.node.offset,
      affinity: position.affinity,
    );
    final parentData = child.parentData as BoxParentData;
    return child.getLocalRectForCaret(localPosition).shift(parentData.offset);
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

  /// This method unlike [RenderEditor.getPositionForOffset] expects the
  /// `offset` parameter to be local to the coordinate system of this render
  /// object.
  @override
  TextPosition getPositionForOffset(Offset offset) {
    final child = childAtOffset(offset);
    final parentData = child.parentData as BoxParentData;
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
    // memoize node's offset since it's not cached by the document.
    final nodeOffset = child.node.offset;
    final childPosition = TextPosition(offset: position.offset - nodeOffset);
    final childWord = child.getWordBoundary(childPosition);
    return TextRange(
      start: childWord.start + nodeOffset,
      end: childWord.end + nodeOffset,
    );
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    assert(position.offset < node.length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.node.offset);
    // ignore: omit_local_variable_types
    TextPosition? result = child.getPositionAbove(childLocalPosition);
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
  TextPosition? getPositionBelow(TextPosition position) {
    assert(position.offset < node.length);

    final child = childAtPosition(position);
    final childLocalPosition =
        TextPosition(offset: position.offset - child.node.offset);
    // ignore: omit_local_variable_types
    TextPosition? result = child.getPositionBelow(childLocalPosition);
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

    final baseParentData = baseChild!.parentData as BoxParentData;
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

    final extentParentData = extentChild!.parentData as BoxParentData;
    final extentSelection =
        localSelection(extentChild.node, selection, fromParent: true);
    var extentPoint =
        extentChild.getExtentEndpointForSelection(extentSelection);
    return TextSelectionPoint(
        extentPoint.point + extentParentData.offset, extentPoint.direction);
  }

  // End RenderEditableBox implementation

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
    // Since we're disposing of our painter, we won't receive change
    // notifications. We mark ourselves as needing paint so that we will
    // resubscribe to change notifications. If we didn't do this, then, for
    // example, animated GIFs would stop animating when a DecoratedBox gets
    // moved around the tree due to GlobalKey reparenting.
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDecoration(context, offset);
    defaultPaint(context, offset);
  }

  void _paintDecoration(PaintingContext context, Offset offset) {
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);

    final decorationPadding = resolvedPadding! - _contentPadding;

    final decorationSize = decorationPadding.deflateSize(size);
    final filledConfiguration = configuration.copyWith(size: decorationSize);
    int? debugSaveCount;
    assert(() {
      debugSaveCount = context.canvas.getSaveCount();
      return true;
    }());

    // We want the decoration to align with the text so we adjust left padding
    // by cursorMargin.
    final decorationOffset =
        offset.translate(decorationPadding.left, decorationPadding.top);
    _painter!.paint(context.canvas, decorationOffset, filledConfiguration);
    assert(() {
      if (debugSaveCount != context.canvas.getSaveCount()) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              '${_decoration.runtimeType} painter had mismatching save and restore calls.'),
          ErrorDescription(
              'Before painting the decoration, the canvas save count was $debugSaveCount. '
              'After painting it, the canvas save count was ${context.canvas.getSaveCount()}. '
              'Every call to save() or saveLayer() must be matched by a call to restore().'),
          DiagnosticsProperty<Decoration>('The decoration was', decoration,
              style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<BoxPainter>('The painter was', _painter,
              style: DiagnosticsTreeStyle.errorProperty),
        ]);
      }
      return true;
    }());
    if (decoration.isComplex) context.setIsComplexHint();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
