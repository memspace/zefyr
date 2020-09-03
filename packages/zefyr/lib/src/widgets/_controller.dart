import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

class ZefyrController extends ChangeNotifier {
  ZefyrController([NotusDocument document])
      : document = document ?? NotusDocument(),
        _selection = TextSelection.collapsed(offset: 0);

  /// Document managed by this controller.
  final NotusDocument document;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection;

  /// Store any styles attribute that got toggled by the tap of a button
  /// and that has not been applied yet.
  /// It gets reset after each format action within the [document].
  NotusStyle get toggledStyles => _toggledStyles;
  NotusStyle _toggledStyles = NotusStyle();

  /// Replaces [length] characters in the document starting at [index] with
  /// provided [text].
  ///
  /// Resulting change is registered as produced by user action, e.g.
  /// using [ChangeSource.local].
  ///
  /// It also applies the toggledStyle if needed. And then it resets it
  /// in any cases as we don't want to keep it except on inserts.
  ///
  /// Optionally updates selection if provided.
  void replaceText(int index, int length, String text,
      {TextSelection selection}) {
    Delta delta;

    if (length > 0 || text.isNotEmpty) {
      delta = document.replace(index, length, text);
      // If the delta is an insert operation and we have toggled
      // some styles, then apply those styles to the inserted text.
      if (delta != null &&
          toggledStyles.isNotEmpty &&
          delta.isNotEmpty &&
          delta.length <= 2 && // covers single insert and a retain+insert
          delta.last.isInsert) {
        final retainDelta = Delta()
          ..retain(index)
          ..retain(text.length, toggledStyles.toJson());
        document.compose(retainDelta, ChangeSource.local);
      }
    }

    // Always reset it after any user action, even if it has not been applied.
    _toggledStyles = NotusStyle();

    if (selection != null) {
      if (delta == null) {
        _updateSelectionSilent(selection, source: ChangeSource.local);
      } else {
        // need to transform selection position in case actual delta
        // is different from user's version (in deletes and inserts).
        final user = Delta()
          ..retain(index)
          ..insert(text)
          ..delete(length);
        var positionDelta = getPositionDelta(user, delta);
        _updateSelectionSilent(
          selection.copyWith(
            baseOffset: selection.baseOffset + positionDelta,
            extentOffset: selection.extentOffset + positionDelta,
          ),
          source: ChangeSource.local,
        );
      }
    }
//    _lastChangeSource = ChangeSource.local;
    notifyListeners();
  }

  /// Updates selection with specified [value].
  ///
  /// [value] and [source] cannot be `null`.
  void updateSelection(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    _updateSelectionSilent(value, source: source);
    notifyListeners();
  }

  /// Updates selection without triggering notifications to listeners.
  void _updateSelectionSilent(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    assert(value != null && source != null);
    _selection = value;
//    _lastChangeSource = source;
    _ensureSelectionBeforeLastBreak();
  }

  // Ensures that selection does not include last line break which
  // prevents deletion of the last line in the document.
  // This is required by Notus document model.
  void _ensureSelectionBeforeLastBreak() {
    final end = document.length - 1;
    final base = math.min(_selection.baseOffset, end);
    final extent = math.min(_selection.extentOffset, end);
    _selection = _selection.copyWith(baseOffset: base, extentOffset: extent);
  }

  TextEditingValue get plainTextEditingValue {
    return TextEditingValue(
      text: document.toPlainText(),
      selection: selection,
      composing: TextRange.collapsed(-1),
    );
  }
}
