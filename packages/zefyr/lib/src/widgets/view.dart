// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/zefyr.dart';

import 'code.dart';
import 'common.dart';
import 'image.dart';
import 'list.dart';
import 'paragraph.dart';
import 'quote.dart';
import 'scope.dart';
import 'theme.dart';

/// Non-scrollable read-only view of Notus rich text documents.
@experimental
class ZefyrView extends StatefulWidget {
  final NotusDocument document;
  final ZefyrImageDelegate imageDelegate;
  final ZefyrAttrDelegate attrDelegate;

  const ZefyrView(
      {Key key, @required this.document, this.imageDelegate, this.attrDelegate})
      : super(key: key);

  @override
  ZefyrViewState createState() => ZefyrViewState();
}

class ZefyrViewState extends State<ZefyrView> {
  ZefyrScope _scope;
  ZefyrThemeData _themeData;

  ZefyrImageDelegate get imageDelegate => widget.imageDelegate;

  @override
  void initState() {
    super.initState();
    _scope = ZefyrScope.view(
        imageDelegate: widget.imageDelegate, attrDelegate: widget.attrDelegate);
  }

  @override
  void didUpdateWidget(ZefyrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scope.imageDelegate = widget.imageDelegate;
    _scope.attrDelegate = widget.attrDelegate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentTheme = ZefyrTheme.of(context, nullOk: true);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    _themeData = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZefyrTheme(
      data: _themeData,
      child: ZefyrScopeAccess(
        scope: _scope,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    for (var node in widget.document.root.children) {
      result.add(_defaultChildBuilder(context, node));
    }
    return result;
  }

  Widget _defaultChildBuilder(BuildContext context, Node node) {
    if (node is LineNode) {
      if (node.hasEmbed) {
        return ZefyrLine(node: node);
      } else if (node.style.contains(NotusAttribute.heading)) {
        return ZefyrHeading(node: node);
      }
      return ZefyrParagraph(node: node);
    }

    final BlockNode block = node;
    final blockStyle = block.style.get(NotusAttribute.block);
    if (blockStyle == NotusAttribute.block.code) {
      return ZefyrCode(node: block);
    } else if (blockStyle == NotusAttribute.block.bulletList) {
      return ZefyrList(node: block);
    } else if (blockStyle == NotusAttribute.block.numberList) {
      return ZefyrList(node: block);
    } else if (blockStyle == NotusAttribute.block.quote) {
      return ZefyrQuote(node: block);
    }

    throw UnimplementedError('Block format $blockStyle.');
  }
}
