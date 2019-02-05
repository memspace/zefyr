// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:zefyr/src/widgets/common.dart';

import 'controller.dart';
import 'editable_text.dart';
import 'image.dart';
import 'scaffold.dart';
import 'scope.dart';
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
    this.embedWidgetDelegate,
    this.physics,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final bool enabled;
  final ZefyrToolbarDelegate toolbarDelegate;
  final EmbedWidgetDelegate embedWidgetDelegate;
  final ScrollPhysics physics;

  /// Padding around editable area.
  final EdgeInsets padding;

  @override
  _ZefyrEditorState createState() => new _ZefyrEditorState();
}

class _ZefyrEditorState extends State<ZefyrEditor> {
  EmbedWidgetDelegate _embedWidgetDelegate;
  ZefyrScope _scope;
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

  Widget buildToolbar(BuildContext context) {
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
      // TODO: is there a nicer way to do this?
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toolbarKey?.currentState?.markNeedsRebuild();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _embedWidgetDelegate = widget.embedWidgetDelegate ?? new DefaultEmbedWidgetDelegate();
  }

  @override
  void didUpdateWidget(ZefyrEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scope.controller = widget.controller;
    _scope.focusNode = widget.focusNode;
    if (widget.embedWidgetDelegate != oldWidget.embedWidgetDelegate) {
      _embedWidgetDelegate = widget.embedWidgetDelegate ?? new DefaultEmbedWidgetDelegate();
      _scope.embedWidgetDelegate = _embedWidgetDelegate;
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
      _scope = ZefyrScope.editable(
        embedWidgetDelegate: _embedWidgetDelegate,
        controller: widget.controller,
        focusNode: widget.focusNode,
        focusScope: FocusScope.of(context),
      );
      _scope.addListener(_handleChange);
    } else {
      final focusScope = FocusScope.of(context);
      _scope.focusScope = focusScope;
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
      controller: _scope.controller,
      focusNode: _scope.focusNode,
      embedWidgetDelegate: _scope.embedWidgetDelegate,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      padding: widget.padding,
      physics: widget.physics,
    );

    return ZefyrTheme(
      data: _themeData,
      child: ZefyrScopeAccess(
        scope: _scope,
        child: editable,
      ),
    );
  }
}
