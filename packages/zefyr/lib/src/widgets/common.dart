// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';
import 'editable_text.dart';
import 'horizontal_rule.dart';
import 'image.dart';
import 'rich_text.dart';
import 'theme.dart';

/// Raw widget representing a single line of rich text document in Zefyr editor.
///
/// See [ZefyrParagraph] and [ZefyrHeading] which wrap this widget and
/// integrate it with current [ZefyrTheme].
class RawZefyrLine extends StatefulWidget {
  const RawZefyrLine({
    Key key,
    @required this.node,
    this.style,
    this.padding,
  }) : super(key: key);

  /// Line in the document represented by this widget.
  final LineNode node;

  /// Style to apply to this line. Required for lines with text contents,
  /// ignored for lines containing embeds.
  final TextStyle style;

  /// Padding to add around this paragraph.
  final EdgeInsets padding;

  @override
  _RawZefyrLineState createState() => new _RawZefyrLineState();
}

class _RawZefyrLineState extends State<RawZefyrLine> {
  final LayerLink _link = new LayerLink();

  @override
  Widget build(BuildContext context) {
    ensureVisible(context);
    final theme = ZefyrTheme.of(context);
    final editable = ZefyrEditableText.of(context);

    Widget content;
    if (widget.node.hasEmbed) {
      content = buildEmbed(context);
    } else {
      assert(widget.style != null);

      final text = new EditableRichText(
        node: widget.node,
        text: buildText(context),
      );
      content = new EditableBox(
        child: text,
        node: widget.node,
        layerLink: _link,
        renderContext: editable.renderContext,
        showCursor: editable.showCursor,
        selection: editable.selection,
        selectionColor: theme.selectionColor,
        cursorColor: theme.cursorColor,
      );
    }

    final result = new CompositedTransformTarget(link: _link, child: content);
    if (widget.padding != null) {
      return new Padding(padding: widget.padding, child: result);
    }
    return result;
  }

  void ensureVisible(BuildContext context) {
    final editable = ZefyrEditableText.of(context);
    if (editable.selection.isCollapsed &&
        widget.node.containsOffset(editable.selection.extentOffset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bringIntoView(context);
      });
    }
  }

  void bringIntoView(BuildContext context) {
    ScrollableState scrollable = Scrollable.of(context);
    final object = context.findRenderObject();
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final double offset = scrollable.position.pixels;
    double target = viewport.getOffsetToReveal(object, 0.0).offset;
    if (target - offset < 0.0) {
      scrollable.position.jumpTo(target);
      return;
    }
    target = viewport.getOffsetToReveal(object, 1.0).offset;
    if (target - offset > 0.0) {
      scrollable.position.jumpTo(target);
    }
  }

  TextSpan buildText(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final List<TextSpan> children = widget.node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return new TextSpan(style: widget.style, children: children);
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme) {
    final TextNode segment = node;
    final attrs = segment.style;

    return new TextSpan(
      text: segment.value,
      style: _getTextStyle(attrs, theme),
    );
  }

  TextStyle _getTextStyle(NotusStyle style, ZefyrThemeData theme) {
    TextStyle result = new TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.boldStyle);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.italicStyle);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.linkStyle);
    }
    return result;
  }

  Widget buildEmbed(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final editable = ZefyrEditableText.of(context);

    EmbedNode node = widget.node.children.single;
    EmbedAttribute embed = node.style.get(NotusAttribute.embed);

    if (embed.type == EmbedType.horizontalRule) {
      final hr = new ZefyrHorizontalRule(node: node);
      return new EditableBox(
        child: hr,
        node: widget.node,
        layerLink: _link,
        renderContext: editable.renderContext,
        showCursor: editable.showCursor,
        selection: editable.selection,
        selectionColor: theme.selectionColor,
        cursorColor: theme.cursorColor,
      );
    } else if (embed.type == EmbedType.image) {
      return new EditableBox(
        child: ZefyrImage(node: node, delegate: editable.imageDelegate),
        node: widget.node,
        layerLink: _link,
        renderContext: editable.renderContext,
        showCursor: editable.showCursor,
        selection: editable.selection,
        selectionColor: theme.selectionColor,
        cursorColor: theme.cursorColor,
      );
    } else {
      throw new UnimplementedError('Unimplemented embed type ${embed.type}');
    }
  }
}
