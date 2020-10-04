// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(data != null),
        assert(child != null),
        super(key: key, child: child);

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
  static ZefyrThemeData of(BuildContext context, {bool nullOk = false}) {
    final widget = context.dependOnInheritedWidgetOfExactType<ZefyrTheme>();
    if (widget == null && nullOk) return null;
    assert(widget != null,
        '$ZefyrTheme.of() called with a context that does not contain a ZefyrEditor.');
    return widget.data;
  }
}

/// Holds colors and typography styles for [ZefyrEditor].
class ZefyrThemeData {
  final TextStyle boldStyle;
  final TextStyle italicStyle;
  final TextStyle underlineStyle;
  final TextStyle linkStyle;
  final StyleTheme paragraphTheme;
  final HeadingTheme headingTheme;
  final BlockTheme blockTheme;
  final Color selectionColor;
  final Color cursorColor;

  /// Size of indentation for blocks.
  final double indentSize;
  final ZefyrToolbarTheme toolbarTheme;

  factory ZefyrThemeData.fallback(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    final paragraphStyle = defaultStyle.style.copyWith(
      fontSize: 16.0,
      height: 1.3,
    );
    const padding = EdgeInsets.symmetric(vertical: 8.0);
    final boldStyle = TextStyle(fontWeight: FontWeight.bold);
    final italicStyle = TextStyle(fontStyle: FontStyle.italic);
    final underlineStyle = TextStyle(decoration: TextDecoration.underline);
    final linkStyle = TextStyle(
        color: themeData.accentColor, decoration: TextDecoration.underline);

    return ZefyrThemeData(
      boldStyle: boldStyle,
      italicStyle: italicStyle,
      underlineStyle: underlineStyle,
      linkStyle: linkStyle,
      paragraphTheme: StyleTheme(textStyle: paragraphStyle, padding: padding),
      headingTheme: HeadingTheme.fallback(context),
      blockTheme: BlockTheme.fallback(context),
      selectionColor: themeData.textSelectionColor,
      cursorColor: themeData.cursorColor,
      indentSize: 16.0,
      toolbarTheme: ZefyrToolbarTheme.fallback(context),
    );
  }

  const ZefyrThemeData({
    this.boldStyle,
    this.italicStyle,
    this.underlineStyle,
    this.linkStyle,
    this.paragraphTheme,
    this.headingTheme,
    this.blockTheme,
    this.selectionColor,
    this.cursorColor,
    this.indentSize,
    this.toolbarTheme,
  });

  ZefyrThemeData copyWith({
    TextStyle textStyle,
    TextStyle boldStyle,
    TextStyle italicStyle,
    TextStyle underlineStyle,
    TextStyle linkStyle,
    StyleTheme paragraphTheme,
    HeadingTheme headingTheme,
    BlockTheme blockTheme,
    Color selectionColor,
    Color cursorColor,
    double indentSize,
    ZefyrToolbarTheme toolbarTheme,
  }) {
    return ZefyrThemeData(
      boldStyle: boldStyle ?? this.boldStyle,
      italicStyle: italicStyle ?? this.italicStyle,
      underlineStyle: underlineStyle ?? this.underlineStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      paragraphTheme: paragraphTheme ?? this.paragraphTheme,
      headingTheme: headingTheme ?? this.headingTheme,
      blockTheme: blockTheme ?? this.blockTheme,
      selectionColor: selectionColor ?? this.selectionColor,
      cursorColor: cursorColor ?? this.cursorColor,
      indentSize: indentSize ?? this.indentSize,
      toolbarTheme: toolbarTheme ?? this.toolbarTheme,
    );
  }

  ZefyrThemeData merge(ZefyrThemeData other) {
    return copyWith(
      boldStyle: other.boldStyle,
      italicStyle: other.italicStyle,
      underlineStyle: other.underlineStyle,
      linkStyle: other.linkStyle,
      paragraphTheme: other.paragraphTheme,
      headingTheme: other.headingTheme,
      blockTheme: other.blockTheme,
      selectionColor: other.selectionColor,
      cursorColor: other.cursorColor,
      indentSize: other.indentSize,
      toolbarTheme: other.toolbarTheme,
    );
  }
}

/// Theme for heading-styled lines of text.
class HeadingTheme {
  /// Style theme for level 1 headings.
  final StyleTheme level1;

  /// Style theme for level 2 headings.
  final StyleTheme level2;

  /// Style theme for level 3 headings.
  final StyleTheme level3;

  HeadingTheme({
    @required this.level1,
    @required this.level2,
    @required this.level3,
  });

  /// Creates fallback theme for headings.
  factory HeadingTheme.fallback(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context);
    return HeadingTheme(
      level1: StyleTheme(
        textStyle: defaultStyle.style.copyWith(
          fontSize: 34.0,
          color: defaultStyle.style.color.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        padding: EdgeInsets.only(top: 16.0, bottom: 0.0),
      ),
      level2: StyleTheme(
        textStyle: TextStyle(
          fontSize: 24.0,
          color: defaultStyle.style.color.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.normal,
        ),
        padding: EdgeInsets.only(bottom: 0.0, top: 8.0),
      ),
      level3: StyleTheme(
        textStyle: TextStyle(
          fontSize: 20.0,
          color: defaultStyle.style.color.withOpacity(0.70),
          height: 1.25,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.only(bottom: 0.0, top: 8.0),
      ),
    );
  }
}

/// Theme for a block of lines in a document.
class BlockTheme {
  /// Style theme for bullet lists.
  final StyleTheme bulletList;

  /// Style theme for number lists.
  final StyleTheme numberList;

  /// Style theme for code snippets.
  final StyleTheme code;

  /// Style theme for quotes.
  final StyleTheme quote;

  BlockTheme({
    @required this.bulletList,
    @required this.numberList,
    @required this.quote,
    @required this.code,
  });

  /// Creates fallback theme for blocks.
  factory BlockTheme.fallback(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context);
    final padding = const EdgeInsets.symmetric(vertical: 8.0);
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

    return BlockTheme(
      bulletList: StyleTheme(padding: padding),
      numberList: StyleTheme(padding: padding),
      quote: StyleTheme(
        textStyle: TextStyle(
          color: defaultTextStyle.style.color.withOpacity(0.6),
        ),
        padding: padding,
      ),
      code: StyleTheme(
        textStyle: TextStyle(
          color: defaultTextStyle.style.color.withOpacity(0.8),
          fontFamily: fontFamily,
          fontSize: 14.0,
          height: 1.25,
        ),
        padding: padding,
      ),
    );
  }
}

/// Theme for a specific attribute style.
///
/// Used in [HeadingTheme] and [BlockTheme], as well as in
/// [ZefyrThemeData.paragraphTheme].
class StyleTheme {
  /// Text style of this theme.
  final TextStyle textStyle;

  /// Padding to apply around lines of text.
  final EdgeInsets padding;

  /// Creates a new [StyleTheme].
  StyleTheme({
    this.textStyle,
    this.padding,
  });
}

/// Defines styles and colors for [ZefyrToolbar].
class ZefyrToolbarTheme {
  /// The background color of toolbar.
  final Color color;

  /// Color of buttons in toggled state.
  final Color toggleColor;

  /// Color of button icons.
  final Color iconColor;

  /// Color of button icons in disabled state.
  final Color disabledIconColor;

  /// Creates fallback theme for editor toolbars.
  factory ZefyrToolbarTheme.fallback(BuildContext context) {
    final theme = Theme.of(context);
    return ZefyrToolbarTheme._(
      color: theme.primaryColorBrightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade800,
      toggleColor: theme.primaryColorBrightness == Brightness.light
          ? Colors.grey.shade400
          : Colors.grey.shade900,
      iconColor: theme.primaryIconTheme.color,
      disabledIconColor: theme.disabledColor,
    );
  }

  ZefyrToolbarTheme._({
    @required this.color,
    @required this.toggleColor,
    @required this.iconColor,
    @required this.disabledIconColor,
  });

  ZefyrToolbarTheme copyWith({
    Color color,
    Color toggleColor,
    Color iconColor,
    Color disabledIconColor,
  }) {
    return ZefyrToolbarTheme._(
      color: color ?? this.color,
      toggleColor: toggleColor ?? this.toggleColor,
      iconColor: iconColor ?? this.iconColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
    );
  }
}
