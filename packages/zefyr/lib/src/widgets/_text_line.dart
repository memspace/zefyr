import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/paragraph_proxy.dart';

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
    return _RichTextProxy(
      paragraphStyle: text.style,
      child: RichText(
        text: buildText(context, node),
      ),
    );
  }

  TextSpan buildText(BuildContext context, LineNode node) {
    final children = node.children
        .map((node) => _segmentToTextSpan(node /*, theme*/))
        .toList(growable: false);
    final style = TextStyle(
      color: Colors.grey.shade900,
      fontFamily: '.SF UI Text',
      fontSize: 16,
    );
    return TextSpan(style: style, children: children);
  }

  TextSpan _segmentToTextSpan(
    Node node,
    /*ZefyrThemeData theme*/
  ) {
    final TextNode segment = node;
    final attrs = segment.style;
    var style = TextStyle();
    if (attrs.contains(NotusAttribute.bold)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }

    return TextSpan(
      text: segment.value,
      style: style,
//      style: _getTextStyle(attrs, theme),
    );
  }
}

class _RichTextProxy extends SingleChildRenderObjectWidget {
  final TextStyle paragraphStyle;

  /// Child argument should be an instance of RichText widget.
  _RichTextProxy({
    @required RichText child,
    @required this.paragraphStyle,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraphProxy();
  }
}
