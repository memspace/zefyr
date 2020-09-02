import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:notus/notus.dart';

class ZefyrController extends ChangeNotifier {
  ZefyrController([NotusDocument document])
      : document = document ?? NotusDocument(),
        _selection = TextSelection.collapsed(offset: 0);

  /// Document managed by this controller.
  final NotusDocument document;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection;

  /// Updates selection with specified [value].
  ///
  /// [value] and [source] cannot be `null`.
  void updateSelection(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    assert(value != null && source != null);
    _selection = value;
//    _lastChangeSource = source;
    _ensureSelectionBeforeLastBreak();
    notifyListeners();
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
      composing: TextRange.collapsed(0),
    );
  }
}
