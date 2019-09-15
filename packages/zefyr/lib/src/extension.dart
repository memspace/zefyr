// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'registry.dart';

abstract class ZefyrInlineExtension {
  List<NotusAttributeKey> get attributes;

  /// Default styles to use in Zefyr theme.
  Map<String, TextStyle> get defaultStyles;

  /// Return true is specified [attribute] reacts to press events (tap, click).
  bool acceptsPress(NotusAttributeKey attribute);

  // For Link style must return `false` if specified range has @mention or #hashtag
  bool canApply(TextRange range) => true;

  TextStyle buildStyle(BuildContext context, TextNode node);
}

abstract class ZefyrExtension {
  List<NotusAttribute> get attributes => [];

  void registerHeuristicRules(ZefyrRegistry registry) {}

  TextSpan buildTextNode(BuildContext context, TextNode node, TextStyle style) {
    return TextSpan(
      text: node.value,
      style: style,
    );
  }

  Widget buildLineNode(BuildContext context, LineNode node) {
    throw StateError(
        "ZefyrExtension must implement buildEmbedNode if it registers an embed attribute.");
  }

  Widget buildEmbedNode(BuildContext context, EmbedNode node) {
    throw StateError(
        "ZefyrExtension must implement buildEmbedNode if it registers an embed attribute.");
  }

  Widget buildBlockNode(BuildContext context, BlockNode node) {
    throw StateError(
        "ZefyrExtension must implement buildBlockNode if it registers a block style attribute.");
  }
}
