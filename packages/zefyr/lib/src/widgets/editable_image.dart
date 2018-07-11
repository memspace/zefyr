// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';

class EditableImage extends LeafRenderObjectWidget {
  EditableImage({@required this.node}) : assert(node != null);

  final EmbedNode node;

  @override
  RenderEditableImage createRenderObject(BuildContext context) {
    return new RenderEditableImage(node: node);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderEditableImage renderObject) {
    renderObject..node = node;
  }
}

class RenderEditableImage extends RenderImage implements RenderEditableBox {
  RenderEditableImage({
    ui.Image image,
    @required EmbedNode node,
  })  : _node = node,
        super(
          image: image,
        );
  //
  // Public members
  //

  @override
  EmbedNode get node => _node;
  EmbedNode _node;
  void set node(EmbedNode value) {
    _node = value;
  }

  @override
  double get preferredLineHeight => size.height;

  @override
  SelectionOrder get selectionOrder => SelectionOrder.foreground;

  @override
  TextSelection getLocalSelection(TextSelection documentSelection) {
    if (!intersectsWithSelection(documentSelection)) return null;

    int nodeBase = node.documentOffset;
    int nodeExtent = nodeBase + node.length;
    int base = math.max(0, documentSelection.baseOffset - nodeBase);
    int extent =
        math.min(documentSelection.extentOffset, nodeExtent) - nodeBase;
    return documentSelection.copyWith(baseOffset: base, extentOffset: extent);
  }

  @override
  List<TextBox> getEndpointsForSelection(TextSelection selection) {
    TextSelection local = getLocalSelection(selection);
    if (local.isCollapsed) {
      return [
        new TextBox.fromLTRBD(0.0, 0.0, 0.0, size.height, TextDirection.ltr),
      ];
    }

    return [
      new TextBox.fromLTRBD(0.0, 0.0, 0.0, size.height, TextDirection.ltr),
      new TextBox.fromLTRBD(
          size.width, 0.0, size.width, size.height, TextDirection.ltr),
    ];
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return new TextPosition(offset: node.documentOffset);
  }

  @override
  bool intersectsWithSelection(TextSelection selection) {
    final int base = node.documentOffset;
    final int extent = base + node.length;
    return base <= selection.extentOffset && selection.baseOffset <= extent;
  }

  @override
  TextRange getWordBoundary(ui.TextPosition position) {
    return new TextRange(start: position.offset, end: position.offset + 1);
  }

  @override
  ui.Offset getOffsetForCaret(
      ui.TextPosition position, ui.Rect caretPrototype) {
    final pos = position.offset - node.documentOffset;
    Offset caretOffset = Offset.zero;
    if (pos == 1) {
      caretOffset = caretOffset + new Offset(size.width - 1.0, 0.0);
    }
    return caretOffset;
  }

  @override
  void paintSelection(PaintingContext context, ui.Offset offset,
      TextSelection selection, ui.Color selectionColor) {
    // TODO: implement paintSelection
  }
}
