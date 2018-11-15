// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_text.dart';
import 'image.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'toolbar.dart';

class ZefyrEditorScope extends ChangeNotifier {
  ZefyrEditorScope({
    @required ZefyrImageDelegate imageDelegate,
    @required ZefyrController controller,
    @required FocusNode focusNode,
    @required FocusScopeNode focusScope,
  })  : _controller = controller,
        _imageDelegate = imageDelegate,
        _focusScope = focusScope,
        _focusNode = focusNode {
    _selectionStyle = _controller.getSelectionStyle();
    _selection = _controller.selection;
    _controller.addListener(_handleControllerChange);
    _focusNode.addListener(_handleFocusChange);
  }

  bool _disposed = false;

  ZefyrImageDelegate _imageDelegate;
  ZefyrImageDelegate get imageDelegate => _imageDelegate;

  FocusScopeNode _focusScope;
  FocusNode _focusNode;

  ZefyrController _controller;
  NotusStyle get selectionStyle => _selectionStyle;
  NotusStyle _selectionStyle;
  TextSelection get selection => _selection;
  TextSelection _selection;

  @override
  void dispose() {
    assert(!_disposed);
    _controller.removeListener(_handleControllerChange);
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

  FocusNode _toolbarFocusNode;

  void setToolbarFocusNode(FocusNode node) {
    assert(!_disposed || node == null);
    if (_toolbarFocusNode != node) {
      _toolbarFocusNode?.removeListener(_handleFocusChange);
      _toolbarFocusNode = node;
      _toolbarFocusNode?.addListener(_handleFocusChange);
      // We do not notify listeners here because it will happen when
      // focus state changes, see [_handleFocusChange].
    }
  }

  FocusOwner get focusOwner {
    assert(!_disposed);
    if (_focusNode.hasFocus) {
      return FocusOwner.editor;
    } else if (_toolbarFocusNode?.hasFocus == true) {
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

  void focus() {
    assert(!_disposed);
    _focusScope.requestFocus(_focusNode);
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
    this.physics,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool enabled;
  final ZefyrToolbarDelegate toolbarDelegate;
  final ZefyrImageDelegate imageDelegate;
  final ScrollPhysics physics;

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
  ZefyrImageDelegate _imageDelegate;
  ZefyrEditorScope _scope;
  ZefyrThemeData _themeData;
  GlobalKey<ZefyrToolbarState> _toolbarKey;
  ZefyrScaffoldState _scaffold;

  bool get hasToolbar => _toolbarKey != null;

  void showToolbar() {
    assert(_toolbarKey == null);
    _toolbarKey = GlobalKey();
    _scaffold.showToolbar(buildToolbar);
  }

  void hideToolbar() {
    if (_toolbarKey == null) return;
    _scaffold.hideToolbar();
    _toolbarKey = null;
  }

  Widget buildToolbar(BuildContext) {
    return ZefyrTheme(
      data: _themeData,
      child: ZefyrToolbar(
        key: _toolbarKey,
        editor: _scope,
        delegate: widget.toolbarDelegate,
      ),
    );
  }

  void _handleChange() {
    if (_scope.focusOwner == FocusOwner.none) {
      hideToolbar();
    } else if (!hasToolbar) {
      showToolbar();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toolbarKey?.currentState?.markNeedsRebuild();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _imageDelegate = widget.imageDelegate ?? new ZefyrDefaultImageDelegate();
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

    if (_scope == null) {
      _scope = ZefyrEditorScope(
        imageDelegate: _imageDelegate,
        controller: widget.controller,
        focusNode: widget.focusNode,
        focusScope: FocusScope.of(context),
      );
      _scope.addListener(_handleChange);
    } else {
      final focusScope = FocusScope.of(context);
      if (focusScope != _scope._focusScope) {
        _scope._focusScope = focusScope;
      }
    }

    final scaffold = ZefyrScaffold.of(context);
    if (_scaffold != scaffold) {
      bool didHaveToolbar = hasToolbar;
      hideToolbar();
      _scaffold = scaffold;
      if (didHaveToolbar) showToolbar();
    }
  }

  @override
  void dispose() {
    hideToolbar();
    _scope.removeListener(_handleChange);
    _scope.dispose();
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
      physics: widget.physics,
    );

    return ZefyrTheme(
      data: _themeData,
      child: _ZefyrEditorScope(
        scope: _scope,
        child: editable,
      ),
    );
  }
}
