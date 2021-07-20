import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'controller.dart';

const double kToolbarHeight = 56.0;

class InsertEmbedButton extends StatelessWidget {
  final ZefyrController controller;
  final IconData icon;

  const InsertEmbedButton({
    Key? key,
    required this.controller,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: 32,
      icon: Icon(
        icon,
        size: 18,
        color: Theme.of(context).iconTheme.color,
      ),
      fillColor: Theme.of(context).canvasColor,
      onPressed: () {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;
        controller.replaceText(index, length, BlockEmbed.horizontalRule);
      },
    );
  }
}

/// Toolbar button for formatting text as a link.
class LinkStyleButton extends StatefulWidget {
  final ZefyrController controller;
  final IconData? icon;

  const LinkStyleButton({
    Key? key,
    required this.controller,
    this.icon,
  }) : super(key: key);

  @override
  _LinkStyleButtonState createState() => _LinkStyleButtonState();
}

class _LinkStyleButtonState extends State<LinkStyleButton> {
  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant LinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      widget.controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didChangeSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.controller.selection.isCollapsed;
    final pressedHandler = isEnabled ? () => _openLinkDialog(context) : null;
    return ZIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: 32,
      icon: Icon(
        widget.icon ?? Icons.link,
        size: 18,
        color: isEnabled ? theme.iconTheme.color : theme.disabledColor,
      ),
      fillColor: Theme.of(context).canvasColor,
      onPressed: pressedHandler,
    );
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        return _LinkDialog();
      },
    ).then(_linkSubmitted);
  }

  void _linkSubmitted(String? value) {
    if (value == null || value.isEmpty) return;
    widget.controller.formatSelection(NotusAttribute.link.fromString(value));
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({Key? key}) : super(key: key);

  @override
  _LinkDialogState createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  String _link = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(
        decoration: InputDecoration(labelText: 'Paste a link'),
        autofocus: true,
        onChanged: _linkChanged,
      ),
      actions: [
        //TODO: Update to use TextButton
        TextButton(
          onPressed: _link.isNotEmpty ? _applyLink : null,
          child: Text('Apply'),
        ),
      ],
    );
  }

  void _linkChanged(String value) {
    setState(() {
      _link = value;
    });
  }

  void _applyLink() {
    Navigator.pop(context, _link);
  }
}

/// Builder for toolbar buttons handling toggleable style attributes.
///
/// See [defaultToggleStyleButtonBuilder] as a reference implementation.
typedef ToggleStyleButtonBuilder = Widget Function(
  BuildContext context,
  NotusAttribute attribute,
  IconData icon,
  bool isToggled,
  VoidCallback? onPressed,
);

/// Toolbar button which allows to toggle a style attribute on or off.
class ToggleStyleButton extends StatefulWidget {
  /// The style attribute controlled by this button.
  final NotusAttribute attribute;

  /// The icon representing the style [attribute].
  final IconData icon;

  /// Controller attached to a Zefyr editor.
  final ZefyrController controller;

  /// Builder function to customize visual representation of this button.
  final ToggleStyleButtonBuilder childBuilder;

  ToggleStyleButton({
    Key? key,
    required this.attribute,
    required this.icon,
    required this.controller,
    this.childBuilder = defaultToggleStyleButtonBuilder,
  })  : assert(!attribute.isUnset),
        super(key: key);

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  late bool _isToggled;

  NotusStyle get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          widget.controller.getSelectionStyle().containsSame(widget.attribute);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = _selectionStyle.containsSame(widget.attribute);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = _selectionStyle.containsSame(widget.attribute);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the cursor is currently inside a code block we disable all
    // toggle style buttons (except the code block button itself) since there
    // is no point in applying styles to a unformatted block of text.
    // TODO: Add code block checks to heading and embed buttons as well.
    final isInCodeBlock =
        _selectionStyle.containsSame(NotusAttribute.block.code);
    final isEnabled =
        !isInCodeBlock || widget.attribute == NotusAttribute.block.code;
    return widget.childBuilder(context, widget.attribute, widget.icon,
        _isToggled, isEnabled ? _toggleAttribute : null);
  }

  void _toggleAttribute() {
    if (_isToggled) {
      widget.controller.formatSelection(widget.attribute.unset);
    } else {
      widget.controller.formatSelection(widget.attribute);
    }
  }
}

/// Default builder for toggle style buttons.
Widget defaultToggleStyleButtonBuilder(
  BuildContext context,
  NotusAttribute attribute,
  IconData icon,
  bool isToggled,
  VoidCallback? onPressed,
) {
  final theme = Theme.of(context);
  final isEnabled = onPressed != null;
  final iconColor = isEnabled
      ? isToggled
          ? theme.primaryIconTheme.color
          : theme.iconTheme.color
      : theme.disabledColor;
  final fillColor = isToggled ? theme.toggleableActiveColor : theme.canvasColor;
  return ZIconButton(
    highlightElevation: 0,
    hoverElevation: 0,
    size: 32,
    icon: Icon(icon, size: 18, color: iconColor),
    fillColor: fillColor,
    onPressed: onPressed,
  );
}

/// Toolbar button which allows to apply heading style to a line of text in
/// Zefyr editor.
///
/// Works as a dropdown menu button.
// TODO: Add "dense" parameter which if set to true changes the button to use an icon instead of text (useful for mobile layouts)
class SelectHeadingStyleButton extends StatefulWidget {
  final ZefyrController controller;

  const SelectHeadingStyleButton({Key? key, required this.controller})
      : super(key: key);

  @override
  _SelectHeadingStyleButtonState createState() =>
      _SelectHeadingStyleButtonState();
}

class _SelectHeadingStyleButtonState extends State<SelectHeadingStyleButton> {
  NotusAttribute? _value;

  NotusStyle get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _value = _selectionStyle.get(NotusAttribute.heading) ??
          NotusAttribute.heading.unset;
    });
  }

  void _selectAttribute(value) {
    widget.controller.formatSelection(value);
  }

  @override
  void initState() {
    super.initState();
    _value = _selectionStyle.get(NotusAttribute.heading) ??
        NotusAttribute.heading.unset;
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant SelectHeadingStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _selectionStyle.get(NotusAttribute.heading) ??
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
    return _selectHeadingStyleButtonBuilder(context, _value, _selectAttribute);
  }
}

Widget _selectHeadingStyleButtonBuilder(BuildContext context,
    NotusAttribute? value, ValueChanged<NotusAttribute?> onSelected) {
  final style = TextStyle(fontSize: 12);

  final valueToText = {
    NotusAttribute.heading.unset: 'Normal text',
    NotusAttribute.heading.level1: 'Heading 1',
    NotusAttribute.heading.level2: 'Heading 2',
    NotusAttribute.heading.level3: 'Heading 3',
  };

  return ZDropdownButton<NotusAttribute?>(
    highlightElevation: 0,
    hoverElevation: 0,
    height: 32,
    initialValue: value,
    items: [
      PopupMenuItem(
        value: NotusAttribute.heading.unset,
        height: 32,
        child: Text(valueToText[NotusAttribute.heading.unset]!, style: style),
      ),
      PopupMenuItem(
        value: NotusAttribute.heading.level1,
        height: 32,
        child: Text(valueToText[NotusAttribute.heading.level1]!, style: style),
      ),
      PopupMenuItem(
        value: NotusAttribute.heading.level2,
        height: 32,
        child: Text(valueToText[NotusAttribute.heading.level2]!, style: style),
      ),
      PopupMenuItem(
        value: NotusAttribute.heading.level3,
        height: 32,
        child: Text(valueToText[NotusAttribute.heading.level3]!, style: style),
      ),
    ],
    onSelected: onSelected,
    child: Text(
      valueToText[value as NotusAttribute<int>]!,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class ZefyrToolbar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget> children;

  const ZefyrToolbar({Key? key, required this.children}) : super(key: key);

  factory ZefyrToolbar.basic(
      {Key? key,
      required ZefyrController controller,
      bool hideBoldButton = false,
      bool hideItalicButton = false,
      bool hideUnderLineButton = false,
      bool hideStrikeThrough = false,
      bool hideHeadingStyle = false,
      bool hideListNumbers = false,
      bool hideListBullets = false,
      bool hideCodeBlock = false,
      bool hideQuote = false,
      bool hideLink = false,
      bool hideHorizontalRule = false}) {
    return ZefyrToolbar(key: key, children: [
      Visibility(
        visible: !hideBoldButton,
        child: ToggleStyleButton(
          attribute: NotusAttribute.bold,
          icon: Icons.format_bold,
          controller: controller,
        ),
      ),
      SizedBox(width: 1),
      Visibility(
        visible: !hideItalicButton,
        child: ToggleStyleButton(
          attribute: NotusAttribute.italic,
          icon: Icons.format_italic,
          controller: controller,
        ),
      ),
      SizedBox(width: 1),
      Visibility(
        visible: !hideUnderLineButton,
        child: ToggleStyleButton(
          attribute: NotusAttribute.underline,
          icon: Icons.format_underline,
          controller: controller,
        ),
      ),
      SizedBox(width: 1),
      Visibility(
        visible: !hideStrikeThrough,
        child: ToggleStyleButton(
          attribute: NotusAttribute.strikethrough,
          icon: Icons.format_strikethrough,
          controller: controller,
        ),
      ),
      Visibility(
          visible: !hideHeadingStyle,
          child: VerticalDivider(
              indent: 16, endIndent: 16, color: Colors.grey.shade400)),
      Visibility(
          visible: !hideHeadingStyle,
          child: SelectHeadingStyleButton(controller: controller)),
      VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
      Visibility(
        visible: !hideListNumbers,
        child: ToggleStyleButton(
          attribute: NotusAttribute.block.numberList,
          controller: controller,
          icon: Icons.format_list_numbered,
        ),
      ),
      Visibility(
        visible: !hideListBullets,
        child: ToggleStyleButton(
          attribute: NotusAttribute.block.bulletList,
          controller: controller,
          icon: Icons.format_list_bulleted,
        ),
      ),
      Visibility(
        visible: !hideCodeBlock,
        child: ToggleStyleButton(
          attribute: NotusAttribute.block.code,
          controller: controller,
          icon: Icons.code,
        ),
      ),
      Visibility(
          visible: !hideListNumbers && !hideListBullets && !hideCodeBlock,
          child: VerticalDivider(
              indent: 16, endIndent: 16, color: Colors.grey.shade400)),
      Visibility(
        visible: !hideQuote,
        child: ToggleStyleButton(
          attribute: NotusAttribute.block.quote,
          controller: controller,
          icon: Icons.format_quote,
        ),
      ),
      Visibility(
          visible: !hideQuote,
          child: VerticalDivider(
              indent: 16, endIndent: 16, color: Colors.grey.shade400)),
      Visibility(
          visible: !hideLink, child: LinkStyleButton(controller: controller)),
      Visibility(
        visible: !hideHorizontalRule,
        child: InsertEmbedButton(
          controller: controller,
          icon: Icons.horizontal_rule,
        ),
      ),
    ]);
  }

  @override
  _ZefyrToolbarState createState() => _ZefyrToolbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _ZefyrToolbarState extends State<ZefyrToolbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints.tightFor(height: widget.preferredSize.height),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.children,
        ),
      ),
    );
  }
}

/// Default icon button used in Zefyr editor toolbar.
///
/// Named with a "Z" prefix to distinguish from the Flutter's built-in version.
class ZIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final double size;
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;

  const ZIconButton({
    Key? key,
    required this.onPressed,
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
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        padding: EdgeInsets.zero,
        fillColor: fillColor,
        elevation: 0,
        hoverElevation: hoverElevation,
        highlightElevation: hoverElevation,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}

class ZDropdownButton<T> extends StatefulWidget {
  final double height;
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;
  final Widget child;
  final T initialValue;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  const ZDropdownButton({
    Key? key,
    this.height = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    required this.child,
    required this.initialValue,
    required this.items,
    required this.onSelected,
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
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        padding: EdgeInsets.zero,
        fillColor: widget.fillColor,
        elevation: 0,
        hoverElevation: widget.hoverElevation,
        highlightElevation: widget.hoverElevation,
        onPressed: _showMenu,
        child: _buildContent(context),
      ),
    );
  }

  void _showMenu() {
    final popupMenuTheme = PopupMenuTheme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<T>(
      context: context,
      elevation: 4,
      // widget.elevation ?? popupMenuTheme.elevation,
      initialValue: widget.initialValue,
      items: widget.items,
      position: position,
      shape: popupMenuTheme.shape,
      // widget.shape ?? popupMenuTheme.shape,
      color: popupMenuTheme.color, // widget.color ?? popupMenuTheme.color,
      // captureInheritedThemes: widget.captureInheritedThemes,
    ).then((T? newValue) {
      if (!mounted) return null;
      if (newValue == null) {
        // if (widget.onCanceled != null) widget.onCanceled();
        return null;
      }
      widget.onSelected(newValue);
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
