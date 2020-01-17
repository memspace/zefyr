import 'package:flutter/material.dart';

/// Applies a Zefyr editor theme to descendant widgets.
///
/// Describes colors and typographic styles.
///
/// Descendant widgets obtain the current theme's [ZefyrThemeData] object using
/// [ZefyrTheme.of].
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
    final ZefyrTheme widget =
        context.dependOnInheritedWidgetOfExactType<ZefyrTheme>();
    if (widget == null && nullOk) return null;
    assert(widget != null,
        '$ZefyrTheme.of() called with a context that does not contain a ZefyrEditor.');
    return widget.data;
  }
}

/// Holds colors and typography values for a Zefyr design theme.
///
/// To obtain the current theme, use [ZefyrTheme.of].
@immutable
class ZefyrThemeData {
  /// Default theme used for document lines in Zefyr editor.
  ///
  /// Defines text style and spacing for regular paragraphs of text with
  /// no style attributes applied.
  final LineTheme defaultLineTheme;

  /// The text styles, padding and decorations used to render text with
  /// different style attributes.
  final AttributeTheme attributeTheme;

  /// The width of indentation used for blocks (lists, quotes, code).
  final double indentWidth;

  /// The colors used to render editor toolbar.
  final ToolbarTheme toolbarTheme;

  /// Creates a [ZefyrThemeData] given a set of exact values. All values
  /// must be specified and must be not null.
  const ZefyrThemeData({
    this.defaultLineTheme,
    this.attributeTheme,
    this.indentWidth,
    this.toolbarTheme,
  });

  /// The default color theme.
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
      toolbarTheme: ToolbarTheme.fallback(context),
    );
  }

  /// Creates a copy of this theme but with the given fields replaced with
  /// the new values.
  ZefyrThemeData copyWith({
    LineTheme defaultLineTheme,
    AttributeTheme attributeTheme,
    double indentWidth,
    ToolbarTheme toolbarTheme,
  }) {
    return ZefyrThemeData(
      defaultLineTheme: defaultLineTheme ?? this.defaultLineTheme,
      attributeTheme: attributeTheme ?? this.attributeTheme,
      indentWidth: indentWidth ?? this.indentWidth,
      toolbarTheme: toolbarTheme ?? this.toolbarTheme,
    );
  }

  /// Creates a new [ZefyrThemeData] where each property from this object has
  /// been merged with the matching text style from the `other` object.
  ZefyrThemeData merge(ZefyrThemeData other) {
    if (other == null) return this;
    return copyWith(
      defaultLineTheme: defaultLineTheme?.merge(other.defaultLineTheme) ??
          other.defaultLineTheme,
      attributeTheme:
          attributeTheme?.merge(other.attributeTheme) ?? other.attributeTheme,
      indentWidth: other.indentWidth ?? indentWidth,
      toolbarTheme:
          toolbarTheme?.merge(other.toolbarTheme) ?? other.toolbarTheme,
    );
  }

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;
    final ZefyrThemeData otherData = other;
    return (otherData.defaultLineTheme == defaultLineTheme) &&
        (otherData.attributeTheme == attributeTheme) &&
        (otherData.indentWidth == indentWidth) &&
        (otherData.toolbarTheme == toolbarTheme);
  }

  @override
  int get hashCode {
    return hashList([
      defaultLineTheme,
      attributeTheme,
      indentWidth,
      toolbarTheme,
    ]);
  }
}

class LineTheme {
  final TextStyle textStyle;
  final EdgeInsets padding;

  LineTheme({this.textStyle, this.padding})
      : assert(textStyle != null),
        assert(padding != null);

  LineTheme copyWith({TextStyle textStyle, EdgeInsets padding}) {
    return LineTheme(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
    );
  }

  LineTheme merge(LineTheme other) {
    if (other == null) return this;
    return copyWith(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      padding: other.padding ?? padding,
    );
  }

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;
    final LineTheme otherTheme = other;
    return (otherTheme.textStyle == textStyle) &&
        (otherTheme.padding == padding);
  }

  @override
  int get hashCode => hashValues(textStyle, padding);
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

  BlockTheme copyWith({
    TextStyle textStyle,
    EdgeInsets padding,
    bool inheritLineTextStyle,
    EdgeInsets linePadding,
  }) {
    return BlockTheme(
      textStyle: textStyle ?? this.textStyle,
      inheritLineTextStyle: inheritLineTextStyle ?? this.inheritLineTextStyle,
      padding: padding ?? this.padding,
      linePadding: linePadding ?? this.linePadding,
    );
  }

  BlockTheme merge(BlockTheme other) {
    if (other == null) return this;
    return copyWith(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      inheritLineTextStyle: other.inheritLineTextStyle ?? inheritLineTextStyle,
      padding: other.padding ?? padding,
      linePadding: other.linePadding ?? linePadding,
    );
  }

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;
    final BlockTheme otherTheme = other;
    return (otherTheme.textStyle == textStyle) &&
        (otherTheme.inheritLineTextStyle == inheritLineTextStyle) &&
        (otherTheme.padding == padding) &&
        (otherTheme.linePadding == linePadding);
  }

  @override
  int get hashCode =>
      hashValues(textStyle, inheritLineTextStyle, padding, linePadding);
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
        linePadding: EdgeInsets.symmetric(vertical: 2.0),
      ),
      numberList: BlockTheme(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        linePadding: EdgeInsets.symmetric(vertical: 2.0),
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

  AttributeTheme copyWith({
    TextStyle bold,
    TextStyle italic,
    TextStyle link,
    LineTheme heading1,
    LineTheme heading2,
    LineTheme heading3,
    BlockTheme bulletList,
    BlockTheme numberList,
    BlockTheme quote,
    BlockTheme code,
  }) {
    return AttributeTheme(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      link: link ?? this.link,
      heading1: heading1 ?? this.heading1,
      heading2: heading2 ?? this.heading2,
      heading3: heading3 ?? this.heading3,
      bulletList: bulletList ?? this.bulletList,
      numberList: numberList ?? this.numberList,
      quote: quote ?? this.quote,
      code: code ?? this.code,
    );
  }

  AttributeTheme merge(AttributeTheme other) {
    if (other == null) return this;
    return copyWith(
      bold: bold?.merge(other.bold) ?? other.bold,
      italic: italic?.merge(other.italic) ?? other.italic,
      link: link?.merge(other.link) ?? other.link,
      heading1: heading1?.merge(other.heading1) ?? other.heading1,
      heading2: heading2?.merge(other.heading2) ?? other.heading2,
      heading3: heading3?.merge(other.heading3) ?? other.heading3,
      bulletList: bulletList?.merge(other.bulletList) ?? other.bulletList,
      numberList: numberList?.merge(other.numberList) ?? other.numberList,
      quote: quote?.merge(other.quote) ?? other.quote,
      code: code?.merge(other.code) ?? other.code,
    );
  }

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;
    final AttributeTheme otherTheme = other;
    return (otherTheme.bold == bold) &&
        (otherTheme.italic == italic) &&
        (otherTheme.link == link) &&
        (otherTheme.heading1 == heading1) &&
        (otherTheme.heading2 == heading2) &&
        (otherTheme.heading3 == heading3) &&
        (otherTheme.bulletList == bulletList) &&
        (otherTheme.numberList == numberList) &&
        (otherTheme.quote == quote) &&
        (otherTheme.code == code);
  }

  @override
  int get hashCode {
    return hashList([
      bold,
      italic,
      link,
      heading1,
      heading2,
      heading3,
      bulletList,
      numberList,
      quote,
      code,
    ]);
  }
}

/// Defines styles and colors for [ZefyrToolbar].
class ToolbarTheme {
  /// The background color of toolbar.
  final Color color;

  /// Color of buttons in toggled state.
  final Color toggleColor;

  /// Color of button icons.
  final Color iconColor;

  /// Color of button icons in disabled state.
  final Color disabledIconColor;

  /// Creates fallback theme for editor toolbars.
  factory ToolbarTheme.fallback(BuildContext context) {
    final theme = Theme.of(context);
    return ToolbarTheme._(
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

  ToolbarTheme._({
    @required this.color,
    @required this.toggleColor,
    @required this.iconColor,
    @required this.disabledIconColor,
  });

  ToolbarTheme copyWith({
    Color color,
    Color toggleColor,
    Color iconColor,
    Color disabledIconColor,
  }) {
    return ToolbarTheme._(
      color: color ?? this.color,
      toggleColor: toggleColor ?? this.toggleColor,
      iconColor: iconColor ?? this.iconColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
    );
  }

  ToolbarTheme merge(ToolbarTheme other) {
    if (other == null) return this;
    return copyWith(
      color: other.color ?? color,
      toggleColor: other.toggleColor ?? toggleColor,
      iconColor: other.iconColor ?? iconColor,
      disabledIconColor: other.disabledIconColor ?? disabledIconColor,
    );
  }

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;
    final ToolbarTheme otherTheme = other;
    return (otherTheme.color == color) &&
        (otherTheme.toggleColor == toggleColor) &&
        (otherTheme.iconColor == iconColor) &&
        (otherTheme.disabledIconColor == disabledIconColor);
  }

  @override
  int get hashCode =>
      hashValues(color, toggleColor, iconColor, disabledIconColor);
}
