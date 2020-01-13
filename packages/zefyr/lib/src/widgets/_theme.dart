import 'package:flutter/material.dart';

class ZefyrThemeData {
  final LineTheme defaultLineTheme;
  final AttributeTheme attributeTheme;
  final double indentWidth;
  final toolbarTheme;

  ZefyrThemeData({
    this.defaultLineTheme,
    this.attributeTheme,
    this.indentWidth,
    this.toolbarTheme,
  });

  factory ZefyrThemeData.fallback(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context);
    final defaultLineTheme = LineTheme(
      textStyle: defaultStyle.style.copyWith(
        fontSize: 16.0,
        height: 1.3,
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0),
    );
    return ZefyrThemeData(
      defaultLineTheme: defaultLineTheme,
      attributeTheme: AttributeTheme.fallback(context, defaultLineTheme),
      indentWidth: 16.0,
    );
  }
}

class LineTheme {
  final TextStyle textStyle;
  final EdgeInsets padding;

  LineTheme({this.textStyle, this.padding})
      : assert(textStyle != null),
        assert(padding != null);
}

class BlockTheme {
  /// Text style for all text within a block, can be null.
  ///
  /// Takes precedence over line-level text style set by [LineTheme] if
  /// [inheritLineTextStyle] is set to `false`. Otherwise this text style
  /// is merged with the line's style.
  final TextStyle textStyle;

  /// Whether [textStyle] specified by this block theme should be merged with
  /// text style of each individual line.
  ///
  /// Only applicable if [textStyle] is not null.
  ///
  /// If set to `true` then [textStyle] is merged with text style specified
  /// by [LineTheme] of each line within a block. Otherwise [textStyle]
  /// takes precedence and replaces style of [LineTheme].
  final bool inheritLineTextStyle;

  /// Space around the block.
  final EdgeInsets padding;

  /// Space around each individual line within a block, can be null.
  ///
  /// Takes precedence over line padding set in [LineTheme].
  final EdgeInsets linePadding;

  BlockTheme({
    this.textStyle,
    this.inheritLineTextStyle = true,
    @required this.padding,
    this.linePadding,
  }) : assert(padding != null);
}

class AttributeTheme {
  final TextStyle bold;
  final TextStyle italic;
  final TextStyle link;
  final LineTheme heading1;
  final LineTheme heading2;
  final LineTheme heading3;
  final BlockTheme bulletList;
  final BlockTheme numberList;
  final BlockTheme quote;
  final BlockTheme code;

  AttributeTheme({
    this.bold,
    this.italic,
    this.link,
    this.heading1,
    this.heading2,
    this.heading3,
    this.bulletList,
    this.numberList,
    this.quote,
    this.code,
  });

  factory AttributeTheme.fallback(
      BuildContext context, LineTheme defaultLineTheme) {
    final theme = Theme.of(context);

    String monospaceFontFamily;
    switch (theme.platform) {
      case TargetPlatform.iOS:
        monospaceFontFamily = 'Menlo';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        monospaceFontFamily = 'Roboto Mono';
        break;
      default:
        throw UnimplementedError("Platform ${theme.platform} not implemented.");
    }

    return AttributeTheme(
      bold: TextStyle(fontWeight: FontWeight.bold),
      italic: TextStyle(fontStyle: FontStyle.italic),
      link: TextStyle(
        decoration: TextDecoration.underline,
        color: theme.accentColor,
      ),
      heading1: LineTheme(
        textStyle: defaultLineTheme.textStyle.copyWith(
          fontSize: 34.0,
          color: defaultLineTheme.textStyle.color.withOpacity(0.7),
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        padding: EdgeInsets.only(top: 16.0),
      ),
      heading2: LineTheme(
        textStyle: defaultLineTheme.textStyle.copyWith(
          fontSize: 24.0,
          color: defaultLineTheme.textStyle.color.withOpacity(0.7),
          height: 1.15,
          fontWeight: FontWeight.normal,
        ),
        padding: EdgeInsets.only(top: 8.0),
      ),
      heading3: LineTheme(
        textStyle: defaultLineTheme.textStyle.copyWith(
          fontSize: 20.0,
          color: defaultLineTheme.textStyle.color.withOpacity(0.7),
          height: 1.15,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.only(top: 8.0),
      ),
      bulletList: BlockTheme(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        linePadding: EdgeInsets.zero,
      ),
      numberList: BlockTheme(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        linePadding: EdgeInsets.zero,
      ),
      quote: BlockTheme(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        textStyle: TextStyle(
          color: defaultLineTheme.textStyle.color.withOpacity(0.6),
        ),
        inheritLineTextStyle: true,
      ),
      code: BlockTheme(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        textStyle: TextStyle(
          fontFamily: monospaceFontFamily,
          fontSize: 14.0,
          color: defaultLineTheme.textStyle.color.withOpacity(0.8),
          height: 1.25,
        ),
        inheritLineTextStyle: false,
        linePadding: EdgeInsets.zero,
      ),
    );
  }
}
