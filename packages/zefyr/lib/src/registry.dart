// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'extension.dart';
import 'extensions/bold_italic.dart';
import 'extensions/link.dart';

class ZefyrRegistry {
  static const List<List<NotusAttributeKey>> allStyles = [
    [NotusAttribute.bold, NotusAttribute.italic, NotusAttribute.link]
  ];

  final List<List<NotusAttributeKey>> enabledStyles;
  final List<ZefyrInlineExtension> inlineExtensions = List();

  ZefyrRegistry({this.enabledStyles = allStyles}) {
    inlineExtensions.add(BoldItalicExtension());
    inlineExtensions.add(LinkExtension());
  }

  Map<String, TextStyle> get defaultInlineStyles {
    Map<String, TextStyle> result = {};
    inlineExtensions.forEach((ext) => result.addAll(ext.defaultStyles));
    return result;
  }

  TextStyle buildTextStyle(BuildContext context, TextNode node) {
    return inlineExtensions.fold(
      TextStyle(),
      (TextStyle style, ZefyrInlineExtension ext) =>
          style.merge(ext.buildStyle(context, node)),
    );
  }
}
