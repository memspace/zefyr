import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '_controller.dart';
import '_cursor.dart';
import '_editor.dart';
import '_text_selection.dart';

class _TextFieldSelectionGestureDetectorBuilder
    extends EditorTextSelectionGestureDetectorBuilder {
  _TextFieldSelectionGestureDetectorBuilder({
    @required _ZefyrFieldState state,
  })  : _state = state,
        super(delegate: state);

  final _ZefyrFieldState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editor.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {
    // Not required.
  }

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditor.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  void _launchUrlIfNeeded(TapUpDetails details) {
    final pos = renderEditor.getPositionForOffset(details.globalPosition);
    final result = editor.widget.controller.document.lookupLine(pos.offset);
    if (result.node == null) return;
    final line = result.node as LineNode;
    final segmentResult = line.lookup(result.offset);
    if (segmentResult.node == null) return;
    final segment = segmentResult.node as LeafNode;
    if (segment.style.contains(NotusAttribute.link) &&
        editor.widget.onLaunchUrl != null) {
      if (editor.widget.readOnly) {
        editor.widget.onLaunchUrl(segment.style.get(NotusAttribute.link).value);
      } else {
        // TODO: Implement a toolbar to display the URL and allow to launch it.
        // editor.showToolbar();
      }
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    editor.hideToolbar();

    _launchUrlIfNeeded(details);

    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              renderEditor.selectPosition(cause: SelectionChangedCause.tap);
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
              // of the word.
              renderEditor.selectWordEdge(cause: SelectionChangedCause.tap);
              break;
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor.selectPosition(cause: SelectionChangedCause.tap);
          break;
      }
    }
    // _state._requestKeyboard();
    // if (_state.widget.onTap != null)
    //   _state.widget.onTap();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditor.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor.selectWord(cause: SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
      }
    }
  }
}

class ZefyrField extends StatefulWidget {
  final ZefyrController controller;
  final FocusNode focusNode;
  final EdgeInsetsGeometry padding;
  final bool readOnly;
  final bool showCursor;
  final ValueChanged<String> onLaunchUrl;

  const ZefyrField({
    Key key,
    @required this.controller,
    @required this.focusNode,
    this.padding = EdgeInsets.zero,
    this.readOnly = false,
    this.showCursor,
    this.onLaunchUrl,
  }) : super(key: key);

  @override
  _ZefyrFieldState createState() => _ZefyrFieldState();
}

class _ZefyrFieldState extends State<ZefyrField>
    implements EditorTextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  EditorTextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _TextFieldSelectionGestureDetectorBuilder(state: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Color cursorColor;
    Color selectionColor;
    Color autocorrectionTextRectColor;
    Radius cursorRadius;

    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // forcePressEnabled = true;
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        if (theme.useTextSelectionTheme) {
          cursorColor ??= selectionTheme.cursorColor ??
              CupertinoTheme.of(context).primaryColor;
          selectionColor = selectionTheme.selectionColor ??
              _defaultSelectionColor(
                  context, CupertinoTheme.of(context).primaryColor);
        } else {
          cursorColor ??= CupertinoTheme.of(context).primaryColor;
          selectionColor = theme.textSelectionColor;
        }
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        autocorrectionTextRectColor = selectionColor;
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // forcePressEnabled = false;
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        if (theme.useTextSelectionTheme) {
          cursorColor ??=
              selectionTheme.cursorColor ?? theme.colorScheme.primary;
          selectionColor = selectionTheme.selectionColor ??
              _defaultSelectionColor(context, theme.colorScheme.primary);
        } else {
          cursorColor ??= theme.cursorColor;
          selectionColor = theme.textSelectionColor;
        }
        break;
    }

    Widget child = RawEditor(
      key: _editorKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      padding: widget.padding,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      cursorStyle: CursorStyle(
        color: cursorColor,
        backgroundColor: Colors.grey,
        width: 2.0,
        radius: Radius.circular(1),
        opacityAnimates: true,
      ),
      onLaunchUrl: widget.onLaunchUrl,
      autofocus: true,
      selectionColor: selectionColor,
      showSelectionHandles: false,
      selectionControls: cupertinoTextSelectionControls,
    );

    return _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }

  @override
  GlobalKey<EditorState> get editableTextKey => _editorKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  Color _defaultSelectionColor(BuildContext context, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return primary.withOpacity(isDark ? 0.40 : 0.12);
  }
}
