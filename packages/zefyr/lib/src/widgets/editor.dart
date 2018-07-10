// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_text.dart';
import 'theme.dart';
import 'toolbar.dart';

/// Widget for editing Zefyr documents.
class ZefyrEditor extends StatefulWidget {
  const ZefyrEditor({
    Key key,
    @required this.controller,
    @required this.focusNode,
    this.autofocus: true,
    this.enabled: true,
    this.padding: const EdgeInsets.symmetric(horizontal: 16.0),
    this.toolbarDelegate,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool enabled;
  final ZefyrToolbarDelegate toolbarDelegate;

  /// Padding around editable area.
  final EdgeInsets padding;

  static ZefyrEditorScope of(BuildContext context) {
    ZefyrEditorScope scope =
        context.inheritFromWidgetOfExactType(ZefyrEditorScope);
    return scope;
  }

  @override
  _ZefyrEditorState createState() => new _ZefyrEditorState();
}

/// Inherited widget which provides access to shared state of a Zefyr editor.
class ZefyrEditorScope extends InheritedWidget {
  /// Current selection style
  final NotusStyle selectionStyle;
  final TextSelection selection;
  final FocusOwner focusOwner;
  final FocusNode toolbarFocusNode;
  final ZefyrController _controller;
  final FocusNode _focusNode;

  ZefyrEditorScope({
    Key key,
    @required Widget child,
    @required this.selectionStyle,
    @required this.selection,
    @required this.focusOwner,
    @required this.toolbarFocusNode,
    @required ZefyrController controller,
    @required FocusNode focusNode,
  })  : _controller = controller,
        _focusNode = focusNode,
        super(key: key, child: child);

  void updateSelection(TextSelection value,
      {ChangeSource source: ChangeSource.remote}) {
    _controller.updateSelection(value, source: source);
  }

  void formatSelection(NotusAttribute value) {
    _controller.formatSelection(value);
  }

  void focus(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void hideKeyboard() {
    _focusNode.unfocus();
  }

  @override
  bool updateShouldNotify(ZefyrEditorScope oldWidget) {
    return (selectionStyle != oldWidget.selectionStyle ||
        selection != oldWidget.selection ||
        focusOwner != oldWidget.focusOwner);
  }
}

class _ZefyrEditorState extends State<ZefyrEditor> {
  final FocusNode _toolbarFocusNode = new FocusNode();

  NotusStyle _selectionStyle;
  TextSelection _selection;
  FocusOwner _focusOwner;

  FocusOwner getFocusOwner() {
    if (widget.focusNode.hasFocus) {
      return FocusOwner.editor;
    } else if (_toolbarFocusNode.hasFocus) {
      return FocusOwner.toolbar;
    } else {
      return FocusOwner.none;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectionStyle = widget.controller.getSelectionStyle();
    _selection = widget.controller.selection;
    _focusOwner = getFocusOwner();
    widget.controller.addListener(_handleControllerChange);
    _toolbarFocusNode.addListener(_handleFocusChange);
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(ZefyrEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      _selectionStyle = widget.controller.getSelectionStyle();
      _selection = widget.controller.selection;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    widget.focusNode.removeListener(_handleFocusChange);
    _toolbarFocusNode.removeListener(_handleFocusChange);
    _toolbarFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget editable = new ZefyrEditableText(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
    );
    if (widget.padding != null) {
      editable = new Padding(padding: widget.padding, child: editable);
    }
    final children = <Widget>[];
    children.add(Expanded(child: editable));
    final toolbar = ZefyrToolbar(
      focusNode: _toolbarFocusNode,
      controller: widget.controller,
      delegate: widget.toolbarDelegate,
    );
    children.add(toolbar);

    final parentTheme = ZefyrTheme.of(context, nullOk: true);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    final actualTheme = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;

    return ZefyrTheme(
      data: actualTheme,
      child: ZefyrEditorScope(
        selection: _selection,
        selectionStyle: _selectionStyle,
        focusOwner: _focusOwner,
        toolbarFocusNode: _toolbarFocusNode,
        controller: widget.controller,
        focusNode: widget.focusNode,
        child: Column(children: children),
      ),
    );
  }

  void _handleControllerChange() {
    final attrs = widget.controller.getSelectionStyle();
    final selection = widget.controller.selection;
    if (_selectionStyle != attrs || _selection != selection) {
      setState(() {
        _selectionStyle = attrs;
        _selection = widget.controller.selection;
      });
    }
  }

  void _handleFocusChange() {
    setState(() {
      _focusOwner = getFocusOwner();
      if (_focusOwner == FocusOwner.none && !_selection.isCollapsed) {
        // Collapse selection if there is nothing focused.
        widget.controller.updateSelection(_selection.copyWith(
          baseOffset: _selection.extentOffset,
          extentOffset: _selection.extentOffset,
        ));
      }
    });
  }
}
