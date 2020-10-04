import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

class AutoHideToolbar extends StatefulWidget {
  final ZefyrController controller;
  final FocusNode focusNode;
  const AutoHideToolbar(
      {@required this.controller, @required this.focusNode, Key key})
      : super(key: key);

  @override
  _AutoHideToolbarState createState() => _AutoHideToolbarState();
}

class _AutoHideToolbarState extends State<AutoHideToolbar> {
  bool _activeMenu = false;
  final _toolbarFocusNode = FocusNode();

  void _onToggleMenu(bool active) {
    setState(() {
      _activeMenu = active;
    });
  }

  _onFocusChange() {
    setState(() => null);
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _toolbarFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AutoHideToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _toolbarFocusNode.hasFocus || widget.focusNode.hasFocus || _activeMenu;
    print(
        'ToobarFocus: ${_toolbarFocusNode.hasFocus} EditorFocus: ${widget.focusNode.hasFocus} ToolbarPopupFocus: ${_activeMenu}');
    return Focus(
        focusNode: _toolbarFocusNode,
        child: Visibility(
            visible: visible,
            child: ZefyrToolbar.basic(
                controller: widget.controller, onShowMenu: _onToggleMenu)));
  }
}
