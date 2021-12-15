import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_box.dart';
import '../rendering/editable_text_line.dart';
import 'cursor.dart';
import 'text_line.dart';
import 'theme.dart';

/// Line of editable text in Zefyr editor.
///
/// This widget adds editing features to the otherwise static [TextLine] widget.
class EditableTextLine extends RenderObjectWidget {
  /// The line node represented by this widget.
  final LineNode node;

  /// A widget to display before the body.
  final Widget? leading;

  /// The primary rich text content of this widget. Usually [TextLine] widget.
  final Widget body;

  /// Width of indentation space before the [body].
  final double indentWidth;

  /// Space above and below [body] of this text line.
  final VerticalSpacing spacing;

  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final double devicePixelRatio;

  /// Creates an editable line of text.
  const EditableTextLine({
    Key? key,
    required this.node,
    required this.body,
    required this.cursorController,
    required this.selection,
    required this.selectionColor,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.devicePixelRatio,
    this.leading,
    this.indentWidth = 0.0,
    this.spacing = const VerticalSpacing(),
  }) : super(key: key);

  EdgeInsetsGeometry get _padding => EdgeInsetsDirectional.only(
        start: indentWidth,
        top: spacing.top,
        bottom: spacing.bottom,
      );

  @override
  RenderObjectElement createElement() => _RenderEditableTextLineElement(this);

  @override
  RenderEditableTextLine createRenderObject(BuildContext context) {
    final theme = ZefyrTheme.of(context)!;
    return RenderEditableTextLine(
      node: node,
      padding: _padding,
      textDirection: Directionality.of(context),
      cursorController: cursorController,
      selection: selection,
      selectionColor: selectionColor,
      enableInteractiveSelection: enableInteractiveSelection,
      hasFocus: hasFocus,
      devicePixelRatio: devicePixelRatio,
      inlineCodeTheme: theme.inlineCode,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextLine renderObject) {
    final theme = ZefyrTheme.of(context)!;
    renderObject.node = node;
    renderObject.padding = _padding;
    renderObject.textDirection = Directionality.of(context);
    renderObject.cursorController = cursorController;
    renderObject.selection = selection;
    renderObject.selectionColor = selectionColor;
    renderObject.enableInteractiveSelection = enableInteractiveSelection;
    renderObject.hasFocus = hasFocus;
    renderObject.devicePixelRatio = devicePixelRatio;
    renderObject.inlineCodeTheme = theme.inlineCode;
  }
}

class _RenderEditableTextLineElement extends RenderObjectElement {
  _RenderEditableTextLineElement(EditableTextLine line) : super(line);

  final Map<TextLineSlot, Element> slotToChild = <TextLineSlot, Element>{};

  @override
  EditableTextLine get widget => super.widget as EditableTextLine;

  @override
  RenderEditableTextLine get renderObject =>
      super.renderObject as RenderEditableTextLine;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.containsValue(child));
    assert(child.slot is TextLineSlot);
    assert(slotToChild.containsKey(child.slot));
    slotToChild.remove(child.slot);
    super.forgetChild(child);
  }

  void _mountChild(Widget? widget, TextLineSlot slot) {
    final oldChild = slotToChild[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, TextLineSlot.leading);
    _mountChild(widget.body, TextLineSlot.body);
  }

  void _updateChild(Widget? widget, TextLineSlot slot) {
    final oldChild = slotToChild[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void update(EditableTextLine newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.leading, TextLineSlot.leading);
    _updateChild(widget.body, TextLineSlot.body);
  }

  void _updateRenderObject(RenderObject? child, TextLineSlot? slot) {
    switch (slot) {
      case TextLineSlot.leading:
        renderObject.leading = child as RenderBox?;
        break;
      case TextLineSlot.body:
        renderObject.body = child as RenderContentProxyBox?;
        break;
      case null:
        break;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, TextLineSlot? slot) {
    assert(child is RenderBox);
    _updateRenderObject(child, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, TextLineSlot? slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot!] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
    assert(false, 'not reachable');
  }
}
