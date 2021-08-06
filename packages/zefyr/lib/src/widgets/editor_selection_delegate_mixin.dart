import 'package:flutter/cupertino.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/util.dart';

import 'editor.dart';

mixin RawEditorStateSelectionDelegateMixin on EditorState
    implements TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue {
    return widget.controller.plainTextEditingValue;
  }

  @override
  set textEditingValue(TextEditingValue value) {
    final cursorPosition = value.selection.extentOffset;
    final oldText = widget.controller.document.toPlainText();
    final newText = value.text;
    final diff = fastDiff(oldText, newText, cursorPosition);
    widget.controller.replaceText(
        diff.start, diff.deleted.length, diff.inserted,
        selection: value.selection);
    widget.controller
        .updateSelection(value.selection, source: ChangeSource.local);
  }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) {
    textEditingValue = value;
  }

  @override
  void bringIntoView(TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (selectionOverlay?.toolbarIsVisible == true) {
      selectionOverlay?.hideToolbar();
    }
  }

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;
}
