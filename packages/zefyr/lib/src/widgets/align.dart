// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'paragraph.dart';
import 'theme.dart';

/// Represents number lists and bullet lists in a Zefyr editor.
class ZefyrAlign extends StatelessWidget {
  const ZefyrAlign({Key key, @required this.node}) : super(key: key);

  final BlockNode node;

  TextAlign _getTextAlign() {
    final blockStyle = node.style.get(NotusAttribute.block);
    if (blockStyle == NotusAttribute.block.alignLeft) {
      return TextAlign.left;
    } else if (blockStyle == NotusAttribute.block.alignRight) {
      return TextAlign.right;
    } else if (blockStyle == NotusAttribute.block.alignCenter) {
      return TextAlign.center;
    } else if (blockStyle == NotusAttribute.block.alignJustify) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    List<Widget> items = [];
    for (var line in node.children) {
      items.add(_buildLine(
        line,
        null,
        theme.indentWidth,
      ));
    }

    return Column(children: items);
  }

  Widget _buildLine(Node node, TextStyle blockStyle, double indentSize) {
    LineNode line = node;
    final textAlign = _getTextAlign();
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
    return Row(
      key: UniqueKey(),
      children: <Widget>[Expanded(child: content)],
    );
  }
}
