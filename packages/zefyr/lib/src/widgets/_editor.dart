import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import '../rendering/editor.dart';
import '../services/keyboard.dart';
import '_controller.dart';
import '_cursor.dart';
import '_editable_text_block.dart';
import '_editable_text_line.dart';
import '_editor_input_client_mixin.dart';
import '_editor_keyboard_mixin.dart';
import '_editor_selection_delegate_mixin.dart';
import '_text_line.dart';
import '_text_selection.dart';

class RawEditor extends StatefulWidget {
  RawEditor({
    Key key,
    @required this.controller,
    @required this.focusNode,
    @required this.selectionColor,
    this.enableInteractiveSelection = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    StrutStyle strutStyle,
    bool showCursor,
    this.cursorStyle,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxHeight,
    this.minHeight,
    this.autofocus = false,
    this.showSelectionHandles = false,
    this.selectionControls,
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    this.scrollController,
    this.scrollPhysics,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
  })  : assert(controller != null),
        assert(focusNode != null),
        assert(selectionColor != null),
        assert(enableInteractiveSelection != null),
        assert(autocorrect != null),
        assert(enableSuggestions != null),
        assert(showSelectionHandles != null),
        assert(readOnly != null),
        assert(!showCursor || cursorStyle != null),
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

  /// Controls the document being edited.
  final ZefyrController controller;

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
  ///  * [cursorStyle], which controls the cursor visual representation.
  ///  * [showSelectionHandles], which controls the visibility of the selection handles.
  final bool showCursor;

  /// The style to be used for the editing cursor.
  final CursorStyle cursorStyle;

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
    final style = TextStyle(); // TODO: remove hardcode
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
    properties
        .add(DiagnosticsProperty<ZefyrController>('controller', controller));
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

/// Base interface for the editor state which defines contract used by
/// various mixins.
///
/// Following mixins rely on this interface:
///
///   * [RawEditorStateKeyboardMixin],
///   * [RawEditorStateTextInputClientMixin]
///   * [RawEditorStateSelectionDelegateMixin]
///
abstract class EditorState extends State<RawEditor> {
  TextEditingValue get textEditingValue;
  set textEditingValue(TextEditingValue value);
  RenderEditor get renderEditor;
  bool showToolbar();
}

class RawEditorState extends EditorState
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>,
        RawEditorStateKeyboardMixin,
        RawEditorStateTextInputClientMixin,
        RawEditorStateSelectionDelegateMixin
    implements TextSelectionDelegate {
  final GlobalKey _editorKey = GlobalKey();

  // Cursor
  CursorController _cursorController;
  FloatingCursorController _floatingCursorController;

  // Keyboard
  KeyboardListener _keyboardListener;

  TextInputConnection _textInputConnection;
  EditorTextSelectionOverlay _selectionOverlay;

  ScrollController _scrollController;

  final ClipboardStatusNotifier _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;
  FocusAttachment _focusAttachment;
  bool get _hasFocus => widget.focusNode.hasFocus;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

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
  @override
  RenderEditor get renderEditor => _editorKey.currentContext.findRenderObject();

  // Start text Input connection

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus) {
      openConnectionIfNeeded();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay.showToolbar();
    return true;
  }

  // State lifecycle:

  @override
  void initState() {
    super.initState();

    _clipboardStatus?.addListener(_onChangedClipboardStatus);

    widget.controller.addListener(_didChangeTextEditingValue);

    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(() {
      _selectionOverlay?.updateForScroll();
    });

    // Cursor
    _cursorController = CursorController(
      showCursor: ValueNotifier<bool>(widget.showCursor ?? false),
      style: widget.cursorStyle ??
          CursorStyle(
            // TODO: fallback to current theme's accent color
            color: Colors.blueAccent,
            backgroundColor: Colors.grey,
            width: 2.0,
          ),
      tickerProvider: this,
    );

    // Keyboard
    _keyboardListener = KeyboardListener(
      onCursorMovement: handleCursorMovement,
      onShortcut: handleShortcut,
      onDelete: handleDelete,
    );

    // Focus
    _focusAttachment = widget.focusNode.attach(context,
        onKey: (node, event) => _keyboardListener.handleKeyEvent(event));
    widget.focusNode.addListener(_handleFocusChanged);
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

    _cursorController.showCursor.value = widget.showCursor;
    _cursorController.style = widget.cursorStyle;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      updateRemoteValueIfNeeded();
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context,
          onKey: (node, event) => _keyboardListener.handleKeyEvent(event));
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(textEditingValue);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;

    if (widget.readOnly) {
      closeConnectionIfNeeded();
    } else if (oldWidget.readOnly && _hasFocus) {
      openConnectionIfNeeded();
    }

//    if (widget.style != oldWidget.style) {
//      final TextStyle style = widget.style;
//      _textInputConnection?.setStyle(
//        fontFamily: style.fontFamily,
//        fontSize: style.fontSize,
//        fontWeight: style.fontWeight,
//        textDirection: _textDirection,
//        textAlign: widget.textAlign,
//      );
//    }
  }

  @override
  void dispose() {
    closeConnectionIfNeeded();
    assert(!hasConnection);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.controller.removeListener(_didChangeTextEditingValue);
    widget.focusNode.removeListener(_handleFocusChanged);
    _focusAttachment.detach();
    _cursorController.dispose();
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    super.dispose();
  }

  void _didChangeTextEditingValue() {
    requestKeyboard();

    updateRemoteValueIfNeeded();
    _cursorController.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    if (hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorController.stopCursorTimer(resetCharTicks: false);
      _cursorController.startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor. Otherwise this will
    // fail in situations where a new line of text is entered, which adds
    // a new RenderEditableBox child. If we try to update selection overlay
    // immediately it'll not be able to find the new child since it hasn't been
    // built yet.
    SchedulerBinding.instance.addPostFrameCallback(
        (Duration _) => _updateOrDisposeSelectionOverlayIfNeeded());
//    _textChangedSinceLastCaretUpdate = true;

    setState(() {/* We use widget.controller.value in build(). */});
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [EditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    // if (!widget.controller.isSelectionWithinTextBounds(selection))
    //   return;

    widget.controller.updateSelection(selection, source: ChangeSource.local);

    // This will show the keyboard for all selection changes on the
    // EditableWidget, not just changes triggered by user gestures.
    requestKeyboard();
  }

  void _handleFocusChanged() {
    openOrCloseConnection();
    _cursorController.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance.addObserver(this);
//      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
//      _showCaretOnScreen();
//      if (!_value.selection.isValid) {
      // Place cursor at the end if the selection is invalid when we receive focus.
//        _handleSelectionChanged(TextSelection.collapsed(offset: _value.text.length), renderEditable, null);
//      }
    } else {
      WidgetsBinding.instance.removeObserver(this);
      // Clear the selection and composition state if this widget lost focus.
      widget.controller.updateSelection(TextSelection.collapsed(offset: 0),
          source: ChangeSource.local);
//      _currentPromptRectRange = null;
    }
    updateKeepAlive();
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay.update(textEditingValue);
      } else {
        _selectionOverlay.dispose();
        _selectionOverlay = null;
      }
    } else if (_hasFocus) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;

      if (widget.selectionControls != null) {
        _selectionOverlay = EditorTextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: textEditingValue,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditor,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: widget.dragStartBehavior,
          // onSelectionHandleTapped: widget.onSelectionHandleTapped,
        );
        _selectionOverlay.handlesVisible = widget.showSelectionHandles;
        _selectionOverlay.showHandles();
        // if (widget.onSelectionChanged != null)
        //   widget.onSelectionChanged(selection, cause);
      }
    }
  }

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment.reparent();
    super.build(context); // See AutomaticKeepAliveClientMixin.

//    final TextSelectionControls controls = widget.selectionControls;

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: Container(
        // constraints: BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
//      excludeFromSemantics: true,
//      axisDirection: AxisDirection.down,
          controller: _scrollController,
          physics: widget.scrollPhysics,
          dragStartBehavior: widget.dragStartBehavior,
          child: CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: Semantics(
//            onCopy: _semanticsOnCopy(controls),
//            onCut: _semanticsOnCut(controls),
//            onPaste: _semanticsOnPaste(controls),
              child: _Editor(
                key: _editorKey,
                children: _buildChildren(context),
                document: widget.controller.document,
                selection: widget.controller.selection,
                hasFocus: _hasFocus,
                textDirection: _textDirection,
                startHandleLayerLink: _startHandleLayerLink,
                endHandleLayerLink: _endHandleLayerLink,
                onSelectionChanged: _handleSelectionChanged,
                // Not implemented fields:
                maxHeight: widget.maxHeight,
                minHeight: widget.minHeight,
                strutStyle: widget.strutStyle,
                selectionColor: widget.selectionColor,
                textScaleFactor: widget.textScaleFactor ??
                    MediaQuery.textScaleFactorOf(context),
                readOnly: widget.readOnly,
                locale: widget.locale,
                devicePixelRatio: _devicePixelRatio,
                enableInteractiveSelection: widget.enableInteractiveSelection,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    for (final node in widget.controller.document.root.children) {
      if (node is LineNode) {
        result.add(EditableTextLine(
          node: node,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          body: TextLine(node: node, textDirection: _textDirection),
        ));
      } else if (node is BlockNode) {
        result.add(EditableTextBlock(
          node: node,
          textDirection: _textDirection,
          // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
        ));
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }
}

class _Editor extends MultiChildRenderObjectWidget {
  _Editor({
    @required Key key,
    @required List<Widget> children,
    @required this.document,
    @required this.textDirection,
    @required this.hasFocus,
    @required this.selection,
    @required this.selectionColor,
    @required this.enableInteractiveSelection,
    @required this.startHandleLayerLink,
    @required this.endHandleLayerLink,
    @required this.onSelectionChanged,
    // Not implemented fields:
    @required this.maxHeight,
    @required this.minHeight,
    @required this.strutStyle,
    @required this.textScaleFactor,
    @required this.readOnly,
    @required this.locale,
    @required this.devicePixelRatio,
  }) : super(key: key, children: children);

  final NotusDocument document;
  final TextDirection textDirection;
  final bool hasFocus;
  final TextSelection selection;
  final Color selectionColor;

  /// Whether to enable user interface affordances for changing the
  /// text selection.
  ///
  /// For example, setting this to true will enable features such as
  /// long-pressing the TextField to select text and show the
  /// cut/copy/paste menu, and tapping to move the text caret.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  final bool enableInteractiveSelection;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final TextSelectionChangedHandler onSelectionChanged;
  // Not implemented fields:
  final double maxHeight;
  final double minHeight;
  final StrutStyle strutStyle;
  final double textScaleFactor;
  final bool readOnly;
  final Locale locale;
  final double devicePixelRatio;

  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor(
      document: document,
      textDirection: textDirection,
      hasFocus: hasFocus,
      selection: selection,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      onSelectionChanged: onSelectionChanged,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    renderObject.document = document;
    renderObject.node = document.root;
    renderObject.textDirection = textDirection;
    renderObject.hasFocus = hasFocus;
    renderObject.selection = selection;
    renderObject.startHandleLayerLink = startHandleLayerLink;
    renderObject.endHandleLayerLink = endHandleLayerLink;
    renderObject.onSelectionChanged = onSelectionChanged;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO
//    properties.add(EnumProperty<Axis>('direction', direction));
  }
}
