import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/paragraph_proxy.dart';
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
    return _RichTextProxy(
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
    final color = node.style.contains(NotusAttribute.block.quote)
        ? Colors.grey.shade600
        : Colors.grey.shade900;
    // final style = TextStyle(
    //   color: color,
    //   // height: 1.35,
    //   // fontFamily: '.SF UI Text',
    //   fontSize: 16,
    // );
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
    // TODO: apply block-level style
    final style = node.style.get(NotusAttribute.heading);
    if (style == NotusAttribute.heading.level1) {
      return theme.headingTheme.level1.textStyle;
    } else if (style == NotusAttribute.heading.level2) {
      return theme.headingTheme.level2.textStyle;
    } else if (style == NotusAttribute.heading.level3) {
      return theme.headingTheme.level3.textStyle;
    }

    return theme.paragraphTheme.textStyle;
  }

  TextStyle _getInlineTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var result = TextStyle();
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
}

class _RichTextProxy extends SingleChildRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  _RichTextProxy({
    @required RichText child,
    @required this.textStyle,
    @required this.textDirection,
    this.textScaleFactor = 1.0,
    @required this.locale,
    @required this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(child: child);

  final TextStyle textStyle;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
      textStyle: textStyle,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject.textStyle = textStyle;
    renderObject.textDirection = textDirection;
    renderObject.textScaleFactor = textScaleFactor;
    renderObject.locale = locale;
    renderObject.strutStyle = strutStyle;
    renderObject.textWidthBasis = textWidthBasis;
    renderObject.textHeightBehavior = textHeightBehavior;
  }
}
