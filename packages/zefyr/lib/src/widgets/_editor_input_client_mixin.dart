import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:zefyr/util.dart';

import '_editor.dart';

mixin RawEditorStateTextInputClientMixin on EditorState
    implements TextInputClient {
  final List<TextEditingValue> _sentRemoteValues = [];
  TextInputConnection _textInputConnection;
  TextEditingValue _lastKnownRemoteTextEditingValue;

  void _remoteValueChanged(
      int start, String deleted, String inserted, TextSelection selection) {
    widget.controller
        .replaceText(start, deleted.length, inserted, selection: selection);
  }

  /// Returns `true` if there is open input connection.
  bool get hasConnection =>
      _textInputConnection != null && _textInputConnection.attached;

  /// Opens or closes input connection based on the current state of
  /// [focusNode] and [value].
  void openOrCloseConnection() {
    if (widget.focusNode.hasFocus && widget.focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded();
    } else if (!widget.focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  void openConnectionIfNeeded() {
    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = textEditingValue;
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          obscureText: false,
          autocorrect: widget.autocorrect,
          inputAction: TextInputAction.newline,
          keyboardAppearance: widget.keyboardAppearance,
          textCapitalization: widget.textCapitalization,
        ),
      );

      _updateSizeAndTransform();
      _textInputConnection.setEditingState(_lastKnownRemoteTextEditingValue);

      _sentRemoteValues.add(_lastKnownRemoteTextEditingValue);
    }
    _textInputConnection.show();
  }

  /// Closes input connection if it's currently open. Otherwise does nothing.
  void closeConnectionIfNeeded() {
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
  void updateRemoteValueIfNeeded() {
    if (!hasConnection) return;

    final value = textEditingValue;

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

  // Start TextInputClient implementation
  @override
  TextEditingValue get currentTextEditingValue =>
      _lastKnownRemoteTextEditingValue;

  // autofill is not needed
  @override
  AutofillScope /*?*/ get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    if (_sentRemoteValues.contains(value)) {
      /// There is a race condition in Flutter text input plugin where sending
      /// updates to native side too often results in broken behavior.
      /// TextInputConnection.setEditingValue is an async call to native side.
      /// For each such call native side _always_ an sends update which triggers
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
      // This check fixes an issue on Android when it sends
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
      _remoteValueChanged(
          diff.start, diff.deleted, diff.inserted, value.selection);
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
  void performAction(TextInputAction action) {
    // no-op
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // no-op
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    throw UnimplementedError();
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    throw UnimplementedError();
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

  void _updateSizeAndTransform() {
    if (hasConnection) {
      final size = renderEditor.size;
      final transform = renderEditor.getTransformTo(null);
      _textInputConnection.setEditableSizeAndTransform(size, transform);
      SchedulerBinding.instance
          .addPostFrameCallback((Duration _) => _updateSizeAndTransform());
    }
  }
}
