// ignore_for_file: omit_local_variable_types
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ui';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';

import '../services/keyboard.dart';
import 'editor.dart';

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
int nextCharacter(int index, String string, [bool includeWhitespace = true]) {
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
int previousCharacter(int index, String string,
    [bool includeWhitespace = true]) {
  assert(index >= 0 && index <= string.length);
  if (index == 0) {
    return 0;
  }

  int count = 0;
  int? lastNonWhitespace;
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

mixin RawEditorStateKeyboardMixin on EditorState {
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

  void handleCursorMovement(
    LogicalKeyboardKey key, {
    required bool wordModifier,
    required bool lineModifier,
    required bool shift,
  }) {
    if (wordModifier && lineModifier) {
      // If both modifiers are down, nothing happens on any of the platforms.
      return;
    }
    final selection = widget.controller.selection;

    TextSelection newSelection = widget.controller.selection;

    final plainText = textEditingValue.text;

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
              previousCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection = renderEditor
              .selectWordAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, we want to skip over any whitespace after the word,
          // so we go forward to the first non-whitespace character before asking
          // for the word bounds, since _selectWordAtOffset finds the word
          // boundaries without including whitespace.
          final int startPoint =
              nextCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection = renderEditor
              .selectWordAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.extentOffset);
        }
      } else if (lineModifier) {
        // If control/command is pressed, we will decide which way to expand to
        // the beginning/end of the line based on which arrow is pressed.
        if (leftArrow) {
          // When going left.
          // This is not the optimal approach, see comment below for details.
          final int startPoint =
              previousCharacter(newSelection.extentOffset, plainText, false);
          final TextSelection textSelection = renderEditor
              .selectLineAtPosition(TextPosition(offset: startPoint));
          newSelection =
              newSelection.copyWith(extentOffset: textSelection.baseOffset);
        } else {
          // When going right, look to the right from current position until
          // we find the end of the line.
          // A better solution would be to take into account word wrapping and
          // only jump to the end of text before wrapping occurs.
          // TODO: Handle soft-wrapping
          // This can be implemented by getting vertical offset at the start
          // point, then getting selection boxes for this line, filtering to
          // only include boxes with the same vertical offset and getting the
          // largest right edge of all the remaining boxes.
          final int startPoint = newSelection.extentOffset;
          if (startPoint < plainText.length) {
            final TextSelection textSelection = renderEditor
                .selectLineAtPosition(TextPosition(offset: startPoint));
            newSelection =
                newSelection.copyWith(extentOffset: textSelection.extentOffset);
          }
        }
      } else {
        if (rightArrow && newSelection.extentOffset < plainText.length) {
          final int nextExtent =
              nextCharacter(newSelection.extentOffset, plainText);
          final int distance = nextExtent - newSelection.extentOffset;
          newSelection = newSelection.copyWith(extentOffset: nextExtent);
          if (shift) {
            _cursorResetLocation += distance;
          }
        } else if (leftArrow && newSelection.extentOffset > 0) {
          final int previousExtent =
              previousCharacter(newSelection.extentOffset, plainText);
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
      final originPosition = TextPosition(
          offset: upArrow ? selection.baseOffset : selection.extentOffset);

      final child = renderEditor.childAtPosition(originPosition);
      final localPosition = TextPosition(
          offset: originPosition.offset - child.node.documentOffset);

      TextPosition? position = upArrow
          ? child.getPositionAbove(localPosition)
          : child.getPositionBelow(localPosition);

      if (position == null) {
        // There was no text above/below in the current child, check the direct
        // sibling.
        final sibling = upArrow
            ? renderEditor.childBefore(child)
            : renderEditor.childAfter(child);
        if (sibling == null) {
          // reached beginning or end of the document, move to the
          // first/last character
          position = TextPosition(offset: upArrow ? 0 : plainText.length - 1);
        } else {
          final caretOffset = child.getOffsetForCaret(localPosition);
          final testPosition =
              TextPosition(offset: upArrow ? sibling.node.length - 1 : 0);
          final testOffset = sibling.getOffsetForCaret(testPosition);
          final finalOffset = Offset(caretOffset.dx, testOffset.dy);
          final siblingPosition = sibling.getPositionForOffset(finalOffset);
          position = TextPosition(
              offset: sibling.node.documentOffset + siblingPosition.offset);
        }
      } else {
        position =
            TextPosition(offset: child.node.documentOffset + position.offset);
      }

      // To account for the possibility where the user vertically highlights
      // all the way to the top or bottom of the text, we hold the previous
      // cursor location. This allows us to restore to this position in the
      // case that the user wants to unhighlight some text.
      if (position.offset == newSelection.extentOffset) {
        if (downArrow) {
          newSelection = newSelection.copyWith(extentOffset: plainText.length);
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

    widget.controller.updateSelection(newSelection, source: ChangeSource.local);
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control/command + (X, C, V, A).
  // TODO: Add support for formatting shortcuts: Cmd+B (bold), Cmd+I (italic)
  Future<void> handleShortcut(InputShortcut? shortcut) async {
    final selection = widget.controller.selection;
    final plainText = textEditingValue.text;
    if (shortcut == InputShortcut.copy) {
      if (!selection.isCollapsed) {
        // ignore: unawaited_futures
        Clipboard.setData(ClipboardData(text: selection.textInside(plainText)));
      }
      return;
    }
    if (shortcut == InputShortcut.cut && !widget.readOnly) {
      if (!selection.isCollapsed) {
        final data = selection.textInside(plainText);
        // ignore: unawaited_futures
        Clipboard.setData(ClipboardData(text: data));

        widget.controller.replaceText(
          selection.start,
          data.length,
          '',
          selection: TextSelection.collapsed(offset: selection.start),
        );

        textEditingValue = TextEditingValue(
          text:
              selection.textBefore(plainText) + selection.textAfter(plainText),
          selection: TextSelection.collapsed(offset: selection.start),
        );
      }
      return;
    }
    if (shortcut == InputShortcut.paste && !widget.readOnly) {
      // Snapshot the input before using `await`.
      // See https://github.com/flutter/flutter/issues/11427
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final length = selection.end - selection.start;
        widget.controller.replaceText(
          selection.start,
          length,
          data.text!,
          selection: TextSelection.collapsed(
              offset: selection.start + data.text!.length),
        );
      }
      return;
    }
    if (shortcut == InputShortcut.selectAll &&
        widget.enableInteractiveSelection) {
      final newSelection = selection.copyWith(
        baseOffset: 0,
        extentOffset: textEditingValue.text.length,
      );
      widget.controller.updateSelection(newSelection);
      return;
    }
  }

  void handleDelete(bool forward) {
    final selection = widget.controller.selection;
    final plainText = textEditingValue.text;
    int cursorPosition = selection.start;
    String textBefore = selection.textBefore(plainText);
    String textAfter = selection.textAfter(plainText);
    // If not deleting a selection, delete the next/previous character.
    if (selection.isCollapsed) {
      if (!forward && textBefore.isNotEmpty) {
        final int characterBoundary =
            previousCharacter(textBefore.length, textBefore);
        textBefore = textBefore.substring(0, characterBoundary);
        cursorPosition = characterBoundary;
      }
      // we don't want to remove the last new line
      if (forward && textAfter.isNotEmpty && textAfter != '\n') {
        final int deleteCount = nextCharacter(0, textAfter);
        textAfter = textAfter.substring(deleteCount);
      }
    }
    var newSelection = TextSelection.collapsed(offset: cursorPosition);
    var newText = textBefore + textAfter;
    var size = plainText.length - newText.length;
    widget.controller.replaceText(
      cursorPosition,
      size,
      '',
      selection: newSelection,
    );
  }
}
