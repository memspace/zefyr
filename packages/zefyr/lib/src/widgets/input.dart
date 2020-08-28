// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:zefyr/util.dart';

typedef RemoteValueChanged = Function(
    int start, String deleted, String inserted, TextSelection selection);

class InputConnectionController implements TextInputClient {
  InputConnectionController(this.onValueChanged)
      : assert(onValueChanged != null);

  //
  // public members
  //

  final RemoteValueChanged onValueChanged;

  /// Returns `true` if there is open input connection.
  bool get hasConnection =>
      _textInputConnection != null && _textInputConnection.attached;

  /// Opens or closes input connection based on the current state of
  /// [focusNode] and [value].
  void openOrCloseConnection(FocusNode focusNode, TextEditingValue value,
      Brightness keyboardAppearance) {
    if (focusNode.hasFocus && focusNode.consumeKeyboardToken()) {
      openConnection(value, keyboardAppearance);
    } else if (!focusNode.hasFocus) {
      closeConnection();
    }
  }

  void openConnection(TextEditingValue value, Brightness keyboardAppearance) {
    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = value;
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          obscureText: false,
          autocorrect: true,
          inputAction: TextInputAction.newline,
          keyboardAppearance: keyboardAppearance,
          textCapitalization: TextCapitalization.sentences,
        ),
      )
        ..show()
        ..setEditingState(value);
      _sentRemoteValues.add(value);
    } else {
      _textInputConnection.show();
    }
  }

  /// Closes input connection if it's currently open. Otherwise does nothing.
  void closeConnection() {
    if (hasConnection) {
      _textInputConnection.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _sentRemoteValues.clear();
    }
  }

  /// Updates remote value based on current state of [document] and
  /// [selection].
  ///
  /// This method may not actually send an update to native side if it thinks
  /// remote value is up to date or identical.
  void updateRemoteValue(TextEditingValue value) {
    if (!hasConnection) return;

    // Since we don't keep track of composing range in value provided by
    // ZefyrController we need to add it here manually before comparing
    // with the last known remote value.
    // It is important to prevent excessive remote updates as it can cause
    // race conditions.
    final actualValue = value.copyWith(
      composing: _lastKnownRemoteTextEditingValue.composing,
    );

    if (actualValue == _lastKnownRemoteTextEditingValue) return;

    final shouldRemember = value.text != _lastKnownRemoteTextEditingValue.text;
    _lastKnownRemoteTextEditingValue = actualValue;
    _textInputConnection.setEditingState(actualValue);
    if (shouldRemember) {
      // Only keep track if text changed (selection changes are not relevant)
      _sentRemoteValues.add(actualValue);
    }
  }

  //
  // Overridden members
  //

  @override
  void performAction(TextInputAction action) {
    // no-op
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    if (_sentRemoteValues.contains(value)) {
      /// There is a race condition in Flutter text input plugin where sending
      /// updates to native side too often results in broken behavior.
      /// TextInputConnection.setEditingValue is an async call to native side.
      /// For each such call native side _always_ sends update which triggers
      /// this method (updateEditingValue) with the same value we've sent it.
      /// If multiple calls to setEditingValue happen too fast and we only
      /// track the last sent value then there is no way for us to filter out
      /// automatic callbacks from native side.
      /// Therefore we have to keep track of all values we send to the native
      /// side and when we see this same value appear here we skip it.
      /// This is fragile but it's probably the only available option.
      _sentRemoteValues.remove(value);
      return;
    }

    if (_lastKnownRemoteTextEditingValue == value) {
      // There is no difference between this value and the last known value.
      return;
    }

    // Check if only composing range changed.
    if (_lastKnownRemoteTextEditingValue.text == value.text &&
        _lastKnownRemoteTextEditingValue.selection == value.selection) {
      // This update only modifies composing range. Since we don't keep track
      // of composing range in Zefyr we just need to update last known value
      // here.
      // Note: this check fixes an issue on Android when it sends
      // composing updates separately from regular changes for text and
      // selection.
      _lastKnownRemoteTextEditingValue = value;
      return;
    }

    // Note Flutter (unintentionally?) silences errors occurred during
    // text input update, so we have to report it ourselves.
    // For more details see https://github.com/flutter/flutter/issues/19191
    // TODO: remove try-catch when/if Flutter stops silencing these errors.
    try {
      final effectiveLastKnownValue = _lastKnownRemoteTextEditingValue;
      _lastKnownRemoteTextEditingValue = value;
      final oldText = effectiveLastKnownValue.text;
      final text = value.text;
      final cursorPosition = value.selection.extentOffset;
      final diff = fastDiff(oldText, text, cursorPosition);
      onValueChanged(diff.start, diff.deleted, diff.inserted, value.selection);
    } catch (e, trace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: trace,
        library: 'Zefyr',
        context: ErrorSummary('while updating editing value'),
      ));
      rethrow;
    }
  }

  @override
  TextEditingValue get currentTextEditingValue =>
      _lastKnownRemoteTextEditingValue;

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  @override
  void connectionClosed() {
    if (hasConnection) {
      _textInputConnection.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _sentRemoteValues.clear();
    }
  }

  //
  // Private members
  //

  final List<TextEditingValue> _sentRemoteValues = [];
  TextInputConnection _textInputConnection;
  TextEditingValue _lastKnownRemoteTextEditingValue;

  // TODO: figure out if we need to support autofill
  @override
  AutofillScope get currentAutofillScope => null;

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }
}
