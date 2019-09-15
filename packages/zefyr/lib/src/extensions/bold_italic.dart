import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import '../extension.dart';
import '../widgets/theme.dart';

/// Implements bold and italic inline styles.
class BoldItalicExtension extends ZefyrInlineExtension {
  // TODO: move attribute declarations from Notus to Zefyr
  @override
  List<NotusAttributeKey> get attributes => [
        NotusAttribute.bold,
        NotusAttribute.italic,
      ];

  Map<String, TextStyle> get defaultStyles => {
        NotusAttribute.bold.key: TextStyle(fontWeight: FontWeight.bold),
        NotusAttribute.italic.key: TextStyle(fontStyle: FontStyle.italic),
      };

  @override
  bool acceptsPress(NotusAttributeKey attribute) => false;

  @override
  TextStyle buildStyle(BuildContext context, TextNode node) {
    final ZefyrThemeData theme = ZefyrTheme.of(context);
    final NotusStyle style = node.style;
    TextStyle result = TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.inlineStyles[NotusAttribute.bold.key]);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.inlineStyles[NotusAttribute.italic.key]);
    }
    return result;
  }
}
