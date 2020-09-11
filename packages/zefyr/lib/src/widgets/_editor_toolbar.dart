import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '_controller.dart';

const double kToolbarHeight = 56.0;

enum ToggleAttribute { bold, italic, bulletList, numberList, code, quote }

typedef ToggleButtonBuilder = Widget Function(BuildContext context,
    ToggleAttribute attribute, bool isToggled, VoidCallback onPressed);

class ToggleStyleButton extends StatefulWidget {
  final ToggleAttribute attribute;
  final ZefyrController controller;
  final ToggleButtonBuilder childBuilder;

  const ToggleStyleButton({
    Key key,
    @required this.attribute,
    @required this.controller,
    @required this.childBuilder,
  }) : super(key: key);

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

final Map<ToggleAttribute, NotusAttribute> _toggleAttributeMap = {
  ToggleAttribute.bold: NotusAttribute.bold,
  ToggleAttribute.italic: NotusAttribute.italic,
  ToggleAttribute.numberList: NotusAttribute.block.numberList,
  ToggleAttribute.bulletList: NotusAttribute.block.bulletList,
  ToggleAttribute.quote: NotusAttribute.block.quote,
  ToggleAttribute.code: NotusAttribute.block.code,
};

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  bool _isToggled;

  NotusAttribute get _attribute => _toggleAttributeMap[widget.attribute];

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          widget.controller.getSelectionStyle().containsSame(_attribute);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = widget.controller.getSelectionStyle().containsSame(_attribute);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled =
          widget.controller.getSelectionStyle().containsSame(_attribute);
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
    size: 32,
    icon: Icon(
      _defaultToggleIcons[attribute],
      size: 18,
      color: isToggled
          ? Theme.of(context).primaryIconTheme.color
          : Theme.of(context).iconTheme.color,
    ),
    fillColor: isToggled
        ? Theme.of(context).toggleableActiveColor
        : Theme.of(context).canvasColor,
    onPressed: onPressed,
  );
}

final Map<ToggleAttribute, IconData> _defaultToggleIcons = {
  ToggleAttribute.bold: Icons.format_bold,
  ToggleAttribute.italic: Icons.format_italic,
  ToggleAttribute.numberList: Icons.format_list_numbered,
  ToggleAttribute.bulletList: Icons.format_list_bulleted,
  ToggleAttribute.quote: Icons.format_quote,
  ToggleAttribute.code: Icons.code,
};

typedef DropdownButtonBuilder = Widget Function(
  BuildContext context,
  NotusAttribute value,
  ValueChanged<NotusAttribute> onSelected,
);

class SelectStyleButton extends StatefulWidget {
  final ZefyrController controller;
  final DropdownButtonBuilder childBuilder;

  const SelectStyleButton({
    Key key,
    @required this.controller,
    @required this.childBuilder,
  }) : super(key: key);

  @override
  _SelectStyleButtonState createState() => _SelectStyleButtonState();
}

class _SelectStyleButtonState extends State<SelectStyleButton> {
  NotusAttribute _value;

  void _didChangeEditingValue() {
    setState(() {
      _value =
          widget.controller.getSelectionStyle().get(NotusAttribute.heading) ??
              NotusAttribute.heading.unset;
    });
  }

  void _selectAttribute(value) {
    widget.controller.formatSelection(value);
  }

  @override
  void initState() {
    super.initState();
    _value =
        widget.controller.getSelectionStyle().get(NotusAttribute.heading) ??
            NotusAttribute.heading.unset;
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant SelectStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value =
          widget.controller.getSelectionStyle().get(NotusAttribute.heading) ??
              NotusAttribute.heading.unset;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(context, _value, _selectAttribute);
  }
}

Widget _selectHeadingStyleButtonBuilder(BuildContext context,
    NotusAttribute value, ValueChanged<NotusAttribute> onSelected) {
  final style = TextStyle(fontSize: 12);

  final valueToText = {
    NotusAttribute.heading.unset: 'Normal text',
    NotusAttribute.heading.level1: 'Heading 1',
    NotusAttribute.heading.level2: 'Heading 2',
    NotusAttribute.heading.level3: 'Heading 3',
  };

  return ZDropdownButton<NotusAttribute>(
    highlightElevation: 0,
    hoverElevation: 0,
    height: 32,
    child: Text(
      valueToText[value],
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    initialValue: value,
    items: [
      PopupMenuItem(
        child: Text(valueToText[NotusAttribute.heading.unset], style: style),
        value: NotusAttribute.heading.unset,
        height: 32,
      ),
      PopupMenuItem(
        child: Text(valueToText[NotusAttribute.heading.level1], style: style),
        value: NotusAttribute.heading.level1,
        height: 32,
      ),
      PopupMenuItem(
        child: Text(valueToText[NotusAttribute.heading.level2], style: style),
        value: NotusAttribute.heading.level2,
        height: 32,
      ),
      PopupMenuItem(
        child: Text(valueToText[NotusAttribute.heading.level3], style: style),
        value: NotusAttribute.heading.level3,
        height: 32,
      ),
    ],
    onSelected: onSelected,
  );
}

class EditorToolbar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget> children;

  const EditorToolbar({Key key, @required this.children}) : super(key: key);

  factory EditorToolbar.basic({
    Key key,
    @required ZefyrController controller,
    @required FocusNode editorFocusNode,
  }) {
    return EditorToolbar(key: key, children: [
      ToggleStyleButton(
        attribute: ToggleAttribute.bold,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      SizedBox(width: 1),
      ToggleStyleButton(
        attribute: ToggleAttribute.italic,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
      SelectStyleButton(
        controller: controller,
        childBuilder: _selectHeadingStyleButtonBuilder,
      ),
      VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
      ToggleStyleButton(
        attribute: ToggleAttribute.numberList,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      ToggleStyleButton(
        attribute: ToggleAttribute.bulletList,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      ToggleStyleButton(
        attribute: ToggleAttribute.quote,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      ToggleStyleButton(
        attribute: ToggleAttribute.code,
        controller: controller,
        childBuilder: _defaultToggleButtonBuilder,
      ),
      // VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
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
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: size, height: size),
      child: RawMaterialButton(
        child: icon,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        padding: EdgeInsets.zero,
        fillColor: fillColor,
        elevation: 0,
        hoverElevation: hoverElevation,
        highlightElevation: hoverElevation,
        onPressed: onPressed,
      ),
    );
  }
}

class ZDropdownButton<T> extends StatefulWidget {
  final double height;
  final Color fillColor;
  final double hoverElevation;
  final double highlightElevation;
  final Widget child;
  final T initialValue;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  const ZDropdownButton({
    Key key,
    this.height = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    @required this.child,
    @required this.initialValue,
    @required this.items,
    @required this.onSelected,
  }) : super(key: key);

  @override
  _ZDropdownButtonState<T> createState() => _ZDropdownButtonState<T>();
}

class _ZDropdownButtonState<T> extends State<ZDropdownButton<T>> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: widget.height),
      child: RawMaterialButton(
        child: _buildContent(context),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        padding: EdgeInsets.zero,
        fillColor: widget.fillColor,
        elevation: 0,
        hoverElevation: widget.hoverElevation,
        highlightElevation: widget.hoverElevation,
        onPressed: _showMenu,
      ),
    );
  }

  void _showMenu() {
    final popupMenuTheme = PopupMenuTheme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        // button.localToGlobal(widget.offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<T>(
      context: context,
      elevation: 4, // widget.elevation ?? popupMenuTheme.elevation,
      initialValue: widget.initialValue,
      items: widget.items,
      position: position,
      shape: popupMenuTheme.shape, // widget.shape ?? popupMenuTheme.shape,
      color: popupMenuTheme.color, // widget.color ?? popupMenuTheme.color,
      // captureInheritedThemes: widget.captureInheritedThemes,
    ).then((T newValue) {
      if (!mounted) return null;
      if (newValue == null) {
        // if (widget.onCanceled != null) widget.onCanceled();
        return null;
      }
      if (widget.onSelected != null) {
        widget.onSelected(newValue);
      }
    });
  }

  Widget _buildContent(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: 110),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            widget.child,
            Expanded(child: Container()),
            Icon(Icons.arrow_drop_down, size: 14)
          ],
        ),
      ),
    );
  }
}
