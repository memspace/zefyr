// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'common.dart';
import 'theme.dart';

/// Represents regular paragraph line in a Zefyr editor.
class ZefyrParagraph extends StatelessWidget {
  ZefyrParagraph({Key key, @required this.node, this.blockStyle})
      : super(key: key);

  final LineNode node;
  final TextStyle blockStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    var style = theme.defaultLineTheme.textStyle;
    if (blockStyle != null) {
      style = style.merge(blockStyle);
    }
    return ZefyrLine(
      node: node,
      style: style,
      padding: theme.defaultLineTheme.padding,
    );
  }
}

/// Represents heading-styled line in [ZefyrEditor].
class ZefyrHeading extends StatelessWidget {
  ZefyrHeading({Key key, @required this.node, this.blockStyle, this.align})
      : assert(node.style.contains(NotusAttribute.heading)),
        super(key: key);

  final LineNode node;
  final TextAlign align;
  final TextStyle blockStyle;

  @override
  Widget build(BuildContext context) {
    final theme = themeOf(node, context);
    var style = theme.textStyle;
    if (blockStyle != null) {
      style = style.merge(blockStyle);
    }
    return ZefyrLine(
      node: node,
      style: style,
      padding: theme.padding,
      textAlign: align,
    );
  }

  static LineTheme themeOf(LineNode node, BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final style = node.style.get(NotusAttribute.heading);
    if (style == NotusAttribute.heading.level1) {
      return theme.attributeTheme.heading1;
    } else if (style == NotusAttribute.heading.level2) {
      return theme.attributeTheme.heading2;
    } else if (style == NotusAttribute.heading.level3) {
      return theme.attributeTheme.heading3;
    }
    throw UnimplementedError('Unsupported heading style $style');
  }
}

/// Represents heading-styled line in [ZefyrEditor].
class ZefyrAlign extends StatelessWidget {
  ZefyrAlign({
    Key key,
    @required this.node,
    this.blockStyle,
    this.align,
  })  : assert(node.style.contains(NotusAttribute.textAlign)),
        super(key: key);

  final TextAlign align;
  final LineNode node;
  final TextStyle blockStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final align = alignOf(node, context);

    TextStyle textStyle;
    Widget content;
    EdgeInsets padding;

    if (node.style.contains(NotusAttribute.heading)) {
      final headingTheme = ZefyrHeading.themeOf(node, context);
      textStyle = headingTheme.textStyle;
      padding = headingTheme.padding;
      content = ZefyrHeading(node: node, align: this.align ?? align);
    } else {
      textStyle = theme.defaultLineTheme.textStyle;
      content = ZefyrLine(
        node: node,
        style: textStyle,
        textAlign: this.align ?? align,
      );
      padding = EdgeInsets.all(0);
    }

    if (blockStyle != null) {
      textStyle = textStyle.merge(blockStyle);
    }
    if (padding != null) {
      return Padding(padding: padding, child: content);
    }

    return content;
  }

  static TextAlign alignOf(LineNode node, BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final style = node.style.get(NotusAttribute.textAlign);
    if (style == NotusAttribute.textAlign.left) {
      return theme.attributeTheme.alignLeft;
    } else if (style == NotusAttribute.textAlign.center) {
      return theme.attributeTheme.alignCenter;
    } else if (style == NotusAttribute.textAlign.right) {
      return theme.attributeTheme.alignRight;
    }
    throw UnimplementedError('Unsupported align $style');
  }
}
