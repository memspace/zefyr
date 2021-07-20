// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Applies a Zefyr editor theme to descendant widgets.
///
/// Describes colors and typographic styles for an editor.
///
/// Descendant widgets obtain the current theme's [ZefyrThemeData] object using
/// [ZefyrTheme.of].
///
/// See also:
///
///   * [ZefyrThemeData], which describes actual configuration of a theme.
class ZefyrTheme extends InheritedWidget {
  final ZefyrThemeData data;

  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  ZefyrTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(ZefyrTheme oldWidget) {
    return data != oldWidget.data;
  }

  /// The data from the closest [ZefyrTheme] instance that encloses the given
  /// context.
  ///
  /// Returns `null` if there is no [ZefyrTheme] in the given build context
  /// and [nullOk] is set to `true`. If [nullOk] is set to `false` (default)
  /// then this method asserts.
  static ZefyrThemeData? of(BuildContext context, {bool nullOk = false}) {
    final widget = context.dependOnInheritedWidgetOfExactType<ZefyrTheme>();
    if (widget == null && nullOk) return null;
    assert(widget != null,
        '$ZefyrTheme.of() called with a context that does not contain a ZefyrEditor.');
    return widget!.data;
  }
}

/// Vertical spacing around a block of text.
class VerticalSpacing {
  final double top;
  final double bottom;

  const VerticalSpacing({this.top = 0.0, this.bottom = 0.0});

  const VerticalSpacing.zero()
      : top = 0.0,
        bottom = 0.0;
}

class ZefyrThemeData {
  /// Style of bold text.
  final TextStyle bold;

  /// Style of italic text.
  final TextStyle italic;

  /// Style of underline text.
  final TextStyle underline;

  /// Style of strikethrough text.
  final TextStyle strikethrough;

  /// Style of links in text.
  final TextStyle link;

  /// Default style theme for regular paragraphs of text.
  final TextBlockTheme paragraph; // spacing: top: 6, bottom: 10
  /// Style theme for level 1 headings.
  final TextBlockTheme heading1;

  /// Style theme for level 2 headings.
  final TextBlockTheme heading2;

  /// Style theme for level 3 headings.
  final TextBlockTheme heading3;

  /// Style theme for bullet and number lists.
  final TextBlockTheme lists;

  /// Style theme for quote blocks.
  final TextBlockTheme quote;

  /// Style theme for code blocks.
  final TextBlockTheme code;

  ZefyrThemeData({
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.link,
    required this.paragraph,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.lists,
    required this.quote,
    required this.code,
  });

  factory ZefyrThemeData.fallback(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    final baseStyle = defaultStyle.style.copyWith(
      fontSize: 16.0,
      height: 1.3,
    );
    final baseSpacing = VerticalSpacing(top: 6.0, bottom: 10);

    String fontFamily;
    switch (themeData.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        fontFamily = 'Menlo';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        fontFamily = 'Roboto Mono';
        break;
    }

    return ZefyrThemeData(
      bold: TextStyle(fontWeight: FontWeight.bold),
      italic: TextStyle(fontStyle: FontStyle.italic),
      underline: TextStyle(decoration: TextDecoration.underline),
      strikethrough: TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: themeData.accentColor,
        decoration: TextDecoration.underline,
      ),
      paragraph: TextBlockTheme(
        style: baseStyle,
        spacing: baseSpacing,
        // lineSpacing is not relevant for paragraphs since they consist of one line
      ),
      heading1: TextBlockTheme(
        style: defaultStyle.style.copyWith(
          fontSize: 34.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        spacing: VerticalSpacing(top: 16.0, bottom: 0.0),
      ),
      heading2: TextBlockTheme(
        style: TextStyle(
          fontSize: 24.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.normal,
        ),
        spacing: VerticalSpacing(bottom: 0.0, top: 8.0),
      ),
      heading3: TextBlockTheme(
        style: TextStyle(
          fontSize: 20.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
          height: 1.25,
          fontWeight: FontWeight.w500,
        ),
        spacing: VerticalSpacing(bottom: 0.0, top: 8.0),
      ),
      lists: TextBlockTheme(
        style: baseStyle,
        spacing: baseSpacing,
        lineSpacing: VerticalSpacing(bottom: 6),
      ),
      quote: TextBlockTheme(
        style: TextStyle(color: baseStyle.color?.withOpacity(0.6)),
        spacing: baseSpacing,
        lineSpacing: VerticalSpacing(top: 6, bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(width: 4, color: Colors.grey.shade300),
          ),
        ),
      ),
      code: TextBlockTheme(
        style: TextStyle(
          color: Colors.blue.shade900.withOpacity(0.9),
          fontFamily: fontFamily,
          fontSize: 13.0,
          height: 1.15,
        ),
        spacing: baseSpacing,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  ZefyrThemeData copyWith({
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? underline,
    TextStyle? strikethrough,
    TextStyle? link,
    TextBlockTheme? paragraph,
    TextBlockTheme? heading1,
    TextBlockTheme? heading2,
    TextBlockTheme? heading3,
    TextBlockTheme? lists,
    TextBlockTheme? quote,
    TextBlockTheme? code,
  }) {
    return ZefyrThemeData(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      link: link ?? this.link,
      paragraph: paragraph ?? this.paragraph,
      heading1: heading1 ?? this.heading1,
      heading2: heading2 ?? this.heading2,
      heading3: heading3 ?? this.heading3,
      lists: lists ?? this.lists,
      quote: quote ?? this.quote,
      code: code ?? this.code,
    );
  }

  ZefyrThemeData merge(ZefyrThemeData other) {
    return copyWith(
      bold: other.bold,
      italic: other.italic,
      underline: other.underline,
      strikethrough: other.strikethrough,
      link: other.link,
      paragraph: other.paragraph,
      heading1: other.heading1,
      heading2: other.heading2,
      heading3: other.heading3,
      lists: other.lists,
      quote: other.quote,
      code: other.code,
    );
  }
}

/// Style theme applied to a block of rich text, including single-line
/// paragraphs.
class TextBlockTheme {
  /// Base text style for a text block.
  final TextStyle style;

  /// Vertical spacing around a text block.
  final VerticalSpacing spacing;

  /// Vertical spacing for individual lines within a text block.
  ///
  final VerticalSpacing lineSpacing;

  /// Decoration of a text block.
  ///
  /// Decoration, if present, is painted in the content area, excluding
  /// any [spacing].
  final BoxDecoration? decoration;

  TextBlockTheme({
    required this.style,
    required this.spacing,
    this.lineSpacing = const VerticalSpacing.zero(),
    this.decoration,
  });
}
