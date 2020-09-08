import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '_controller.dart';

const double kToolbarHeight = 56.0;

enum ToggleAttribute { bold, italic, bulletList, numberList, code, quote }

typedef ToggleButtonBuilder = Widget Function(BuildContext context,
    ToggleAttribute attribute, bool isToggled, VoidCallback onPressed);

class ToggleButton extends StatefulWidget {
  final ToggleAttribute attribute;
  final ZefyrController controller;
  final ToggleButtonBuilder childBuilder;

  const ToggleButton({
    Key key,
    @required this.attribute,
    @required this.controller,
    @required this.childBuilder,
  }) : super(key: key);

  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}

final Map<ToggleAttribute, NotusAttribute> _attributeMap = {
  ToggleAttribute.bold: NotusAttribute.bold,
  ToggleAttribute.italic: NotusAttribute.italic,
  ToggleAttribute.quote: NotusAttribute.block.quote,
};

class _ToggleButtonState extends State<ToggleButton> {
  bool _isToggled;

  NotusAttribute get _attribute => _attributeMap[widget.attribute];

  void _didChangeEditingValue() {
    setState(() {
      _isToggled = widget.controller.getSelectionStyle().contains(_attribute);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = widget.controller.getSelectionStyle().contains(_attribute);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant ToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = widget.controller.getSelectionStyle().contains(_attribute);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(
        context, widget.attribute, _isToggled, _toggleAttribute);
  }

  void _toggleAttribute() {
    if (_isToggled) {
      widget.controller.formatSelection(_attribute.unset);
    } else {
      widget.controller.formatSelection(_attribute);
    }
  }
}

Widget _defaultToggleButtonBuilder(BuildContext context,
    ToggleAttribute attribute, bool isToggled, VoidCallback onPressed) {
  return ZIconButton(
    highlightElevation: 0,
    hoverElevation: 0,
    icon: Icon(
      _defaultToggleIcons[attribute],
      size: 20,
      color: isToggled
          ? Theme.of(context).primaryIconTheme.color
          : Theme.of(context).iconTheme.color,
    ),
    fillColor: isToggled
        ? Theme.of(context).toggleableActiveColor
        : Theme.of(context).buttonColor,
    onPressed: onPressed,
  );
}

final Map<ToggleAttribute, IconData> _defaultToggleIcons = {
  ToggleAttribute.bold: Icons.format_bold,
  ToggleAttribute.italic: Icons.format_italic,
  ToggleAttribute.quote: Icons.format_quote,
};

class EditorToolbar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget> children;

  const EditorToolbar({Key key, @required this.children}) : super(key: key);

  factory EditorToolbar.basic({
    Key key,
    @required ZefyrController controller,
    @required FocusNode editorFocusNode,
  }) {
    return EditorToolbar(key: key, children: [
      ToggleButton(
        attribute: ToggleAttribute.bold,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      ToggleButton(
        attribute: ToggleAttribute.italic,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      ToggleButton(
        attribute: ToggleAttribute.quote,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
    ]);
  }

  @override
  _EditorToolbarState createState() => _EditorToolbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _EditorToolbarState extends State<EditorToolbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints.tightFor(height: widget.preferredSize.height),
      child: Row(
        children: widget.children,
      ),
    );
  }
}

/// Default icon button used in Zefyr editor toolbar.
///
/// Named with a "Z" prefix to distinguish from the Flutter's built-in version.
class ZIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final double size;
  final Color fillColor;
  final double hoverElevation;
  final double highlightElevation;

  const ZIconButton({
    Key key,
    @required this.onPressed,
    this.icon,
    this.size = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      child: icon,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      padding: EdgeInsets.zero,
      fillColor: fillColor,
      elevation: 0,
      hoverElevation: hoverElevation,
      highlightElevation: hoverElevation,
      onPressed: onPressed,
    );
  }
}
