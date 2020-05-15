import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../rendering/editor.dart';

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// The time the cursor is static in opacity before animating to become
// transparent.
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

class CursorController {
  CursorController({
    @required this.cursorColor,
    @required TickerProvider tickerProvider,
    @required this.showCursor,
    @required bool cursorOpacityAnimates,
    @required this.onCursorColorChanged,
  })  : assert(cursorColor != null),
        assert(tickerProvider != null),
        assert(showCursor != null),
        assert(cursorOpacityAnimates != null),
        assert(onCursorColorChanged != null),
        _cursorBlink = ValueNotifier(false),
        cursorOpacityAnimates = cursorOpacityAnimates {
    _cursorBlinkOpacityController =
        AnimationController(vsync: tickerProvider, duration: _fadeDuration);
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
  }

  // This value is an eyeball estimation of the time it takes for the iOS cursor
  // to ease in and out.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  final bool showCursor;
  final bool cursorOpacityAnimates;
  final ValueChanged<Color> onCursorColorChanged;

  Timer _cursorTimer;
  bool _targetCursorVisibility = false;

  AnimationController _cursorBlinkOpacityController;

  Color get _actualCursorColor =>
      cursorColor.withOpacity(_cursorBlinkOpacityController.value);
  Color cursorColor;

  ValueNotifier<bool> get cursorBlink => _cursorBlink;
  final ValueNotifier<bool> _cursorBlink;

  void dispose() {
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    stopCursorTimer();
    assert(_cursorTimer == null);
  }

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final double targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (cursorOpacityAnimates) {
      // If we want to show the cursor, we will animate the opacity to the value
      // of 1.0, and likewise if we want to make it disappear, to 0.0. An easing
      // curve is used for the animation to mimic the aesthetics of the native
      // iOS cursor.
      //
      // These values and curves have been obtained through eyeballing, so are
      // likely not exactly the same as the values for native iOS.
      _cursorBlinkOpacityController.animateTo(targetOpacity,
          curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController.value = targetOpacity;
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void startCursorTimer() {
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController.value = 1.0;

    if (cursorOpacityAnimates) {
      _cursorTimer =
          Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void stopCursorTimer({bool resetCharTicks = true}) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController.value = 0.0;

    if (cursorOpacityAnimates) {
      _cursorBlinkOpacityController.stop();
      _cursorBlinkOpacityController.value = 0.0;
    }
  }

  void startOrStopCursorTimerIfNeeded(bool hasFocus, TextSelection selection) {
    if (_cursorTimer == null && hasFocus && selection.isCollapsed) {
      startCursorTimer();
    } else if (_cursorTimer != null && (!hasFocus || !selection.isCollapsed)) {
      stopCursorTimer();
    }
  }

  void _onCursorColorTick() {
    onCursorColorChanged(_actualCursorColor);
    cursorBlink.value = showCursor && _cursorBlinkOpacityController.value > 0;
  }
}

class FloatingCursorController {
  FloatingCursorController({
    @required TickerProvider tickerProvider,
  }) {
    _floatingCursorResetController = AnimationController(vsync: tickerProvider);
    _floatingCursorResetController.addListener(_onFloatingCursorResetTick);
  }

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  AnimationController _floatingCursorResetController;

  // The original position of the caret on FloatingCursorDragState.start.
  Rect _startCaretRect;

  // The most recent text position as determined by the location of the floating
  // cursor.
  TextPosition _lastTextPosition;

  // The offset of the floating cursor as determined from the first update call.
  Offset _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset _lastBoundedOffset;

  // Because the center of the cursor is preferredLineHeight / 2 below the touch
  // origin, but the touch origin is used to determine which line the cursor is
  // on, we need this offset to correctly render and move the cursor.
  Offset get _floatingCursorOffset =>
      Offset(0, renderEditor.preferredLineHeight / 2);

  void updateFloatingCursor(
      RawFloatingCursorPoint point, RenderEditor renderEditor) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (_floatingCursorResetController.isAnimating) {
          _floatingCursorResetController.stop();
          _onFloatingCursorResetTick();
        }
        final TextPosition currentTextPosition =
            TextPosition(offset: renderEditor.selection.baseOffset);
        _startCaretRect =
            renderEditor.getLocalRectForCaret(currentTextPosition);
        renderEditor.setFloatingCursor(
            point.state,
            _startCaretRect.center - _floatingCursorOffset,
            currentTextPosition);
        break;
      case FloatingCursorDragState.Update:
        // We want to send in points that are centered around a (0,0) origin, so we cache the
        // position on the first update call.
        if (_pointOffsetOrigin != null) {
          final Offset centeredPoint = point.offset - _pointOffsetOrigin;
          final Offset rawCursorOffset =
              _startCaretRect.center + centeredPoint - _floatingCursorOffset;
          _lastBoundedOffset = renderEditor
              .calculateBoundedFloatingCursorOffset(rawCursorOffset);
          _lastTextPosition = renderEditor.getPositionForPoint(renderEditor
              .localToGlobal(_lastBoundedOffset + _floatingCursorOffset));
          renderEditor.setFloatingCursor(
              point.state, _lastBoundedOffset, _lastTextPosition);
        } else {
          _pointOffsetOrigin = point.offset;
        }
        break;
      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          _floatingCursorResetController.value = 0.0;
          _floatingCursorResetController.animateTo(1.0,
              duration: _floatingCursorResetTime, curve: Curves.decelerate);
        }
        break;
    }
  }

  void dispose() {
    _floatingCursorResetController.removeListener(_onFloatingCursorResetTick);
  }

  void _onFloatingCursorResetTick() {
    final Offset finalPosition =
        renderEditable.getLocalRectForCaret(_lastTextPosition).centerLeft -
            _floatingCursorOffset;
    if (_floatingCursorResetController.isCompleted) {
      renderEditable.setFloatingCursor(
          FloatingCursorDragState.End, finalPosition, _lastTextPosition);
      if (_lastTextPosition.offset != renderEditable.selection.baseOffset)
        // The cause is technically the force cursor, but the cause is listed as tap as the desired functionality is the same.
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _lastTextPosition.offset),
            renderEditable,
            SelectionChangedCause.forcePress);
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final double lerpValue = _floatingCursorResetController.value;
      final double lerpX =
          ui.lerpDouble(_lastBoundedOffset.dx, finalPosition.dx, lerpValue);
      final double lerpY =
          ui.lerpDouble(_lastBoundedOffset.dy, finalPosition.dy, lerpValue);

      renderEditable.setFloatingCursor(FloatingCursorDragState.Update,
          Offset(lerpX, lerpY), _lastTextPosition,
          resetLerpValue: lerpValue);
    }
  }
}
