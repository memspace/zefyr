// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/zefyr.dart';

import 'editable_box.dart';

/// Provides interface for embedding video into Zefyr editor.
@experimental
abstract class ZefyrVideoDelegate<S> {
  /// Unique key to identify camera source.
  S get cameraSource;

  /// Unique key to identify gallery source.
  S get gallerySource;

  /// Builds video widget for specified video [key].
  ///
  /// The [key] argument contains value which was previously returned from
  /// [pickVideo] method.
  Widget buildVideo(BuildContext context, String key);

  /// Picks an video from specified [source].
  ///
  /// Returns unique string key for the selected video. Returned key is stored
  /// in the document.
  ///
  /// Depending on your application returned key may represent a path to
  /// an video file on user's device, an HTTP link, or an identifier generated
  /// by a file hosting service like AWS S3 or Google Drive.
  Future<String> pickVideo(S source);
}

class ZefyrVideo extends StatefulWidget {
  const ZefyrVideo({Key key, @required this.node, @required this.delegate})
      : super(key: key);

  final EmbedNode node;
  final ZefyrVideoDelegate delegate;

  @override
  _ZefyrVideoState createState() => _ZefyrVideoState();
}

class _ZefyrVideoState extends State<ZefyrVideo> {
  String get videoSource {
    EmbedAttribute attribute = widget.node.style.get(NotusAttribute.embed);
    return attribute.value['source'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final video = widget.delegate.buildVideo(context, videoSource);
    return _EditableVideo(
      child: Padding(
        padding: theme.defaultLineTheme.padding,
        child: video,
      ),
      node: widget.node,
    );
  }
}

class _EditableVideo extends SingleChildRenderObjectWidget {
  _EditableVideo({@required Widget child, @required this.node})
      : assert(node != null),
        super(child: child);

  final EmbedNode node;

  @override
  RenderEditableVideo createRenderObject(BuildContext context) {
    return RenderEditableVideo(node: node);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderEditableVideo renderObject) {
    renderObject..node = node;
  }
}

class RenderEditableVideo extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin<RenderBox>
    implements RenderEditableBox {
  RenderEditableVideo({
    TextureBox child,
    @required EmbedNode node,
  }) : node = node {
    this.child = child;
  }

  @override
  EmbedNode node;

  // TODO: Customize caret height offset instead of adjusting here by 2px.
  @override
  double get preferredLineHeight => size.height + 2.0;

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
  List<ui.TextBox> getEndpointsForSelection(TextSelection selection) {
    TextSelection local = getLocalSelection(selection);
    if (local.isCollapsed) {
      final dx = local.extentOffset == 0 ? _childOffset.dx : size.width;
      return [
        ui.TextBox.fromLTRBD(dx, 0.0, dx, size.height, TextDirection.ltr),
      ];
    }

    final rect = _childRect;
    return [
      ui.TextBox.fromLTRBD(
          rect.left, rect.top, rect.left, rect.bottom, TextDirection.ltr),
      ui.TextBox.fromLTRBD(
          rect.right, rect.top, rect.right, rect.bottom, TextDirection.ltr),
    ];
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    int position = node.documentOffset;

    if (offset.dx > size.width / 2) {
      position++;
    }
    return TextPosition(offset: position);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final start = node.documentOffset;
    return TextRange(start: start, end: start + 1);
  }

  @override
  bool intersectsWithSelection(TextSelection selection) {
    final int base = node.documentOffset;
    final int extent = base + node.length;
    return base <= selection.extentOffset && selection.baseOffset <= extent;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final pos = position.offset - node.documentOffset;
    Offset caretOffset = _childOffset - Offset(kHorizontalPadding, 0.0);
    if (pos == 1) {
      caretOffset =
          caretOffset + Offset(_lastChildSize.width + kHorizontalPadding, 0.0);
    }
    return caretOffset;
  }

  @override
  void paintSelection(PaintingContext context, Offset offset,
      TextSelection selection, Color selectionColor) {
    final localSelection = getLocalSelection(selection);
    assert(localSelection != null);
    if (!localSelection.isCollapsed) {
      final Paint paint = Paint()
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      final rect =
          Rect.fromLTWH(0.0, 0.0, _lastChildSize.width, _lastChildSize.height);
      context.canvas.drawRect(rect.shift(offset + _childOffset), paint);
    }
  }

  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + _childOffset);
  }

  static const double kHorizontalPadding = 1.0;

  Size _lastChildSize;

  Offset get _childOffset {
    final dx = (size.width - _lastChildSize.width) / 2 + kHorizontalPadding;
    final dy = (size.height - _lastChildSize.height) / 2;
    return Offset(dx, dy);
  }

  Rect get _childRect {
    return Rect.fromLTWH(_childOffset.dx, _childOffset.dy, _lastChildSize.width,
        _lastChildSize.height);
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    if (child != null) {
      // Make constraints use 16:9 aspect ratio.
      final width = constraints.maxWidth - kHorizontalPadding * 2;
      final childConstraints = constraints.copyWith(
        minWidth: 0.0,
        maxWidth: width,
        minHeight: 0.0,
        maxHeight: 500, //double.infinity,
      );
      child.layout(childConstraints, parentUsesSize: true);
      _lastChildSize = child.size;
      size = Size(constraints.maxWidth, _lastChildSize.height);
    } else {
      performResize();
    }
  }
}
