// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_text.dart';
import 'image.dart';
import 'theme.dart';
import 'toolbar.dart';

class ZefyrEditorScope extends ChangeNotifier {
  ZefyrEditorScope({
    @required ZefyrImageDelegate imageDelegate,
    @required ZefyrController controller,
    @required FocusNode focusNode,
    @required FocusNode toolbarFocusNode,
  })  : _controller = controller,
        _imageDelegate = imageDelegate,
        _focusNode = focusNode,
        _toolbarFocusNode = toolbarFocusNode {
    _selectionStyle = _controller.getSelectionStyle();
    _selection = _controller.selection;
    _controller.addListener(_handleControllerChange);
    toolbarFocusNode.addListener(_handleFocusChange);
    _focusNode.addListener(_handleFocusChange);
  }

  bool _disposed = false;

  ZefyrImageDelegate _imageDelegate;
  ZefyrImageDelegate get imageDelegate => _imageDelegate;

  FocusNode _focusNode;
  FocusNode _toolbarFocusNode;
  FocusNode get toolbarFocusNode => _toolbarFocusNode;

  ZefyrController _controller;
  NotusStyle get selectionStyle => _selectionStyle;
  NotusStyle _selectionStyle;
  TextSelection get selection => _selection;
  TextSelection _selection;

  @override
  void dispose() {
    assert(!_disposed);
    _controller.removeListener(_handleControllerChange);
    _toolbarFocusNode.removeListener(_handleFocusChange);
    _focusNode.removeListener(_handleFocusChange);
    _disposed = true;
    super.dispose();
  }

  void _updateControllerIfNeeded(ZefyrController value) {
    if (_controller != value) {
      _controller.removeListener(_handleControllerChange);
      _controller = value;
      _selectionStyle = _controller.getSelectionStyle();
      _selection = _controller.selection;
      _controller.addListener(_handleControllerChange);
      notifyListeners();
    }
  }

  void _updateFocusNodeIfNeeded(FocusNode value) {
    if (_focusNode != value) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode = value;
      _focusNode.addListener(_handleFocusChange);
      notifyListeners();
    }
  }

  void _updateImageDelegateIfNeeded(ZefyrImageDelegate value) {
    if (_imageDelegate != value) {
      _imageDelegate = value;
      notifyListeners();
    }
  }

  void _handleControllerChange() {
    assert(!_disposed);
    final attrs = _controller.getSelectionStyle();
    final selection = _controller.selection;
    if (_selectionStyle != attrs || _selection != selection) {
      _selectionStyle = attrs;
      _selection = _controller.selection;
      notifyListeners();
    }
  }

  void _handleFocusChange() {
    assert(!_disposed);
    if (focusOwner == FocusOwner.none && !_selection.isCollapsed) {
      // Collapse selection if there is nothing focused.
      _controller.updateSelection(_selection.copyWith(
        baseOffset: _selection.extentOffset,
        extentOffset: _selection.extentOffset,
      ));
    }
    notifyListeners();
  }

  FocusOwner get focusOwner {
    assert(!_disposed);
    if (_focusNode.hasFocus) {
      return FocusOwner.editor;
    } else if (toolbarFocusNode.hasFocus) {
      return FocusOwner.toolbar;
    } else {
      return FocusOwner.none;
    }
  }

  void updateSelection(TextSelection value,
      {ChangeSource source: ChangeSource.remote}) {
    assert(!_disposed);
    _controller.updateSelection(value, source: source);
  }

  void formatSelection(NotusAttribute value) {
    assert(!_disposed);
    _controller.formatSelection(value);
  }

  void focus(BuildContext context) {
    assert(!_disposed);
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void hideKeyboard() {
    assert(!_disposed);
    _focusNode.unfocus();
  }
}

class _ZefyrEditorScope extends InheritedWidget {
  final ZefyrEditorScope scope;

  _ZefyrEditorScope({Key key, Widget child, @required this.scope})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ZefyrEditorScope oldWidget) {
    return oldWidget.scope != scope;
  }
}

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
    this.imageDelegate,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool enabled;
  final ZefyrToolbarDelegate toolbarDelegate;
  final ZefyrImageDelegate imageDelegate;

  /// Padding around editable area.
  final EdgeInsets padding;

  static ZefyrEditorScope of(BuildContext context) {
    _ZefyrEditorScope widget =
        context.inheritFromWidgetOfExactType(_ZefyrEditorScope);
    return widget.scope;
  }

  @override
  _ZefyrEditorState createState() => new _ZefyrEditorState();
}

class _ZefyrEditorState extends State<ZefyrEditor> {
  final FocusNode _toolbarFocusNode = new FocusNode();
  ZefyrImageDelegate _imageDelegate;
  ZefyrEditorScope _scope;
  ZefyrThemeData _themeData;

  OverlayEntry _toolbar;
  OverlayState _overlay;

  void showToolbar() {
    _toolbar = new OverlayEntry(
      builder: (context) => _ZefyrToolbarContainer(
            theme: _themeData,
            toolbar: ZefyrToolbar(
              focusNode: _toolbarFocusNode,
              editor: _scope,
              delegate: widget.toolbarDelegate,
            ),
          ),
    );
    _overlay.insert(_toolbar);
  }

  void hideToolbar() {
    _toolbar?.remove();
    _toolbar = null;
  }

  void _handleChange() {
    if (_scope.focusOwner == FocusOwner.none) {
      hideToolbar();
    } else if (_toolbar == null) {
      showToolbar();
    }
  }

  @override
  void initState() {
    super.initState();
    _imageDelegate = widget.imageDelegate ?? new ZefyrDefaultImageDelegate();
    _scope = ZefyrEditorScope(
      toolbarFocusNode: _toolbarFocusNode,
      imageDelegate: _imageDelegate,
      controller: widget.controller,
      focusNode: widget.focusNode,
    );
    _scope.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(ZefyrEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scope._updateControllerIfNeeded(widget.controller);
    _scope._updateFocusNodeIfNeeded(widget.focusNode);
    if (widget.imageDelegate != oldWidget.imageDelegate) {
      _imageDelegate = widget.imageDelegate ?? new ZefyrDefaultImageDelegate();
      _scope._updateImageDelegateIfNeeded(_imageDelegate);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final parentTheme = ZefyrTheme.of(context, nullOk: true);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    _themeData = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;

    final overlay = Overlay.of(context, debugRequiredFor: widget);
    if (_overlay != overlay) {
      hideToolbar();
      _overlay = overlay;
      // TODO: update toolbar.
    }
  }

  @override
  void dispose() {
    hideToolbar();
    _scope.removeListener(_handleChange);
    _scope.dispose();
    _toolbarFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget editable = new ZefyrEditableText(
      controller: widget.controller,
      focusNode: widget.focusNode,
      imageDelegate: _imageDelegate,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      padding: widget.padding,
    );

    final children = <Widget>[];
    children.add(Expanded(child: editable));
    if (_toolbar != null) {
      children.add(SizedBox(height: ZefyrToolbar.kToolbarHeight));
    }
//    final toolbar = ZefyrToolbar(
//      editor: _scope,
//      focusNode: _toolbarFocusNode,
//      delegate: widget.toolbarDelegate,
//    );
//    children.add(toolbar);

    return ZefyrTheme(
      data: _themeData,
      child: _ZefyrEditorScope(
        scope: _scope,
        child: Column(children: children),
      ),
    );
  }
}

class _ZefyrToolbarContainer extends StatelessWidget {
  final ZefyrThemeData theme;
  final Widget toolbar;

  const _ZefyrToolbarContainer({Key key, this.theme, this.toolbar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      bottom: media.viewInsets.bottom,
      left: 0.0,
      right: 0.0,
      child: ZefyrTheme(data: theme, child: toolbar),
    );
  }
}
