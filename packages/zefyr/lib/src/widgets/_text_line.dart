import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '_rich_text_proxy.dart';
import '_theme.dart';

/// Line of text in Zefyr editor.
///
/// This widget allows to render non-editable line of rich text, but can be
/// wrapped with [EditableTextLine] which adds editing features.
class TextLine extends StatelessWidget {
  /// Line of text represented by this paragraph.
  final LineNode node;
  final TextDirection textDirection;

  const TextLine({
    Key key,
    @required this.node,
    this.textDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = buildText(context, node);
    final strutStyle = StrutStyle.fromTextStyle(text.style);
    return RichTextProxy(
      textStyle: text.style,
      textDirection: textDirection,
      strutStyle: strutStyle,
      locale: Localizations.localeOf(context, nullOk: true),
      child: RichText(
        text: buildText(context, node),
        textDirection: textDirection,
        strutStyle: strutStyle,
      ),
    );
  }

  TextSpan buildText(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final children = node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return TextSpan(
      style: _getParagraphTextStyle(node.style, theme),
      children: children,
    );
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme) {
    final TextNode segment = node;
    final attrs = segment.style;
    var style = TextStyle();
    if (attrs.contains(NotusAttribute.bold)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (attrs.contains(NotusAttribute.italic)) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    return TextSpan(
      text: segment.value,
      style: _getInlineTextStyle(attrs, theme),
    );
  }

  TextStyle _getParagraphTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var textStyle = TextStyle();
    final heading = node.style.get(NotusAttribute.heading);
    if (heading == NotusAttribute.heading.level1) {
      textStyle = textStyle.merge(theme.heading1.style);
    } else if (heading == NotusAttribute.heading.level2) {
      textStyle = textStyle.merge(theme.heading2.style);
    } else if (heading == NotusAttribute.heading.level3) {
      textStyle = textStyle.merge(theme.heading3.style);
    } else {
      textStyle = textStyle.merge(theme.paragraph.style);
    }

    final block = style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      textStyle = textStyle.merge(theme.quote.style);
    } else if (block == NotusAttribute.block.code) {
      textStyle = textStyle.merge(theme.code.style);
    } else if (block != null) {
      // lists
      textStyle = textStyle.merge(theme.lists.style);
    }

    return textStyle;
  }

  TextStyle _getInlineTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var result = TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.bold);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.italic);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.link);
    }
    return result;
  }
}
