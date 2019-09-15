import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import '../extension.dart';
import '../widgets/theme.dart';

/// Implements link inline style.
class LinkExtension extends ZefyrInlineExtension {
  // TODO: move attribute declarations from Notus to Zefyr
  @override
  List<NotusAttributeKey> get attributes => [NotusAttribute.link];

  @override
  Map<String, TextStyle> get defaultStyles => {
        NotusAttribute.link.key:
            TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
      };

  @override
  bool acceptsPress(NotusAttributeKey attribute) => true;

  @override
  TextStyle buildStyle(BuildContext context, TextNode node) {
    final ZefyrThemeData theme = ZefyrTheme.of(context);
    TextStyle result = TextStyle();
    if (node.style.contains(NotusAttribute.link)) {
      result = result.merge(theme.inlineStyles[NotusAttribute.link.key]);
    }
    return result;
  }
}
