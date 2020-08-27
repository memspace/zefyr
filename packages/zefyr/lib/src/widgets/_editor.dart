import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import '../rendering/editor.dart';
import '_cursor.dart';

class RawEditor extends StatefulWidget {
  RawEditor({
    Key key,
    @required this.document,
    @required this.controller,
    @required this.focusNode,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    StrutStyle strutStyle,
    @required this.cursorColor,
    @required this.backgroundCursorColor,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxHeight,
    this.minHeight,
    this.autofocus = false,
    bool showCursor,
    this.showSelectionHandles = false,
    this.selectionColor,
    this.selectionControls,
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorOpacityAnimates = false,
    this.cursorOffset,
    this.paintCursorAboveText = false,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.scrollController,
    this.scrollPhysics,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
  })  : assert(document != null),
        assert(controller != null),
        assert(focusNode != null),
        assert(autocorrect != null),
        assert(enableSuggestions != null),
        assert(showSelectionHandles != null),
        assert(enableInteractiveSelection != null),
        assert(readOnly != null),
        assert(cursorColor != null),
        assert(cursorOpacityAnimates != null),
        assert(backgroundCursorColor != null),
        assert(maxHeight == null || maxHeight > 0),
        assert(minHeight == null || minHeight >= 0),
        assert(
          (maxHeight == null) ||
              (minHeight == null) ||
              (maxHeight >= minHeight),
          'minHeight can\'t be greater than maxHeight',
        ),
        assert(autofocus != null),
        assert(scrollPadding != null),
        assert(dragStartBehavior != null),
        assert(toolbarOptions != null),
        _strutStyle = strutStyle,
        keyboardType = keyboardType ?? TextInputType.multiline,
        showCursor = showCursor ?? !readOnly,
        super(key: key);

  /// Document being edited in this editor.
  final NotusDocument document;

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// Whether the text can be changed.
  ///
  /// When this is set to true, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to false. Must not be null.
  final bool readOnly;

  /// Configuration of toolbar options.
  ///
  /// By default, all options are enabled. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// Whether to show selection handles.
  ///
  /// When a selection is active, there will be two handles at each side of
  /// boundary, or one handle if the selection is collapsed. The handles can be
  /// dragged to adjust the selection.
  ///
  /// See also:
  ///
  ///  * [showCursor], which controls the visibility of the cursor..
  final bool showSelectionHandles;

  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the [RawEditor] is focused.
  ///
  /// See also:
  ///
  ///  * [showSelectionHandles], which controls the visibility of the selection handles.
  final bool showCursor;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  final bool autocorrect;

  /// Whether to show input suggestions as the user types.
  ///
  /// This flag only affects Android. On iOS, suggestions are tied directly to
  /// [autocorrect], so that suggestions are only shown when [autocorrect] is
  /// true. On Android autocorrection and suggestion are controlled separately.
  ///
  /// Defaults to true. Cannot be null.
  final bool enableSuggestions;

  /// The strut style used for the vertical layout.
  ///
  /// [StrutStyle] is used to establish a predictable vertical layout.
  /// Since fonts may vary depending on user input and due to font
  /// fallback, [StrutStyle.forceStrutHeight] is enabled by default
  /// to lock all lines to the height of the base [TextStyle], used by
  /// particular paragraph of text. This ensures the typed text fits within
  /// the allotted space.
  ///
  /// If null, the strut used will inherit values from the paragraph style and
  /// will have [StrutStyle.forceStrutHeight] set to true.
  ///
  /// To disable strut-based vertical alignment and allow dynamic vertical
  /// layout based on the glyphs typed, use [StrutStyle.disabled].
  ///
  /// Flutter's strut is based on [typesetting strut](https://en.wikipedia.org/wiki/Strut_(typesetting))
  /// and CSS's [line-height](https://www.w3.org/TR/CSS2/visudet.html#line-height).
  ///
  /// Within editable text and text fields, [StrutStyle] will not use its standalone
  /// default values, and will instead inherit omitted/null properties from the
  /// [TextStyle] instead. See [StrutStyle.inheritFromTextStyle].
  StrutStyle get strutStyle {
    if (_strutStyle == null) {
      return style != null
          ? StrutStyle.fromTextStyle(style, forceStrutHeight: true)
          : StrutStyle.disabled;
    }
    return _strutStyle.inheritFromTextStyle(style);
  }

  final StrutStyle _strutStyle;

  /// The directionality of the text.
  ///
  /// This is used to disambiguate how to render bidirectional text. For
  /// example, if the text is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection textDirection;

  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.none]. Must not be null.
  ///
  /// See also:
  ///
  ///  * [TextCapitalization], for a description of each capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  final Locale locale;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double textScaleFactor;

  /// The color to use when painting the cursor.
  ///
  /// Cannot be null.
  final Color cursorColor;

  /// The color to use when painting the background cursor aligned with the text
  /// while rendering the floating cursor.
  ///
  /// Cannot be null. By default it is the disabled grey color from
  /// CupertinoColors.
  final Color backgroundCursorColor;

  /// The maximum height this editor can have.
  ///
  /// If this is null then there is no limit to the editor's height and it will
  /// expand to fill its parent.
  final double maxHeight;

  /// The minimum height this editor can have.
  final double minHeight;

  /// Whether this editor should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  final bool autofocus;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// The [RawEditor] widget used on its own will not trigger the display
  /// of the selection toolbar by itself. The toolbar is shown by calling
  /// [RawEditorState.showToolbar] in response to an appropriate user event.
  final TextSelectionControls selectionControls;

  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.multiline].
  final TextInputType keyboardType;

  /// The type of action button to use with the soft keyboard.
  final TextInputAction textInputAction;

  /// How thick the cursor will be.
  ///
  /// Defaults to 2.0
  ///
  /// The cursor will draw under the text. The cursor width will extend
  /// to the right of the boundary between characters for left-to-right text
  /// and to the left for right-to-left text. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  final double cursorWidth;

  /// How rounded the corners of the cursor should be.
  ///
  /// By default, the cursor has no radius.
  final Radius cursorRadius;

  /// Whether the cursor will animate from fully transparent to fully opaque
  /// during each cursor blink.
  ///
  /// By default, the cursor opacity will animate on iOS platforms and will not
  /// animate on Android platforms.
  final bool cursorOpacityAnimates;

  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  final Offset cursorOffset;

  /// If the cursor should be painted on top of the text or underneath it.
  ///
  /// By default, the cursor should be painted on top for iOS platforms and
  /// underneath for Android platforms.
  final bool paintCursorAboveText;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// Configures padding to edges surrounding a [Scrollable] when the editor scrolls into view.
  ///
  /// When this widget receives focus and is not completely visible (for example scrolled partially
  /// off the screen or overlapped by the keyboard)
  /// then it will attempt to make itself visible by scrolling a surrounding [Scrollable], if one is present.
  /// This value controls how far from the edges of a [Scrollable] the TextField will be positioned after the scroll.
  ///
  /// Defaults to EdgeInsets.all(20.0).
  final EdgeInsets scrollPadding;

  /// If true, then long-pressing this TextField will select text and show the
  /// cut/copy/paste menu, and tapping will move the text caret.
  ///
  /// True by default.
  ///
  /// If false, most of the accessibility support for selecting text, copy
  /// and paste, and moving the caret will be disabled.
  final bool enableInteractiveSelection;

  final DragStartBehavior dragStartBehavior;

  /// The [ScrollController] to use when vertically scrolling the input.
  ///
  /// If null, it will instantiate a new ScrollController.
  ///
  /// See [Scrollable.controller].
  final ScrollController scrollController;

  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  final ScrollPhysics scrollPhysics;

  bool get selectionEnabled => enableInteractiveSelection;

  @override
  State<RawEditor> createState() {
    return RawEditorState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<TextEditingController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: true));
    properties.add(DiagnosticsProperty<bool>(
        'enableSuggestions', enableSuggestions,
        defaultValue: true));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(DoubleProperty('maxLines', maxHeight, defaultValue: null));
    properties.add(DoubleProperty('minLines', minHeight, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollController>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
  }
}

class RawEditorState extends State<RawEditor>
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>
    implements TextInputClient, TextSelectionDelegate {
  final GlobalKey _editorKey = GlobalKey();

  CursorController _cursorController;
  FloatingCursorController _floatingCursorController;

  TextInputConnection _textInputConnection;
  TextSelectionOverlay _selectionOverlay;

  ScrollController _scrollController;

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;
  FocusAttachment _focusAttachment;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;

  TextDirection get _textDirection {
    final result = widget.textDirection ?? Directionality.of(context);
    assert(result != null,
        '$runtimeType created without a textDirection and with no ambient Directionality.');
    return result;
  }

  double get _devicePixelRatio =>
      MediaQuery.of(context).devicePixelRatio ?? 1.0;

  /// The renderer for this widget's editor descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures.
  RenderEditor get renderEditor => _editorKey.currentContext.findRenderObject();

  // State lifecycle:

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeTextEditingValue);
    _focusAttachment = widget.focusNode.attach(context);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(() {
      _selectionOverlay?.updateForScroll();
    });
    _cursorController = CursorController(
      tickerProvider: this,
      cursorColor: widget.cursorColor,
      cursorOpacityAnimates: widget.cursorOpacityAnimates,
      showCursor: widget.showCursor,
      onCursorColorChanged: _handleCursorColorChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoFocus && widget.autofocus) {
      FocusScope.of(context).autofocus(widget.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(_value);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }
    if (widget.readOnly) {
      _closeInputConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) _openInputConnection();
    }
    if (widget.style != oldWidget.style) {
      final TextStyle style = widget.style;
      _textInputConnection?.setStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        textDirection: _textDirection,
        textAlign: widget.textAlign,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);

    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    _focusAttachment.detach();
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment.reparent();
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls controls = widget.selectionControls;

    return Scrollable(
      excludeFromSemantics: true,
      axisDirection: AxisDirection.down,
      controller: _scrollController,
      physics: widget.scrollPhysics,
      dragStartBehavior: widget.dragStartBehavior,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return CompositedTransformTarget(
          link: _toolbarLayerLink,
          child: Semantics(
            onCopy: _semanticsOnCopy(controls),
            onCut: _semanticsOnCut(controls),
            onPaste: _semanticsOnPaste(controls),
            child: _Editor(
              key: _editorKey,
              children: _buildParagraphs(context),
              document: widget.document,
              textDirection: _textDirection,
              cursorColor: _cursorController.cursorColor,
              backgroundCursorColor: widget.backgroundCursorColor,
              showCursor: _cursorController.cursorBlink,
              hasFocus: widget.focusNode.hasFocus,
              startHandleLayerLink: _startHandleLayerLink,
              endHandleLayerLink: _endHandleLayerLink,
              maxHeight: widget.maxHeight,
              minHeight: widget.minHeight,
              strutStyle: widget.strutStyle,
              selectionColor: widget.selectionColor,
              textScaleFactor: widget.textScaleFactor ??
                  MediaQuery.textScaleFactorOf(context),
              offset: offset,
              readOnly: widget.readOnly,
              locale: widget.locale,
              cursorWidth: widget.cursorWidth,
              cursorRadius: widget.cursorRadius,
              cursorOffset: widget.cursorOffset,
              paintCursorAboveText: widget.paintCursorAboveText,
              devicePixelRatio: _devicePixelRatio,
              enableInteractiveSelection: widget.enableInteractiveSelection,
              textSelectionDelegate: this,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParagraphs(BuildContext context) {
    return [];
  }

  void _handleCursorColorChanged(Color cursorColor) {
    renderEditor.cursorColor = cursorColor;
  }
}

class _Editor extends MultiChildRenderObjectWidget {
  _Editor({
    @required Key key,
    @required List<Widget> children,
    @required this.document,
    @required this.textDirection,
    @required this.cursorColor,
    @required this.backgroundCursorColor,
    @required this.showCursor,
    @required this.hasFocus,
    @required this.startHandleLayerLink,
    @required this.endHandleLayerLink,
    @required this.maxHeight,
    @required this.minHeight,
    @required this.strutStyle,
    @required this.selectionColor,
    @required this.textScaleFactor,
    @required this.offset,
    @required this.readOnly,
    @required this.locale,
    @required this.cursorWidth,
    @required this.cursorRadius,
    @required this.cursorOffset,
    @required this.paintCursorAboveText,
    @required this.devicePixelRatio,
    @required this.enableInteractiveSelection,
    @required this.textSelectionDelegate,
  }) : super(key: key, children: children);

  final NotusDocument document;
  final TextDirection textDirection;
  final Color cursorColor;
  final Color backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool hasFocus;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final double maxHeight;
  final double minHeight;
  final StrutStyle strutStyle;
  final Color selectionColor;
  final double textScaleFactor;
  final ViewportOffset offset;
  final bool readOnly;
  final Locale locale;
  final double cursorWidth;
  final Radius cursorRadius;
  final bool paintCursorAboveText;
  final Offset cursorOffset;
  final double devicePixelRatio;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;

  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor(
      document: document,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    // TODO
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO
//    properties.add(EnumProperty<Axis>('direction', direction));
  }
}
