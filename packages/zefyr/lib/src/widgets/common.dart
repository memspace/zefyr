// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';
import 'horizontal_rule.dart';
import 'image.dart';
import 'rich_text.dart';
import 'scope.dart';
import 'theme.dart';

/// Represents single line of rich text document in Zefyr editor.
class ZefyrLine extends StatefulWidget {
  const ZefyrLine({Key key, @required this.node, this.style, this.padding})
      : assert(node != null),
        super(key: key);

  /// Line in the document represented by this widget.
  final LineNode node;

  /// Style to apply to this line. Required for lines with text contents,
  /// ignored for lines containing embeds.
  final TextStyle style;

  /// Padding to add around this paragraph.
  final EdgeInsets padding;

  @override
  _ZefyrLineState createState() => _ZefyrLineState();
}

class _ZefyrLineState extends State<ZefyrLine> {
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final scope = ZefyrScope.of(context);
    if (scope.isEditable) {
      ensureVisible(context, scope);
    }
    final theme = Theme.of(context);

    Widget content;
    if (widget.node.hasEmbed) {
      content = buildEmbed(context, scope);
    } else {
      assert(widget.style != null);
      content = ZefyrRichText(
        node: widget.node,
        text: buildText(context),
      );
    }

    if (scope.isEditable) {
      Color cursorColor;
      switch (theme.platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          cursorColor ??= CupertinoTheme.of(context).primaryColor;
          break;

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          cursorColor = theme.cursorColor;
          break;
      }

      content = EditableBox(
        child: content,
        node: widget.node,
        layerLink: _link,
        renderContext: scope.renderContext,
        showCursor: scope.showCursor,
        selection: scope.selection,
        selectionColor: theme.textSelectionColor,
        cursorColor: cursorColor,
      );
      content = CompositedTransformTarget(link: _link, child: content);
    }

    if (widget.padding != null) {
      return Padding(padding: widget.padding, child: content);
    }
    return content;
  }

  void ensureVisible(BuildContext context, ZefyrScope scope) {
    if (scope.selection.isCollapsed &&
        widget.node.containsOffset(scope.selection.extentOffset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bringIntoView(context);
      });
    }
  }

  void bringIntoView(BuildContext context) {
    final scrollable = Scrollable.of(context);
    final object = context.findRenderObject();
    assert(object.attached);
    final viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final offset = scrollable.position.pixels;
    var target = viewport.getOffsetToReveal(object, 0.0).offset;
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
    final children = widget.node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return TextSpan(style: widget.style, children: children);
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme) {
    final TextNode segment = node;
    final attrs = segment.style;

    return TextSpan(
      text: segment.value,
      style: _getTextStyle(attrs, theme),
    );
  }

  TextStyle _getTextStyle(NotusStyle style, ZefyrThemeData theme) {
    TextStyle result = TextStyle();
    final hexStringToColor = (String hex) {
      hex = hex.replaceFirst('#', '');
      hex = hex.length == 6 ? 'ff' + hex : hex;
      int val = int.parse(hex, radix: 16);
      return Color(val);
    };


    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.attributeTheme.bold);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.attributeTheme.italic);
    }
    if (style.containsSame(NotusAttribute.strikethrough)) {
      result = result.merge(theme.attributeTheme.strikethrough);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.attributeTheme.link);
    }

    //Colors
    if (style.contains(NotusAttribute.cPink)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cPink));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cNeonPink)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cNeonPink));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cMaroonRed)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cMaroonRed));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cCherryRed)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cCherryRed));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cCoralRed)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cCoralRed));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cMahogany)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cMahogany));
      result = result.copyWith(color: textColor);
    }

    if (style.contains(NotusAttribute.cOrange)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cOrange));
      result = result.copyWith(color: textColor);
    }

    if (style.contains(NotusAttribute.cYellow)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cYellow));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cNeonYellow)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cNeonYellow));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cForestGreen)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cForestGreen));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cAppleGreen)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cAppleGreen));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cTeaGreen)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cTeaGreen));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cNeonGreen)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cNeonGreen));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cTealGreen)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cTealGreen));
      result = result.copyWith(color: textColor);
    }

    if (style.contains(NotusAttribute.cLBlue)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cLBlue));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cOceanBlue)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cOceanBlue));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cLilBlue)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cLilBlue));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cNavyBlue)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cNavyBlue));
      result = result.copyWith(color: textColor);
    }

    if (style.contains(NotusAttribute.cPlum)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cPlum));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cNeonPurple)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cNeonPurple));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cSuedePurple)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cSuedePurple));
      result = result.copyWith(color: textColor);
    }
    if (style.contains(NotusAttribute.cOrchidPurple)) {
      final textColor = hexStringToColor(style.value<String>(NotusAttribute.cOrchidPurple));
      result = result.copyWith(color: textColor);
    }
    }
    return result;
  }

  Widget buildEmbed(BuildContext context, ZefyrScope scope) {
    EmbedNode node = widget.node.children.single;
    EmbedAttribute embed = node.style.get(NotusAttribute.embed);

    if (embed.type == EmbedType.horizontalRule) {
      return ZefyrHorizontalRule(node: node);
    } else if (embed.type == EmbedType.image) {
      return ZefyrImage(node: node, delegate: scope.imageDelegate);
    } else {
      throw UnimplementedError('Unimplemented embed type ${embed.type}');
    }
  }
}
