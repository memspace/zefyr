// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';
import 'package:image_picker/image_picker.dart';

import 'editable_box.dart';

abstract class ZefyrImageDelegate<S> {
  /// Creates [ImageProvider] for specified [imageSource].
  ImageProvider createImageProvider(String imageSource);

  /// Picks an image from specified [source].
  ///
  /// Returns unique string key for the selected image. Returned key is stored
  /// in the document.
  Future<String> pickImage(S source);
}

class ZefyrDefaultImageDelegate implements ZefyrImageDelegate<ImageSource> {
  @override
  ImageProvider createImageProvider(String imageSource) {
    final file = new File.fromUri(Uri.parse(imageSource));
    return new FileImage(file);
  }

  @override
  Future<String> pickImage(ImageSource source) async {
    final file = await ImagePicker.pickImage(source: source);
    if (file == null) return null;
    return file.uri.toString();
  }
}

class ImageEmbed extends StatefulWidget {
  const ImageEmbed({Key key, @required this.node, @required this.delegate})
      : super(key: key);

  final EmbedNode node;
  final ZefyrImageDelegate delegate;

  @override
  _ImageEmbedState createState() => _ImageEmbedState();
}

class _ImageEmbedState extends State<ImageEmbed> {
  ImageProvider _provider;
  ImageStream _imageStream;
  ImageInfo _imageInfo;

  @override
  void initState() {
    super.initState();
    EmbedAttribute attribute = widget.node.style.get(NotusAttribute.embed);
    final source = attribute.value['source'];
    _provider = widget.delegate.createImageProvider(source);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  @override
  void didUpdateWidget(ImageEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    EmbedAttribute oldStyle = oldWidget.node.style.get(NotusAttribute.embed);
    final oldSource = oldStyle.value['source'];
    EmbedAttribute style = widget.node.style.get(NotusAttribute.embed);
    final source = style.value['source'];
    if (oldSource != source || oldWidget.delegate != widget.delegate) {
      _provider = widget.delegate.createImageProvider(source);
      _getImage();
    }
  }

  @override
  void dispose() {
    _imageStream.removeListener(_updateImage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditableImage(
      node: widget.node,
      image: _imageInfo?.image,
    );
  }

  void _getImage() {
    final oldImageStream = _imageStream;
    _imageStream = _provider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_updateImage);
      _imageStream.addListener(_updateImage);
    }
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
    });
  }
}

class _EditableImage extends LeafRenderObjectWidget {
  _EditableImage({@required this.node, this.image}) : assert(node != null);

  final EmbedNode node;
  final ui.Image image;

  @override
  RenderEditableImage createRenderObject(BuildContext context) {
    return new RenderEditableImage(node: node, image: image);
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
