// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'caret.dart';
import 'editable_box.dart';
import 'render_context.dart';

class EditableParagraph extends LeafRenderObjectWidget {
  EditableParagraph({
    @required this.node,
    @required this.text,
    @required this.layerLink,
    @required this.renderContext,
    @required this.showCursor,
    @required this.selection,
    @required this.selectionColor,
  }) : assert(renderContext != null);

  final ContainerNode node;
  final TextSpan text;
  final LayerLink layerLink;
  final ZefyrRenderContext renderContext;
  final ValueNotifier<bool> showCursor;
  final TextSelection selection;
  final Color selectionColor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new RenderEditableParagraph(
      text,
      node: node,
      layerLink: layerLink,
      renderContext: renderContext,
      showCursor: showCursor,
      selection: selection,
      selectionColor: selectionColor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderEditableParagraph renderObject) {
    renderObject
      ..text = text
      ..node = node
      ..layerLink = layerLink
      ..renderContext = renderContext
      ..showCursor = showCursor
      ..selection = selection
      ..selectionColor = selectionColor;
  }
}

class RenderEditableParagraph extends RenderParagraph
    implements RenderEditableBox {
  RenderEditableParagraph(
    TextSpan text, {
    @required ContainerNode node,
    @required LayerLink layerLink,
    @required ZefyrRenderContext renderContext,
    @required ValueNotifier<bool> showCursor,
    @required TextSelection selection,
    @required Color selectionColor,
    TextAlign textAlign: TextAlign.start,
    @required TextDirection textDirection,
    bool softWrap: true,
    TextOverflow overflow: TextOverflow.clip,
    double textScaleFactor: 1.0,
    int maxLines,
  })  : _node = node,
        _layerLink = layerLink,
        _renderContext = renderContext,
        _showCursor = showCursor,
        _selection = selection,
        _selectionColor = selectionColor,
        _prototypePainter = new TextPainter(
          text: new TextSpan(text: '.', style: text.style),
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
        ),
        super(
          text,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
        );

  //
  // Public members
  //

  ContainerNode get node => _node;
  ContainerNode _node;
  void set node(ContainerNode value) {
    _node = value;
  }

  LayerLink get layerLink => _layerLink;
  LayerLink _layerLink;
  void set layerLink(LayerLink value) {
    if (_layerLink == value) return;
    _layerLink = value;
  }

  ZefyrRenderContext _renderContext;
  void set renderContext(ZefyrRenderContext value) {
    if (_renderContext == value) return;
    if (attached) _renderContext.removeBox(this);
    _renderContext = value;
    if (attached) _renderContext.addBox(this);
  }

  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value) return;
    if (attached) _showCursor.removeListener(markNeedsPaint);
    _showCursor = value;
    if (attached) _showCursor.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value) return;
    // TODO: check if selection affects this block (also check previous value)
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
  }

  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  double get preferredLineHeight => _prototypePainter.height;

  /// Returns part of document [selection] local to this paragraph. May return
  /// `null`.
  ///
  /// [selection] must not be collapsed.
  TextSelection getLocalSelection(TextSelection selection) {
    if (!_intersectsWithSelection(selection)) return null;

    int nodeBase = node.documentOffset;
    int nodeExtent = nodeBase + node.length;
    int base = math.max(0, selection.baseOffset - nodeBase);
    int extent = math.min(selection.extentOffset, nodeExtent) - nodeBase;
    return _selection.copyWith(baseOffset: base, extentOffset: extent);
  }

  // This method works around some issues in getBoxesForSelection and handleы
  // edge-case with our TextSpan objects not having last line-break character.
  // Wait for https://github.com/flutter/flutter/issues/16418 to be resolved.
  List<ui.TextBox> getEndpointsForSelection(TextSelection selection,
      {bool isLocal: false}) {
    TextSelection local = isLocal ? selection : getLocalSelection(selection);
    if (local.isCollapsed) {
      final offset = getOffsetForCaret(local.extent, _caretPainter.prototype);
      return [
        new ui.TextBox.fromLTRBD(
          offset.dx,
          offset.dy,
          offset.dx,
          offset.dy + _caretPainter.prototype.height,
          TextDirection.ltr,
        )
      ];
    }

    int isBaseShifted = 0;
    bool isExtentShifted = false;
    if (local.baseOffset == node.length - 1 && local.baseOffset > 0) {
      // Since we exclude last line-break from rendered TextSpan we have to
      // handle end-of-line selection explicitly.
      local = local.copyWith(baseOffset: local.baseOffset - 1);
      isBaseShifted = -1;
    } else if (local.baseOffset == 0 && local.isCollapsed) {
      // This takes care of beginning of line position.
      local = local.copyWith(baseOffset: local.baseOffset + 1);
      isBaseShifted = 1;
    }
    if (text.codeUnitAt(local.extentOffset - 1) == 0xA) {
      // This takes care of the rest end-of-line scenarios, where there are
      // actually line-breaks in the TextSpan (e.g. in code blocks).
      local = local.copyWith(extentOffset: local.extentOffset + 1);
      isExtentShifted = true;
    }
    final result = getBoxesForSelection(local).toList();
    if (isBaseShifted != 0) {
      final box = result.first;
      final dx = isBaseShifted == -1 ? box.right : box.left;
      result.removeAt(0);
      result.insert(0,
          new ui.TextBox.fromLTRBD(dx, box.top, dx, box.bottom, box.direction));
    }
    if (isExtentShifted) {
      final box = result.last;
      result.removeLast;
      result.add(new ui.TextBox.fromLTRBD(
          box.left, box.top, box.left, box.bottom, box.direction));
    }
    return result;
  }

  //
  // Overridden members
  //

  @override
  void set text(TextSpan value) {
    _prototypePainter.text = new TextSpan(text: '.', style: value.style);
    _selectionRects = null;
    super.text = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _showCursor.addListener(markNeedsPaint);
    _renderContext.addBox(this);
  }

  @override
  void detach() {
    _showCursor.removeListener(markNeedsPaint);
    _renderContext.removeBox(this);
    super.detach();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTest(HitTestResult result, {Offset position}) {
    if (size.contains(position)) {
      result.add(new BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout(
        minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    _caretPainter.layout(_prototypePainter.height);
    // Indicate to render context that this object can be used by other
    // layers (selection overlay, for instance).
    _renderContext.markDirty(this, false);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_isSelectionVisible) _paintSelection(context, offset);
    super.paint(context, offset);
    if (_isCaretVisible) _paintCaret(context, offset);
  }

  @override
  void markNeedsLayout() {
    // Temporarily remove this object from the render context.
    _renderContext.markDirty(this, true);
    super.markNeedsLayout();
  }

  //
  // Private members
  //

  final TextPainter _prototypePainter;
  final CaretPainter _caretPainter = new CaretPainter();
  List<ui.TextBox> _selectionRects;

  /// Returns `true` if current selection is collapsed, located within
  /// this paragraph and is visible according to tick timer.
  bool get _isCaretVisible {
    if (!_selection.isCollapsed) return false;
    if (!_showCursor.value) return false;

    final int start = node.documentOffset;
    final int end = start + node.length;
    final int caretOffset = _selection.extentOffset;
    return caretOffset >= start && caretOffset < end;
  }

  /// Returns `true` if selection is not collapsed and intersects with this
  /// paragraph.
  bool get _isSelectionVisible {
    if (_selection.isCollapsed) return false;
    return _intersectsWithSelection(_selection);
  }

  /// Returns `true` if this paragraph intersects with document [selection].
  bool _intersectsWithSelection(TextSelection selection) {
    final int base = node.documentOffset;
    final int extent = base + node.length;
    return base <= selection.extentOffset && selection.baseOffset <= extent;
  }

  void _paintCaret(PaintingContext context, Offset offset) {
    final TextPosition caret = new TextPosition(
      offset: _selection.extentOffset - node.documentOffset,
    );
    Offset caretOffset = getOffsetForCaret(caret, _caretPainter.prototype);
    _caretPainter.paint(context.canvas, caretOffset + offset);
  }

  void _paintSelection(PaintingContext context, Offset offset) {
    assert(_isSelectionVisible);
    // TODO: this could be improved by painting additional box for line-break characters.
    _selectionRects ??= getBoxesForSelection(getLocalSelection(_selection));
    final Paint paint = new Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects)
      context.canvas.drawRect(box.toRect().shift(offset), paint);
  }
}
