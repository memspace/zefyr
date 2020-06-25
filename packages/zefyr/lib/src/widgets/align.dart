import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'paragraph.dart';
import 'theme.dart';

/// Represents a align block in a Zefyr editor.
class ZefyrAlign extends StatelessWidget {
  const ZefyrAlign({
    Key key,
    @required this.node,
    @required this.textAlign,
  }) : super(key: key);

  final BlockNode node;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final style = theme.attributeTheme.align.textStyle;
    final items = [];
    for (var line in node.children) {
      items.add(_buildLine(line, style, theme.indentWidth));
    }

    return Padding(
      padding: theme.attributeTheme.quote.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }

  Widget _buildLine(Node node, TextStyle blockStyle, double indentSize) {
    LineNode line = node;

    Widget content;
    if (line.style.contains(NotusAttribute.heading)) {
      content = ZefyrHeading(
        node: line,
        blockStyle: blockStyle,
        textAlign: textAlign,
      );
    } else {
      content = ZefyrParagraph(
        node: line,
        blockStyle: blockStyle,
        textAlign: textAlign,
      );
    }

    final row = Row(children: <Widget>[Expanded(child: content)]);
    return Container(
      padding: EdgeInsets.only(left: indentSize),
      child: row,
    );
  }
}
