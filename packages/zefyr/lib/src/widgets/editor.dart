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
import 'controller.dart';
import 'cursor.dart';
import 'editable_text_block.dart';
import 'editable_text_line.dart';
import 'editor_input_client_mixin.dart';
import 'editor_keyboard_mixin.dart';
import 'editor_selection_delegate_mixin.dart';
import 'text_line.dart';
import 'text_selection.dart';
import 'theme.dart';

abstract class ZefyrEmbedDelegate {
  Widget buildEmbed(BuildContext context, EmbeddableObject object);
}

class RawEditor extends StatefulWidget {
  RawEditor({
    Key key,
    @required this.controller,
    @required this.focusNode,
    this.padding = EdgeInsets.zero,
    @required this.selectionColor,
    this.enableInteractiveSelection = true,
    this.readOnly = false,
    this.onLaunchUrl,
    this.autocorrect = true,
    this.enableSuggestions = true,
    StrutStyle strutStyle,
    bool showCursor,
    this.cursorStyle,
    this.maxHeight,
    this.minHeight,
    this.autofocus = false,
    this.showSelectionHandles = false,
    this.selectionControls,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance = Brightness.light,
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
        assert(maxHeight == null || maxHeight > 0),
        assert(minHeight == null || minHeight >= 0),
        assert(
          (maxHeight == null) ||
              (minHeight == null) ||
              (maxHeight >= minHeight),
          'minHeight can\'t be greater than maxHeight',
        ),
        assert(autofocus != null),
        assert(toolbarOptions != null),
        // keyboardType = keyboardType ?? TextInputType.multiline,
        showCursor = showCursor ?? !readOnly,
        super(key: key);

  /// Controls the document being edited.
  final ZefyrController controller;

  /// Controls whether this editor has keyboard focus.
  final FocusNode focusNode;

  /// Additional space around the editor contents.
  final EdgeInsetsGeometry padding;

  /// Whether the text can be changed.
  ///
  /// When this is set to true, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to false. Must not be null.
  final bool readOnly;

  /// Callback which is triggered when the user wants to open a URL from
  /// a link in the document.
  final ValueChanged<String> onLaunchUrl;

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
  /// The cursor refers to the blinking caret when the editor is focused.
  ///
  /// See also:
  ///
  ///  * [cursorStyle], which controls the cursor visual representation.
  ///  * [showSelectionHandles], which controls the visibility of the selection
  ///    handles.
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

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// If true, then long-pressing this TextField will select text and show the
  /// cut/copy/paste menu, and tapping will move the text caret.
  ///
  /// True by default.
  ///
  /// If false, most of the accessibility support for selecting text, copy
  /// and paste, and moving the caret will be disabled.
  final bool enableInteractiveSelection;

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
    properties.add(DoubleProperty('maxLines', maxHeight, defaultValue: null));
    properties.add(DoubleProperty('minLines', minHeight, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
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
  EditorTextSelectionOverlay get selectionOverlay;
  bool showToolbar();
  void hideToolbar();
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

  // Theme
  ZefyrThemeData _themeData;

  // Cursors
  CursorController _cursorController;
  FloatingCursorController _floatingCursorController;

  // Keyboard
  KeyboardListener _keyboardListener;

  // Selection overlay
  @override
  EditorTextSelectionOverlay get selectionOverlay => _selectionOverlay;
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
    final result = Directionality.of(context);
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

    _scrollController = ScrollController();
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
    final parentTheme = ZefyrTheme.of(context, nullOk: true);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    _themeData = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;

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

    if (!shouldCreateInputConnection) {
      closeConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        openConnectionIfNeeded();
      }
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

    _showCaretOnScreen();
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
    widget.controller.updateSelection(selection, source: ChangeSource.local);

    // This will show the keyboard for all selection changes on the
    // editor, not just changes triggered by user gestures.
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
      _showCaretOnScreen();
//      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
//      if (!_value.selection.isValid) {
      // Place cursor at the end if the selection is invalid when we receive focus.
//        _handleSelectionChanged(TextSelection.collapsed(offset: _value.text.length), renderEditable, null);
//      }
    } else {
      WidgetsBinding.instance.removeObserver(this);
      // TODO: teach editor about state of the toolbar and whether the user is in the middle of applying styles.
      //       this is needed because some buttons in toolbar can steal focus from the editor
      //       but we want to preserve the selection, maybe adjusting its style slightly.
      //
      // Clear the selection and composition state if this widget lost focus.
      // widget.controller.updateSelection(TextSelection.collapsed(offset: 0),
      //     source: ChangeSource.local);
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
          dragStartBehavior: DragStartBehavior.start,
          // onSelectionHandleTapped: widget.onSelectionHandleTapped,
        );
        _selectionOverlay.handlesVisible = widget.showSelectionHandles;
        _selectionOverlay.showHandles();
        // if (widget.onSelectionChanged != null)
        //   widget.onSelectionChanged(selection, cause);
      }
    }
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _showCaretOnScreen() {
    if (!widget.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _showCaretOnScreenScheduled = false;

      final offset = renderEditor.getOffsetToRevealCursor(
          _scrollController.position.viewportDimension,
          _scrollController.offset);

      if (offset != null) {
        _scrollController.animateTo(
          offset,
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
      }
    });
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

    return ZefyrTheme(
      data: _themeData,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Container(
          // constraints: BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            // excludeFromSemantics: true,
            controller: _scrollController,
            physics: widget.scrollPhysics,
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
                  padding: widget.padding,
                ),
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
          textDirection: _textDirection,
          indentWidth: 0,
          spacing: _getSpacingForLine(node, _themeData),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          body: TextLine(node: node, textDirection: _textDirection),
          hasFocus: _hasFocus,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        ));
      } else if (node is BlockNode) {
        final block = node.style.get(NotusAttribute.block);
        result.add(EditableTextBlock(
          node: node,
          textDirection: _textDirection,
          spacing: _getSpacingForBlock(node, _themeData),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          hasFocus: _hasFocus,
          contentPadding: (block == NotusAttribute.block.code)
              ? EdgeInsets.all(16.0)
              : null,
        ));
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }

  VerticalSpacing _getSpacingForLine(LineNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.heading);
    if (style == NotusAttribute.heading.level1) {
      return theme.heading1.spacing;
    } else if (style == NotusAttribute.heading.level2) {
      return theme.heading2.spacing;
    } else if (style == NotusAttribute.heading.level3) {
      return theme.heading3.spacing;
    }

    return theme.paragraph.spacing;
  }

  VerticalSpacing _getSpacingForBlock(BlockNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.code) {
      return theme.code.spacing;
    } else if (style == NotusAttribute.block.quote) {
      return theme.quote.spacing;
    } else {
      return theme.lists.spacing;
    }
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
    @required this.startHandleLayerLink,
    @required this.endHandleLayerLink,
    @required this.onSelectionChanged,
    this.padding = EdgeInsets.zero,
  }) : super(key: key, children: children);

  final NotusDocument document;
  final TextDirection textDirection;
  final bool hasFocus;
  final TextSelection selection;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final TextSelectionChangedHandler onSelectionChanged;
  final EdgeInsetsGeometry padding;

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
      padding: padding,
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
    renderObject.padding = padding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO
//    properties.add(EnumProperty<Axis>('direction', direction));
  }
}
