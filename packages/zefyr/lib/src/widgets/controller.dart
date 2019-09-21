// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

const TextSelection _kZeroSelection = TextSelection.collapsed(
  offset: 0,
  affinity: TextAffinity.upstream,
);

/// Owner of focus.
enum FocusOwner {
  /// Current owner is the editor.
  editor,

  /// Current owner is the toolbar.
  toolbar,

  /// No focus owner.
  none,
}

/// Controls instance of [ZefyrEditor].
class ZefyrController extends ChangeNotifier {
  ZefyrController(NotusDocument document)
      : assert(document != null),
        _document = document;

  /// Zefyr document managed by this controller.
  NotusDocument get document => _document;
  NotusDocument _document;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection = _kZeroSelection;

  ChangeSource _lastChangeSource;

  /// Source of the last text or selection change.
  ChangeSource get lastChangeSource => _lastChangeSource;

  /// The styles that got toogled by the tap of a button,
  /// outside of the scope of already existing scope.
  /// The key of the map is the char count index
  /// where the style got toggled.
  Map<int, NotusStyle> _toggledStyles = new Map<int, NotusStyle>();
  Map<int, NotusStyle> get toggledStyles => _toggledStyles;

  /// Updates selection with specified [value].
  ///
  /// [value] and [source] cannot be `null`.
  void updateSelection(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    _updateSelectionSilent(value, source: source);
    notifyListeners();
  }

  // Updates selection without triggering notifications to listeners.
  void _updateSelectionSilent(TextSelection value,
      {ChangeSource source = ChangeSource.remote}) {
    assert(value != null && source != null);
    _selection = value;
    _lastChangeSource = source;
    _ensureSelectionBeforeLastBreak();
  }

  @override
  void dispose() {
    _document.close();
    super.dispose();
  }

  /// Composes [change] into document managed by this controller.
  ///
  /// This method does not apply any adjustments or heuristic rules to
  /// provided [change] and it is caller's responsibility to ensure this change
  /// can be composed without errors.
  ///
  /// If composing this change fails then this method throws [ComposeError].
  void compose(Delta change,
      {TextSelection selection, ChangeSource source = ChangeSource.remote}) {
    if (change.isNotEmpty) {
      _document.compose(change, source);
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
    _lastChangeSource = source;
    notifyListeners();
  }

  /// Replaces [length] characters in the document starting at [index] with
  /// provided [text].
  ///
  /// Resulting change is registered as produced by user action, e.g.
  /// using [ChangeSource.local].
  ///
  /// It also applies the toggledStyle if any.
  ///
  /// Optionally updates selection if provided.
  void replaceText(int index, int length, String text,
      {TextSelection selection}) {
    Delta delta;

    if (length > 0 || text.isNotEmpty) {
      delta = document.replace(index, length, text);
      if (delta != null) {
        // If we are inserting somewhere where we've toggled an attribute,
        // and it's a classical insert operation, we are going to want to
        // apply the toggled style to the inserted text.
        if (
          toggledStyles.containsKey(index)
          && delta.length == 2
          && delta[1].isInsert
        ) {
          // Extract the style.
          var style = toggledStyles.remove(index);

          // Apply it.
          Delta retainDelta = new Delta()
            ..retain(index)
            ..retain(1 , style.toJson());
          document.compose(retainDelta, ChangeSource.local);
        }

        // Update the rest of our toggledStyles map indexes
        // as we've inserted a character.
        _toggledStyles = toggledStyles.map((key, value) {
          if (key < index) {
            return new MapEntry(key, value);
          }
          return new MapEntry(key + text.length, value);
        });
      }
    }

    if (selection != null) {
      if (delta == null) {
        _updateSelectionSilent(selection, source: ChangeSource.local);
      } else {
        // need to transform selection position in case actual delta
        // is different from user's version (in deletes and inserts).
        Delta user = Delta()
          ..retain(index)
          ..insert(text)
          ..delete(length);
        int positionDelta = getPositionDelta(user, delta);
        _updateSelectionSilent(
          selection.copyWith(
            baseOffset: selection.baseOffset + positionDelta,
            extentOffset: selection.extentOffset + positionDelta,
          ),
          source: ChangeSource.local,
        );
      }
    }
    _lastChangeSource = ChangeSource.local;
    notifyListeners();
  }

  void formatText(int index, int length, NotusAttribute attribute) {
    final change = document.format(index, length, attribute);
    _lastChangeSource = ChangeSource.local;
    // Transform selection against the composed change and give priority to
    // the change. This is needed in cases when format operation actually
    // inserts data into the document (e.g. embeds).
    final base = change.transformPosition(_selection.baseOffset);
    final extent = change.transformPosition(_selection.extentOffset);
    final adjustedSelection =
        _selection.copyWith(baseOffset: base, extentOffset: extent);
    if (_selection != adjustedSelection) {
      _updateSelectionSilent(adjustedSelection, source: _lastChangeSource);
    }
    notifyListeners();
  }

  /// Formats current selection with [attribute].
  void formatSelection(NotusAttribute attribute) {
    int index = _selection.start;
    int length = _selection.end - index;
    formatText(index, length, attribute);
  }

  NotusStyle getSelectionStyle() {
    int start = _selection.start;
    int length = _selection.end - start;
    return _document.collectStyle(start, length);
  }

  TextEditingValue get plainTextEditingValue {
    return TextEditingValue(
      text: document.toPlainText(),
      selection: selection,
      composing: TextRange.collapsed(0),
    );
  }

  void _ensureSelectionBeforeLastBreak() {
    final end = _document.length - 1;
    final base = math.min(_selection.baseOffset, end);
    final extent = math.min(_selection.extentOffset, end);
    _selection = _selection.copyWith(baseOffset: base, extentOffset: extent);
  }
}
