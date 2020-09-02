// ignore_for_file: omit_local_variable_types
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zefyr/src/rendering/editor.dart';

// Check if the given code unit is a white space or separator
// character.
//
// Includes newline characters from ASCII and separators from the
// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
// TODO(gspencergoog): replace when we expose this ICU information.
bool _isWhitespace(int codeUnit) {
  switch (codeUnit) {
    case 0x9: // horizontal tab
    case 0xA: // line feed
    case 0xB: // vertical tab
    case 0xC: // form feed
    case 0xD: // carriage return
    case 0x1C: // file separator
    case 0x1D: // group separator
    case 0x1E: // record separator
    case 0x1F: // unit separator
    case 0x20: // space
    case 0xA0: // no-break space
    case 0x1680: // ogham space mark
    case 0x2000: // en quad
    case 0x2001: // em quad
    case 0x2002: // en space
    case 0x2003: // em space
    case 0x2004: // three-per-em space
    case 0x2005: // four-er-em space
    case 0x2006: // six-per-em space
    case 0x2007: // figure space
    case 0x2008: // punctuation space
    case 0x2009: // thin space
    case 0x200A: // hair space
    case 0x202F: // narrow no-break space
    case 0x205F: // medium mathematical space
    case 0x3000: // ideographic space
      break;
    default:
      return false;
  }
  return true;
}

final Set<LogicalKeyboardKey> _movementKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
};

final Set<LogicalKeyboardKey> _shortcutKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.delete,
};

final Set<LogicalKeyboardKey> _nonModifierKeys = <LogicalKeyboardKey>{
  ..._shortcutKeys,
  ..._movementKeys,
};

final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
};

final Set<LogicalKeyboardKey> _macOsModifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.alt,
};

final Set<LogicalKeyboardKey> _interestingKeys = <LogicalKeyboardKey>{
  ..._modifierKeys,
  ..._macOsModifierKeys,
  ..._nonModifierKeys,
};

class EditableKeyboardListener {
  final RenderAbstractEditor editable;
  final ValueChanged<TextSelection> onSelectionChanged;

  EditableKeyboardListener({
    @required this.editable,
    @required this.onSelectionChanged,
  }) : assert(editable != null);

  TextSelection get selection => editable.selection;

//  final onSelectionChanged;
//  final TextSelection selection;
//  final bool selectionEnabled;

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate textSelectionDelegate;

  // Holds the last cursor location the user selected in the case the user tries
  // to select vertically past the end or beginning of the field. If they do,
  // then we need to keep the old cursor location so that we can go back to it
  // if they change their minds. Only used for moving selection up and down in a
  // multiline text field when selecting using the keyboard.
  int _cursorResetLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // tries to select vertically past the end or beginning of the field. If they
  // do, then we need to keep the old cursor location so that we can go back to
  // it if they change their minds. Only used for resetting selection up and
  // down in a multiline text field when selecting using the keyboard.
  bool _wasSelectingVerticallyWithKeyboard = false;

  /// Whether this keyboard listener is currently attached to the system
  /// keyboard.
  bool get isAttached => _isAttached;
  bool _isAttached = false;

  void attach() {
    assert(!_isAttached);
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _isAttached = true;
  }

  void detach() {
    assert(_isAttached);
    RawKeyboard.instance.removeListener(_handleKeyEvent);
  }

  /// Content of the editable as a string of plain text.
  String get plainText => _plainText;
  String _plainText;
  set plainText(String value) {
    assert(value != null);
    if (_plainText == value) return;
    _plainText = value;
  }

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int nextCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    int count = 0;
    final Characters remaining =
        string.characters.skipWhile((String currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return _isWhitespace(currentString.codeUnitAt(0));
    });
    return string.length - remaining.toString().length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int previousCharacter(int index, String string,
      [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    int count = 0;
    int lastNonWhitespace;
    for (final String currentString in string.characters) {
      if (!includeWhitespace &&
          !_isWhitespace(
              currentString.characters.first.toString().codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  void _handleKeyEvent(RawKeyEvent keyEvent) {
    if (kIsWeb) {
      // On web platform, we should ignore the key because it's processed already.
      return;
    }

    if (keyEvent is! RawKeyDownEvent || onSelectionChanged == null) return;

    final Set<LogicalKeyboardKey> keysPressed =
        LogicalKeyboardKey.collapseSynonyms(RawKeyboard.instance.keysPressed);
    final LogicalKeyboardKey key = keyEvent.logicalKey;

    final bool isMacOS = keyEvent.data is RawKeyEventDataMacOs;
    if (!_nonModifierKeys.contains(key) ||
        keysPressed
                .difference(isMacOS ? _macOsModifierKeys : _modifierKeys)
                .length >
            1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      // If the most recently pressed key isn't a non-modifier key, or more than
      // one non-modifier key is down, or keys other than the ones we're interested in
      // are pressed, just ignore the keypress.
      return;
    }

    // TODO(ianh): It seems to be entirely possible for the selection to be null here, but
    // all the keyboard handling functions assume it is not.
    assert(selection != null);

    final bool isWordModifierPressed =
        isMacOS ? keyEvent.isAltPressed : keyEvent.isControlPressed;
    final bool isLineModifierPressed =
        isMacOS ? keyEvent.isMetaPressed : keyEvent.isAltPressed;
    final bool isShortcutModifierPressed =
        isMacOS ? keyEvent.isMetaPressed : keyEvent.isControlPressed;
    if (_movementKeys.contains(key)) {
      _handleMovement(key,
          wordModifier: isWordModifierPressed,
          lineModifier: isLineModifierPressed,
          shift: keyEvent.isShiftPressed);
    } else if (isShortcutModifierPressed && _shortcutKeys.contains(key)) {
      // _handleShortcuts depends on being started in the same stack invocation
      // as the _handleKeyEvent method
      _handleShortcuts(key);
    } else if (key == LogicalKeyboardKey.delete) {
      _handleDelete();
    }
  }

  void _handleMovement(
    LogicalKeyboardKey key, {
    @required bool wordModifier,
    @required bool lineModifier,
    @required bool shift,
  }) {
    if (wordModifier && lineModifier) {
      // If both modifiers are down, nothing happens on any of the platforms.
      return;
    }
    assert(selection != null);

    TextSelection /*!*/ newSelection = selection;

    final bool rightArrow = key == LogicalKeyboardKey.arrowRight;
    final bool leftArrow = key == LogicalKeyboardKey.arrowLeft;
    final bool upArrow = key == LogicalKeyboardKey.arrowUp;
    final bool downArrow = key == LogicalKeyboardKey.arrowDown;

    if ((rightArrow || leftArrow) && !(rightArrow && leftArrow)) {
      // Jump to begin/end of word.
      if (wordModifier) {
        // If control/option is pressed, we will decide which way to look for a
        // word based on which arrow is pressed.
        if (leftArrow) {
          // When going left, we want to skip over any whitespace before the word,
          // so we go back to the first non-whitespace before asking for the word
          // boundary, since _selectWordAtOffset finds the word boundaries without
          // including whitespace.
          final int startPoint =
              previousCharacter(newSelection.extentOffset, _plainText, false);
          final TextSelection textSelection =
              editable.selectWordAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, we want to skip over any whitespace after the word,
          // so we go forward to the first non-whitespace character before asking
          // for the word bounds, since _selectWordAtOffset finds the word
          // boundaries without including whitespace.
          final int startPoint =
              nextCharacter(newSelection.extentOffset, _plainText, false);
          final TextSelection textSelection =
              editable.selectWordAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.extentOffset);
        }
      } else if (lineModifier) {
        // If control/command is pressed, we will decide which way to expand to
        // the beginning/end of the line based on which arrow is pressed.
        if (leftArrow) {
          // When going left, we want to skip over any whitespace before the line,
          // so we go back to the first non-whitespace before asking for the line
          // bounds, since _selectLineAtOffset finds the line boundaries without
          // including whitespace (like the newline).
          final int startPoint =
              previousCharacter(newSelection.extentOffset, _plainText, false);
          final TextSelection textSelection =
              editable.selectLineAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, we want to skip over any whitespace after the line,
          // so we go forward to the first non-whitespace character before asking
          // for the line bounds, since _selectLineAtOffset finds the line
          // boundaries without including whitespace (like the newline).
          final int startPoint =
              nextCharacter(newSelection.extentOffset, _plainText, false);
          final TextSelection textSelection =
              editable.selectLineAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.extentOffset);
        }
      } else {
        if (rightArrow && newSelection.extentOffset < _plainText.length) {
          final int nextExtent =
              nextCharacter(newSelection.extentOffset, _plainText);
          final int distance = nextExtent - newSelection.extentOffset;
          newSelection = newSelection.copyWith(extentOffset: nextExtent);
          if (shift) {
            _cursorResetLocation += distance;
          }
        } else if (leftArrow && newSelection.extentOffset > 0) {
          final int previousExtent =
              previousCharacter(newSelection.extentOffset, _plainText);
          final int distance = newSelection.extentOffset - previousExtent;
          newSelection = newSelection.copyWith(extentOffset: previousExtent);
          if (shift) {
            _cursorResetLocation -= distance;
          }
        }
      }
    }

    // Handles moving the cursor vertically as well as taking care of the
    // case where the user moves the cursor to the end or beginning of the text
    // and then back up or down.
    if (downArrow || upArrow) {
      // The caret offset gives a location in the upper left hand corner of
      // the caret so the middle of the line above is a half line above that
      // point and the line below is 1.5 lines below that point.
      // TODO: The above logic may not work for zefyr paragraphs which have
      // TODO: additional padding around them.
      final originPosition = TextPosition(
          offset: upArrow ? selection.baseOffset : selection.extentOffset);
      final double preferredLineHeight =
          editable.preferredLineHeightAtPosition(originPosition);
      final double verticalOffset =
          upArrow ? -0.5 * preferredLineHeight : 1.5 * preferredLineHeight;

      final Offset caretOffset = editable
          .getOffsetForCaret(TextPosition(offset: newSelection.extentOffset));
      final Offset caretOffsetTranslated =
          caretOffset.translate(0.0, verticalOffset);
      final TextPosition position =
          editable.getPositionForOffset(caretOffsetTranslated);

      // To account for the possibility where the user vertically highlights
      // all the way to the top or bottom of the text, we hold the previous
      // cursor location. This allows us to restore to this position in the
      // case that the user wants to unhighlight some text.
      if (position.offset == newSelection.extentOffset) {
        if (downArrow) {
          newSelection = newSelection.copyWith(extentOffset: _plainText.length);
        } else if (upArrow) {
          newSelection = newSelection.copyWith(extentOffset: 0);
        }
        _wasSelectingVerticallyWithKeyboard = shift;
      } else if (_wasSelectingVerticallyWithKeyboard && shift) {
        newSelection =
            newSelection.copyWith(extentOffset: _cursorResetLocation);
        _wasSelectingVerticallyWithKeyboard = false;
      } else {
        newSelection = newSelection.copyWith(extentOffset: position.offset);
        _cursorResetLocation = newSelection.extentOffset;
      }
    }

    // Just place the collapsed selection at the end or beginning of the region
    // if shift isn't down.
    if (!shift) {
      // We want to put the cursor at the correct location depending on which
      // arrow is used while there is a selection.
      int newOffset = newSelection.extentOffset;
      if (!selection.isCollapsed) {
        if (leftArrow) {
          newOffset = newSelection.baseOffset < newSelection.extentOffset
              ? newSelection.baseOffset
              : newSelection.extentOffset;
        } else if (rightArrow) {
          newOffset = newSelection.baseOffset > newSelection.extentOffset
              ? newSelection.baseOffset
              : newSelection.extentOffset;
        }
      }
      newSelection =
          TextSelection.fromPosition(TextPosition(offset: newOffset));
    }

    // Update the text selection delegate so that the engine knows what we did.
    textSelectionDelegate.textEditingValue = textSelectionDelegate
        .textEditingValue
        .copyWith(selection: newSelection);
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control/command + (X, C, V, A).
  Future<void> _handleShortcuts(LogicalKeyboardKey key) async {
    assert(selection != null);
    assert(_shortcutKeys.contains(key), 'shortcut key $key not recognized.');
    if (key == LogicalKeyboardKey.keyC) {
      if (!selection.isCollapsed) {
        // ignore: unawaited_futures
        Clipboard.setData(
            ClipboardData(text: selection.textInside(_plainText)));
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyX) {
      if (!selection.isCollapsed) {
        // ignore: unawaited_futures
        Clipboard.setData(
            ClipboardData(text: selection.textInside(_plainText)));
        textSelectionDelegate.textEditingValue = TextEditingValue(
          text: selection.textBefore(_plainText) +
              selection.textAfter(_plainText),
          selection: TextSelection.collapsed(offset: selection.start),
        );
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyV) {
      // Snapshot the input before using `await`.
      // See https://github.com/flutter/flutter/issues/11427
      final TextEditingValue value = textSelectionDelegate.textEditingValue;
      final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        textSelectionDelegate.textEditingValue = TextEditingValue(
          text: value.selection.textBefore(value.text) +
              data.text +
              value.selection.textAfter(value.text),
          selection: TextSelection.collapsed(
              offset: value.selection.start + data.text.length),
        );
      }
      return;
    }
    if (key == LogicalKeyboardKey.keyA) {
      final newSelection = selection.copyWith(
        baseOffset: 0,
        extentOffset: textSelectionDelegate.textEditingValue.text.length,
      );
      textSelectionDelegate.textEditingValue = textSelectionDelegate
          .textEditingValue
          .copyWith(selection: newSelection);
//      _handleSelectionChange(
//        selection.copyWith(
//          baseOffset: 0,
//          extentOffset: textSelectionDelegate.textEditingValue.text.length,
//        ),
//        SelectionChangedCause.keyboard,
//      );
      return;
    }
  }

  void _handleDelete() {
    assert(selection != null);
    final String textAfter = selection.textAfter(_plainText);
    if (textAfter.isNotEmpty) {
      final int deleteCount = nextCharacter(0, textAfter);
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(_plainText) +
            selection.textAfter(_plainText).substring(deleteCount),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(_plainText),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }
}
