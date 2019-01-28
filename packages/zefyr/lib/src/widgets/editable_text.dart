// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'code.dart';
import 'common.dart';
import 'controller.dart';
import 'editable_box.dart';
import 'editor.dart';
import 'image.dart';
import 'input.dart';
import 'list.dart';
import 'paragraph.dart';
import 'quote.dart';
import 'render_context.dart';
import 'selection.dart';

/// Core widget responsible for editing Zefyr documents.
///
/// Depends on presence of [ZefyrTheme] somewhere up the widget tree.
///
/// Consider using [ZefyrEditor] which wraps this widget and adds a toolbar to
/// edit style attributes.
class ZefyrEditableText extends StatefulWidget {
  const ZefyrEditableText({
    Key key,
    @required this.controller,
    @required this.focusNode,
    @required this.imageDelegate,
    this.autofocus: true,
    this.enabled: true,
    this.padding: const EdgeInsets.symmetric(horizontal: 16.0),
    this.physics,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final ZefyrImageDelegate imageDelegate;
  final bool autofocus;
  final bool enabled;
  final ScrollPhysics physics;

  /// Padding around editable area.
  final EdgeInsets padding;

  static ZefyrEditableTextScope of(BuildContext context) {
    final ZefyrEditableTextScope result =
        context.inheritFromWidgetOfExactType(ZefyrEditableTextScope);
    return result;
  }

  @override
  _ZefyrEditableTextState createState() => new _ZefyrEditableTextState();
}

/// Provides access to shared state of [ZefyrEditableText].
class ZefyrEditableTextScope extends InheritedWidget {
  static const _kEquality = const SetEquality<RenderEditableBox>();

  ZefyrEditableTextScope({
    Key key,
    @required Widget child,
    @required this.selection,
    @required this.showCursor,
    @required this.renderContext,
    @required this.imageDelegate,
  })  : _activeBoxes = new Set.from(renderContext.active),
        super(key: key, child: child);

  final TextSelection selection;
  final ValueNotifier<bool> showCursor;
  final ZefyrRenderContext renderContext;
  final ZefyrImageDelegate imageDelegate;
  final Set<RenderEditableBox> _activeBoxes;

  @override
  bool updateShouldNotify(ZefyrEditableTextScope oldWidget) {
    return selection != oldWidget.selection ||
        showCursor != oldWidget.showCursor ||
        imageDelegate != oldWidget.imageDelegate ||
        !_kEquality.equals(_activeBoxes, oldWidget._activeBoxes);
  }
}

class _ZefyrEditableTextState extends State<ZefyrEditableText>
    with AutomaticKeepAliveClientMixin {
  //
  // New public members
  //

  /// Focus node of this widget.
  FocusNode get focusNode => widget.focusNode;

  /// Document controlled by this widget.
  NotusDocument get document => widget.controller.document;

  /// Current text selection.
  TextSelection get selection => widget.controller.selection;
  ZefyrRenderContext get renderContext => _renderContext;
  ValueNotifier<bool> get showCursor => _cursorTimer.value;

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (focusNode.hasFocus)
      _input.openConnection(widget.controller.plainTextEditingValue);
    else
      FocusScope.of(context).requestFocus(focusNode);
  }

  void focusOrUnfocusIfNeeded() {
    if (!_didAutoFocus && widget.autofocus && widget.enabled) {
      FocusScope.of(context).autofocus(focusNode);
      _didAutoFocus = true;
    }
    if (!widget.enabled && focusNode.hasFocus) {
      _didAutoFocus = false;
      focusNode.unfocus();
    }
  }

  //
  // Overridden members of State
  //

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(focusNode);
    super.build(context); // See AutomaticKeepAliveState.
    ZefyrEditor.of(context);

    Widget body = ListBody(children: _buildChildren(context));
    if (widget.padding != null) {
      body = new Padding(padding: widget.padding, child: body);
    }
    final scrollable = SingleChildScrollView(
      physics: widget.physics,
      controller: _scrollController,
      child: body,
    );

    final overlay = Overlay.of(context, debugRequiredFor: widget);
    final layers = <Widget>[scrollable];
    if (widget.enabled) {
      layers.add(ZefyrSelectionOverlay(
        controller: widget.controller,
        controls: cupertinoTextSelectionControls,
        overlay: overlay,
      ));
    }

    return new ZefyrEditableTextScope(
      selection: selection,
      showCursor: showCursor,
      renderContext: renderContext,
      imageDelegate: widget.imageDelegate,
      child: Stack(fit: StackFit.expand, children: layers),
    );
  }

  @override
  void initState() {
    super.initState();
    _input = new InputConnectionController(_handleRemoteValueChange);
    _updateSubscriptions();
  }

  @override
  void didUpdateWidget(ZefyrEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSubscriptions(oldWidget);
    focusOrUnfocusIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    focusOrUnfocusIfNeeded();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  //
  // Overridden members of AutomaticKeepAliveClientMixin
  //

  @override
  bool get wantKeepAlive => focusNode.hasFocus;

  //
  // Private members
  //

  final ScrollController _scrollController = new ScrollController();
  final ZefyrRenderContext _renderContext = new ZefyrRenderContext();
  final _CursorTimer _cursorTimer = new _CursorTimer();
  InputConnectionController _input;
  bool _didAutoFocus = false;

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    for (var node in document.root.children) {
      result.add(_defaultChildBuilder(context, node));
    }
    return result;
  }

  Widget _defaultChildBuilder(BuildContext context, Node node) {
    if (node is LineNode) {
      if (node.hasEmbed) {
        return new RawZefyrLine(node: node);
      } else if (node.style.contains(NotusAttribute.heading)) {
        return new ZefyrHeading(node: node);
      }
      return new ZefyrParagraph(node: node);
    }

    final BlockNode block = node;
    final blockStyle = block.style.get(NotusAttribute.block);
    if (blockStyle == NotusAttribute.block.code) {
      return new ZefyrCode(node: node);
    } else if (blockStyle == NotusAttribute.block.bulletList) {
      return new ZefyrList(node: node);
    } else if (blockStyle == NotusAttribute.block.numberList) {
      return new ZefyrList(node: node);
    } else if (blockStyle == NotusAttribute.block.quote) {
      return new ZefyrQuote(node: node);
    }

    throw new UnimplementedError('Block format $blockStyle.');
  }

  void _updateSubscriptions([ZefyrEditableText oldWidget]) {
    if (oldWidget == null) {
      _renderContext.addListener(_handleRenderContextChange);
      widget.controller.addListener(_handleLocalValueChange);
      focusNode.addListener(_handleFocusChange);
      return;
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleLocalValueChange);
      widget.controller.addListener(_handleLocalValueChange);
      _input.updateRemoteValue(widget.controller.plainTextEditingValue);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      updateKeepAlive();
    }
  }

  void _cancelSubscriptions() {
    _renderContext.removeListener(_handleRenderContextChange);
    _renderContext.dispose();
    widget.controller.removeListener(_handleLocalValueChange);
    focusNode.removeListener(_handleFocusChange);
    _input.closeConnection();
    _cursorTimer.stop();
  }

  // Triggered for both text and selection changes.
  void _handleLocalValueChange() {
    if (widget.enabled &&
        widget.controller.lastChangeSource == ChangeSource.local) {
      // Only request keyboard for user actions.
      requestKeyboard();
    }
    _input.updateRemoteValue(widget.controller.plainTextEditingValue);
    _cursorTimer.startOrStop(focusNode, selection);
    setState(() {
      // nothing to update internally.
    });
  }

  void _handleFocusChange() {
    _input.openOrCloseConnection(
        focusNode, widget.controller.plainTextEditingValue);
    _cursorTimer.startOrStop(focusNode, selection);
    updateKeepAlive();
  }

  void _handleRemoteValueChange(
      int start, String deleted, String inserted, TextSelection selection) {
    widget.controller
        .replaceText(start, deleted.length, inserted, selection: selection);
  }

  void _handleRenderContextChange() {
    setState(() {
      // nothing to update internally.
    });
  }
}

/// Helper class that keeps state relevant to the cursor.
class _CursorTimer {
  static const _kCursorBlinkHalfPeriod = const Duration(milliseconds: 500);

  Timer _timer;
  final ValueNotifier<bool> _showCursor = new ValueNotifier<bool>(false);

  ValueNotifier<bool> get value => _showCursor;

  void _cursorTick(Timer timer) {
    _showCursor.value = !_showCursor.value;
  }

  /// Starts cursor timer.
  void start() {
    _showCursor.value = true;
    _timer = new Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  /// Stops cursor timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _showCursor.value = false;
  }

  /// Starts or stops cursor timer based on current state of [focusNode]
  /// and [selection].
  void startOrStop(FocusNode focusNode, TextSelection selection) {
    final hasFocus = focusNode.hasFocus;
    final selectionCollapsed = selection.isCollapsed;
    if (_timer == null && hasFocus && selectionCollapsed) {
      start();
    } else if (_timer != null && (!hasFocus || !selectionCollapsed)) {
      stop();
    }
  }
}
