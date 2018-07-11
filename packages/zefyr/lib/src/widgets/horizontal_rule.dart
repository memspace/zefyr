// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';

class HorizontalRule extends LeafRenderObjectWidget {
  HorizontalRule({@required this.node}) : assert(node != null);

  final EmbedNode node;

  @override
  RenderHorizontalRule createRenderObject(BuildContext context) {
    return new RenderHorizontalRule(node: node);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderHorizontalRule renderObject) {
    renderObject..node = node;
  }
}

class RenderHorizontalRule extends RenderEditableBox {
  static const _kPaddingBottom = 24.0;
  static const _kThickness = 3.0;
  static const _kHeight = _kThickness + _kPaddingBottom;

  RenderHorizontalRule({
    @required EmbedNode node,
  }) : _node = node;

  @override
  EmbedNode get node => _node;
  EmbedNode _node;
  set node(EmbedNode value) {
    if (_node == value) return;
    _node = value;
    markNeedsPaint();
  }

  @override
  double get preferredLineHeight => size.height;

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

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    size = new Size(constraints.maxWidth, _kHeight);
//    _caretPainter.layout(height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
//    if (isSelectionVisible) _paintSelection(context, offset);
    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, _kThickness);
    final paint = new ui.Paint()..color = Colors.grey.shade200;
    context.canvas.drawRect(rect.shift(offset), paint);
//    if (isCaretVisible) _paintCaret(context, offset);
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return new ui.TextPosition(offset: _node.documentOffset);
  }

  @override
  TextRange getWordBoundary(ui.TextPosition position) {
    return new TextRange(start: position.offset, end: position.offset + 1);
  }

  //
  // Private members
  //
//
//  final CaretPainter _caretPainter = new CaretPainter();
//
//  void _paintCaret(PaintingContext context, Offset offset) {
//    final pos = selection.extentOffset - node.documentOffset;
//    Offset caretOffset = Offset.zero;
//    if (pos == 1) {
//      caretOffset = caretOffset + new Offset(size.width - 1.0, 0.0);
//    }
//    _caretPainter.paint(context.canvas, caretOffset + offset);
//  }
//
//  void _paintSelection(PaintingContext context, Offset offset) {
//    assert(isSelectionVisible);
//    final Paint paint = new Paint()..color = selectionColor;
//    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, _kHeight);
//    context.canvas.drawRect(rect.shift(offset), paint);
//  }
}
