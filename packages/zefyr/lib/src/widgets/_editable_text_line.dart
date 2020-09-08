import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_text_line.dart';
import '_cursor.dart';
import '_text_line.dart';

/// Line of editable text in Zefyr editor.
///
/// This widget adds editing features to the otherwise static [TextLine] widget.
class EditableTextLine extends RenderObjectWidget {
  final LineNode node;
  final Widget leading;
  final Widget body;
  final EdgeInsetsGeometry padding;
  final TextDirection textDirection;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;

  /// Creates an editable line of text represented by [node].
  EditableTextLine({
    Key key,
    @required this.node,
    this.leading,
    @required this.body,
    @required this.padding,
    this.textDirection,
    @required this.cursorController,
    @required this.selection,
    @required this.selectionColor,
    @required this.enableInteractiveSelection,
  })  : assert(node != null),
        assert(padding != null),
        assert(cursorController != null),
        assert(selection != null),
        assert(selectionColor != null),
        assert(enableInteractiveSelection != null),
        super(key: key);

  @override
  RenderObjectElement createElement() => _RenderEditableTextLineElement(this);

  @override
  RenderEditableTextLine createRenderObject(BuildContext context) {
    return RenderEditableTextLine(
      node: node,
      padding: padding,
      textDirection: textDirection,
      cursorController: cursorController,
      selection: selection,
      selectionColor: selectionColor,
      enableInteractiveSelection: enableInteractiveSelection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextLine renderObject) {
    renderObject.node = node;
    renderObject.padding = padding;
    renderObject.textDirection = textDirection;
    renderObject.cursorController = cursorController;
    renderObject.selection = selection;
    renderObject.selectionColor = selectionColor;
    renderObject.enableInteractiveSelection = enableInteractiveSelection;
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

  void _mountChild(Widget widget, TextLineSlot slot) {
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
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, TextLineSlot.leading);
    _mountChild(widget.body, TextLineSlot.body);
  }

  void _updateChild(Widget widget, TextLineSlot slot) {
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

  void _updateRenderObject(RenderObject child, TextLineSlot slot) {
    switch (slot) {
      case TextLineSlot.leading:
        renderObject.leading = child as RenderBox;
        break;
      case TextLineSlot.body:
        renderObject.body = child as RenderBox;
        break;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, TextLineSlot slot) {
    assert(child is RenderBox);
    _updateRenderObject(child, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, TextLineSlot slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
    assert(false, 'not reachable');
  }
}
