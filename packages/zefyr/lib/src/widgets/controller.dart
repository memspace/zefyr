import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

/// List of style keys which can be toggled for insertion
List<String> _insertionToggleableStyleKeys = [
  NotusAttribute.bold.key,
  NotusAttribute.italic.key,
  NotusAttribute.underline.key,
  NotusAttribute.strikethrough.key,
];

class ZefyrController extends ChangeNotifier {
  ZefyrController([NotusDocument? document])
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

  /// Returns style of specified text range.
  ///
  /// If nothing is selected but we've toggled an attribute,
  /// we also merge those in our style before returning.
  NotusStyle getSelectionStyle() {
    final start = _selection.start;
    final length = _selection.end - start;
    var lineStyle = document.collectStyle(start, length);

    lineStyle = lineStyle.mergeAll(toggledStyles);

    return lineStyle;
  }

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
  void replaceText(int index, int length, Object data,
      {TextSelection? selection}) {
    assert(data is String || data is EmbeddableObject);
    Delta? delta;

    final isDataNotEmpty = data is String ? data.isNotEmpty : true;
    if (length > 0 || isDataNotEmpty) {
      delta = document.replace(index, length, data);
      // If the delta is an insert operation and we have toggled
      // some styles, then apply those styles to the inserted text.
      if (toggledStyles.isNotEmpty &&
          delta.isNotEmpty &&
          delta.length <= 2 && // covers single insert and a retain+insert
          delta.last.isInsert) {
        final dataLength = data is String ? data.length : 1;
        final retainDelta = Delta()
          ..retain(index)
          ..retain(dataLength, toggledStyles.toJson());
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
          ..insert(data)
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

  void formatText(int index, int length, NotusAttribute attribute) {
    final change = document.format(index, length, attribute);
    // _lastChangeSource = ChangeSource.local;
    final source = ChangeSource.local;

    if (length == 0 && _insertionToggleableStyleKeys.contains(attribute.key)) {
      // Add the attribute to our toggledStyle. It will be used later upon insertion.
      _toggledStyles = toggledStyles.put(attribute);
    }

    // Transform selection against the composed change and give priority to
    // the change. This is needed in cases when format operation actually
    // inserts data into the document (e.g. embeds).
    final base = change.transformPosition(_selection.baseOffset);
    final extent = change.transformPosition(_selection.extentOffset);
    final adjustedSelection =
        _selection.copyWith(baseOffset: base, extentOffset: extent);
    if (_selection != adjustedSelection) {
      _updateSelectionSilent(adjustedSelection, source: source);
    }
    notifyListeners();
  }

  /// Formats current selection with [attribute].
  void formatSelection(NotusAttribute attribute) {
    final index = _selection.start;
    final length = _selection.end - index;
    formatText(index, length, attribute);
  }

  /// Updates selection with specified [value].
  ///
  /// [value] and [source] cannot be `null`.
  void updateSelection(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    _updateSelectionSilent(value, source: source);
    notifyListeners();
  }

  /// Composes [change] into document managed by this controller.
  ///
  /// This method does not apply any adjustments or heuristic rules to
  /// provided [change] and it is caller's responsibility to ensure this change
  /// can be composed without errors.
  ///
  /// If composing this change fails then this method throws [ComposeError].
  void compose(Delta change,
      {TextSelection? selection, ChangeSource source = ChangeSource.remote}) {
    if (change.isNotEmpty) {
      document.compose(change, source);
    }
    if (selection != null) {
      _updateSelectionSilent(selection, source: source);
    } else {
      // Transform selection against the composed change and give priority to
      // current position (force: false).
      final base =
          change.transformPosition(_selection.baseOffset, force: false);
      final extent =
          change.transformPosition(_selection.extentOffset, force: false);
      selection = _selection.copyWith(baseOffset: base, extentOffset: extent);
      if (_selection != selection) {
        _updateSelectionSilent(selection, source: source);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    document.close();
    super.dispose();
  }

  /// Updates selection without triggering notifications to listeners.
  void _updateSelectionSilent(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
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
      composing: TextRange.empty,
    );
  }
}
