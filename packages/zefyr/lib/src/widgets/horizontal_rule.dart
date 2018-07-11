// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'caret.dart';
import 'editable_box.dart';
import 'render_context.dart';

class HorizontalRule extends LeafRenderObjectWidget {
  HorizontalRule({
    @required this.node,
    @required this.layerLink,
    @required this.renderContext,
    @required this.showCursor,
    @required this.selection,
    @required this.selectionColor,
  }) : assert(renderContext != null);

  final ContainerNode node;
  final LayerLink layerLink;
  final ZefyrRenderContext renderContext;
  final ValueNotifier<bool> showCursor;
  final TextSelection selection;
  final Color selectionColor;

  @override
  RenderHorizontalRule createRenderObject(BuildContext context) {
    return new RenderHorizontalRule(
      node: node,
      layerLink: layerLink,
      renderContext: renderContext,
      showCursor: showCursor,
      selection: selection,
      selectionColor: selectionColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderHorizontalRule renderObject) {
    renderObject
      ..node = node
      ..layerLink = layerLink
      ..renderContext = renderContext
      ..showCursor = showCursor
      ..selection = selection
      ..selectionColor = selectionColor;
  }
}

class RenderHorizontalRule extends RenderBox implements RenderEditableBox {
  static const kPaddingBottom = 24.0;
  static const kWidth = 3.0;

  RenderHorizontalRule({
    @required ContainerNode node,
    @required LayerLink layerLink,
    @required ZefyrRenderContext renderContext,
    @required ValueNotifier<bool> showCursor,
    @required TextSelection selection,
    @required Color selectionColor,
  })  : _node = node,
        _layerLink = layerLink,
        _renderContext = renderContext,
        _showCursor = showCursor,
        _selection = selection,
        _selectionColor = selectionColor,
        super();

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
    markNeedsPaint();
  }

  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  double get preferredLineHeight => size.height;

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

  List<ui.TextBox> getEndpointsForSelection(TextSelection selection,
      {bool isLocal: false}) {
    TextSelection local = isLocal ? selection : getLocalSelection(selection);
    if (local.isCollapsed) {
      return [
        new ui.TextBox.fromLTRBD(0.0, 0.0, 0.0, size.height, TextDirection.ltr),
      ];
    }

    return [
      new ui.TextBox.fromLTRBD(0.0, 0.0, 0.0, size.height, TextDirection.ltr),
      new ui.TextBox.fromLTRBD(
          size.width, 0.0, size.width, size.height, TextDirection.ltr),
    ];
  }

  //
  // Overridden members
  //

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
    assert(constraints.hasBoundedWidth);
    final height = kWidth + kPaddingBottom;
    size = new Size(constraints.maxWidth, height);
    _caretPainter.layout(height);
    // Indicate to render context that this object can be used by other
    // layers (selection overlay, for instance).
    _renderContext.markDirty(this, false);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
//    if (_isSelectionVisible) _paintSelection(context, offset);
    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, kWidth);
    final paint = new ui.Paint()..color = Colors.grey.shade200;
    context.canvas.drawRect(rect.shift(offset), paint);
    if (_isCaretVisible) _paintCaret(context, offset);
  }

  @override
  void markNeedsLayout() {
    // Temporarily remove this object from the render context.
    _renderContext.markDirty(this, true);
    super.markNeedsLayout();
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return new ui.TextPosition(offset: node.documentOffset);
  }

  @override
  TextRange getWordBoundary(ui.TextPosition position) {
    return new TextRange(start: position.offset, end: position.offset + 1);
  }

  //
  // Private members
  //

  final CaretPainter _caretPainter = new CaretPainter();
//  List<ui.TextBox> _selectionRects;

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
//  bool get _isSelectionVisible {
//    if (_selection.isCollapsed) return false;
//    return _intersectsWithSelection(_selection);
//  }

  /// Returns `true` if this paragraph intersects with document [selection].
  bool _intersectsWithSelection(TextSelection selection) {
    final int base = node.documentOffset;
    final int extent = base + node.length;
    return base <= selection.extentOffset && selection.baseOffset <= extent;
  }

  void _paintCaret(PaintingContext context, Offset offset) {
    final pos = _selection.extentOffset - node.documentOffset;
    Offset caretOffset = Offset.zero;
    if (pos == 1) {
      caretOffset = caretOffset + new Offset(size.width - 1.0, 0.0);
    }
    _caretPainter.paint(context.canvas, caretOffset + offset);
  }

//
//  void _paintSelection(PaintingContext context, Offset offset) {
//    assert(_isSelectionVisible);
//    // TODO: this could be improved by painting additional box for line-break characters.
//    _selectionRects ??= getBoxesForSelection(getLocalSelection(_selection));
//    final Paint paint = new Paint()..color = _selectionColor;
//    for (ui.TextBox box in _selectionRects)
//      context.canvas.drawRect(box.toRect().shift(offset), paint);
//  }
}
