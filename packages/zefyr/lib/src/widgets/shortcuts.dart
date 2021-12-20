import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';

import 'editor.dart';

class ZefyrShortcuts extends Shortcuts {
  ZefyrShortcuts({Key? key, required Widget child})
      : super(
          key: key,
          shortcuts: _shortcuts,
          child: child,
        );

  static Map<ShortcutActivator, Intent> get _shortcuts {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _defaultShortcuts;
      case TargetPlatform.fuchsia:
        return _defaultShortcuts;
      case TargetPlatform.iOS:
        return _macShortcuts;
      case TargetPlatform.linux:
        return _defaultShortcuts;
      case TargetPlatform.macOS:
        return _macShortcuts;
      case TargetPlatform.windows:
        return _defaultShortcuts;
    }
  }

  static const Map<ShortcutActivator, Intent> _defaultShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyB, control: true):
        ToggleBoldStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyI, control: true):
        ToggleBoldStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true):
        ToggleUnderlineStyleIntent(),
  };

  static final Map<ShortcutActivator, Intent> _macShortcuts =
      <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
        const ToggleBoldStyleIntent(),
    const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
        const ToggleItalicStyleIntent(),
    const SingleActivator(LogicalKeyboardKey.keyU, meta: true):
        const ToggleUnderlineStyleIntent(),
  };
}

class ToggleBoldStyleIntent extends Intent {
  const ToggleBoldStyleIntent();
}

class ToggleItalicStyleIntent extends Intent {
  const ToggleItalicStyleIntent();
}

class ToggleUnderlineStyleIntent extends Intent {
  const ToggleUnderlineStyleIntent();
}

class ZefyrActions extends Actions {
  ZefyrActions({
    Key? key,
    required Widget child,
  }) : super(
          key: key,
          actions: _shortcutsActions,
          child: child,
        );

  static final Map<Type, Action<Intent>> _shortcutsActions =
      <Type, Action<Intent>>{
    ToggleBoldStyleIntent: _ToggleInlineStyleAction(NotusAttribute.bold),
    ToggleItalicStyleIntent: _ToggleInlineStyleAction(NotusAttribute.italic),
    ToggleUnderlineStyleIntent:
        _ToggleInlineStyleAction(NotusAttribute.underline),
  };
}

class _ToggleInlineStyleAction extends TextEditingAction<Intent> {
  final NotusAttribute attribute;

  _ToggleInlineStyleAction(this.attribute);

  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    assert(textEditingActionTarget is RawEditorState);
    final editorState = textEditingActionTarget as RawEditorState;
    final style = editorState.controller.getSelectionStyle();
    final actualAttr =
        style.containsSame(attribute) ? attribute.unset : attribute;
    editorState.controller.formatSelection(actualAttr);
  }
}
